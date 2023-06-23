/*
* r8-> temporario mascara
* r10 -> leitura da memoria de animação
* r11-> taxa de incremento
* r12-> endereço dos leds
* r13->  endereço das alavancas
* r14-> valor da alavanca
* r16 -> indice a ser salvo do led
*/

.global animation
.equ ALAVANCAS, 0x10000040
.equ LEDS_VERMELHOS, 0x10000000

animation:
    movia r8, ANIM_FLAG #endereço primeiro elemento do buffer
    ldw r10, 0(r8)
    beq r10, r0, EXIT

    movia r12, LEDS_VERMELHOS #endereço dos leds 
    ldwio r16, 0(r12) #carrega os leds acessos para r16

    movia r13, ALAVANCAS # carrega as alavancas
    ldwio r14, 0(r13)

    movi r11, 1 #taxa de incremento

    beq r14, r0, INVERTER_SENTIDO #se for no sentido direita -> esquerda

    sll r16, r16, r11  #move led acesso para próxima
    andi r8, r16, 0b1000000000000000000 #se for borda, colta led para esquerda
    beq r8, r0, FIM
    addi r16, r16, 1

FIM:
    stwio r16, 0(r12)
EXIT:
    ret

INVERTER_SENTIDO:
    srl r16, r16, r11  #move led acesso para próxima
    bne r16, r0, FIM #se apagou todos
    mov r16, r0   
    addi r16, r16, 1  
    slli r16, r16, 17 #volta para direita
    br FIM

#Função que controla a animação
.global animationController
animationController:  
    movia r8, LIST #endereço primeiro elemento do buffer de entrada do usuario
    ldb r9, 1(r8) #valor 0 ou 1
    addi r9, r9, -0x30      #subtrai 30 para obter o número

    beq r9, r0, LIGAR_ANIM #se for 0, liga animação
    #se não, desliga a animação
    movia r8, ANIM_FLAG #endereço primeiro elemento do buffer
    movi r10, 0
    stw r10, 0(r8)
    
    movia r12, LEDS_VERMELHOS #endereço dos leds 
    stwio r0, 0(r12) #carrega os leds acessos para r16

    
    ret

LIGAR_ANIM:
    movia r8, ANIM_FLAG #endereço primeiro elemento do buffer
    movi r10, 1
    stw r10, 0(r8)
    
    #Apaga leds anteriores
    movia r12, LEDS_VERMELHOS #endereço dos leds 
    movi r16, 1
    stwio r16, 0(r12)
    ret
    