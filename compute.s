
#
# I2C interface is wired to Arduino PORTC bits
# 4 and 5, with 4 being data and 5 being clock,
# so these symbols give us the values needed
#
      .set PINC, 0x06
      .set DDIRC, 0x07
      .set PORTC, 0x08
      
      .set SDA, 4
      .set SCL, 5

#
# I2C addresses of the components:
#  7-segment LED: 0x70
#  Digital Thermometer: 0x92
#  EEPROM: 0xA0

#
# Global data
#
    .data
    .comm tempV1, 1
    .comm tempV2, 1
    .global tempV1
    .global tempV2
    
digitPatterns:
    .byte 0x3F, 0x06, 0x5B, 0x4F, 0x66, 0x6D, 0x7D, 0x07, 0x7F, 0x6F

# external symbols
    .extern delayMicroseconds
    .extern delay

#
# Program code
#
     .text
     .global setupTherm
     .global readTherm
     .global displayTemp

setupTherm: 
      sbi  DDIRC, SDA      ; set SDA to output
      sbi  DDIRC, SCL      ; set SCL to output 
      call delay1          ; make sure PORTC is ready
      
      call startBit
      call sendWriteAdd    ; 0x92 (7-bit address + 0 bit for write mode)
      call sendControl1    ; indicate writing to the config register
      call sendConfigReg
      call stopBit
      
      call startBit
      call sendWriteAdd    ; 0x92 (7-bit address + 0 bit for write mode)
      call sendControl0    ; tell the thermometer to send the data when we read
      call stopBit
      
      ret

readTherm:
      call startBit
      call sendReadAdd
      
      call readI2CByte
      sts  tempV1, r24
      
      call readI2CByte
      sts  tempV2, r24
      
      call stopBit
      
      ret

displayTemp:
      call  startBit        ; send start bit
      call  sendAddress     ; send 7SEG address
      call  sendInst        ; send instruction
      call  sendControl     ; send control params
      call  showTemp        ; sends three bytes
      call  showBlank       ; send blank
      call  stopBit         ; send stop bit
      call  delay1          ; wait to allow settling
      
      ret


#
# Delay for 1 millisecond
#
delay1:
      push r20
      push r22
      push r23
      push r24
      push r25
      
      ldi  r22, 0x1
      ldi  r23, 0
      ldi  r24, 0
      ldi  r25, 0
      
      call delay
      
      pop  r25
      pop  r24
      pop  r23
      pop  r22
      pop  r20
      
      ret


#
# Delay for creating our clock period (50usec delay)
#
clockDelay:
      push r23
      push r24
      push r25
      
      ldi  r24, 50
      ldi  r25, 0
      
      call delayMicroseconds
      
      pop  r25
      pop  r24
      pop  r23
      
      ret


startBit:
      sbi   PORTC,SDA    ; set data bit high
      sbi   PORTC,SCL    ; set clock high
      call  delay1       ; leave clock high long enough
      cbi   PORTC,SDA    ; set data bit low (this causes the transition)
      call  delay1       ; keep clock high for a while
      cbi   PORTC,SCL    ; finally bring clock low
      call  delay1       ; leave clock low for long enough
      
      ret


stopBit:
      cbi    PORTC,SDA    ; set data bit low
      sbi    PORTC,SCL    ; set clock high
      call   delay1       ; leave clock high long enough
      sbi    PORTC,SDA    ; set data bit high (this causes the transition)
      call   delay1       ; keep clock high for a while
      cbi    PORTC,SCL    ; finally bring clock low
      call   delay1       ; leave clock low or long enough
      
      ret


oneBit:
      cbi    PORTC,SCL    ; set clock low
      sbi    PORTC,SDA    ; set data bit high
      call   delay1       ; wait for a while
      sbi    PORTC,SCL    ; set clock high
      call   delay1       ; wait for a while
      cbi    PORTC,SCL    ; set clock low
      call   delay1       ; wait for a while
      
      ret


zeroBit:
      cbi    PORTC,SCL    ; set clock low
      cbi    PORTC,SDA    ; set data bit low
      call   delay1       ; wait for a while
      sbi    PORTC,SCL    ; set clock high
      call   delay1       ; wait for a while
      cbi    PORTC,SCL    ; set clock low
      call   delay1       ; wait for a while
      
      ret


sendAddress:
      call  zeroBit
      call  oneBit
      call  oneBit
      call  oneBit
      
      call  zeroBit
      call  zeroBit
      call  zeroBit
      call  zeroBit
      
      call  zeroBit     ; ACK
      
      ret


sendWriteAdd:
      call  oneBit
      call  zeroBit
      call  zeroBit
      call  oneBit
      
      call  zeroBit
      call  zeroBit
      call  oneBit
      call  zeroBit
      
      call  zeroBit     ; ACK
      
      ret


sendReadAdd:
      call  oneBit
      call  zeroBit
      call  zeroBit
      call  oneBit
      
      call  zeroBit
      call  zeroBit
      call  oneBit
      call  oneBit
      
      call  zeroBit     ; ACK
      
      ret


sendControl:
      call  zeroBit
      call  oneBit
      call  zeroBit
      call  zeroBit
      
      call  zeroBit
      call  oneBit
      call  oneBit
      call  oneBit
      
      call  zeroBit    ; ACK
      
      ret


sendControl0:
      call  zeroBit
      call  zeroBit
      call  zeroBit
      call  zeroBit
      
      call  zeroBit
      call  zeroBit
      call  zeroBit
      call  zeroBit
      
      call  zeroBit    ; ACK

      ret


sendControl1:
      call  zeroBit
      call  zeroBit
      call  zeroBit
      call  zeroBit
      
      call  zeroBit
      call  zeroBit
      call  zeroBit
      call  oneBit
      
      call  zeroBit    ; ACK

      ret

#
# Resolution: for full resolution must send 0x60
#
sendConfigReg:
      call zeroBit
      call oneBit          ; TMP175: r1 = 1, resolution bit set high
      call oneBit          ; TMP175: r0 = 1, resolution bit set high
      call zeroBit
      
      call zeroBit
      call zeroBit
      call zeroBit
      call zeroBit
      
      call zeroBit         ; ACK
      
      ret


sendInst:
      call  zeroBit
      call  zeroBit
      call  zeroBit
      call  zeroBit
      
      call  zeroBit
      call  zeroBit
      call  zeroBit
      call  zeroBit
      
      call  zeroBit    ; ACK
      
      ret

#
# Transmit three bytes for temperature
#
showTemp:
      ; send decimal part
      lds  r24, tempV2
      ldi  r22, 26         ; about 25.5
      call divide          ; r24/r22 -> r24 = quotient & r22 = remainder
      call findByte        ; find byte for r24 to send
      call sendByte        ; send r20 to LED
      
      ; send ones part
      lds  r24, tempV1
      ldi  r22, 10
      call divide
      mov  r25, r24        ; r25 = r24
      mov  r24, r22        ; r24 = r22
      call findByte        ; find byte for r24 to send
      ori  r20, 0x80       ; add decimal point
      call sendByte        ; send r20 to LED
      
      ; send 10s part
      mov  r24, r25        ; r24 = r25
      call findByte        ; find byte for r24 to send
      call sendByte        ; send r20 to LED
      
      ret

#
# Transmit a byte that will display a " "
#
showBlank:

      call  zeroBit
      call  zeroBit
      call  zeroBit
      call  zeroBit

      call  zeroBit
      call  zeroBit
      call  zeroBit
      call  zeroBit

      call  zeroBit    ; ACK

      ret


readI2CByte:
      cbi  PORTC, SDA    ; ensure output is low to switch to input
      cbi  DDIRC, SDA    ; change SDA pin to input rather than output
      ldi  r20, 8        ; we are going to read 8 bits
      clr  r24           ; r24 will hold data byte, so start it at 0
readLoop:
      lsl  r24           ; shift the bits we have so far one place to left
      sbi  PORTC, SCL    ; set clock high
      call clockDelay    ; keep high for a bit, gives time for therm to send bit
      sbic PINC, SDA     ; skip next instruction if input bit is 0
      ori  r24, 0x01     ; input bit is a 1, so put a 1 into data byte
      cbi  PORTC, SCL    ; set clock low
      call clockDelay    ; keep low for a bit
      dec  r20           ; decrement our loop counter
      brne readLoop      ; if it is still not 0, go back to top of loop
readDone:
      sbi  DDIRC, SDA    ; change SDA pin back to output
      cbi  PORTC, SDA    ; set data line low for ACK
      sbi  PORTC, SCL    ; start ACK clock period
      call delay1        ; hold high
      cbi  PORTC, SCL    ; set clock low
      call delay1        ; hold low
      ret                ; data byte is left in r24

#
# Find byte to send to LED display using r24 and store byte in r20
#
findByte:
      ldi  r26, lo8(digitPatterns)  ; get array address into X
      ldi  r27, hi8(digitPatterns)
      add  r26, r24                 ; add index into address
      adc  r27, r1                  ; take care of possible carry
      ld   r20, X                   ; r20 has our byte
      
      ret

#
# send byte value stored in r20 to LED display
#
sendByte:
      push r22                      ; save r22
      ldi  r22, 8                   ; we are reading 8 bits
      
dLoop:
      rol  r20           ; put uppermost bit into C flag
      brcc zero          ; branch if C = 0
      call oneBit
      rjmp one
zero:
      call zeroBit
one:
      dec r22
      brne dLoop
      
      call zeroBit       ; ACK
      
      pop r22            ; restore r22
      
      ret

#
# divide r24 by r22, leaving int quotient in r24 and remainder in r22
#
divide:
      clr  r25
      mov  r23, r22      ; save copy of divisor
      
myd1:
      tst  r22
      
loop:
      brmi myd2          ; tests the N flag, which is a copy of leftmost bit
      lsl  r22
      rjmp myd1
      
myd2:
      cp   r24, r23      ; if lower than original divisor, then done
      brlo myd4
      lsl  r25           ; make room for the next quotient bit
      cp   r24, r22      ; if current divisot is smaller, subtract
      brlo myd3
      sub  r24, r22
      ori  r25, 1        ; did subtract, so put 1 bit in quotient
      
myd3:
      lsr  r22           ; scoot divisor over 1 place
      rjmp myd2          ; do all again
      
myd4:
      cp   r22, r23      ; shift quotient until divisor is smaller
      brlo myd5          ; than original divisor value
      lsr  r22           ; shift current divisor
      lsl  r25           ; shift quotient
      rjmp myd4
      
myd5:
      mov  r22, r24      ; put remiander in r22
      mov  r24, r25      ; put quotient in r24
      clr  r25
      
      ret
