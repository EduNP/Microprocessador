/*
 r8-> base do vetor de numero em hexa do display
 r9-> temporáro; Em updatecron: unidade
 r10-> Em updatecron: dezena
 r11-> endereço do display de 7 segmentos; Em updatecron: centena
 r13-> temporario; Em updatecron: milhar
 r14-> temporario
 r15-> temporario com numero carrregado da memoria
*/

.equ SEGMENTS, 0x10000020   #Display de 7 segmentos

.global startStopCron
startStopCron: #Chamado por botão
   
    #Inverte estado do Cronometro
    movia r13, ENABLE_CRON 
    ldw r14, 0(r13) #le valor da memoria
    beq r14, r0, store_1

    #se não, store_0
    stw r0, 0(r13) #salva flag na memoria
    br DISPLAYS
    
store_1:
    addi r14, r14, 1
    stw r14, 0(r13) #salva flag na memoria
    br DISPLAYS

.global cronometro
cronometro:                 #chamado por 20 ou 21 do usuário
    movia r8, LIST          #endereço primeiro elemento do buffer de entrada do usuario
    ldb r9, 1(r8)           #valor 0 ou 1
    addi r9, r9, -0x30      #subtrai 30 para obter o número

    beq r9, r0, LIGAR_CRON  #se for 0, liga cronometro

    #Desliga Cronometro
    movia r8, ENABLE_CRON 
    movi r10, 0
    stw r10, 0(r8) #salva flag na memoria
    br ZERAR

LIGAR_CRON:
    movia r8, ENABLE_CRON 
    movi r10, 1
    stw r10, 0(r8) #salva flag na memoria
    
ZERAR:
    movia r8, COUNTERS
    stw r0, 0(r8);
    stw r0, 4(r8);
    stw r0, 8(r8);
    stw r0, 12(r8);
    br DISPLAYS

.global updateCron
updateCron: #Chamada a cada segundo pelo timer
    #aumentar contadores
    #atualizar display

    movi r15, 10 #numero 10 para comparar

    movia r8, COUNTERS
    ldw r9, 0(r8); #unidade
    ldw r10, 4(r8); #dezena
    ldw r11, 8(r8); #centena
    ldw r12, 12(r8); #milhar

    addi r9, r9, 1
    beq r9, r15, DEZENA

    stw r9, 0(r8);

    br DISPLAYS

DEZENA:

    addi r10, r10, 1
    beq r10, r15, CENTENA

    stw r0, 0(r8);
    stw r10, 4(r8);

    br DISPLAYS
    
CENTENA:

    addi r11, r11, 1
    beq r11, r15, MILHAR

    stw r0, 0(r8);
    stw r0, 4(r8);
    stw r11, 8(r8);

    br DISPLAYS

MILHAR:

    addi r12, r12, 1
    beq r12, r15, ZERAR

    stw r0, 0(r8);
    stw r0, 4(r8);
    stw r0, 8(r8);
    stw r12, 12(r8);

    br DISPLAYS 


DISPLAYS:
    movia r16, SEGMENTS #Device 
    movia r8, COUNTERS

 #Display 1
    movia r13, DISPLAY  #Base do vetor de digitos
    ldw r14, 0(r8);
    slli r14, r14, 2
    add r13, r13, r14
    ldw r15, (r13)
    stbio r15, (r16)       #mostra nos segmentos, primeiro digito

 #Display 2
    movia r13, DISPLAY  #Base do vetor de digitos
       ldw r14, 4(r8);
    slli r14, r14, 2
    add r13, r13, r14
    ldw r15, (r13)
    addi r16, r16, 1
    stbio r15, (r16)       #mostra nos segmentos, segundo digito

 #Display 3
    movia r13, DISPLAY  #Base do vetor de digitos
       ldw r14, 8(r8);
    slli r14, r14, 2
    add r13, r13, r14
    ldw r15, (r13)
    addi r16, r16, 1
    stbio r15, (r16)       #mostra nos segmentos, terceiro digito

 #Display 4
    movia r13, DISPLAY  #Base do vetor de digitos
    ldw r14, 12(r8);
    slli r14, r14, 2
    add r13, r13, r14
    ldw r15, (r13)
    addi r16, r16, 1
    stbio r15, (r16)       #mostra nos segmentos, quarto digito

    ret     

