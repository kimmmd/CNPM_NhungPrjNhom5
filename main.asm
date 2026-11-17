; ==============================================================================
; CHUONG TRINH CHINH - main.asm
; Tac gia : Kim (nguoi 1 & nguoi 4)
; Mo ta   : Xuc xac dien tu 8051
;           Nhan nut -> hieu ung quay -> dung o so ngau nhien 1-6 -> giu 3s
; Chip    : AT89C51, 12 MHz (1 chu ky may = 1 us)
; Quy uoc : Xem quy_uoc.inc
; Build   : Chi build file nay trong Keil (Add main.asm vao project)
;           display.asm va input.asm duoc include tu dong
; ==============================================================================

$INCLUDE (quy_uoc.inc)

; ------------------------------------------------------------------------------
; VUNG VECTOR NGAT
; ------------------------------------------------------------------------------
        ORG     0000H
        LJMP    START           ; Vector reset -> nhay thang vao START

; (Cac vector ngat khac khong dung, bo trong)

; ------------------------------------------------------------------------------
; CHUONG TRINH CHINH
; ------------------------------------------------------------------------------
        ORG     0030H

START:
        ; --- Khoi tao he thong ---
        MOV     SP,   #60H      ; Doi Stack len 60H, tranh de len vung thanh ghi va bit
        MOV     TMOD, #11H      ; Timer0 Mode1 (16-bit), Timer1 Mode1 (16-bit)
                                ; Chi MAIN duoc ghi TMOD, chuong trinh con khong duoc đung vao

        LCALL   RND_INIT_TIMER0 ; Bat Timer0 chay tu do (lay so ngau nhien)

; ------------------------------------------------------------------------------
; VONG LAP CHINH (May trang thai)
;   S0 - CHO : WAIT_IDLE chay hieu ung vien, cho nhan nut
;   S1 - QUAY: (Kim tu viet hieu ung dem cham dan o day)
;   S2 - NGAU NHIEN : GET_RANDOM lay ket qua
;   S3 - HIEN THI   : DISPLAY hien so, giu 3 giay
;   -> quay lai S0
; ------------------------------------------------------------------------------

MAIN_LOOP:

        ; === S0: CHO NUT NHAN ===
        LCALL   WAIT_IDLE

        ; === S1+S2+S3: HIEU UNG + RANDOM + HIEN THI ===
        LCALL   GET_RANDOM      ; A = 1..6
        MOV     R4, A           ; Luu vao R4
        LCALL   EFF_SPIN_AND_BLINK  ; A = so ngau nhien, tu xu ly hieu ung + hien thi

        SJMP    MAIN_LOOP

; ------------------------------------------------------------------------------
; INCLUDE CAC MODULE CHUONG TRINH CON
; (Dat sau code chinh de CPU khong chay lot vao giua chuong trinh con khi reset)
; ------------------------------------------------------------------------------
$INCLUDE (display.asm)          ; DISPLAY, DELAY_MS, WAIT_IDLE      - tac gia: Khoa
$INCLUDE (input.asm)            ; RND_INIT_TIMER0, GET_RANDOM       - tac gia: Cuong
$INCLUDE (effect.asm)           ; EFF_SPIN_AND_BLINK                - tac gia: Kim

        END
