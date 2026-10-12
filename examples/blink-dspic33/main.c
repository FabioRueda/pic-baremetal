/*
 * Minimal LED blink for dsPIC33CK256MP508 (XC-DSC) - TOOLCHAIN TEST ONLY.
 * Change the device, the pins and the CONFIG to match your real board.
 * LED assumed on RE0, internal FRC oscillator at 8 MHz.
 */
#include <xc.h>

/* CONFIG - names checked against config_docs/33CK256MP508.html in the dsPIC33CK-MP_DFP.
 * On this chip MCLR is always reset (there is no fuse to disable it). */
#pragma config FNOSC = FRC       // FRC 8 MHz, no PLL
#pragma config IESO = OFF        // start directly on the selected oscillator
#pragma config POSCMD = NONE     // no primary oscillator (no crystal)
#pragma config OSCIOFNC = ON     // OSC2 as I/O
#pragma config FCKSM = CSDCMD    // no clock switching and no Fail-Safe Clock Monitor
#pragma config FWDTEN = ON_SW    // watchdog software-controlled only (WDTCON.ON = 0 at reset: off)
#pragma config DMTDIS = OFF      // Dead Man Timer off
#pragma config JTAGEN = OFF      // JTAG off
#pragma config ICS = PGD1        // debugger channel: PGC1/PGD1; check your board
#pragma config GSS = DISABLED    // no code protection (general segment)
#pragma config GWRP = OFF        // general segment not write-protected
#pragma config CSS = DISABLED    // no code protection (configuration segment)
#pragma config CWRP = OFF        // CONFIG not write-protected
#pragma config BSEN = OFF        // no boot segment

#define FCY 4000000UL            // Fcy = Fosc/2 = 8 MHz/2; used by __delay_ms
#include <libpic30.h>            // must come after FCY

int main(void)
{
    ANSELEbits.ANSELE0 = 0;      // digital pin (comes out of reset as analog)
    TRISEbits.TRISE0 = 0;        // output
    LATEbits.LATE0 = 0;

    while (1) {
        LATEbits.LATE0 ^= 1;     // write the latch, not PORT
        __delay_ms(500);
    }
}
