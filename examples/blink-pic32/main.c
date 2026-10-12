/*
 * Minimal LED blink for PIC32MX795F512L (XC32) - TOOLCHAIN TEST ONLY.
 * Change the device, the pins and the CONFIG to match your real board.
 * LED assumed on RD0 (LED1 on the PIC32 Starter Kit), internal FRC oscillator at 8 MHz.
 */
#include <xc.h>

/* CONFIG - names checked against xc32\v4.60\docs\config_docs\32mx795f512l.html.
 * Clock: FRC 8 MHz -> SYSCLK 8 MHz (no PLL) -> PBCLK 8 MHz (FPBDIV 1:1).
 * On this chip MCLR is always reset (there is no fuse to disable it). */
#pragma config FNOSC = FRC       // FRC 8 MHz, no PLL
#pragma config FPBDIV = DIV_1    // peripheral clock = SYSCLK
#pragma config POSCMOD = OFF     // no primary oscillator (no crystal)
#pragma config FSOSCEN = OFF     // no secondary oscillator
#pragma config OSCIOFNC = OFF    // no CLKO on the OSCO pin
#pragma config FCKSM = CSDCMD    // no clock switching and no Fail-Safe Clock Monitor
#pragma config IESO = OFF        // no two-speed start-up
#pragma config FWDTEN = OFF      // watchdog off
#pragma config DEBUG = OFF       // MPLAB turns it on by itself when debugging
#pragma config ICESEL = ICS_PGx2 // debugger channel: PGC2/PGD2 (Starter Kit); check your board
#pragma config PWP = OFF         // program flash not write-protected
#pragma config BWP = OFF         // boot flash not write-protected
#pragma config CP = OFF          // no code protection

#define SYSCLK 8000000UL
#define CORE_TICKS_PER_MS (SYSCLK / 2 / 1000)  // the core timer counts at SYSCLK/2

static void delay_ms(unsigned ms)
{
    unsigned start = _CP0_GET_COUNT();
    while ((unsigned)(_CP0_GET_COUNT() - start) < ms * CORE_TICKS_PER_MS)
        ;  // unsigned subtraction: works even when the counter wraps around
}

int main(void)
{
    TRISDbits.TRISD0 = 0;        // output (PORTD on this chip has no analog function)
    LATDbits.LATD0 = 0;

    while (1) {
        LATDbits.LATD0 ^= 1;     // write the latch, not PORT
        delay_ms(500);
    }
}
