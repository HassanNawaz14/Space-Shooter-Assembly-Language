[org 0x0100]
	JMP start

BrickGrid: 	times 2000 db	0
GridUpdate:		dw 0
Paddle_Pos: 	dw 3898
oldisr_kb:		dd 0
oldisr_timer:	dd 0
Score:			dw 0
tick_counter:	db 0
firing_active:	db 0
bullet_pos:		dw 0
game_active:	db 1
game_state:		db 0		; 0=menu, 1=playing, 2=game over, 3=win
fall_timer:		db 0
fall_speed:		db 5
bullet_timer:	db 0
active_bubble:	dw 0xFFFF
bubble_done:	db 1
random_seed:	dw 12345
bubble_count:	db 0
current_row:	db 0
current_col:	db 0
temp_positions: times 80 dw 0
first_draw:		dw 1
menu_selection:	db 0		; 0=Start, 1=Exit

; ====================================================
; --- COLOR PALETTE ---
; ====================================================
COLOR_BG		equ 0x10	; Blue background
COLOR_BORDER	equ 0x1E	; Yellow border
COLOR_TEXT		equ 0x0F	; White text
COLOR_HIGHLIGHT	equ 0x9F	; Blue on white (highlight)
COLOR_SCORE		equ 0x0E	; Yellow score
COLOR_LIVES		equ 0x0C	; Red lives
COLOR_MENU		equ 0x0B	; Cyan menu text
COLOR_GAMEOVER	equ 0x4E	; Red on yellow
COLOR_WIN		equ 0x2E	; Green on yellow

; ====================================================
; --- STRINGS ---
; ====================================================
game_title:		db 'BUBBLE SHOOTER', 0
menu_start:		db '> START GAME <', 0
menu_exit:		db '  EXIT GAME  ', 0
menu_sel_start:	db '> START GAME <', 0
menu_sel_exit:	db '> EXIT GAME  <', 0
game_over_msg:	db 'GAME OVER!', 0
win_msg:		db 'YOU WIN!', 0
score_str:		db 'SCORE: ', 0
lives_str:		db 'LIVES: ', 0
speed_str:		db 'SPEED: ', 0
controls_str:	db 'CONTROLS: ARROWS=MOVE, UP=SHOOT, ESC=EXIT', 0
instructions1:	db 'DESTROY ALL BUBBLES BEFORE THEY REACH THE BOTTOM!', 0
instructions2:	db 'USE +/- TO ADJUST GAME SPEED', 0
slow_str:		db 'SLOW', 0
normal_str:		db 'NORMAL', 0
fast_str:		db 'FAST', 0
heart:			db 3, 0		; Heart symbol
press_any_key:	db 'PRESS ANY KEY TO CONTINUE', 0

; ====================================================
; --- NEW: DRAW BORDER ---
; ====================================================
DrawBorder:
	pusha
	push es
	
	mov ax, 0xB800
	mov es, ax
	
	; Top border
	mov di, 0
	mov cx, 80
	mov ax, (COLOR_BORDER << 8) + 0xCD	; Double line
top_border:
	mov [es:di], ax
	add di, 2
	loop top_border
	
	; Bottom border
	mov di, 3840
	mov cx, 80
bottom_border:
	mov [es:di], ax
	add di, 2
	loop bottom_border
	
	; Left and right borders
	mov di, 160
	mov cx, 23
side_borders:
	; Left border
	mov word [es:di], (COLOR_BORDER << 8) + 0xBA
	; Right border
	mov word [es:di+158], (COLOR_BORDER << 8) + 0xBA
	add di, 160
	loop side_borders
	
	; Corners
	mov word [es:0], (COLOR_BORDER << 8) + 0xC9		; Top-left
	mov word [es:158], (COLOR_BORDER << 8) + 0xBB	; Top-right
	mov word [es:3840], (COLOR_BORDER << 8) + 0xC8	; Bottom-left
	mov word [es:3998], (COLOR_BORDER << 8) + 0xBC	; Bottom-right
	
	pop es
	popa
	ret

; ====================================================
; --- NEW: DRAW STATUS BAR ---
; ====================================================
DrawStatusBar:
	pusha
	push es
	
	mov ax, 0xB800
	mov es, ax
	
	; Status bar at bottom (row 24)
	mov di, 3840
	mov cx, 80
	mov ax, (COLOR_BG << 8) + ' '
status_bar_clear:
	mov [es:di], ax
	add di, 2
	loop status_bar_clear
	
	; Draw score
	mov si, score_str
	mov di, 3842
	mov ah, COLOR_TEXT
draw_score_str:
	lodsb
	cmp al, 0
	je draw_score_value
	mov [es:di], ax
	add di, 2
	jmp draw_score_str
	
draw_score_value:
	mov ax, [Score]
	call PrintNumberAt
	
	; Draw lives (always show 3 for now)
	mov si, lives_str
	mov di, 3900
	mov ah, COLOR_LIVES
draw_lives_str:
	lodsb
	cmp al, 0
	je draw_hearts
	mov [es:di], ax
	add di, 2
	jmp draw_lives_str
	
draw_hearts:
	; Draw 3 hearts
	mov cx, 3
	mov al, 3	; Heart symbol
	mov ah, COLOR_LIVES
draw_heart_loop:
	mov [es:di], ax
	add di, 2
	loop draw_heart_loop
	
	; Draw speed
	mov si, speed_str
	mov di, 3940
	mov ah, COLOR_TEXT
draw_speed_str:
	lodsb
	cmp al, 0
	je draw_speed_value
	mov [es:di], ax
	add di, 2
	jmp draw_speed_str
	
draw_speed_value:
	mov al, [fall_speed]
	cmp al, 3
	jbe speed_fast
	cmp al, 6
	jbe speed_medium
	jmp speed_slow
	
speed_fast:
	mov si, fast_str
	jmp draw_speed_text
	
speed_medium:
	mov si, normal_str
	jmp draw_speed_text
	
speed_slow:
	mov si, slow_str
	
draw_speed_text:
	mov ah, COLOR_TEXT
draw_speed_text_loop:
	lodsb
	cmp al, 0
	je status_bar_done
	mov [es:di], ax
	add di, 2
	jmp draw_speed_text_loop
	
status_bar_done:
	pop es
	popa
	ret

; ====================================================
; --- NEW: PRINT NUMBER AT POSITION ---
; ====================================================
; Input: AX = number, ES:DI = screen position
PrintNumberAt:
	pusha
	
	push di
	
	mov bx, 10
	xor cx, cx
	
convert_digits:
	xor dx, dx
	div bx
	add dl, '0'
	push dx
	inc cx
	test ax, ax
	jnz convert_digits
	
print_digits:
	pop dx
	mov dh, COLOR_SCORE
	mov [es:di], dx
	add di, 2
	loop print_digits
	
	pop di
	popa
	ret

; ====================================================
; --- NEW: SHOW START MENU ---
; ====================================================
ShowStartMenu:
	pusha
	push es
	
	mov ax, 0xB800
	mov es, ax
	
	; Clear screen with blue background
	mov di, 0
	mov cx, 2000
	mov ax, (COLOR_BG << 8) + ' '
	rep stosw
	
	call DrawBorder
	
	; Draw game title (centered)
	mov si, game_title
	mov di, 690	; Center of row 9
	mov ah, COLOR_HIGHLIGHT
draw_title:
	lodsb
	cmp al, 0
	je draw_menu_options
	mov [es:di], ax
	add di, 2
	jmp draw_title
	
draw_menu_options:
	; Draw menu options
	mov si, menu_start
	mov di, 1090	; Row 14
	mov ah, COLOR_MENU
	cmp byte [menu_selection], 0
	jne draw_menu_cont
	mov si, menu_sel_start
	mov ah, COLOR_HIGHLIGHT
	
draw_menu_cont:
draw_start_option:
	lodsb
	cmp al, 0
	je draw_exit_option
	mov [es:di], ax
	add di, 2
	jmp draw_start_option
	
draw_exit_option:
	mov si, menu_exit
	mov di, 1250	; Row 16
	mov ah, COLOR_MENU
	cmp byte [menu_selection], 1
	jne draw_exit_cont
	mov si, menu_sel_exit
	mov ah, COLOR_HIGHLIGHT
	
draw_exit_cont:
draw_exit_loop:
	lodsb
	cmp al, 0
	je draw_instructions
	mov [es:di], ax
	add di, 2
	jmp draw_exit_loop
	
draw_instructions:
	; Draw instructions
	mov si, instructions1
	mov di, 1610	; Row 21
	mov ah, COLOR_TEXT
draw_inst1:
	lodsb
	cmp al, 0
	je draw_inst2
	mov [es:di], ax
	add di, 2
	jmp draw_inst1
	
draw_inst2:
	mov si, instructions2
	mov di, 1770	; Row 23
	mov ah, COLOR_TEXT
draw_inst2_loop:
	lodsb
	cmp al, 0
	je draw_controls
	mov [es:di], ax
	add di, 2
	jmp draw_inst2_loop
	
draw_controls:
	mov si, controls_str
	mov di, 1930	; Row 25 (status bar area)
	mov ah, COLOR_TEXT
draw_controls_loop:
	lodsb
	cmp al, 0
	je menu_done
	mov [es:di], ax
	add di, 2
	jmp draw_controls_loop
	
menu_done:
	pop es
	popa
	ret

; ====================================================
; --- NEW: HANDLE MENU INPUT ---
; ====================================================
HandleMenuInput:
	pusha
	
	mov ah, 01h
	int 16h
	jz menu_input_done
	
	mov ah, 00h
	int 16h
	
	cmp al, 0x1B	; ESC
	je exit_game_menu
	
	cmp ah, 0x48	; Up arrow
	je menu_up
	
	cmp ah, 0x50	; Down arrow
	je menu_down
	
	cmp al, 0x0D	; Enter
	je menu_select
	
	jmp menu_input_done
	
menu_up:
	cmp byte [menu_selection], 0
	je menu_input_done
	dec byte [menu_selection]
	jmp redraw_menu
	
menu_down:
	cmp byte [menu_selection], 1
	je menu_input_done
	inc byte [menu_selection]
	
redraw_menu:
	call ShowStartMenu
	jmp menu_input_done
	
menu_select:
	cmp byte [menu_selection], 0
	je start_game
	; Exit selected
exit_game_menu:
	mov byte [game_active], 0
	jmp menu_input_done
	
start_game:
	mov byte [game_state], 1
	call InitializeGame
	
menu_input_done:
	popa
	ret

; ====================================================
; --- NEW: INITIALIZE GAME ---
; ====================================================
InitializeGame:
	pusha
	
	; Reset game variables
	mov word [Score], 0
	mov byte [fall_timer], 0
	mov byte [fall_speed], 5
	mov byte [bullet_timer], 0
	mov word [active_bubble], 0xFFFF
	mov byte [bubble_done], 1
	mov word [first_draw], 1
	mov word [GridUpdate], 1
	mov word [Paddle_Pos], 3920
	
	; Clear screen
	mov ax, 0xB800
	mov es, ax
	mov di, 0
	mov cx, 2000
	mov ax, (COLOR_BG << 8) + ' '
	rep stosw
	
	call DrawBorder
	call DrawStatusBar
	
	; Initialize bubbles
	call makeBrickGridArray_Rand3Rows
	
	; Draw initial game state
	call DrawBricks
	call MakePaddle
	
	; Draw initial score
	push word [Score]
	call printnum
	
	popa
	ret

; ====================================================
; --- NEW: SHOW GAME OVER SCREEN ---
; ====================================================
ShowGameOver:
	pusha
	push es
	
	mov ax, 0xB800
	mov es, ax
	
	; Draw semi-transparent overlay
	mov di, 640	; Row 4
	mov cx, 1200
	mov ax, (COLOR_BG << 8) + ' '
overlay_loop:
	mov [es:di], ax
	add di, 2
	loop overlay_loop
	
	; Draw game over box
	mov di, 1030	; Row 13, col 15
	mov si, game_over_msg
	mov ah, COLOR_GAMEOVER
draw_game_over:
	lodsb
	cmp al, 0
	je draw_final_score
	mov [es:di], ax
	add di, 2
	jmp draw_game_over
	
draw_final_score:
	; Draw final score
	mov si, score_str
	mov di, 1190	; Row 15, col 15
	mov ah, COLOR_TEXT
draw_score_label:
	lodsb
	cmp al, 0
	je draw_score_value2
	mov [es:di], ax
	add di, 2
	jmp draw_score_label
	
draw_score_value2:
	mov ax, [Score]
	call PrintNumberAt
	
	; Draw restart instruction
	mov si, press_any_key
	mov di, 1350	; Row 17, col 15
	mov ah, COLOR_TEXT
draw_restart:
	lodsb
	cmp al, 0
	je game_over_done
	mov [es:di], ax
	add di, 2
	jmp draw_restart
	
game_over_done:
	pop es
	popa
	ret

; ====================================================
; --- NEW: SHOW WIN SCREEN ---
; ====================================================
ShowWinScreen:
	pusha
	push es
	
	mov ax, 0xB800
	mov es, ax
	
	; Draw celebration overlay
	mov di, 640	; Row 4
	mov cx, 1200
	mov ax, (0x20 << 8) + ' '	; Green background
win_overlay:
	mov [es:di], ax
	add di, 2
	loop win_overlay
	
	; Draw win message
	mov di, 1030	; Row 13, col 15
	mov si, win_msg
	mov ah, COLOR_WIN
draw_win_msg:
	lodsb
	cmp al, 0
	je draw_win_score
	mov [es:di], ax
	add di, 2
	jmp draw_win_msg
	
draw_win_score:
	; Draw final score
	mov si, score_str
	mov di, 1190	; Row 15, col 15
	mov ah, COLOR_TEXT
draw_win_score_label:
	lodsb
	cmp al, 0
	je draw_win_score_value
	mov [es:di], ax
	add di, 2
	jmp draw_win_score_label
	
draw_win_score_value:
	mov ax, [Score]
	call PrintNumberAt
	
	; Draw congratulations
	mov si, press_any_key
	mov di, 1350	; Row 17, col 15
	mov ah, COLOR_TEXT
draw_congrats:
	lodsb
	cmp al, 0
	je win_screen_done
	mov [es:di], ax
	add di, 2
	jmp draw_congrats
	
win_screen_done:
	pop es
	popa
	ret

; ====================================================
; --- TIMER ISR FOR MENU SUPPORT ---
; ====================================================
timerisr:
    push ax
    push ds
    
    push cs
    pop ds
    
    inc byte [tick_counter]
    
    cmp byte [game_state], 0
    je menu_state
    
    cmp byte [game_state], 1
    je playing_state
    
    jmp timerisr_done
    
menu_state:
    call HandleMenuInput
    jmp timerisr_done
    
playing_state:
    inc byte [fall_timer]
    
    ; Decrement bullet timer if active
    cmp byte [bullet_timer], 0
    je skip_bullet_timer
    dec byte [bullet_timer]
    
skip_bullet_timer:
    ; Task 0: Main Game Logic (every tick)
    call MainGameTask
    
    ; Task 1: Bullet Movement (every 3rd tick for slower movement)
    mov al, [tick_counter]
    and al, 3
    jnz check_falling_task
    
    call BulletTask
    
check_falling_task:
    ; Task 2: Single Bubble Falling (controlled by fall_speed)
    mov al, [fall_timer]
    cmp al, [fall_speed]
    jb timerisr_done
    
    ; Reset fall timer and move current bubble
    mov byte [fall_timer], 0
    call MoveActiveBubbleTask
    
timerisr_done:
    ; Send EOI to PIC
    mov al, 0x20
    out 0x20, al
    
    pop ds
    pop ax
    iret

; ====================================================
; --- GENERATE RANDOM NUMBER ---
; ====================================================
GenerateRandom:
    push dx
    push bx
    
    mov ax, [random_seed]
    mov dx, 0x343FD
    mul dx
    add ax, 0x269EC3
    mov [random_seed], ax
    
    ; Use high byte for more randomness
    mov al, ah
    xor al, [random_seed + 1]
    
    pop bx
    pop dx
    ret

; ====================================================
; --- TASK 2: MOVE ACTIVE BUBBLE ---
; ====================================================
MoveActiveBubbleTask:
    pusha
    push es
    push ds
    
    push cs
    pop ds
    
    cmp byte [game_state], 1
    jne MoveActiveBubbleTask_end
    
    ; Check if we need a new active bubble
    cmp byte [bubble_done], 1
    je get_new_bubble
    
    ; Check if active bubble still exists (might have been shot)
    mov bx, [active_bubble]
    cmp bx, 0xFFFF
    je bubble_missing
    cmp byte [BrickGrid + bx], 1
    je move_current_bubble
    
bubble_missing:
    ; Active bubble was destroyed (shot), get new one
    mov byte [bubble_done], 1
    jmp get_new_bubble
    
move_current_bubble:
    ; Move the currently active bubble
    call MoveCurrentBubbleDown
    jmp MoveActiveBubbleTask_end
    
get_new_bubble:
    ; Get a new bubble to fall (from bottom row of existing bubbles)
    call FindBottomRowBubble
    cmp word [active_bubble], 0xFFFF
    je check_win_condition  ; No bubbles left
    
    ; Start falling this bubble
    mov byte [bubble_done], 0
    jmp MoveActiveBubbleTask_end
    
check_win_condition:
    ; Check if all bubbles are gone (win condition)
    call CountBubbles
    cmp byte [bubble_count], 0
    jne MoveActiveBubbleTask_end
    
    ; Player wins!
    mov byte [game_state], 3
    call ShowWinScreen
    
MoveActiveBubbleTask_end:
    pop ds
    pop es
    popa
    ret

; ====================================================
; --- FIND BOTTOM ROW BUBBLE ---
; ====================================================
FindBottomRowBubble:
    pusha
    
    ; First collect all bubbles in row 4
    mov byte [bubble_count], 0
    mov cx, 80
    mov bx, 320  ; Start of row 4 (4 * 80 = 320)
    mov si, 0    ; Index for temp_positions
    
collect_row4_bubbles:
    cmp byte [BrickGrid + bx], 1
    jne not_bubble_in_row4
    ; Store this position
    mov [temp_positions + si], bx
    add si, 2
    inc byte [bubble_count]
not_bubble_in_row4:
    inc bx
    loop collect_row4_bubbles
    
    ; If no bubbles in row 4, check rows 3 and 2
    cmp byte [bubble_count], 0
    je find_from_any_row
    
    ; Randomly select one bubble from row 4
    call GenerateRandom
    xor ah, ah
    mov bl, [bubble_count]
    div bl  ; AH = remainder (0 to bubble_count-1)
    
    ; Convert remainder to index
    mov al, ah
    xor ah, ah
    shl ax, 1  ; Multiply by 2 (word size)
    
    ; Get the selected bubble position
    push si
    mov si, ax
    mov bx, [temp_positions + si]
    pop si
    mov [active_bubble], bx
    jmp find_done
    
find_from_any_row:
    ; If no bubbles in row 4, find the lowest bubble in any row
    mov byte [current_row], 4  ; Start from row 4
    
find_lowest_row:
    cmp byte [current_row], 2  ; Stop at row 2
    jl no_bubble_found_at_all
    
    mov byte [current_col], 0
    
check_row_for_bubble:
    ; Calculate grid index: row * 80 + col
    mov al, [current_row]
    mov bl, 80
    mul bl
    add al, [current_col]
    adc ah, 0
    mov bx, ax
    
    ; Check if this cell has a bubble
    cmp byte [BrickGrid + bx], 1
    je bubble_found_in_any_row
    
    ; Next column
    inc byte [current_col]
    cmp byte [current_col], 80
    jb check_row_for_bubble
    
    ; Previous row
    dec byte [current_row]
    jmp find_lowest_row
    
bubble_found_in_any_row:
    mov [active_bubble], bx
    jmp find_done
    
no_bubble_found_at_all:
    mov word [active_bubble], 0xFFFF
    
find_done:
    popa
    ret

; ====================================================
; --- MOVE CURRENT BUBBLE DOWN ---
; ====================================================
MoveCurrentBubbleDown:
    pusha
    
    mov bx, [active_bubble]
    
    ; Calculate position below
    mov si, bx
    add si, 80
    
    ; Check if below is off screen
    cmp si, 2000
    jae bubble_falls_off1
    
    ; Check if below position is empty
    cmp byte [BrickGrid + si], 0
    je move_bubble_down
    
    ; Can't move down - try left-down or right-down with random choice
    call GenerateRandom
    and al, 1
    jz try_left_down
    
    ; Try right-down first
    jmp try_right_down
    
try_left_down:
    ; Check left edge
    mov ax, bx
    xor dx, dx
    mov cx, 80
    div cx
    cmp dx, 0
    je try_right_down  ; At left edge, try right instead
    
    ; Check left-down position
    mov si, bx
    add si, 79
    cmp si, 2000
    jae bubble_cannot_fall1
    cmp byte [BrickGrid + si], 0
    je move_bubble_left_down
    jmp try_right_down
    
try_right_down:
    ; Check right edge
    mov ax, bx
    xor dx, dx
    mov cx, 80
    div cx
    cmp dx, 79
    je bubble_cannot_fall1  ; At right edge
    
    ; Check right-down position
    mov si, bx
    add si, 81
    cmp si, 2000
    jae bubble_cannot_fall1
    cmp byte [BrickGrid + si], 0
    je move_bubble_right_down
    
bubble_cannot_fall1:
    jmp bubble_cannot_fall
    
bubble_falls_off1:
    jmp bubble_falls_off
    
move_bubble_down:
    ; Check if moving to paddle position
    call CheckPaddleHit
    jc bubble_hits_paddle
    
    ; Move bubble straight down
    mov byte [BrickGrid + bx], 0
    mov byte [BrickGrid + si], 1
    mov [active_bubble], si
    
    ; Update only the changed positions
    call UpdateBubbleOnScreen
    jmp move_done
    
move_bubble_left_down:
    ; Check if moving to paddle position
    call CheckPaddleHit
    jc bubble_hits_paddle
    
    ; Move bubble left-down
    mov byte [BrickGrid + bx], 0
    mov byte [BrickGrid + si], 1
    mov [active_bubble], si
    
    ; Update only the changed positions
    call UpdateBubbleOnScreen
    jmp move_done
    
move_bubble_right_down:
    ; Check if moving to paddle position
    call CheckPaddleHit
    jc bubble_hits_paddle
    
    ; Move bubble right-down
    mov byte [BrickGrid + bx], 0
    mov byte [BrickGrid + si], 1
    mov [active_bubble], si
    
    ; Update only the changed positions
    call UpdateBubbleOnScreen
    jmp move_done
    
bubble_falls_off:
    ; Bubble fell off screen - remove it
    mov byte [BrickGrid + bx], 0
    mov byte [bubble_done], 1
    mov word [active_bubble], 0xFFFF
    
    ; Update only the changed position
    call EraseBubbleOnScreen
    jmp move_done
    
bubble_hits_paddle:
    ; Bubble hit the paddle! Game over
    mov byte [BrickGrid + bx], 0
    mov byte [game_state], 2
    
    ; Update only the changed position
    call EraseBubbleOnScreen
    call ShowGameOver
    jmp move_done
    
bubble_cannot_fall:
    ; Bubble is stuck - mark as done
    mov byte [bubble_done], 1
    mov word [active_bubble], 0xFFFF
    
move_done:
    popa
    ret

; ====================================================
; --- UPDATE BUBBLE ON SCREEN ---
; ====================================================
UpdateBubbleOnScreen:
    pusha
    push es
    
    mov ax, 0xB800
    mov es, ax
    
    ; Erase old position
    mov ax, bx
    shl ax, 1
    mov di, ax
    
    ; Choose color based on row for old position
    push bx
    mov ax, bx
    xor dx, dx
    mov cx, 80
    div cx
    cmp ax, 2
    je old_row2
    cmp ax, 3
    je old_row3
    ; Row 4
    mov ax, (0x0B << 8) + 'O'
    jmp draw_old
    
old_row2:
    mov ax, (0x0E << 8) + 'O'
    jmp draw_old
    
old_row3:
    mov ax, (0x0A << 8) + 'O'
    
draw_old:
    ; Actually we want to erase, so use background
    mov word [es:di], (COLOR_BG << 8) + ' '
    
    ; Draw new position
    mov ax, si
    shl ax, 1
    mov di, ax
    
    ; Choose color based on row for new position
    mov ax, si
    xor dx, dx
    mov cx, 80
    div cx
    cmp ax, 2
    je new_row2
    cmp ax, 3
    je new_row3
    ; Row 4 or below
    mov ax, (0x0B << 8) + 'O'
    jmp draw_new
    
new_row2:
    mov ax, (0x0E << 8) + 'O'
    jmp draw_new
    
new_row3:
    mov ax, (0x0A << 8) + 'O'
    
draw_new:
    mov [es:di], ax
    pop bx
    
    pop es
    popa
    ret

; ====================================================
; --- ERASE BUBBLE FROM SCREEN ---
; ====================================================
EraseBubbleOnScreen:
    pusha
    push es
    
    mov ax, 0xB800
    mov es, ax
    
    mov ax, bx
    shl ax, 1
    mov di, ax
    mov word [es:di], (COLOR_BG << 8) + ' '
    
    pop es
    popa
    ret

; ====================================================
; --- CHECK PADDLE HIT ---
; ====================================================
CheckPaddleHit:
    push ax
    push bx
    
    ; Convert paddle screen position to grid index
    mov ax, [Paddle_Pos]
    shr ax, 1  ; Convert screen pos to grid index
    
    ; Check if bubble is moving to paddle position
    cmp si, ax
    je hits_paddle
    
    ; Also check if bubble is in bottom row (row 24)
    cmp si, 1920
    jb no_hit
    cmp si, 2000
    jae no_hit
    
    ; Bubble is in bottom row, check column
    mov bx, si
    sub bx, 1920  ; Column in bottom row
    mov ax, [Paddle_Pos]
    shr ax, 1
    sub ax, 1920  ; Paddle column in bottom row
    
    cmp bx, ax
    je hits_paddle
    
no_hit:
    clc  ; Clear carry = no hit
    jmp check_done
    
hits_paddle:
    stc  ; Set carry = hit
    
check_done:
    pop bx
    pop ax
    ret

; ====================================================
; --- COUNT BUBBLES ---
; ====================================================
CountBubbles:
    pusha
    
    mov byte [bubble_count], 0
    mov cx, 2000
    xor bx, bx
    
count_loop:
    cmp byte [BrickGrid + bx], 1
    jne not_bubble
    inc byte [bubble_count]
not_bubble:
    inc bx
    loop count_loop
    
    popa
    ret

; ====================================================
; --- MODIFIED KBISR FOR MENU SUPPORT ---
; ====================================================
kbisr:        
    push ax
    push ds
    
    push cs
    pop ds

    in   al, 0x60
    
    cmp byte [game_state], 0
    je menu_kb_handler1
    
    cmp byte [game_state], 2
    je game_over_kb_handler1
    
    cmp byte [game_state], 3
    je win_kb_handler1
    
    ; Game playing keyboard handler
    cmp  al, 0x4D
    jne  nextcmp
    
    cmp word [Paddle_Pos], 3998
    jae no_paddle_movement1
    add word [Paddle_Pos], 2
    jmp  terminateKbisr1

nextcmp:      
    cmp  al, 0x4B
    jne  check_up
    
    cmp word [Paddle_Pos], 3840
    jbe no_paddle_movement1
    sub word [Paddle_Pos], 2
    terminateKbisr1:
    jmp  terminateKbisr

check_up:
    cmp  al, 0x48
    jne  no_key
    
    cmp byte [firing_active], 0
    jne no_key
    cmp byte [bullet_timer], 0
    jne no_key
    
    mov byte [bullet_timer], 10
    mov byte [firing_active], 1
    mov di, [Paddle_Pos]
    sub di, 160
    mov [bullet_pos], di
    
    push es
    mov ax, 0xB800
    mov es, ax
    mov word [es:di], (0x0E << 8) + '*'  ; Yellow '*'
    pop es
    
    jmp terminateKbisr

no_key:
    cmp al, 0x01	; ESC
    jne check_speed
    mov byte [game_state], 0
    call ShowStartMenu
    jmp terminateKbisr
    
    menu_kb_handler1:
        JMP menu_kb_handler
    game_over_kb_handler1:
        JMP game_over_kb_handler
    win_kb_handler1:
        JMP win_kb_handler
    no_paddle_movement1:
        JMP no_paddle_movement
    
check_speed:
    cmp al, '+'
    je increase_speed_kb
    cmp al, '='
    je increase_speed_kb
    cmp al, '-'
    je decrease_speed_kb
    cmp al, '_'
    je decrease_speed_kb
    jmp nomatch
        
increase_speed_kb:
    cmp byte [fall_speed], 2
    jbe no_paddle_movement
    dec byte [fall_speed]
    call DrawStatusBar
    jmp terminateKbisr
    
decrease_speed_kb:
    cmp byte [fall_speed], 20
    jae no_paddle_movement
    inc byte [fall_speed]
    call DrawStatusBar
    jmp terminateKbisr
    
game_over_kb_handler:
win_kb_handler:
    ; Any key returns to menu
    mov byte [game_state], 0
    call ShowStartMenu
    jmp terminateKbisr
    
menu_kb_handler:
    ; Menu keyboard handler (already handled in timer ISR)
    ; Just pass through to old ISR
    pop ds
    pop ax
    jmp far [cs:oldisr_kb]
    
no_paddle_movement:
nomatch:      
    pop ds
    pop ax
    jmp far [cs:oldisr_kb]

terminateKbisr:         
    mov  al, 0x20 
    out  0x20, al
    
    pop ds
    pop ax
    iret

; ====================================================
; --- MAIN GAME TASK ---
; ====================================================
MainGameTask:
    pusha
    push es
    push ds
    
    push cs
    pop ds
    
    cmp byte [game_state], 1
    jne MainGameTask_end
    
    ; Check if grid needs update
    cmp word [GridUpdate], 1
    jne no_Grid_Update_task
    
    ; Only draw bricks once at the beginning
    cmp word [first_draw], 1
    jne skip_full_draw
    
    call DrawBricks
    mov word [first_draw], 0
    jmp grid_updated
    
skip_full_draw:
    ; For subsequent updates, we use UpdateBubbleOnScreen directly
    
grid_updated:
    mov word [GridUpdate], 0
    
no_Grid_Update_task:
    ; Update status bar
    call DrawStatusBar
    
    ; Draw paddle
    call MakePaddle
    
MainGameTask_end:
    pop ds
    pop es
    popa
    ret

; ====================================================
; --- TASK 1: BULLET MOVEMENT ---
; ====================================================
BulletTask:
    pusha
    push es
    push ds
    
    push cs
    pop ds
    
    cmp byte [firing_active], 0
    je BulletTask_end
    
    cmp byte [game_state], 1
    jne BulletTask_end
    
    mov ax, 0xB800
    mov es, ax
    
    ; Erase bullet at current position
    mov di, [bullet_pos]
    mov word [es:di], (COLOR_BG << 8) + ' '
    
    ; Move bullet up
    sub di, 160
    
    ; Check if bullet left screen
    cmp di, 158
    jbe bullet_off_screen
    
    ; Check if hit brick
    push di
    call UpdateBrickGrid
    pop di
    
    cmp word [GridUpdate], 1
    je bullet_hit_brick
    
    ; Draw bullet at new position
    mov word [es:di], (0x0E << 8) + '*'  ; Yellow '*'
    mov [bullet_pos], di
    jmp BulletTask_end
    
bullet_hit_brick:
    mov byte [firing_active], 0
    jmp BulletTask_end
    
bullet_off_screen:
    mov byte [firing_active], 0
    
BulletTask_end:
    pop ds
    pop es
    popa
    ret

; ====================================================
; --- UPDATE BRICK GRID ---
; ====================================================
UpdateBrickGrid:
    pusha
    push ds
    
    push cs
    pop ds
    
    ; Convert screen position to grid index
    mov ax, di
    shr ax, 1
    
    ; Check if position is valid
    cmp ax, 2000
    jae no_update_grid
    
    ; Check if there's a bubble at this position
    mov si, ax
    add si, BrickGrid
    cmp byte [si], 1
    jne no_update_grid
    
    ; Check if this is the active bubble
    cmp [active_bubble], ax
    jne not_active_bubble
    
    ; Active bubble was shot - mark it as done
    mov word [active_bubble], 0xFFFF
    mov byte [bubble_done], 1
    
not_active_bubble:
    ; Remove the bubble from grid
    mov byte [si], 0
    inc word [Score]
    
    ; Erase bubble from screen
    push bx
    mov bx, ax
    call EraseBubbleOnScreen
    pop bx
    
    ; Set flag to prevent unnecessary redraws
    mov word [GridUpdate], 1
    
no_update_grid:
    pop ds
    popa
    ret

; ====================================================
; --- PRINT NUM PROCEDURE ---
; ====================================================
printnum:     
    push bp 
    mov  bp, sp 
    push es 
    push ax 
    push bx 
    push cx 
    push dx 
    push di 
 
    mov  ax, 0xb800 
    mov  es, ax
    mov  ax, [bp+4]
    mov  bx, 10
    mov  cx, 0
 
nextdigit:    
    mov  dx, 0
    div  bx
    add  dl, 0x30
    push dx
    inc  cx
    cmp  ax, 0
    jnz  nextdigit
 
    mov  di, 3834
 
nextpos:      
    pop  dx
    mov  dh, COLOR_SCORE
    mov  [es:di], dx
    add  di, 2
    loop nextpos
 
    pop  di 
    pop  dx 
    pop  cx 
    pop  bx 
    pop  ax
    pop  es 
    pop  bp 
    ret  2

; ====================================================
; --- MAKE BRICK GRID ARRAY (ROWS 2-4) ---
; ====================================================
makeBrickGridArray_Rand3Rows:
    pusha
    push es
    
    mov  ax, 0x0040
    mov  es, ax
    mov  si, 0x006C
    mov  ax, [es:si]
    pop  es

    ; Clear the entire grid first
    mov cx, 2000
    xor bx, bx
clear_grid:
    mov byte [BrickGrid + bx], 0
    inc bx
    loop clear_grid

    ; Now populate only rows 2, 3, and 4 (indices 2-4)
    ; Row 2 starts at index 2*80 = 160
    ; Row 3 starts at index 3*80 = 240
    ; Row 4 starts at index 4*80 = 320
    ; We'll populate 3 rows * 80 columns = 240 bubbles
    
    mov bx, 160  ; Start at row 2
    mov cx, 240  ; 3 rows * 80 columns
    mov di, 25173

Rand3_loop:
    mul  di
    add  ax, 13849
    
    mov  dx, ax
    shr  dx, 3
    xor  ax, dx
    mov  dx, ax
    shr  dx, 7
    xor  ax, dx
    
    and  al, 1
    mov  [BrickGrid + bx], al
    inc  bx
    loop Rand3_loop

    popa
    ret
		
; ====================================================
; --- DRAW BRICKS WITH COLOR ---
; ====================================================
DrawBricks:
	pusha
	push es
	push ds
	
	mov ax, 0xB800
	mov es, ax
	
	; Don't clear entire screen on every draw
	xor bx, bx
	mov cx, 2000
	
main_drawing_loop:
	cmp byte [BrickGrid + bx], 1
	jne dont_drawOnThisCell
	
	; Calculate screen position
	mov ax, bx
	shl ax, 1
	mov di, ax
	
	; Draw bubble with color based on row
	mov ax, bx
	xor dx, dx
	mov cx, 80
	div cx		; AX = row, DX = column
	
	; Choose color based on row
	cmp ax, 2
	je row2_color
	cmp ax, 3
	je row3_color
	
	; Row 4 or below - Cyan
	mov ax, (0x0B << 8) + 'O'
	jmp draw_bubble
	
row2_color:	; Row 2 - Yellow
	mov ax, (0x0E << 8) + 'O'
	jmp draw_bubble
	
row3_color:	; Row 3 - Green
	mov ax, (0x0A << 8) + 'O'
	
draw_bubble:
	mov [es:di], ax
	
dont_drawOnThisCell:
	inc bx
	loop main_drawing_loop
	
	pop ds
	pop es
	popa
	ret

; ====================================================
; --- MAKE PADDLE WITH COLOR ---
; ====================================================
MakePaddle:
	pusha
	push es
	push ds
	
	mov ax, 0xB800
	mov es, ax
	
	; Clear only the paddle area (bottom row)
	mov di, 3840
	mov cx, 80
	mov ax, (COLOR_BG << 8) + ' '
	
clear_paddle_row:
	mov [es:di], ax
	add di, 2
	loop clear_paddle_row
	
	; Draw paddle at new position with color
	mov di, [Paddle_Pos]
	mov word [es:di], (0x1F << 8) + 0xDB	; White on blue
	
	; Draw paddle "wings"
	cmp di, 3840
	je no_left_wing
	mov word [es:di-2], (0x1E << 8) + 0xBA	; Yellow border
	
no_left_wing:
	cmp di, 3998
	je no_right_wing
	mov word [es:di+2], (0x1E << 8) + 0xBA	; Yellow border
	
no_right_wing:
	pop ds
	pop es
	popa
	ret

; ====================================================
; --- START WITH MENU ---
; ====================================================
start:
    mov ax, 0xb800
    mov es, ax
    
    ; Set video mode to 80x25 text mode
    mov ax, 0x0003
    int 0x10
    
    ; Clear screen with blue background
    mov cx, 2000
    mov di, 0
    mov ax, (COLOR_BG << 8) + ' '
    rep stosw
    
    ; Initialize interrupts
    xor ax, ax
    mov es, ax
    
    mov ax, [es:9*4]
    mov [oldisr_kb], ax
    mov ax, [es:9*4+2]
    mov [oldisr_kb+2], ax
    
    mov ax, [es:8*4]
    mov [oldisr_timer], ax
    mov ax, [es:8*4+2]
    mov [oldisr_timer+2], ax
    
    cli
    ; Set timer frequency (1193180 / 11932 = 100Hz)
    mov al, 0x36
    out 0x43, al
    mov ax, 11932
    out 0x40, al
    mov al, ah
    out 0x40, al
    
    ; Install interrupt handlers
    mov word [es:9*4], kbisr
    mov [es:9*4+2], cs
    mov word [es:8*4], timerisr
    mov [es:8*4+2], cs
    sti
    
    ; Show start menu
    mov byte [game_state], 0
    mov byte [menu_selection], 0
    call ShowStartMenu
	
main_loop:
    cmp byte [game_active], 1
    je main_loop
    
exit:
    cli
    xor ax, ax
    mov es, ax
    
    ; Restore original interrupts
    mov ax, [oldisr_kb]
    mov [es:9*4], ax
    mov ax, [oldisr_kb+2]
    mov [es:9*4+2], ax
    
    mov ax, [oldisr_timer]
    mov [es:8*4], ax
    mov ax, [oldisr_timer+2]
    mov [es:8*4+2], ax
    
    ; Restore timer to default (18.2Hz)
    mov al, 0x36
    out 0x43, al
    xor al, al
    out 0x40, al
    out 0x40, al
    
    sti
    
    ; Return to DOS
    mov ax, 0x4c00
    int 0x21