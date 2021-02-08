'' =================================================================================================
''
''   File....... jm_24xx512.spin
''   Purpose.... R/W routines for 24xx512 (64K) EEPROM
''   Author..... Jon "JonnyMac" McPhalen
''               Copyright (c) 2009-2013 Jon McPhalen
''               -- see below for terms of use
''   E-mail..... jon@jonmcphalen.com
''   Started....  
''   Updated.... 14 MAY 2013
''
'' =================================================================================================


con

  EE_WRITE = %1010_000_0
  EE_READ  = %1010_000_1

  PG_SIZE  = 128
  
  
obj

  i2c : "jm_i2c"
  

var

  long  scl
  long  sda

  long  devid
    

pub start(device)

'' Setup I2C using default (boot EEPROM) pins
'' -- device is the device address %000 - %111
''    * %000 is boot eeprom

  startx(i2c#EE_SCL, i2c#EE_SDA, device)
         

pub startx(sclpin, sdapin, device)

'' Define I2C SCL (clock) and SDA (data) pins

  i2c.setupx(sclpin, sdapin)

  devid := EE_WRITE | ((%000 #> device <# %111) << 1)     


pub wait | ackbit

'' Waits for EEPROM to be ready for new command

  i2c.wait(devid) 


con

  { --------------------------- }
  {                             }
  {  W R I T E   M E T H O D S  }
  {                             }
  { --------------------------- }

  
pub wr_byte(addr, b) | ackbit

'' Write byte to eeprom

  ackbit := wr_block(addr, 1, @b)

  return ackbit


pub wr_word(addr, w) | ackbit

'' Write word to eeprom

  ackbit := wr_block(addr, 2, @w)

  return ackbit


pub wr_long(addr, l) | ackbit

'' Write long to eeprom

  ackbit := wr_block(addr, 4, @l)

  return ackbit  


pub wr_block(addr, n, p_src) | ackbit

'' Write block of n bytes from p_src to eeprom
'' -- be mindful of address/page size in device to prevent page wrap-around

  i2c.wait(devid)
  i2c.write(addr.byte[1])                                       ' msb of address
  i2c.write(addr.byte[0])                                       ' lsb of address
  ackbit := i2c#ACK                                             ' assume okay
  repeat n
    ackbit |= i2c.write(byte[p_src++])                          ' write a byte 
  i2c.stop

  return ackbit


pub wr_str(addr, p_zstr) | ackbit, b

'' Write z-string at p_zstr to eeprom

  ackbit := i2c#ACK                                             ' assume okay  
  repeat
    b := byte[p_zstr++]                                         ' get byte from string
    ackbit |= wr_byte(addr++, b)                                ' write to card
    if (b == 0)                                                 ' end of string?
      quit                                                      '  yes, we're done
 
  return ackbit


pub fill(addr, n, b) | ackbit

'' Write byte b to eeprom n times, starting with at addr
'' -- be mindful of address/page size in device to prevent page wrap-around

  i2c.wait(devid)
  i2c.write(addr.byte[1])                                       ' msb of address
  i2c.write(addr.byte[0])                                       ' lsb of address
  ackbit := i2c#ACK                                             ' assume okay
  repeat n
    ackbit |= i2c.write(b)                                      ' write the byte 
  i2c.stop

  return ackbit
 

con

  { ------------------------- }
  {                           }
  {  R E A D   M E T H O D S  }
  {                           }
  { ------------------------- }
  

pub rd_byte(addr) | b

'' Return byte value from eeprom

  rd_block(addr, 1, @b)

  return b & $0000_00FF                                         ' clean-up


pub rd_word(addr) | w

'' Return word value eeprom

  rd_block(addr, 2, @w)

  return w & $0000_FFFF
  

pub rd_long(addr) | l

'' Return long value from eeprom

  rd_block(addr, 4, @l)

  return l


pub rd_block(addr, n, p_dest)

'' Read block of n bytes from eeprom to address at p_dest
'' -- be mindful of address/page size in device to prevent page wrap-around

  i2c.wait(devid)
  i2c.write(addr.byte[1])                                       ' msb of address
  i2c.write(addr.byte[0])                                       ' lsb of address
  i2c.start                                                     ' restart for read
  i2c.write(devid | $01)                                        ' device read
  repeat while (n > 1)
    byte[p_dest++] := i2c.read(i2c#ACK)
    --n
  byte[p_dest] := i2c.read(i2c#NAK)                             ' last byte gets NAK
  i2c.stop 


pub rd_str(addr, p_dest) | b

'' Read (arbitrary-length) z-string, store at p_dest

  repeat
    b := rd_byte(addr++)                                        ' read byte from device
    byte[p_dest++] := b                                         ' write to destination  
    if (b == 0)                                                 ' at end?
      quit                                                      '  if yes, we're done 


con

  { --------------- }
  {                 }
  {  S U P P O R T  }
  {                 }
  { --------------- }


pub page_num(addr)

'' Returns page # of addr

  return (addr / PG_SIZE)

  
pub page_ok(addr, len) | pg0, pg1

'' Returns true if len bytes will fit into current page

  pg0 := page_num(addr)
  pg1 := page_num(addr + len-1)

  return (pg1 == pg0)
    

dat { license }

{{

  Terms of Use: MIT License

  Permission is hereby granted, free of charge, to any person obtaining a copy of this
  software and associated documentation files (the "Software"), to deal in the Software
  without restriction, including without limitation the rights to use, copy, modify,
  merge, publish, distribute, sublicense, and/or sell copies of the Software, and to
  permit persons to whom the Software is furnished to do so, subject to the following
  conditions:

  The above copyright notice and this permission notice shall be included in all copies
  or substantial portions of the Software.

  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,
  INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A
  PARTICULAR PURPOSE AND NON-INFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
  HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF
  CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE
  OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. 

}}