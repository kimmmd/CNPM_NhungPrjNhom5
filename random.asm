GET_RANDOM:

RND_RETRY:
    MOV A, TL0

    ; Neu A = 252 thi doc lai
    CJNE A, #0FCH, RND_COMPARE
    SJMP RND_RETRY

RND_COMPARE:
    ; Neu A >= 252 thi doc lai
    JNC RND_RETRY

    ; Chia cho 6
    MOV B, #06H
    DIV AB

    ; Lay so du va cong 1
    MOV A, B
    INC A

    RET
