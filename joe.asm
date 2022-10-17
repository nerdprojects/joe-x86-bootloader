          ; set video mode, and clear registers
          mov ah,0x0         ; ah = 0 and int 0x10 is setting video mode
          mov al,0x13        ; mode 0x13 is 320 x 200, 256 colors, graphics
          int 0x10           ; call interrupt
          xor bx,bx          ; set bx to 0
          xor cx,cx          ; set cx to 0
          xor dx,dx          ; set dx to 0
          xor di,di          ; set di to 0

          ; fill video memory with white
draw_bg   mov ax,0xa000      ; load video memory segment into ax
          mov es,ax          ; transfer video memory segment into segment register es
          mov dl,0xf         ; move 0xf into dl, 0xf is white (video mode 0x13 uses the vga color table)
          mov [es:di],dl     ; load 0xf into video memory with the offset in di
          inc di             ; increase our video memory pointer by 1
          cmp di,0xfa00      ; compare the video memory pointer with 0xfa00, which is the end of video memory
                             ; (320 x 200 = 64000 = 0xfa00)
          jnz draw_bg        ; if we havent reached end of video memory, continue with drawing white

          xor bx,bx          ; set bx to 0
          mov bx,0x10        ; 0x10 = 16, bx is used as the pointer to a pixel on a image data row
          mov cx,image       ; move the start address of the image data into cx
          mov dx,0x6e94      ; 0x6e94 together with 0xa000 form the offset, where we want to draw the character in video memory
                             ; i guess i came up with this number by calculating the optical center of the screen
                             ; offsetted by the half of the image data... not sure anymore about it ;-)
                             ; we use register dx for that value, because we change it over time to move the character
          mov di,dx

draw      mov ax,0x7c0       ; the BIOS loads this program, at memory location 0x7c00
                             ; we use 0x7c0 here as a segment value, to be able to access our image data later on
                             ; this is due the rather strange addressing scheme used in x86 real mode
                             ; basically it works like this: segment_value * 0x10 + offset_value = final_address
                             ;
                             ; (i'm not sure anymore, why we need to access our data at 0x7c00, instead of using the original boot sector location.
                             ; probably the data is not available anymore at that point)
                             ;
          mov es,ax          ; transfer video memory segment into segment register es
          push di            ; backup di on the stack
          mov di,cx          ; move the pointer to our image data into di
          mov ax,[es:di]     ; load the image data from RAM into ax 
          pop di             ; restore di
          dec bx             ; decrement the row pointer by 1
          bt ax,bx           ; check if we have a bit set in the loaded pixel row
                             ; (bt = bit test, copies the bit number defined by bx from ax to the carry flag)
          push dx            ; backup the draw position pointer in on the stack,
                             ; because the upcoming code section uses dl for the pixel color value, which messes up dx as well
          jc draw_l3         ; jump to draw_l3 if pixel is set (draw_l3 sets dl to 0, which is black and then returns to draw_l1)
          mov dl,0xf         ; otherwise set pixel to white
draw_l1   mov ax,0xa000      ; load video memory segment into ax
          mov es,ax          ; transfer video memory segment into segment register es
          mov [es:di],dl     ; store pixel in video memory
          pop dx             ; restore draw position pointer
          inc di             ; increase video memory pointer by 1
          cmp bx,0           ; compare bx with 0, to see if we reached the end of a row
          jnz draw           ; if not, continue with drawing the row at draw
          mov bx,0x10        ; reset the image data row pointer
          add di,304         ; add 304 to the video memory pointer, so we end up at the next video memory row (16 + 304 = 320)
          mov ax,0x7c0       ; load the 0x7c0 memory segment pointer into ax
          mov es,ax          ; transfer the memory segment value in the segment register es
          add cx,2           ; add two bytes to cx, so we point at the next row of pixels on the image data
          mov ax,dx          ; move the draw position pointer into ax for the upcoming calculation
          add ax,0x1400      ; add the size of one image data frame to the draw position pointer to get an end address
          cmp di,ax          ; check if di matches the end address, to check if we completed one frame
          jnz draw           ; if not, continue with drawing at label draw
          add dx,1           ; if we completed one frame, add 2 pixels to the draw position pointer, to move the character to the right
          mov di,dx          ; move the draw position pointer back into di
          jmp delay          ; jump to the delay routine

draw_l2   cmp cx,image_e     ; check if we reached the end of image data
          jnz draw           ; if not continue drawing
          mov cx,image       ; otherwise reload the start address of the image data into cx
          jmp draw           ; and continue drawing

draw_l3   mov dl,0           ; load 0 into dl, 0 is black on the vga color table
          jmp draw_l1        ; jump back to draw_l1

delay     pusha              ; backup general purpose registers on the stack
          mov di,2           ; di is used by delay_l2 to define how many times it should run, 2 means we delay 2 ticks before continuing
delay_l1  mov ah,0           ; setup ah with value 0 for interrupt call
          int 0x1a           ; interrupt 0x1a with ah set to 0 does read the RTC
                             ; it puts the ticks passed since midnight into cx:dx
                             ; a tick occurs 18.2 times per second
          mov bx,dx          ; move the passed ticks into bx
delay_l2  mov ah,0           ; setup ah for interrupt
          int 0x1a           ; read rtc ticks again
          cmp bx,dx          ; compare with previous reading, to check if we advanced a tick
          jz delay_l2        ; if not, read ticks again
          dec di             ; otherwise decrement our delay counter di
          jnz delay_l1       ; if we did not reach zero on the counter, continue with delay_l1
          popa               ; restore general purpose registers
          jmp draw_l2        ; and continue where we left of before calling "delay"

          ; image data, we have 4 frames, each consists of 16 rows with 16 pixel on it
          ; the pixels are represented by single bits, therefore we need 16 bits = 2 bytes per row
image     db 0x00,0x00       ; 1. frame
          db 0xC0,0x03
          db 0xE0,0x03
          db 0x40,0x02
          db 0x40,0x02
          db 0x80,0x01
          db 0x40,0x02
          db 0x40,0x06
          db 0x60,0x0A
          db 0x50,0x12
          db 0xC8,0x03
          db 0x40,0x02
          db 0x40,0x04
          db 0x20,0x08
          db 0x28,0x10
          db 0x10,0x08

          db 0x00,0x00       ; 2. frame
          db 0x00,0x00
          db 0xC0,0x03
          db 0xE0,0x03
          db 0x40,0x02
          db 0x40,0x02
          db 0x80,0x01
          db 0x40,0x02
          db 0x60,0x0E
          db 0x58,0x12
          db 0x40,0x02
          db 0xC0,0x03
          db 0x20,0x02
          db 0x20,0x3C
          db 0x40,0x20
          db 0x60,0x00

          db 0x00,0x00       ; 3. frame
          db 0xC0,0x03
          db 0xE0,0x03
          db 0x40,0x02
          db 0x40,0x02
          db 0x80,0x01
          db 0x40,0x02
          db 0x40,0x02
          db 0x40,0x02
          db 0x60,0x06
          db 0xC0,0x03
          db 0x40,0x01
          db 0x80,0x07
          db 0x80,0x08
          db 0x80,0x08
          db 0xC0,0x00

          db 0xC0,0x03       ; 4. frame
          db 0xE0,0x03
          db 0x40,0x02
          db 0x40,0x02
          db 0x80,0x01
          db 0x40,0x02
          db 0x40,0x06
          db 0x60,0x0A
          db 0x50,0x0A
          db 0xC0,0x03
          db 0x40,0x02
          db 0x20,0x02
          db 0x40,0x02
          db 0x80,0x04
          db 0x40,0x04
          db 0x00,0x06
image_e
