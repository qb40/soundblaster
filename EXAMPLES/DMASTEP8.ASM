;様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様
; Play with Cxh/Bxh commands on SoundBlaster 16/16ASP (here 8/mono/signed)
;   Andr� Baresel (with some help from Craig Jackson)
;陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳
; STATUS: DOES WORK ON SB16
;陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳
; Requirements: 80286, SoundBlaster 16/16ASP (see BASEADDR,DMA channel,IRQ number)
; Resolutions : 8-bit / 4..44khz
; Parameters  : none
; Note        : Before compiling this call first "VOC2RAW TEST1.VOC /I /S"
;         to creat "TEST1.INC" in this case a file with 8bit mono signed data
;
; � DSP command 40h  ... set sample rate
; � DSP command D0h  ... Halt Autoinit 8 bit DMA operation
; � DSP command D4h  ... Continue Autoinit 8 bit DMA operation
; � DSP command C6h 10h ... autoinit 8 bit mono data with sign
;

.MODEL small
.286
; CONSTANTS 陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳�

; SoundBlaster SETUP
BASEADDR           EQU 0220h       ;SoundBlaster base address
IRQ7               EQU 15          ;SoundBlaster IRQ
DMAchannel         EQU 1           ;SoundBlaster DMA channel

; PIC MASKS FOR MASK/DEMASK IRQ
PICANDMASK         EQU 01111111b   ;'AND' PIC mask for clear IRQ7
PICORMASK          EQU 10000000b   ;'OR' PIC mask for set IRQ7

; DMA CONTROLLER REGISTERS :
WRITEMASK          EQU 00ah         ;WRITE MASK REGISTER
WRITEMODE          EQU 00bh         ;WRITE MODE REGISTER
CLEARFLIPFLOP      EQU 00ch
PAGE_CHN           EQU 083h         ;PAGE REGISTER FOR DMAchannel 1
BASE_CHN           EQU 002h         ;BASEADDRESS REGISTER DMAchannel 1
COUNT_CHN          EQU 003h         ;COUNT REGISTER DMAchannel 1

; SAMPLERATE : (if you change it pay attention to maximum samplerate)
TIMECONST          EQU 165          ; = 10989 Hz (256-1000000/11000)

; DMA WRITE MODE
WANTEDMODE         EQU 01011000b    ; singlemode, autoinit, readmode

;陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳
; MACRO DEFINITIONs
;陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳
STARTUP                 MACRO
; MASM 5.x COMPATIBILITY
__start:                mov     ax,DGROUP
                        mov     ds,ax
                        mov     bx,ss
                        sub     bx,ax
                        shl     bx,004h
                        mov     ss,ax
                        add     sp,bx
ENDM

WAITWRITE               MACRO
LOCAL                   loopWait,endloop
;          Arguments : DX = Status port (BASEADDR+0Ch)
;          Returns   : n/a
;          Destroys  : AL

                        push    cx
                        xor     cx,cx           ; need that for slow SBs !
loopWait:               dec     cx
                        jz      endloop
                        in      al,dx           ; AL = WRITE COMMAND STATUS
                        or      al,al
                        js      loopWait        ; Jump if bit7=1 - writing not allowed
endloop:                pop     cx
ENDM

WAITREAD                MACRO
LOCAL                   loopWait,endloop
;          Arguments : DX = Status port   (normaly BASEADDR+0Eh)
;          Returns   : n/a
;          Destroys  : AL

                        push    cx
                        xor     cx,cx           ; need that for slow SBs !
loopWait:               dec     cx
                        jz      endloop
                        in      al,dx           ; AL = DATA AVAILABLE STATUS
                        or      al,al
                        jns     loopWait        ; Jump if bit7=0 - no data available
endloop:                pop     cx
ENDM

RESET_DSP               MACRO
local                   SBthere
;          Arguments : n/a
;          Returns   : n/a
;          Destroys  : DX,AL

                        mov      dx,BASEADDR+06h
                        mov      al,1
                        out      dx,al          ; start DSP reset

                        in       al,dx
                        in       al,dx
                        in       al,dx
                        in       al,dx          ; wait 3 �sec

                        xor      al,al
                        out      dx,al          ; end DSP Reset

                        add      dx,08h         ; dx = DSP DATA AVAILABLE
                        WAITREAD
                        sub      dx,4           ; dx = DSP Read Data
                        in       al,dx
                        cmp      al,0aah        ; if there is a SB then it returns 0AAh
                        je       SBthere
                        jmp      RESET_ERROR    ; No SB - exit program
SBthere:
ENDM
;陳� End of Macrodefinitions 陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳

.STACK 100h

.DATA
;陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳
; Creat TEST1.INC with calling "VOC2RAW TEST1.VOC /I /S" or creat your own
; textfile with sampledata -> signed_data_8bit = unsigned_data_8bit-128

SAMPLEBUFFER LABEL BYTE
    INCLUDE TEST1.INC
SAMPLEBUFFEREND LABEL BYTE

    part                db 1

    information         db 13,10,'DMASTEP8.EXE - play 8bit mono data with sign (that does only work on a'
                        db 13,10,'SB16/SB16ASP) signed data : -128..127 (e.g. amiga samples)'
                        db 13,10,'Pause playing with key "p" and continue it then with any key.'
                        db 13,10,'Stop playing with <ESC>.','$'
    memerror            db 13,10,'Not enough memory to creat the DMA buffer','$'
    txtpart0            db 13,10,'playing part 0','$'
    txtpart1            db 13,10,'playing part 1','$'
    sberror             db 13,10,'No SoundBlaster at this BASEADDR ! PROGRAM HALTED.','$'

    OLDInterruptSEG     dw ?
    OLDInterruptOFS     dw ?

    DMAbufferOFS        dw ?
    DMAbufferPage       db ?

    SAMPLEBUFFERLENGTH = offset SAMPLEBUFFEREND - offset SAMPLEBUFFER
;陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳
.CODE
 STARTUP

           ; FIRST FREE NOT USED MEMORY :
           mov     bx,ss
           mov     ax,es
           sub     bx,ax

           mov     ax,sp
           add     ax,15

           shr     ax,4

           add     bx,ax
           mov     ah,04ah
           int     21h

           ; NOW ALLOCATE DMABUFFER
           mov     bx,SAMPLEBufferlength+15
           shr     bx,3            ; cx = samplebufferlength*2/16
                                   ; (count of 16byte blocks)
           mov     ah,48h
           int     21h
           jnc     enoughmem       ; ok got the memory
           mov     dx,offset memerror
           mov     ah,9
           int     21h             ; WRITE MSG 2 SCRN THAT THERE'S NOT ENOUGH MEM
           jmp     return2dos
enoughmem: ; AX = segment of DMA buffer / offset = 0

;陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳
; calculate page and offset for DMAcontroller :
;
; segment*16+offset = 20bit memory location -> upper 4 bits  = page
;                                              lower 16 bits = offset
;陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳
           rol     ax,4
           mov     bl,al
           and     bl,00fh
           and     al,0f0h
           mov     [DMABufferOFS],ax
           mov     [DMAbufferPage],bl
;陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳
; check for DMApage override :
; ... problem: DMA controller separates memory into 64KB pages, you can only
; transfer data is placed in one page - no page overrides are allowed
;陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳
; To solve that :
; creat a DMA buffer with double size you want - if the first part is placed
; on a page border the second part is for sure not
;陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳
           mov     cx,SAMPLEBUFFERLENGTH
           neg     ax          ; ax = 65536 - ax   (bytes left to DMA page border)
           cmp     ax,cx
           ja      nooverride

           ; USE SECOND PART :
           neg     ax               ; ax = offset first data
           add     ax,cx            ; use second part
           inc     ax		     ; cx+1 bytes to next part ;)
           mov     [DMABufferOFS],ax
           inc     [DMABufferPage]  ; 2nd part is on next page !
nooverride:

;陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳
; Now move the sampledata into the DMAbuffer
; in a MODplayer you'll do that in the IRQ,
; but in our case we only repeat the same sound in the DMAbuffer
;陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳
           ; FIRST CALCULATE THE DOS SEG/OFS FROM DMAPage/OFS
           mov     al,byte ptr [DMABufferOFS]
           and     al,0fh
           xor     ah,ah
           mov     di,ax       ; di = offset of DMAbuffer
           mov     ax,[DMABufferOFS]
           and     al,0f0h
           or      al,[DMABufferPage]
           ror     ax,4
           mov     es,ax       ; es = segment of DMABuffer
           mov     si,offset samplebuffer

           ;NOW COPY IT :
           ; DS:SI - samples in dataseg
           ; ES:DI - DMABuffer
           ;
           rep movsb

           RESET_DSP

           ; WRITE INFOMRATION TO SCREEN :
mov     dx,offset information
           mov     ah,9
           int     21h                  ; write program information to screen

           ; ENABLE SB SPEAKERS (for all SBs <SB16)
           mov     dx,BASEADDR+00Ch            ;DX = DSP Write Data or Command
           WAITWRITE
           mov     al,0D1h                     ; AL = Enable speaker
           out     dx,al                       ; Output: DSP Write Data or Command

           ; SETUP IRQ :
           xor     ax,ax
           mov     es,ax                       ; es to page 0 (Interrupt table)
           mov     si,IRQ7*4                   ; si = position in interrupt table

           ; DISABLE IRQ (if it was enabled somehow)
           in      al,021h
           and     al,PICANDMASK               ; SET MASK REGISTER BIT TO DISABLE INTERRUPT
           out     021h,al

           ; CHANGE POINTER IN INTERRUPT TABLE
           mov     ax,es:[si]
           mov     [OLDInterruptOFS],ax        ; save offset of old interupt vector for restoring
           mov     ax,OFFSET OWN_IRQ
           mov     es:[si],ax                  ; set offset of new interrupt routine
           mov     ax,es:[si+2]
           mov     [OLDInterruptSEG],ax        ; save segment of old interupt vector for restoring
           mov     ax,cs
           mov     es:[si+2],ax                ; set segment of new interrupt routine

           ; CHANGE PIC MASK :
           in      al,021h
           and     al,PICANDMASK   ; CLEAR MASK REGISTER BIT TO ENABLE INTERRUPT
           out     021h,al


           mov     cx,SAMPLEBUFFERLENGTH-1
;陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳
; Setup DMA-controller :
;
; 1st  MASK DMA CHANNEL
;
           mov     al,DMAchannel
           add     al,4
           out     WRITEMASK,al
;陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳
; 2nd  CLEAR FLIPFLOP
;
           out     CLEARFLIPFLOP,al
;陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳
; 3rd  WRITE TRANSFER MODE
;
           mov     al,WANTEDMODE
           add     al,DMAchannel
           out     WRITEMODE,al
;陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳
; 4th  WRITE PAGE NUMBER
;
           mov     al,[DMAbufferPage]
           out     PAGE_CHN,al
;陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳
; 5th  WRITE DMA BASEADDRESS
;
           mov     ax,[DMABufferOFS]
           out     BASE_CHN,al
           mov     al,ah
           out     BASE_CHN,al
;陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳
; 6th  WRITE BASECOUNTER = SAMPLELENGTH-1
;
           mov     al,cl
           out     COUNT_CHN,al
           mov     al,ch
           out     COUNT_CHN,al
;陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳
; 7th  DEMASK CHANNEL
;
           mov     al,DMAchannel
           out     WRITEMASK,al

;陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳
; Setup SoundBlaster :
;
; 1st  SET TIMECONSTANT
;
           mov     dx,BASEADDR+00Ch            ;DX = DSP Write Data or Command
           WAITWRITE
           mov     al,040h                     ;AL = Set timeconstant
           out     dx,al
           WAITWRITE
           mov     al,TIMECONST
           out     dx,al
;陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳
; 2nd  USE 8bit MONO UNSIGNED MODE (DSPC C6h 10h XX XXh)
;
           WAITWRITE
           mov     al,0C6h                     ;AL = DMA DAC 8bit autoinit
           out     dx,al
           WAITWRITE
           mov     al,010h                     ;AL = mono signed data
           out     dx,al
           mov     cx,SAMPLEBUFFERLENGTH
           shr     cx,1                        ; generate IRQ every half buffer
           dec     cx
           WAITWRITE
           mov     al,cl                       ;AL = LOWER PART SAMPLELENGTH
           out     dx,al
           WAITWRITE
           mov     al,ch                       ;AL = HIGHER PART SAMPLELENGTH
           out     dx,al

; TRANSFER STARTs.....NOW..... :)
waitloop:  mov     ah,01                       ;AH = Check for character function
           int     016h                        ;   Interrupt: Keyboard
           jz      waitloop                    ; wait for a key (sound in background)

           xor     ah,ah                       ;Read character, flush keypress
           int     016h                        ;   Interrupt: Keyboard
           cmp     al,'p'                      ; check for pause key
           je      pause                       ; ok pause playing
           cmp     al,27
           jne     waitloop
           jmp     exit
pause:     ; NOW HALT PLAYING :
           mov     dx,BASEADDR+00Ch            ;DX = DSP Write Data or Command
           WAITWRITE
           mov     al,0D0h
           out     dx,al

           ; WAIT FOR ANY KEY
           xor     ah,ah                       ;Read character, flush keypress
           int     016h                        ;   Interrupt: Keyboard

           ; NOW CONTINUE PLAYING
           mov     dx,BASEADDR+00Ch            ;DX = DSP Write Data or Command
           WAITWRITE
           mov     al,0d4h
           out     dx,al

           jmp     waitloop

exit:      RESET_DSP

           ; RESTORE PIC MASK
           in      al,021h
           or      al,PICORMASK                ;<-- SET REGISTER MASK BITS TO DISABLE
           out     021h,al

           ; RESTORE IRQ :
           xor     ax,ax
           mov     es,ax                       ; es to page 0 (Interrupt table)
           mov     si,IRQ7*4
           mov     ax,[OLDInterruptOFS]
           mov     es:[si],ax                  ; set old interrupt routine
           mov     ax,[OLDInterruptSEG]
           mov     es:[si+2],ax

           ; CLEAR KEYBUFFER
           mov     ah,01
           int     16h
           jz      return2dos
           xor     ah,ah                       ;Read character, flush keypress
           int     016h                        ;   Interrupt: Keyboard

           ; TERMINATE EXE:
return2dos:
           mov     ax,04c00h
           int     21h

; display information if Soundblaster is not on this baseaddress
RESET_ERROR:
           mov     dx,offset sberror
           mov     ah,9
           int     21h                         ; text output
           jmp     return2dos

;陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳
; Our own IRQ for detecting buffer half SB currently plays
; It's generated by the SoundBlaster hardware
;陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳陳
OWN_IRQ:   pusha
           mov     dx,BASEADDR+00Eh            ;DX = DSP DATA AVAILABLE (IRQ ACKNOWLEDGE)
           in      al,dx
           mov     ax,@data
           mov     ds,ax
           mov     dx,offset txtpart0
           cmp     [part],0
           je      notpart1
           mov     dx,offset txtpart1
notpart1:  mov     ah,9
           int     21h             ; text output
           neg     [part]
           inc     [part]          ; part = 1-part  result : 0,1,0,1,0,....
           mov     al,020h
           out     020h,al                     ;ACKNOWLEDGE HARDWARE INTERRUPT
           popa
           IRET

END     __start
