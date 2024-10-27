.286

SetVideMode MACRO
                mov ah,0
                mov al,13h
                int 10h
ENDM
ResetVideMode MACRO
                  mov ah,0
                  mov al,3h
                  int 10h
ENDM

PressAnyKey MACRO

                mov ah,01h
    waitKey:    int 16h
                jz  waitKey

ENDM

GetSystemTime MACRO
                  mov ah,2ch    ;get the system time
                  int 21h       ; CH = hour, CL = minute, DH = seconds, DL = 1/100s

ENDM

setIntteruptHandle MACRO
    ;getting int09h interrupt vector handler
                       cli                       ;turn off interrupt flag
                       pusha
    ;get the interrupt 09 address
                       mov   ax,3509h
                       int   21h
    
    ;save the original interrupt address
                       mov   int9Off, bx
                       mov   int9Seg, es
                       popa


    ;setting the new int 09h interrupt vector handler
                       push  ds
                       mov   ax,cs
                       mov   ds,ax               ;load the segment of the new interrupt
                       lea   dx,checkKeyboard    ;load the offset of the new interrupt
                       mov   ax,2509h            ; int 21/25h at interrupt 09
                       int   21h
                       pop   ds
                       sti
ENDM

resetInterruptHandle MACRO
                         cli

                         mov  ax,int9Seg
                         mov  dx,int9Off
                         push ds
                         mov  ds,ax
                         mov  ax,2509h
                         int  21h
                         pop  ds

                         sti
ENDM

.model small
.data
    time            db  0h                      ;track system time
    
    WINDOW_WIDTH    equ 320
    WINDOW_HEIGHT   equ 200
    
    ball_x          dw  155                     ;x position (column) of ball
    ball_y          dw  96                      ;y position (row) of ball
    
    ball_home_x     equ 155                     ; x coord of the center of the screen
    ball_home_y     equ 96                      ; y coord of the center of the screen
    
    ball_width      equ 5h                      ; width of the ball in pixels
    ball_height     equ 6h                      ; height of the ball in pixels
        
    ball_velocity_x dw  5h                      ;ball velocity in the x direction
    ball_velocity_y dw  2h                      ;ball velocity in the y direction

    paddle_left_y   dw  10                      ;left paddle position for the top of the screen
    paddle_right_y  dw  10                      ;right paddle position for the top of the screen

    paddle_left_x   equ 10                      ;left paddle x coord
    paddle_right_x  equ 305                     ;right paddle x coord

    paddle_velocity equ 10                      ;paddle move speed

    paddle_height   equ 40                      ;paddle height
    paddle_width    equ 5                       ;paddle width

    int9Seg         dw  ?                       ; default interrupt 9 segment
    int9Off         dw  ?                       ;default interrupt 9 offset

    lpMovingUp      dw  0                       ;left paddle move state 0 = no movement, -paddle_velocity = move up
    rpMovingUp      dw  0                       ;right paddle move state 0 = no movement, -paddle_velocity = move up
    lpMovingDown    dw  0                       ;left paddle move state 0 = no movement, paddle_velocity = move down
    rpMovingDown    dw  0                       ;right paddle move state 0 = no movement, paddle_velocity = move down

    exitFlag        db  0

    left_score      db  0
    right_score     db  0

    game_active     db  1

    winner_text     db  "Game Over$"
    left_txt        db  "Left Won$"
    right_txt       db  "Right Won$"
    r_restart       db  "Restart - R key$"
    esc_exit        db  "Exit - ESC key$"
    main_menu_txt   db  "Main Menu$"
    start_txt       db  "Start - Enter key$"






.stack 100h
.code

checkKeyboard proc
                        pusha                                                       ;push all regs to the stack
                        pushf                                                       ;push flag register to the stack
                        in                   al,60h                                 ;read the keyboard scancode

                        cmp                  al,11h                                 ;check for W Keydown Scancode
                        jne                  skipMoveLeftUp
                        mov                  lpMovingUp,-1*paddle_velocity          ;set left paddle move up flag to -1 to move up
                        jmp                  exitKeyboard
    skipMoveLeftUp:     
                        cmp                  al,11h + 80h                           ;check for W Keyup Scancode
                        jne                  skipStopLeftUp
                        mov                  lpMovingUp,0                           ;set left paddle move up flag to zero
                        jmp                  exitKeyboard
    skipStopLeftUp:     

                        cmp                  al,1fh                                 ;check for S Keydown Scancode
                        jne                  skipMoveLeftDown
                        mov                  lpMovingDown,1*paddle_velocity         ;set left paddle move down flag to 1 to move down
                        jmp                  exitKeyboard
    skipMoveLeftDown:   
                        cmp                  al,1fh + 80h                           ;check for S Keyup Scancode
                        jne                  skipStopLeftDown
                        mov                  lpMovingDown,0                         ;set left paddle move down flag to zero
                        jmp                  exitKeyboard
    skipStopLeftDown:   

    ;right paddle
                        
                        cmp                  al,48h                                 ;check for Up arrow Keydown Scancode
                        jne                  skipMoveRightUp
                        mov                  rpMovingUp,-1*paddle_velocity          ;set right paddle move up flag to -1 to move up
                        jmp                  exitKeyboard
    skipMoveRightUp:    
                        
                        cmp                  al,48h + 80h                           ;check for Up arrow Keyup Scancode
                        jne                  skipStopRightUp
                        mov                  rpMovingUp,0                           ;set right paddle move up flag to zero
                        jmp                  exitKeyboard
    skipStopRightUp:    
                        
                        cmp                  al,50h                                 ;check for Down arrow Keydown Scancode
                        jne                  skipMoveRightDown
                        mov                  rpMovingDown,1*paddle_velocity         ;set right paddle move down flag to 1 to move down
                        jmp                  exitKeyboard
    skipMoveRightDown:  
                        
                        cmp                  al,50h + 80h                           ;check for Down arrow Keyup Scancode
                        jne                  skipStopRightDown
                        mov                  rpMovingDown,0                         ;set right paddle move down flag to zero
                        jmp                  exitKeyboard
                        
    skipStopRightDown:  

                        cmp                  al,01h                                 ;check for the ESC key
                        jne                  exitKeyboard
                        mov                  exitFlag,1                             ;set the exit flag

    exitKeyboard:       
                        popf                                                        ;retrive flag register form the stack
                        popa                                                        ;retrive all other flags form the stack

                        mov                  al, 20h                                ;The non specific EOI (End Of Interrupt)
                        out                  20h, al
                        iret                                                        ;return from interrupt


checkKeyboard endp

main proc far
                        mov                  ax,@data
                        mov                  ds,ax

                        call                 MainMenu

    initlize:           
                        SetVideMode
                        setIntteruptHandle                                          ;turn on interrupt flag
                        mov                  lpMovingDown,0
                        mov                  rpMovingDown,0
                        mov                  lpMovingUp,0
                        mov                  rpMovingUp,0
                        mov paddle_left_y,80
                        mov paddle_right_y,80


                        call                 DrawPaddles                            ;draw paddles for the first time
    mainLoop:           
                        
                        cmp                  exitFlag,1
                        je                   exitApp

                        cmp                  game_active,0
                        je                   showGameOver

                        GetSystemTime                                               ;dl = 1/100s
                        cmp                  dl,time                                ;check for the same frame
                        je                   mainLoop                               ;check for time again
                        mov                  time,dl

                        
                        call                 moveLeftPaddle
                        call                 moveRightPaddle
               
                        call                 ClearBall
                        call                 MoveBall
                        call                 DrawBall
                        call                 printScore
                        call                 checkWin

                        jmp                  mainLoop

    showGameOver:       
                        resetInterruptHandle
                        call                 DrawGameOver
                        mov                  game_active,1
                        mov                  left_score,0
                        mov                  right_score,0
                        jmp                  initlize

    exitApp:            

                        ResetVideMode
                        resetInterruptHandle

                        mov                  al,'F'
                        mov                  ah,08H
                        mov                  bh,0
                        mov                  bl,0fh
                        mov                  cx,10
                        int                  10h

                        mov                  ah,4ch
                        int                  21h
main endp

DrawBall proc
                        mov                  cx, ball_x                             ;left ball position
                        mov                  dx, ball_y                             ;top ball posititon
    horizontal:         
                        mov                  ah, 0ch                                ; pixel color interrupt
                        mov                  al, 0Fh                                ;pixel color white
                        mov                  bh,0h
                        int                  10h                                    ;call interrupt
               
                        inc                  cx                                     ;move the x pos to the right
                        mov                  ax,cx                                  ;put current x pos in ax
                        sub                  ax,ball_x                              ;decrement by the defualt pos
                        cmp                  ax,ball_width                          ;check if ball WINDOW_WIDTH equal to predifiend size
                        jl                   horizontal                             ;if not jump to print the next pixel
    
                        mov                  cx,ball_x
                        inc                  dx
               
                        mov                  ax,dx
                        sub                  ax,ball_y
                        cmp                  ax,ball_height
                        jl                   horizontal

                        ret
DrawBall endp

ClearBall proc
                        mov                  cx, ball_x                             ;left ball position
                        mov                  dx, ball_y                             ;top ball posititon
    clear_horizontal:   
                        mov                  ah, 0ch                                ; pixel color interrupt
                        mov                  al, 00h                                ;pixel color white
                        mov                  bh,0h
                        int                  10h                                    ;call interrupt
               
                        inc                  cx                                     ;move the x pos to the right
                        mov                  ax,cx                                  ;put current x pos in ax
                        sub                  ax,ball_x                              ;decrement by the defualt pos
                        cmp                  ax,ball_width                          ;check if ball WINDOW_WIDTH equal to predifiend size
                        jl                   clear_horizontal                       ;if not jump to print the next pixel
    
                        mov                  cx,ball_x
                        inc                  dx
               
                        mov                  ax,dx
                        sub                  ax,ball_y
                        cmp                  ax,ball_height
                        jl                   clear_horizontal

                        ret
ClearBall endp

DrawPaddles proc
                        mov                  cx, paddle_left_x                      ;left ball position
                        mov                  dx, paddle_left_y                      ;top ball posititon
    paddle1_horizontal: 
                        mov                  ah, 0ch                                ; pixel color interrupt
                        mov                  al, 0Fh                                ;pixel color white
                        mov                  bh,0h
                        int                  10h                                    ;call interrupt
               
                        inc                  cx                                     ;move the x pos to the right
                        mov                  ax,cx                                  ;put current x pos in ax
                        sub                  ax,paddle_left_x                       ;decrement by the defualt pos
                        cmp                  ax,paddle_width                        ;check if ball WINDOW_WIDTH equal to predifiend size
                        jl                   paddle1_horizontal                     ;if not jump to print the next pixel
    
                        mov                  cx,paddle_left_x
                        inc                  dx
               
                        mov                  ax,dx
                        sub                  ax,paddle_left_y
                        cmp                  ax,paddle_height
                        jl                   paddle1_horizontal

    ; Drawing the right paddle
                        mov                  cx, paddle_right_x                     ;right ball position
                        mov                  dx, paddle_right_y                     ;top ball posititon
    paddle2_horizontal: 
                        mov                  ah, 0ch                                ; pixel color interrupt
                        mov                  al, 0Fh                                ;pixel color white
                        mov                  bh,0h
                        int                  10h                                    ;call interrupt
               
                        inc                  cx                                     ;move the x pos to the right
                        mov                  ax,cx                                  ;put current x pos in ax
                        sub                  ax,paddle_right_x                      ;decrement by the defualt pos
                        cmp                  ax,paddle_width                        ;check if ball WINDOW_WIDTH equal to predifiend size
                        jl                   paddle2_horizontal                     ;if not jump to print the next pixel
    
                        mov                  cx,paddle_right_x
                        inc                  dx
               
                        mov                  ax,dx
                        sub                  ax,paddle_right_y
                        cmp                  ax,paddle_height
                        jl                   paddle2_horizontal

                        ret
DrawPaddles endp

ClearRightPaddle PROC
                        mov                  cx, paddle_right_x                     ;x coord of right paddle
                        mov                  dx, paddle_right_y                     ;y coord of the right paddle
    cpaddle2_horizontal:
                        mov                  ah, 0ch                                ; pixel color interrupt
                        mov                  al, 00h                                ;pixel color black
                        mov                  bh,0h
                        int                  10h                                    ;call interrupt
               
                        inc                  cx                                     ;move the x pos to the right
                        mov                  ax,cx                                  ;put current x pos in ax
                        sub                  ax,paddle_right_x                      ;decrement by the defualt pos
                        cmp                  ax,paddle_width                        ;check if paddle width equal to predifiend size
                        jl                   cpaddle2_horizontal                    ;if not jump to print the next pixel
    
                        mov                  cx,paddle_right_x
                        inc                  dx
               
                        mov                  ax,dx
                        sub                  ax,paddle_right_y
                        cmp                  ax,paddle_height
                        jl                   cpaddle2_horizontal

                        ret
ClearRightPaddle ENDP

ClearLeftPaddle proc
                        mov                  cx, paddle_left_x                      ;x coord of left paddle
                        mov                  dx, paddle_left_y                      ;y coord of left paddle
    cpaddle1_horizontal:
                        mov                  ah, 0ch                                ; pixel color interrupt
                        mov                  al, 00h                                ;pixel color black
                        mov                  bh,0h
                        int                  10h                                    ;call interrupt
               
                        inc                  cx                                     ;move the x pos to the right
                        mov                  ax,cx                                  ;put current x pos in ax
                        sub                  ax,paddle_left_x                       ;decrement by the defualt pos
                        cmp                  ax,paddle_width                        ;check if paddle width equal to predifiend size
                        jl                   cpaddle1_horizontal                    ;if not jump to print the next pixel
    
                        mov                  cx,paddle_left_x
                        inc                  dx
               
                        mov                  ax,dx
                        sub                  ax,paddle_left_y
                        cmp                  ax,paddle_height
                        jl                   cpaddle1_horizontal
                        ret
ClearLeftPaddle endp

MoveBall proc
    ;check collision with the left pedal

    ;check if ball passed the left paddle
                        cmp                  ball_x,paddle_left_x + paddle_width
                        jg                   skipLeftCheck

                        cmp                  ball_x,paddle_left_x
                        jle                  skipLeftCheck

    ;check for ball below the top of the paddle
                        mov                  ax, ball_y
                        add                  ax,ball_height
                        cmp                  ax,paddle_left_y
                        jl                   skipLeftCheck

    ;check for ball above the bottom of the paddle
                        mov                  ax, paddle_left_y
                        add                  ax,paddle_height
                        cmp                  ball_y,ax
                        jg                   skipLeftCheck
                        jmp                  NegVelocityX
    skipLeftCheck:      
    ;check if ball passed the right paddle
                        cmp                  ball_x,paddle_right_x - ball_width
                        jl                   skipRightCheck

                        cmp                  ball_x,paddle_right_x
                        jge                  skipRightCheck

    ;check for ball below the top of the paddle
                        mov                  ax, ball_y
                        add                  ax,ball_height
                        cmp                  ax,paddle_right_y
                        jl                   skipRightCheck

    ;check for ball above the bottom of the paddle
                        mov                  ax, paddle_right_y
                        add                  ax,paddle_height
                        cmp                  ball_y,ax
                        jg                   skipRightCheck
                        jmp                  NegVelocityX
    skipRightCheck:     

    ;check if the ball passed the right wall
                        mov                  ax,ball_x
                        add                  ax,ball_width
                        cmp                  ax,WINDOW_WIDTH
                        jge                  ballOut

    ;check if the ball passed the left wall
                        cmp                  ball_x,0
                        jle                  ballOut



    checkY:             
                        mov                  ax,ball_y
                        add                  ax,ball_height
                        inc                  ax
                        cmp                  ax,WINDOW_HEIGHT
                        jge                  NegVelocityY
                        cmp                  ball_y,0000h
                        jle                  NegVelocityY
                        jmp                  moveB

    moveB:              
                        mov                  ax,ball_velocity_x
                        add                  ball_x,ax                              ;move the ball horizontally
                        mov                  ax,ball_velocity_y
                        add                  ball_y,ax                              ;move the ball vertically
                        ret
    
    ballOut:            

                        neg                  ball_velocity_x
                        cmp                  ball_x,0
                        jle                  rightPoint
                        inc                  left_score
                        call                 ResetBall
                        ret
    rightPoint:         
                        inc                  right_score
                        call                 ResetBall
                        ret
    
    NegVelocityY:       
                        neg                  ball_velocity_y
                        jmp                  moveB
    NegVelocityX:       
                        neg                  ball_velocity_x
                        jmp                  moveB


MoveBall endp

ResetBall proc
                        mov                  ball_x,ball_home_x
                        mov                  ball_y,ball_home_y
                        ret

ResetBall endp

moveLeftPaddle proc
                        mov                  ax,lpMovingUp
                        add                  ax,lpMovingDown
                        cmp                  ax,0
                        je                   exitMoveLeft

                        mov                  ax,paddle_left_y
                        add                  ax,lpMovingUp
                        add                  ax,lpMovingDown
                        cmp                  ax,0
                        jl                   exitMoveLeft
                        add                  ax,paddle_height
                        cmp                  ax,WINDOW_HEIGHT
                        jg                   exitMoveLeft

                        call                 ClearLeftPaddle
                        mov                  ax,paddle_left_y
                        add                  ax,lpMovingUp
                        add                  ax,lpMovingDown
                        mov                  paddle_left_y,ax
                        call                 DrawPaddles
                        jmp                  exitMoveLeft
    exitMoveLeft:       
                        ret
moveLeftPaddle endp

moveRightPaddle proc
                        mov                  ax,rpMovingUp
                        add                  ax,rpMovingDown
                        cmp                  ax,0
                        je                   exitMoveRight

                        mov                  ax,paddle_right_y
                        add                  ax,rpMovingUp
                        add                  ax,rpMovingDown
                        cmp                  ax,0
                        jl                   exitMoveRight
                        add                  ax,paddle_height
                        cmp                  ax,WINDOW_HEIGHT
                        jg                   exitMoveRight

                        call                 ClearRightPaddle
                        mov                  ax,paddle_right_y
                        add                  ax,rpMovingUp
                        add                  ax,rpMovingDown
                        mov                  paddle_right_y,ax
                        call                 DrawPaddles
                        jmp                  exitMoveRight
    exitMoveRight:      
                        ret
moveRightPaddle endp

printScore proc
                        mov                  ah,02h
                        mov                  bh,0H
                        mov                  dh,5
                        mov                  dl,5
                        int                  10h

                        mov                  ah,09h
                        mov                  al,left_score
                        add                  al,'0'
                        mov                  bl,07h
                        mov                  cx,1
                        int                  10h
                        
                        mov                  ah,02h
                        mov                  bh,0H
                        mov                  dh,5
                        mov                  dl,34
                        int                  10h

                        mov                  ah,09h
                        mov                  al,right_score
                        add                  al,'0'
                        mov                  bl,07h
                        mov                  cx,1
                        int                  10h
                        ret

printScore endp

checkWin proc
                        cmp                  left_score,5
                        jge                  setWin
                        cmp                  right_score,5
                        jge                  setWin
                        ret

    setWin:             mov                  game_active,0
                        ret
checkWin endp

DrawGameOver PROC
                        SetVideMode

    ;set cursor postition to top left with a margin of 5
                        mov                  ah,02h
                        mov                  bh,0H
                        mov                  dh,5
                        mov                  dl,5
                        int                  10h

    ;print the game over text
                        lea                  dx,winner_text
                        mov                  ah,9
                        int                  21h

    ;move the cursor down
                        mov                  ah,02h
                        mov                  bh,0H
                        mov                  dh,6
                        mov                  dl,5
                        int                  10h

    ;check which player won
                        mov                  al,left_score
                        cmp                  al,right_score
                        jl                   rightWinner
                        lea                  dx,left_txt
                        jmp                  leftWinner
    rightWinner:        
                        lea                  dx,right_txt
                       
    leftWinner:         mov                  ah,9
                        int                  21h                                    ;print the winner

    ;move the cursor down
                        mov                  ah,02h
                        mov                  bh,0H
                        mov                  dh,7
                        mov                  dl,5
                        int                  10h
    ;print the restart text
                        lea                  dx,r_restart
                        mov                  ah,9
                        int                  21h
    ;move the cursor down
                        mov                  ah,02h
                        mov                  bh,0H
                        mov                  dh,8
                        mov                  dl,5
                        int                  10h
    ;print the esc text
                        lea                  dx,esc_exit
                        mov                  ah,9
                        int                  21h

    ;wait for ESC key or R key
    waitKeyInput:       mov                  ah, 0
                        int                  16h

                        cmp                  ah,01h
                        jne                  skipExit1
                        mov                  exitFlag,1
                        ret
    skipExit1:          
                        cmp                  ah,13h
                        jne                  waitKeyInput
                        ret
DrawGameOver ENDP

MainMenu PROC
                        SetVideMode
    ;set cursor postition to top left with a margin of 5
                        mov                  ah,02h
                        mov                  bh,0H
                        mov                  dh,5
                        mov                  dl,5
                        int                  10h

    ;print the main menu text
                        lea                  dx,main_menu_txt
                        mov                  ah,9
                        int                  21h

    ;move the cursor down
                        mov                  ah,02h
                        mov                  bh,0H
                        mov                  dh,6
                        mov                  dl,5
                        int                  10h

    ;print the Start text
                        lea                  dx,start_txt
                        mov                  ah,9
                        int                  21h

    ;move the cursor down
                        mov                  ah,02h
                        mov                  bh,0H
                        mov                  dh,7
                        mov                  dl,5
                        int                  10h
    ;print the esc text
                        lea                  dx,esc_exit
                        mov                  ah,9
                        int                  21h

    ;wait for ESC key or Enter key
    waitKeyInput2:      mov                  ah, 0
                        int                  16h

                        cmp                  ah,01h
                        jne                  skipExit2
                        mov                  exitFlag,1
                        ret
    skipExit2:          
                        cmp                  ah,1Ch
                        jne                  waitKeyInput2
                        ret
MainMenu ENDP

end main
