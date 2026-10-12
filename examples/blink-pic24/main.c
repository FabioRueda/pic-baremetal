/*
 * Minimal LED blink for PIC24FJ128GA010 (XC16) - TOOLCHAIN TEST ONLY.
 * Change the device, the pins and the CONFIG to match your real board.
 * LED assumed on RA0 (LED D3 on the Explorer 16), internal FRC oscillator at 8 MHz.
 */
#include <xc.h>

/* CONFIG - names checked against config_docs/24FJ128GA010.html in the PIC24F-GA-GB_DFP.
 * On this chip MCLR is always reset (there is no fuse to disable it). */
#pragma config FNOSC = FRC       // FRC 8 MHz, no PLL
#pragma config POSCMOD = NONE    // no primary oscillator (no crystal)
#pragma config OSCIOFNC = ON     // OSC2 as I/O
#pragma config FCKSM = CSDCMD    // no clock switching and no Fail-Safe Clock Monitor
#pragma config IESO = OFF        // no two-speed start-up
#pragma config FWDTEN = OFF      // watchdog off
#pragma config JTAGEN = OFF      // JTAG off: frees RA0/RA1/RA4/RA5 as I/O
#pragma config ICS = PGx2        // debugger channel: PGC2/PGD2 (Explorer 16); check your board
#pragma config GCP = OFF         // no code protection
#pragma config GWRP = OFF        // flash not write-protected

#define FCY 4000000UL            // Fcy = Fosc/2 = 8 MHz/2; used by __delay_ms
#include <libpic30.h>            // must come after FCY

int main(void)
{
    TRISAbits.TRISA0 = 0;        // output (PORTA on this chip has no analog function)
    LATAbits.LATA0 = 0;

    while (1) {
        LATAbits.LATA0 ^= 1;     // write the latch, not PORT
        __delay_ms(500);
    }
}
