/*============================================================
  arduino_spi_slave.ino
  Arduino Uno -- SPI hardware slave for FPGA demo

  Protocol (each button press on FPGA):
    1. FPGA (master) pulls CS_N LOW and sends 8 SPI clock pulses.
    2. Both sides transfer simultaneously (full-duplex):
         MOSI: FPGA sends SW[7:0]
         MISO: Arduino sends the pre-loaded response
    3. FPGA pulls CS_N HIGH -> SPI_STC interrupt fires on Arduino.
    4. ISR reads the received byte, prints it over Serial,
       and pre-loads SPDR with (received + 1) for the NEXT transfer.
    5. FPGA latches what it received onto LED[7:0].

  First-transfer note:
    On power-up SPDR is pre-loaded with 0x01, so the VERY FIRST
    transfer will show 0x01 on the FPGA LEDs regardless of SW.
    Every subsequent transfer correctly shows (previous SW + 1).

  Overflow:
    0xFF + 1 wraps to 0x00 (uint8 arithmetic -- expected).

  SPI Mode 0 (CPOL=0, CPHA=0), MSB first, 1 MHz -- matches FPGA.
============================================================*/

// ---- Shared state between ISR and loop() ------------------
volatile uint8_t g_received = 0;
volatile bool    g_newData  = false;

// ---- SPI Transfer Complete interrupt ----------------------
ISR(SPI_STC_vect) {
    g_received = SPDR;           // read byte that FPGA sent
    SPDR       = g_received + 1; // pre-load (received+1) for NEXT transfer
    g_newData  = true;
}

void setup() {
    Serial.begin(115200);

    // Configure SPI pins for slave operation
    pinMode(MISO, OUTPUT);   // slave drives MISO
    pinMode(MOSI, INPUT);    // master drives MOSI
    pinMode(SCK,  INPUT);    // master drives SCK
    pinMode(SS,   INPUT);    // master drives SS -- must be INPUT for slave

    /*
      SPCR register bits:
        Bit 7 SPIE = 1  enable SPI interrupt
        Bit 6 SPE  = 1  enable SPI peripheral
        Bit 5 DORD = 0  MSB first (matches FPGA)
        Bit 4 MSTR = 0  slave mode
        Bit 3 CPOL = 0  clock idles LOW  (Mode 0)
        Bit 2 CPHA = 0  sample on rising edge (Mode 0)
    */
    SPCR = (1 << SPE) | (1 << SPIE);   // 0b11000000

    SPDR = 0x01;    // first response pre-loaded

    sei();          // enable global interrupts

    Serial.println(F("=============================================="));
    Serial.println(F("  Arduino SPI Slave -- FPGA demo"));
    Serial.println(F("  Set SW[7:0] on FPGA and press BTND."));
    Serial.println(F("  LEDs show what Arduino sent back (SW+1)."));
    Serial.println(F("  NOTE: first LED result = 0x01 (normal)."));
    Serial.println(F("=============================================="));
    Serial.println(F("  RECEIVED (FPGA)    SENT BACK (FPGA LEDs)"));
    Serial.println(F("----------------------------------------------"));
}

void loop() {
    if (g_newData) {
        noInterrupts();
        uint8_t rx = g_received;
        g_newData  = false;
        interrupts();

        uint8_t tx = (uint8_t)(rx + 1);

        Serial.print(F("  0x"));
        if (rx < 0x10) Serial.print('0');
        Serial.print(rx, HEX);
        Serial.print(F("  (dec "));
        if (rx < 100) Serial.print(' ');
        if (rx < 10)  Serial.print(' ');
        Serial.print(rx, DEC);
        Serial.print(F(")"));

        Serial.print(F("           0x"));
        if (tx < 0x10) Serial.print('0');
        Serial.print(tx, HEX);
        Serial.print(F("  (dec "));
        if (tx < 100) Serial.print(' ');
        if (tx < 10)  Serial.print(' ');
        Serial.print(tx, DEC);
        Serial.println(F(")"));
    }
}
