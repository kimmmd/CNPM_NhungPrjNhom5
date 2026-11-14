; ==============================================================================
; FILE THỬ NGHIỆM PHẦN CỦA KHOA (main_test.asm)
; ==============================================================================

$INCLUDE (quy_uoc.inc)

        ORG     0000H
        LJMP    START

        ORG     0030H
START:
        MOV     SP, #60H
        MOV     TMOD, #11H

TEST_LOOP:
        LCALL   WAIT_IDLE

        MOV     A, #1
        LCALL   DISPLAY
        MOV     R7, #250
        LCALL   DELAY_MS

        MOV     A, #6
        LCALL   DISPLAY
        MOV     R7, #250
        LCALL   DELAY_MS

        MOV     A, #DASH
        LCALL   DISPLAY
        MOV     R7, #500
        LCALL   DELAY_MS

        SJMP    TEST_LOOP

$INCLUDE (display.asm)

        END
