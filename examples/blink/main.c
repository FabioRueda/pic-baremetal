/*
 * Minimal LED blink for PIC18F47Q10 - TOOLCHAIN TEST ONLY.
 * Change the device, the pins and the CONFIG to match your real board.
 * LED assumed on RB0 (change LED_*), internal oscillator at 64 MHz.
 */
#include <xc.h>

/* CONFIG - names checked against 18f47q10.html in the PIC18F-Q_DFP. */
#pragma config FEXTOSC = OFF            // no external oscillator
#pragma config RSTOSC = HFINTOSC_64MHZ  // HFINTOSC 64 MHz, CDIV 1:1 right from reset
#pragma config CLKOUTEN = OFF           // RA6 as I/O, no CLKOUT
#pragma config CSWEN = ON               // allow clock switching in software
#pragma config FCMEN = OFF              // no Fail-Safe Clock Monitor (there is no crystal)
#pragma config MCLRE = EXTMCLR          // RE3 is MCLR (external reset kept)
#pragma config PWRTE = OFF              // power-up timer off
#pragma config BOREN = SBORDIS          // brown-out reset always on
#pragma config BORV = VBOR_190          // BOR threshold at 1.90 V
#pragma config LVP = ON                 // factory default; keeps MCLR and allows LVP
#pragma config XINST = OFF              // extended instruction set OFF (XC8 requires it)
#pragma config STVREN = ON              // stack overflow/underflow causes reset
#pragma config WDTE = OFF               // watchdog off
#pragma config WDTCWS = WDTCWS_7        // WDT window: factory default (no effect with WDT OFF)
#pragma config WDTCCS = SC              // WDT clock: factory default
#pragma config WRT0 = OFF, WRT1 = OFF, WRT2 = OFF, WRT3 = OFF  // flash not write-protected
#pragma config WRT4 = OFF, WRT5 = OFF, WRT6 = OFF, WRT7 = OFF
#pragma config CP = OFF                 // no code protection
#pragma config CPD = OFF                // no EEPROM protection
#pragma config WRTC = OFF               // CONFIG not write-protected

#define _XTAL_FREQ 64000000UL           // = RSTOSC above; used by __delay_ms

#define LED_TRIS  TRISBbits.TRISB0
#define LED_ANSEL ANSELBbits.ANSELB0
#define LED_LAT   LATBbits.LATB0

void main(void)
{
    LED_ANSEL = 0;  // digital pin (Q10 comes out of reset with ANSEL = analog)
    LED_TRIS = 0;   // output
    LED_LAT = 0;

    while (1) {
        LED_LAT = !LED_LAT;  // write the latch, not PORT
        __delay_ms(500);
    }
}
