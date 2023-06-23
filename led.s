/*
* r8-> primeiro caractere do bufer
* r9-> primeiro caracter que indica o led
* r10 -> segundo caracter que indica o led
* r11 -> índice do led para acender.
* r12 -> endereço dos leds vermelhos
*
* r15 -> temporario
* r16 -> temporário
*/
.global ledOn
.equ LEDS_VERMELHOS, 0x10000000

ledOn:
    movia r8, LIST #endereço primeiro elemento do buffer
    ldb r9, 2(r8) #dezena
    ldb r10, 3(r8) #unidade

    addi r9, r9, -0x30      #subtrai 30 de cada caracter para obter o número
    addi r10, r10, -0x30

    mov r11, r10            #soma os números para obter o índice do led

    beq r9, r0, UNIDADE_ON #se for 1, soma 10 ao índice
    addi r11, r11, 10

UNIDADE_ON:
    movi r16, 1
    sll r16, r16, r11

    movia r12, LEDS_VERMELHOS #soma com a base do endereço dos leds 
    ldwio r15, 0(r12) #carrega os leds acessos para r15
    or r16, r16, r15
    stwio r16, 0(r12)
    ret

.global ledOff

ledOff:
    movia r8, LIST #endereço primeiro elemento do buffer
    ldb r9, 2(r8) #dezena
    ldb r10, 3(r8) #unidade

    addi r9, r9, -0x30      #subtrai 30 de cada caracter para obter o número
    addi r10, r10, -0x30

    mov r11, r10            #soma os números para obter o índice do led

    beq r9, r0, UNIDADE_OFF #se for 1, soma 10 ao índice
    addi r11, r11, 10

UNIDADE_OFF:
    movi r16, 1
    sll r16, r16, r11

    movia r12, LEDS_VERMELHOS #soma com a base do endereço dos leds 
    ldwio r15, 0(r12) #carrega os leds acessos para r15
    xor r16, r16, r15
    and r16, r16, r15
    stwio r16, 0(r12)
    ret
