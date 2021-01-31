{{
┌──────────────────────────────────────────────────────────────────────────────────────────────────────┐
│ Autor: Ingo Kripahle                                                                                 │
│ Copyright (c) 2010 Ingo Kripahle                                                                     │
│ See end of file for terms of use.                                                                    │
│ Die Nutzungsbedingungen befinden sich am Ende der Datei                                              │
└──────────────────────────────────────────────────────────────────────────────────────────────────────┘

Informationen   : hive-project.de
Kontakt         : drohne235@gmail.com
System          : mental
Name            : I2C/PlexBus-Objekt
Chip            : Administra
Typ             :

Funktion        :


COG's           :

Logbuch         :


Notizen         :

}}



OBJ
  gc    : "m-glob-con"


CON

  SCL   = 18'gc#adm_scl '20
  SDA   = 19'gc#adm_sda '19
'  VNX   = gc#adm_int1
' portadressen sepia
{
  'pcf8574  %0100_ABC_0
  PORT1 =   %0100_000   '$20
  PORT2 =   %0100_001   '$21
  PORT3 =   %0100_010   '$22
}
  'pcf8574a %0111_ABC_0
  PORT1 =   %0111_000   '$38
  PORT2 =   %0111_001   '$39
  PORT3 =   %0111_010   '$3A

' ad/da-wandler-adresse

  'pcf8591     %1001_ABC_R
  ADDA0      = %1001_000
  ADDA0_WR   = %1001_000_0
  ADDA0_RD   = %1001_000_1

'
'               +------------- 0
'               | +----------- 1 = analog output enable
'               | |  +-------- 00 - four single endet input
'               | |  |         01 - three differential inputs
'               | |  |         10 - single ended and differential mixed
'               | |  |         11 - two differential inputs
'               | |  | +------ 0
'               | |  | | +---- 1 = auto-increment
'               | |  | | |  +- 00 - channel 0
'               | |  | | |  |  01 - channel 1
'               | |  | | |  |  10 - channel 2
'               | |  | | |  |  11 - channel 3
'               | | -+ | | -+
  ADDA0_INIT = %0_1_00_0_0_00
  ADDA0_SCAN = %0_1_00_0_1_00
  ADDA0_CH0  = %0_1_00_0_0_00
  ADDA0_CH1  = %0_1_00_0_0_01
  ADDA0_CH2  = %0_1_00_0_0_10
  ADDA0_CH3  = %0_1_00_0_0_11

' index der register
  R_PAD0        = 0
  R_PAD1        = 1
  R_PAD2        = 2
  R_PAD3        = 3
  R_INP0        = 4
  R_INP1        = 5
  R_INP2        = 6
'  R_VNX         = 7


VAR

  byte  joy0
  byte  pad0

  byte  plxreg[16]
  long  plxstack[16]
  long  plxcogid

  byte  plxback
  byte  plxlock

  byte  adr_adda      'adresse adda (poller)
  byte  adr_port      'adresse ports (poller)

PUB init                                                'plx: io-system initialisieren

  outa[SCL] := 1                'SCL = 1
  dira[SCL] := 1                'SCL = ausgang
  dira[SDA] := 0                'SDA = eingang

  adr_adda := ADDA0
  adr_port := PORT1

  'ad/da-wandler initialisieren
  ad_init(ADDA0)

  'semaphore anfordern
  plxlock := locknew           'trios

  'pollcog starten
  plxcogid := cognew(poller,@plxstack)


pub plxstop

   if(plxcogid)
     cogstop(plxcogid~ - 1)
     lockret(-1 + plxlock~)

PRI poller                                              'plx: pollcog

  repeat
    'semaphore setzen
    repeat until not lockset(plxlock) 'auf freien bus warten
    'analoge eingänge pollen
    plxreg[R_PAD0] := ad_ch(adr_adda,0)
    plxreg[R_PAD1] := ad_ch(adr_adda,1)
    plxreg[R_PAD2] := ad_ch(adr_adda,2)
    plxreg[R_PAD3] := ad_ch(adr_adda,3)
    lockclr(plxlock)            'bus freigeben

    repeat until not lockset(plxlock) 'auf freien bus warten
    'digitale eingabeports pollen
    plxreg[R_INP0] := in(adr_port  )
    plxreg[R_INP1] := in(adr_port+1)
    plxreg[R_INP2] := in(adr_port+2)
    'semaphore freigeben
    lockclr(plxlock)            'bus freigeben

PUB run                                                 'plx: polling aktivieren

  lockclr(plxlock)            'bus freigeben

PUB halt                                                'plx: polling stoppen

  repeat until not lockset(plxlock) 'auf freien bus warten

CON                                                     'Devices: PORTS, AD/DA-WANDLER

PUB in(adr):data | ack                                  'plx: port lesen

  start
  ack := write((adr << 1) + 1)
  ifnot ack
    data := read(0)
  stop

PUB out(adr,data):ack                                   'plx: port schreiben

  start
  ack := write(adr << 1)
  ack := (ack << 1) | write(data)
  stop

PUB ad_init(adr)                                        'plx: ad-wandler initialisieren

  start
  write(adr << 1)
  write(ADDA0_INIT)
  write(0)
  stop

PUB ad_ch(adr,ch): wert                                 'plx: ad-wandler wert auslesen

  start
  write(adr << 1)
  write(ADDA0_CH0 + ch)
  write(0)
  stop
  repeat 2                      'erste messung verwerfen!
    start                       'da diese das ergebnis
    write((adr << 1) + 1)       'der letzten messung
    wert := read(1)             'liefert!
    stop

PUB getreg(regnr):wert                                  'plx: register lesen

  wert := plxreg[regnr & $0F]

PUB setreg(regnr,wert)                                  'plx: register schreiben

  plxreg[regnr & $0F] := wert

PUB ping(adr):ack                                       'plx: device anpingen

  start
  ack := write(adr<<1)
  stop

PUB setadr(adradda,adrport)

  'halt
  adr_adda := adradda
  adr_port := adrport
  ad_init(adr_adda)
  'run

CON                                                     'I2C-FUNKTIONEN

PUB start                                               'i2c: dialog starten

   outa[SCL]~~
   dira[SCL]~~
   outa[SDA]~~
   dira[SDA]~~
   outa[SDA]~
   outa[SCL]~

PUB stop                                                'i2c: dialog beenden
   outa[SCL]~~
   outa[SDA]~~
   dira[SCL]~
   dira[SDA]~

PUB write(data):ack                                     'i2c: byte senden

   ack := 0
   data <<= 24
   repeat 8
      outa[SDA] := (data <-= 1) & 1
      outa[SCL]~~
      outa[SCL]~
   dira[SDA]~
   outa[SCL]~~
   ack := ina[SDA]
   outa[SCL]~
   outa[SDA]~
   dira[SDA]~~

PUB read(ack):data                                      'i2c: byte empfangen

   dira[SDA]~
   repeat 8
      outa[SCL]~~
      data := (data << 1) | ina[SDA]
      outa[SCL]~
   outa[SDA] := ack
   dira[SDA]~~
   outa[SCL]~~
   outa[SCL]~
   outa[SDA]~

{{
┌──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
│                                                   TERMS OF USE: MIT License                                                  │
├──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
│Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation    │
│files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy,    │
│modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software│
│is furnished to do so, subject to the following conditions:                                                                   │
│                                                                                                                              │
│The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.│
│                                                                                                                              │
│THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE          │
│WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR         │
│COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,   │
│ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.                         │
└──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┘
}}

