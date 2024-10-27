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


DrawBackground MACRO
                   SetVideMode
ENDM


.model small

.data
    time            db  0h     ;track system time
    
    WINDOW_WIDTH    equ 320
    WINDOW_HEIGHT   equ 200
    
    ball_x          dw  155    ;x position (column) of ball
    ball_y          dw  96     ;y position (row) of ball
    
    ball_home_x     equ 155
    ball_home_y     equ 96
    
    ball_width      equ 5h     ; width of the ball in pixels
    ball_height     equ 6h     ; height of the ball in pixels
    
    ball_velocity_x dw  5h
    ball_velocity_y dw  2h

    paddle_left_y   dw  10
    paddle_right_y  dw  10

    paddle_left_x   equ 10
    paddle_right_x  equ 305

    paddle_velocity dw  10

    paddle_height   equ 40
    paddle_width    equ 5

.stack 100h
.code

main proc far
                        mov           ax,@data
                        mov           ds,ax

                        SetVideMode


                        call          DrawPaddles
    mainLoop:           
                        GetSystemTime                        ;dl = 1/100s
                        mov           dh,dl
                        sub           dl,time
                        test          dl,dl
                        jns           skipabs
                        neg           dl
    skipabs:            
                        push          dx
                        call          checkKeyboard
                        pop           dx
                        cmp           dl,1                   ;check for the same frame
                        jle           mainLoop               ;check for time again
                        
                        mov           time,dh
               
                        call          ClearBall
                        call          MoveBall
                        call          DrawBall
                        jmp           mainLoop

    exitApp:            
                        ResetVideMode
                        mov           ah,4ch
                        int           21h
main endp

DrawBall proc
                        mov           cx, ball_x             ;left ball position
                        mov           dx, ball_y             ;top ball posititon
    horizontal:         
                        mov           ah, 0ch                ; pixel color interrupt
                        mov           al, 0Fh                ;pixel color white
                        mov           bh,0h
                        int           10h                    ;call interrupt
               
                        inc           cx                     ;move the x pos to the right
                        mov           ax,cx                  ;put current x pos in ax
                        sub           ax,ball_x              ;decrement by the defualt pos
                        cmp           ax,ball_width          ;check if ball WINDOW_WIDTH equal to predifiend size
                        jl            horizontal             ;if not jump to print the next pixel
    
                        mov           cx,ball_x
                        inc           dx
               
                        mov           ax,dx
                        sub           ax,ball_y
                        cmp           ax,ball_height
                        jl            horizontal

                        ret
DrawBall endp

ClearBall proc
                        mov           cx, ball_x             ;left ball position
                        mov           dx, ball_y             ;top ball posititon
    clear_horizontal:   
                        mov           ah, 0ch                ; pixel color interrupt
                        mov           al, 00h                ;pixel color white
                        mov           bh,0h
                        int           10h                    ;call interrupt
               
                        inc           cx                     ;move the x pos to the right
                        mov           ax,cx                  ;put current x pos in ax
                        sub           ax,ball_x              ;decrement by the defualt pos
                        cmp           ax,ball_width          ;check if ball WINDOW_WIDTH equal to predifiend size
                        jl            clear_horizontal       ;if not jump to print the next pixel
    
                        mov           cx,ball_x
                        inc           dx
               
                        mov           ax,dx
                        sub           ax,ball_y
                        cmp           ax,ball_height
                        jl            clear_horizontal

                        ret
ClearBall endp

DrawPaddles proc
                        mov           cx, paddle_left_x      ;left ball position
                        mov           dx, paddle_left_y      ;top ball posititon
    paddle1_horizontal: 
                        mov           ah, 0ch                ; pixel color interrupt
                        mov           al, 0Fh                ;pixel color white
                        mov           bh,0h
                        int           10h                    ;call interrupt
               
                        inc           cx                     ;move the x pos to the right
                        mov           ax,cx                  ;put current x pos in ax
                        sub           ax,paddle_left_x       ;decrement by the defualt pos
                        cmp           ax,paddle_width        ;check if ball WINDOW_WIDTH equal to predifiend size
                        jl            paddle1_horizontal     ;if not jump to print the next pixel
    
                        mov           cx,paddle_left_x
                        inc           dx
               
                        mov           ax,dx
                        sub           ax,paddle_left_y
                        cmp           ax,paddle_height
                        jl            paddle1_horizontal

    ; Drawing the right paddle
                        mov           cx, paddle_right_x     ;right ball position
                        mov           dx, paddle_right_y     ;top ball posititon
    paddle2_horizontal: 
                        mov           ah, 0ch                ; pixel color interrupt
                        mov           al, 0Fh                ;pixel color white
                        mov           bh,0h
                        int           10h                    ;call interrupt
               
                        inc           cx                     ;move the x pos to the right
                        mov           ax,cx                  ;put current x pos in ax
                        sub           ax,paddle_right_x      ;decrement by the defualt pos
                        cmp           ax,paddle_width        ;check if ball WINDOW_WIDTH equal to predifiend size
                        jl            paddle2_horizontal     ;if not jump to print the next pixel
    
                        mov           cx,paddle_right_x
                        inc           dx
               
                        mov           ax,dx
                        sub           ax,paddle_right_y
                        cmp           ax,paddle_height
                        jl            paddle2_horizontal

                        ret
DrawPaddles endp

ClearPaddles PROC
                        mov           cx, paddle_left_x      ;x coord of left paddle
                        mov           dx, paddle_left_y      ;y coord of left paddle
    cpaddle1_horizontal:
                        mov           ah, 0ch                ; pixel color interrupt
                        mov           al, 00h                ;pixel color black
                        mov           bh,0h
                        int           10h                    ;call interrupt
               
                        inc           cx                     ;move the x pos to the right
                        mov           ax,cx                  ;put current x pos in ax
                        sub           ax,paddle_left_x       ;decrement by the defualt pos
                        cmp           ax,paddle_width        ;check if paddle width equal to predifiend size
                        jl            cpaddle1_horizontal    ;if not jump to print the next pixel
    
                        mov           cx,paddle_left_x
                        inc           dx
               
                        mov           ax,dx
                        sub           ax,paddle_left_y
                        cmp           ax,paddle_height
                        jl            cpaddle1_horizontal

    ; Drawing the right paddle
                        mov           cx, paddle_right_x     ;x coord of right paddle
                        mov           dx, paddle_right_y     ;y coord of the right paddle
    cpaddle2_horizontal:
                        mov           ah, 0ch                ; pixel color interrupt
                        mov           al, 00h                ;pixel color black
                        mov           bh,0h
                        int           10h                    ;call interrupt
               
                        inc           cx                     ;move the x pos to the right
                        mov           ax,cx                  ;put current x pos in ax
                        sub           ax,paddle_right_x      ;decrement by the defualt pos
                        cmp           ax,paddle_width        ;check if paddle width equal to predifiend size
                        jl            cpaddle2_horizontal    ;if not jump to print the next pixel
    
                        mov           cx,paddle_right_x
                        inc           dx
               
                        mov           ax,dx
                        sub           ax,paddle_right_y
                        cmp           ax,paddle_height
                        jl            cpaddle2_horizontal

                        ret
ClearPaddles ENDP

MoveBall proc

                        mov           ax,ball_x
                        add           ax,ball_width
                        cmp           ax,WINDOW_WIDTH
                        jge           ballOut
                        cmp           ball_x,0
                        jle           ballOut


    checkY:             
                        mov           ax,ball_y
                        add           ax,ball_height
                        inc           ax
                        cmp           ax,WINDOW_HEIGHT
                        jge           NegVelocityY
                        cmp           ball_y,0000h
                        jle           NegVelocityY

    moveB:              
                        mov           ax,ball_velocity_x
                        add           ball_x,ax              ;move the ball horizontally
                        mov           ax,ball_velocity_y
                        add           ball_y,ax              ;move the ball vertically
                        ret
    
    ballOut:            

                        neg           ball_velocity_x
                        call          ResetBall
                        ret
    
    NegVelocityY:       
                        neg           ball_velocity_Y
                        jmp           moveB


MoveBall endp

ResetBall proc
                        mov           ball_x,ball_home_x
                        mov           ball_y,ball_home_y
                        ret

ResetBall endp

checkKeyboard proc
                        mov           ah,01h
                        int           16h
                        jnz           skipExit
                        jmp           exitKeyboard
                       
    skipExit:           mov           ah,00h
                        int           16h

                        cmp           ah,11h                 ;W scancode
                        je            moveLeftUp
                        cmp           ah,1fh                 ;S scancode
                        je            moveLeftDown
                       
                        cmp           ah,48h                 ;Up scancode
                        je            moveRightUp
                        cmp           ah,50h                 ;Down scancode
                        je            moveRightDown

                        cmp           ah,01h
                        jne           cont
                        jmp           exitApp
    cont:               
                        jmp           exitKeyboard
    moveLeftUp:         
                        mov           ax,paddle_left_y
                        cmp           ax,0
                        jle           exitKeyboard

                        call          ClearPaddles
                        mov           ax,paddle_left_y
                        sub           ax,10
                        mov           paddle_left_y,ax
                        call          DrawPaddles
                        jmp           exitKeyboard
    
    moveLeftDown:       
                        mov           ax,paddle_left_y
                        add           ax,paddle_height
                        cmp           ax,WINDOW_HEIGHT
                        jge           exitKeyboard

                        call          ClearPaddles
                        mov           ax,paddle_left_y
                        add           ax,10
                        mov           paddle_left_y,ax
                        call          DrawPaddles
                        jmp           exitKeyboard
    moveRightUp:        
                        mov           ax,paddle_right_y
                        cmp           ax,0
                        jle           exitKeyboard
                        call          ClearPaddles
                        mov           ax,paddle_right_y
                        sub           ax,10
                        mov           paddle_right_y,ax
                        call          DrawPaddles
                        jmp           exitKeyboard
    
    moveRightDown:      
                        mov           ax,paddle_right_y
                        add           ax,paddle_height
                        cmp           ax,WINDOW_HEIGHT
                        jge           exitKeyboard
                        call          ClearPaddles
                        mov           ax,paddle_right_y
                        add           ax,10
                        mov           paddle_right_y,ax
                        call          DrawPaddles
                        jmp           exitKeyboard
    exitKeyboard:       
                        ret


checkKeyboard endp

end main
