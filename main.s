/*
    --Eduardo Neves Paschoal & João Pedro Rodrigues Martins--

    === Funcionamento da leitura de entrada: ===
    start:
        laço infinito:
            polling de leitura:
            c <- le data register
            if(rvalid == 0) goto Polling leitura

            polling escrtia
                w <- le registrador controle
                se w == cheio goto polling escrtia
                escreve C no registrador de dados [stwio no registrador]
     =============================================
    Registradores em uso:
    r8 -> data - ULTIMO CARACTERE DE ENTRADA - GLOBAL
    r9 ->  Polling_Leitura -> rvalid
    r10 -> Polling_Leitura -> leitura do registrador | Polling_Escrita ->  wspace 
    r11 -> DATA_REGISTER  - GLOBAL
    r12 -> CONTROL_REGISTER

    r13 -> tamanho usado do buffer - GLOBAL
    r14 -> POLLING_ESCRITA -> endereço para ultimo elemento do buffer | Parsing -> Ultimo caractere processado do buffer
    r15 -> temporário
    r16 -> temporário
*/

.global _start
.equ DATA_REGISTER, 0x10001000    #REGISTRADOR DA UART
.equ CONTROL_REGISTER, 0x10001004 
.equ TIMER_BASE_ADDRESS, 0x10002000
.equ baseAddress, 0x10002000 #endereço registrador TO
.equ BOTAO, 0x1000005C #botão 

.org 0x20
    #Handler de exceções
    rdctl et, ipending               
    beq et, r0, OUTRA_EXCECAO        #se interrupção foi gerada por hardware
    subi ea, ea, 4                   #Subtrai 4 do pc, ea = r29
    
    andi r13, et, 0b1                #mascara para checar irq0
    beq r13, r0, OUTRA_INTERRUPCAO
    

    #stackframe
    addi sp, sp, -32
    stw r8, (sp)
    stw r9, 4(sp)
    stw r10, 8(sp)
    stw r11, 12(sp)
    stw r12, 16(sp)
    stw r13, 20(sp)
    stw r14, 24(sp)
    stw r15, 28(sp)


    call animation  #Invoca animação


    movia r8, ENABLE_CRON #verifica se cronometro ativo
    ldw r8, 0(r8)

    beq r8, r0, END_HANDLER     #se não tiver ativo o cronometro, termina
    movia r8, ONE_SEC_FLAG
    ldw r9, 0(r8) #carrega contador
    addi r9, r9, 1 #incrementa contador

    movi r10, 5
    beq r9, r10, RESET_COUNTER #se rodou 5 vezes (1 segundo)
    stw r9, 0(r8)

    br END_HANDLER

RESET_COUNTER:
    stw r0, 0(r8)
    call updateCron

END_HANDLER:
    #escreve 0 no bit TO
    movia r14, baseAddress 
    stwio r0, 0(r14) 

    #Epílogo
    ldw r8, (sp)
    ldw r9, 4(sp)
    ldw r10, 8(sp)
    ldw r11, 12(sp)
    ldw r12, 16(sp)
    ldw r13, 20(sp)
    ldw r14, 24(sp)
    ldw r15, 28(sp)
    addi sp, sp, 32    

OUTRA_INTERRUPCAO:
OUTRA_EXCECAO:
FIM_HANDLER:
    eret

_start:

CONFIGURACAO_TIMER:
    #Habilitar interrupção do dispostivo
    #habilitar no inable PB->IRQ1
    movi r15, 1
    wrctl ienable, r15 
    
    #Habilitar bit PIE do processador
    movi r15, 0x1
    wrctl status, r15

    #configura timer
    movia r15, TIMER_BASE_ADDRESS

    #10 milhoes de ciclos 
    movia r14, 10000000 #10000000
    andi r11, r14, 0xFFFF
    stwio r11, 8(r15) 

    srli r14, r14, 16
    stwio r14, 0xC(r15) 

    movi r14, 7
    stwio r14, 4(r15)

CONFIGURACAO_BASICA:

    movia r11, DATA_REGISTER
    movia r15, MENU             #Endereço da string de menu
    movia sp, 0x10000           #Stack pointer
    
    movia r16, SIZE     #Quantidade de elementos no buffer
    mov r13, r0
    stw r13, 0(r16)     #zera o tamanho do buffer

WRITE_MENU:
    ldb r16, 0(r15)     #Carrega caractere
    addi r15, r15, 1    #Incrementa contador
    stbio r16, 0(r11)   #ESCREVE NA TELA
    bne r16, r0, WRITE_MENU #Enquanto não for 0 continua no escrevendo
    
    movi r16, 0x0A      #Enter para enviar
    stbio r16, 0(r11)

POLLING_LEITURA: #Aguarda entrada do usuario
    #Le entrada de botão
    movia r17, BOTAO
    ldwio r18, 0(r17) #carrega dados do botao
    andi r18,r18,0b0010  #mascara para verificar botao apertado
    stwio r0, 0(r17)
    bne r18, r0, BOTAO_APERTADO

    #Le entrada de teclado
    ldwio r10, (r11)

    andi r8, r10, 0xFF # pega os bits referentes ao data

    srli r9, r10, 15
    andi r9, r9, 0b1  # pega os bits referentes ao rvalid
    beq r9, r0, POLLING_LEITURA

POLLING_ESCRITA:        #Processa entrada do usuario
    movia r12, CONTROL_REGISTER
    ldwio r12, (r12)

    srli r10, r12, 16   #pega os bits referentes ao wspace
    beq r10, r0, POLLING_ESCRITA

    stbio r8, (r11)     #Escreve na tela, o último caractere de entrada

    #--Armazena entrada no buffer --
    movia r16, SIZE     #quantidade de elementos no buffer
    ldw r13, 0(r16)     #carrega valor de size para r13
    movia r14, LIST     #endereço primeiro elemento do buffer
    add r14, r14, r13
    stb	r8,	0(r14)  #armazena caractere no buffer
    
    #Adiciona 1 no size
    addi r13, r13, 1
    stw r13, 0(r16)

    #--Se for enter(0x0D), processa entrada-- 
    movi r15, 0x0A
    beq r8, r15, PARSING

    br POLLING_LEITURA

PARSING:
    #PARSER/SWITCH DE FUNÇÃO
    movia r14, LIST #endereço primeiro elemento do buffer
    ldb r15, 0(r14)

    movi r16, 0x30
    beq r15, r16, CASE_0XXX

    movi r16, 0x31
    beq r15, r16, CASE_1X

    movi r16, 0x32
    beq r15, r16, CASE_2x

    br CONFIGURACAO_BASICA #Volta para inicio

#0
CASE_0XXX:

    ldb r15, 1(r14)

    movi r16, 0x30
    beq r15, r16, CASE_00XX

    movi r16, 0x31
    beq r15, r16, CASE_01XX

    br CONFIGURACAO_BASICA

CASE_00XX:
    #stackframe
    addi sp, sp, -32
    stw r8, (sp)
    stw r9, 4(sp)
    stw r10, 8(sp)
    stw r11, 12(sp)
    stw r12, 16(sp)
    stw r13, 20(sp)
    stw r14, 24(sp)
    stw r15, 28(sp)

    call ledOn

    ldw r8, (sp)
    ldw r9, 4(sp)
    ldw r10, 8(sp)
    ldw r11, 12(sp)
    ldw r12, 16(sp)
    ldw r13, 20(sp)
    ldw r14, 24(sp)
    ldw r15, 28(sp)
    addi sp, sp, 32

    br CONFIGURACAO_BASICA

CASE_01XX:
    #stackframe
    addi sp, sp, -32
    stw r8, (sp)
    stw r9, 4(sp)
    stw r10, 8(sp)
    stw r11, 12(sp)
    stw r12, 16(sp)
    stw r13, 20(sp)
    stw r14, 24(sp)
    stw r15, 28(sp)

    call ledOff

    ldw r8, (sp)
    ldw r9, 4(sp)
    ldw r10, 8(sp)
    ldw r11, 12(sp)
    ldw r12, 16(sp)
    ldw r13, 20(sp)
    ldw r14, 24(sp)
    ldw r15, 28(sp)
    addi sp, sp, 32

    br CONFIGURACAO_BASICA

#1
CASE_1X:
    #stackframe
    addi sp, sp, -32
    stw r8, (sp)
    stw r9, 4(sp)
    stw r10, 8(sp)
    stw r11, 12(sp)
    stw r12, 16(sp)
    stw r13, 20(sp)
    stw r14, 24(sp)
    stw r15, 28(sp)

    call animationController

    ldw r8, (sp)
    ldw r9, 4(sp)
    ldw r10, 8(sp)
    ldw r11, 12(sp)
    ldw r12, 16(sp)
    ldw r13, 20(sp)
    ldw r14, 24(sp)
    ldw r15, 28(sp)
    addi sp, sp, 32

    br CONFIGURACAO_BASICA

#2
CASE_2x:
    #stackframe
    addi sp, sp, -32
    stw r8, (sp)
    stw r9, 4(sp)
    stw r10, 8(sp)
    stw r11, 12(sp)
    stw r12, 16(sp)
    stw r13, 20(sp)
    stw r14, 24(sp)
    stw r15, 28(sp)

    call cronometro

    ldw r8, (sp)
    ldw r9, 4(sp)
    ldw r10, 8(sp)
    ldw r11, 12(sp)
    ldw r12, 16(sp)
    ldw r13, 20(sp)
    ldw r14, 24(sp)
    ldw r15, 28(sp)
    addi sp, sp, 32

    br CONFIGURACAO_BASICA


BOTAO_APERTADO:
    #stackframe
    addi sp, sp, -32
    stw r8, (sp)
    stw r9, 4(sp)
    stw r10, 8(sp)
    stw r11, 12(sp)
    stw r12, 16(sp)
    stw r13, 20(sp)
    stw r14, 24(sp)
    stw r15, 28(sp)

    call startStopCron

    ldw r8, (sp)
    ldw r9, 4(sp)
    ldw r10, 8(sp)
    ldw r11, 12(sp)
    ldw r12, 16(sp)
    ldw r13, 20(sp)
    ldw r14, 24(sp)
    ldw r15, 28(sp)
    addi sp, sp, 32

    br CONFIGURACAO_BASICA

## Espaço de memória ##
#MENSAGEM DE INICIO
MENU:
    .asciz "Entre com o comando"
#Buffer de entrada
.org 0x1000
BUFFER:
    SIZE:
        .word 0
.global LIST
    LIST:
        .skip 200

.global ANIM_FLAG
ANIM_FLAG:
    .word 0

.global DISPLAY
DISPLAY:
    .word 0x3F, 0x06, 0x5B, 0x4F, 0x66, 0x6D, 0x7D, 0x07, 0x7F,0x6F

.global COUNTERS
COUNTERS:
    .skip 16 #4bytes, um para cada segmento

.global ONE_SEC_FLAG
ONE_SEC_FLAG:
    .word 0

.global ENABLE_CRON
ENABLE_CRON:
    .word 0

.global STOP_CRON
STOP_CRON:
    .word 0

    