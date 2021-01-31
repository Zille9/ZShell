{{
┌──────────────────────────────────────────────────────────────────────────────────────────────────────┐
│ Autor: Ingo Kripahle                                                                                 │
│ Copyright (c) 2010 Ingo Kripahle                                                                     │
│ See end of file for terms of use.                                                                    │
│ Die Nutzungsbedingungen befinden sich am Ende der Datei                                              │
└──────────────────────────────────────────────────────────────────────────────────────────────────────┘

Informationen   : hive-project.de
Kontakt         : drohne235@googlemail.com
System          : TriOS
Name            : Regnatix-Flash
Chip            : Regnatix
Typ             : Flash
Version         : 01
Subversion      : 1
Beschreibung    : Residenter Bootloader des Systems. Läuft auf der ersten COG und startet BIN-Dateien
                  von SD-Card. Gesteuert wird er von den Programmen über ein einfaches Interface: Im
                  eRAM übergibt der Loader einen Pointer auf das Loaderflag und einen anschließenden
                  Puffer von 16 Byte für einen Dateinamen. Ein Programm kann also einen Dateinamen
                  hinterlegen und das Flag auf 1 setzen, worauf der Loader die COGs 1..7 stoppt, die
                  BIN-Datei in den Heap lädt und startet.
                  Bootvorgang: Bei Systemstart wird die Datei "reg.sys" in den Heap geladen und
                  gestartet.
 
Logbuch:

19-11-2008-dr235  - erste version startet sys.bin
                  - steuerung durch anwendung integriert
22-03-2010-dr235  - anpassung trios
26-04-2010-dr235  - fehlerabfrage beim mount (in einigen fällen war die fatengine noch  nicht so weit)
16-05-2011-dr235  - umstellung blocktransfer zu administra
                  - einbindung propforth :)


header einer bin-datei

00 00 b400 ' clkfreq low
02 02 04c4 ' clkfreq hi
04 04 ca6f ' sum byte, clkmode byte
06 06 0010 ' (obj) object start addr
08 08 005c ' (vars) variables start
10 0A 0088 ' (stk) stack start
12 0C 002c ' (PUB) obchain first PUB method start
14 0E 008c ' (isp) initial stack pointer value

word[3] - PBASE - Program base. This is the start of the DAT variables and program code after the 16-byte header. It always has a value of 16, or $10
word[4] - VBASE - Variable base. This starts immediately after the program code. It should always be the same as the file size.
word[5] - DBASE - Stack variable base. This points to the first variable on the stack at program start, which is the RESULT variable.
word[6] - PCURR - Current program counter. This points at the starting address of the first instruction to be executed.
word[7] - DCURR - Stack pointer. This is the initial value of the stack pointer.


-Erweiterung um die Funktion Programme in den e-Ram zu laden und von dort in den Heapram zu übertragen
-das erhöht den Programmwechsel unter Plexus erheblich (es entsteht der Eindruck von in Plexus eingebetteten Programmteilen (DLL's)

 --------------------------------------------------------------------------------------------------------- }}


CON ' KONFIGURATION
{
    Achtung: Nur eine Konfiguration wählen!
}

#define regime       ' spin-loader OHNE FORTH, reg.sys wird sofort automatisch gestartet

CON ' LOADER-KONSTANTEN

_CLKMODE        = XTAL1 + PLL16X
_clkfreq        = 80_000_000
  
COGMAX          = 8
INTERPRETER     = $f004                                 'interpreteradresse (rom)

'signaldefinition regnatix
#0,     D0,D1,D2,D3,D4,D5,D6,D7                         'datenbus
#8,     A0,A1,A2,A3,A4,A5,A6,A7,A8,A9,A10               'adressbus
#19,    REG_RAM1,REG_RAM2                               'selektionssignale rambank 1 und 2
#21,    REG_PROP1,REG_PROP2                             'selektionssignale für administra und bellatrix
#23,    REG_AL                                          'strobesignal für adresslatch
#24,    REG_AL2                                         'front-led als Funktionslatch-Signal missbraucht
        BUSCLK                                          'bustakt
        BUS_WR                                          '/wr - schreibsignal
        BUS_HS '                                        '/hs - quittungssignal

'system
LOADERPTR       = $0FFFFB                               'eram-adresse mit pointer auf loader-register
MAGIC           = $0FFFFA                               'Warmstartflag
'LED_OPEN     = HBEAT                                    'led-pin für anzeige "dateioperation"
'prop 1  - administra   (bus_putchar1, bus_getchar1)
'prop 2  - bellatrix    (bus_putchar2, bus_getchar2)
'                            +------------------------- al
'                            |+------------------------ /prop2
'          prop4   --------+ ||+----------------------- /prop1
'          clk     -------+| |||+---------------------- /ram2
'          /wr     ------+|| ||||+--------------------- /ram1
'          /hs     -----+||| |||||           +--------- a0..a10
'                       |||| |||||           |        
'                       |||| |||||-----------+ -------- d0..d7
DB_OFF           = %00000000_00000000_00000000_00000000 'maske: bus inaktiv
DB_IN            = %00000110_11111111_11111111_00000000 'maske: dbus-eingabe
DB_OUT           = %00000111_11111111_11111111_11111111 'maske: dbus-ausgabe

M1               = %00000000_01011000_00000000_00000000 '/prop1=0, /wr=0, busclk=0  frida
M2               = %00000110_01011000_00000000_00000000 '/prop1=0, /wr=1, busclk=1  frida
M3               = %00000100_01111000_00000000_00000000 '/prop1=1, /wr=1, busclk=0  frida

M4               = %00000000_00000000_00000000_00000000
M5               = %00001000_00000000_00000000_00000000 '/hs=0?

#0,     OPT
        SD_MOUNT
        SD_DIROPEN
        SD_NEXTFILE
        SD_OPEN
        SD_CLOSE
        SD_GETC
        SD_PUTC
        SD_GETBLK

VAR

  byte  proghdr[16]                                     'puffer für objektkopf

' achtung: reihenfolge der folgenden zwei variablen nicht ändern!

  byte  lflag                                           'flag zur steuerung des loaders
  byte  lname[16]                                       'stringpuffer für dateinamen

PUB main | spinbin,i',ad                                    'loader: hauptroutine
{{main - loader: hauptroutine}}

  bus_init                                              'bus initialisieren
  waitcnt(clkfreq+cnt)
  wr_word(@lflag,LOADERPTR)                             'zeiger auf loader-register setzen


' ----------------------------------------------------- REGIME

  spinbin := load(@sysname)                             'start-bin laden
  dira := db_off                ' datenbus auf eingabe schalten
  run(spinbin)                                          'sys-objekt ausführen

' ----------------------------------------------------- LOADER

  repeat                                                'kommandoschleife
    repeat
    until lflag                                         'warte das flag gesetzt ist
    repeat i from 1 to 7                                'cog 2..7 anhalten
      cogstop(i)
    bus_init                                            'objekt laden und ausführen
    if lflag>1
       spinbin := load_ram($80000+((lflag-2)*$8000))
    else
       spinbin := load(@lname)
    lflag:=0
    dira := db_off                                      ' datenbus auf eingabe schalten
    run(spinbin)

PRI errorled(time)                                      'loader: fehleranzeige über cardreader-led
{{errorled(time) - loader: fehleranzeige über cardreader-led}}

  repeat
    '!outa[LED_OPEN]
    bus_putchar1(OPT)
    waitcnt(clkfreq / 4 * time + cnt)
  
PRI run(spinptr)                                        'loader: bin-datei bei adresse starten
{{run(spinprt) - loader: bin-datei bei adresse starten}}

  if spinptr
     cognew(INTERPRETER, spinptr+4)                     'neuen cog mit objekt starten
  
PRI load(fname) :progptr| rc,ii,plen                    'loader: datei in heap laden
{{load(fname) - loader: datei in heap laden}}

' kopf der bin-datei einlesen                           ------------------------------------------------------

  rc := sdopen("R",fname)                               'datei öffnen
  if rc > 0                                             'fehler bei öffnen?
     errorled(2)
  repeat ii from 0 to 15                                '16 bytes --> proghdr
    proghdr[ii] := sdgetc
  plen := word[@proghdr+$A]                             '$a ist stackposition und damit länge der objektdatei
  if plen > (@heapend - @heap)                          'objekt größer als verfügbarer speicher?
     errorled(7)
  sdclose                                               'bin-datei schießen

' bin-datei einlesen                                    ------------------------------------------------------
  progptr := @heap'[0]
  progptr := (progptr + 4) & !3
  sdopen("R",fname)                                     'bin-datei öffnen

  'sdgetblk(plen,progptr)                                'datei --> heap
  bus_putchar1(SD_GETBLK)
  bus_putlong1(plen)
  ii:=0
  repeat plen
    byte[progptr][ii++] := bus_getchar1

  sdclose
  progptr:=offset(progptr,plen)
  return progptr

{PRI Fload(adr) :progptr| rc,ii,plen,a                    'loader: datei aus Flash-Rom in heap laden
{{load(fname) - loader: datei in heap laden}}

' kopf der bin-datei einlesen                           ------------------------------------------------------
  a:=adr
  repeat ii from 0 to 15                                '16 bytes --> proghdr
    proghdr[ii] := Read_Flash_Data(a++)
  plen := word[@proghdr+$A]                             '$a ist stackposition und damit länge der objektdatei
  if plen > (@heapend - @heap)                          'objekt größer als verfügbarer speicher?
     errorled(7)

' bin-datei einlesen                                    ------------------------------------------------------
  progptr := @heap'[0]
  progptr := (progptr + 4) & !3
  'sdopen("R",fname)                                     'bin-datei öffnen

  'sdgetblk(plen,progptr)                                'datei --> heap
  bus_putchar1(226)
  bus_putlong1(adr)
  bus_putlong1(plen)
  ii:=0
  repeat plen
    byte[progptr][ii++] := bus_getchar1

  progptr:=offset(progptr,plen)
  return progptr
}
PRI load_ram(adr) :progptr| rc,ii,plen ,a                   'loader: datei aus E-Ram in heap laden
{{load(fname) - loader: datei in heap laden}}

' kopf der bin-datei einlesen                           ------------------------------------------------------
  a:=adr
  repeat ii from 0 to 15                                '16 bytes --> proghdr
    proghdr[ii] := ram_rdbyte(a++)'sdgetc
  plen := word[@proghdr+$A]                             '$a ist stackposition und damit länge der objektdatei
  if plen > (@heapend - @heap)                          'objekt größer als verfügbarer speicher?
     errorled(7)

' bin-datei einlesen                                    ------------------------------------------------------
  progptr := @heap'[0]
  progptr := (progptr + 4) & !3
  ii:=0
  repeat plen
         byte[progptr][ii++]:=ram_rdbyte(adr++)

  progptr:=offset(progptr,plen)

pri offset(ptr,len)|rc,ii
' zeiger im header mit offset versehen                  ------------------------------------------------------
  Repeat ii from 0 to 4
    Word[ptr+6+ii<<1] += ptr

' variablenbereich löschen                              ------------------------------------------------------
  rc := word[@proghdr+$8]
  longfill(ptr + rc, 0, (len - rc)>>2)


' stackwerte setzen?                                    ------------------------------------------------------
  long[ptr+len-4] := $fff9ffff
  long[ptr+len-8] := $fff9ffff

  return ptr
{pub Read_Flash_Data(adr)
    bus_putchar1(222)
    bus_putlong1(adr)
    return bus_getchar1}
CON ' SYSTEMROUTINEN
PUB sdgetc: char                                        'sd-card: liest ein byte aus geöffneter datei
{{sdgetc: char - sd-card: liest ein byte aus geöffneter datei}}
  bus_putchar1(SD_GETC)
  char := bus_getchar1

PUB sdclose:err                                         'sd-card: schließt datei
{{sdclose: err - sd-card: schließt datei}}
  bus_putchar1(SD_CLOSE)
  err := bus_getchar1
  
PUB sdopen(modus,stradr):err | len                    'sd-card: öffnet eine datei
{{sdopen(modus,stradr - sd-card: öffnet eine datei}}
  bus_putchar1(SD_OPEN)
  bus_putchar1(modus)
  bus_putchar1(len := strsize(stradr))
  repeat len
    bus_putchar1(byte[stradr++])
  err := bus_getchar1

PUB bus_putlong1(wert)                                  'bus: long zu administra senden hsb/lsb
  repeat 4
    bus_putchar1(wert <-= 8)                            '32bit wert senden hsb/lsb

PUB bus_putchar1(c)                                     'bus: byte an prop1 (administra) senden 'frida prop2 --> prop1
{{bus_putchar1(c) - bus: byte senden an prop1 (administra)}}
  dira := db_out                                        'datenbus auf ausgabe stellen
  outa := M1                                            '/prop1=0, /wr=0, busclk=0
  outa[7..0] := c                                       'daten --> dbus
  'repeat 10
  outa[busclk] := 1                                     'busclk=1
  waitpeq(M4,M5,0)                                      '/hs=0?
  dira := db_in                                         'bus freigeben
  outa := M3                                            '/prop1=1, /wr=1, busclk=0

PUB bus_getchar1:wert                                   'bus: byte vom prop1 (administra) empfangen  'frida prop2 --> prop1
{{bus_getchar1:wert - bus: byte empfangen von prop1 (administra)}}
  outa := M2                                            '/prop1=0, /wr=1, busclk=1
  waitpeq(M4,M5,0)                                      'hs=0?
  wert := ina[7..0]                                     'daten einlesen
  outa := M3                                            '/prop1=1, /wr=1, busclk=0

PUB ram_write(wert,adresse)                             'schreibt ein byte in eram
{{ram_write(wert,adresse) - ein byte in externen ram schreiben}}
'rambank 1                      000000 - 07FFFF
'rambank 2                      080000 - 0FFFFF

  outa[bus_wr] := 0                       'schreiben aktivieren
  dira := db_out                          'datenbus --> ausgang
  outa[7..0] := wert                      'wert --> datenbus
  outa[15..8] := adresse >> 11            'höherwertige adresse setzen
  outa[reg_al] := 1                           'obere adresse in adresslatch übernehmen  frida
  outa[reg_al] := 0                                                                    'frida
  outa[18..8] := adresse                  'niederwertige adresse setzen

  '*************** Programmteile werden nur in Rambank 2 geladen ****************************
    outa[reg_ram2] := 0                   'ram2 selektieren (wert wird geschrieben)
    outa[reg_ram2] := 1                   'ram2 deselektieren
  dira := db_in                           'datenbus --> eingang
  outa[bus_wr] := 1                       'schreiben deaktivieren

PUB ram_rdbyte(adresse):wert                        'eram: liest ein byte vom eram
{{ram_rdbyte(adresse):wert - eram: ein byte aus externem ram lesen}}
'rambank 1                      000000 - 07FFFF
'rambank 2                      080000 - 0FFFFF
'sys = 0 - systemmodus, keine virtualisierung
'sys = 1 - usermodus, virtualisierte adresse
'sysmodus: der gesamte speicher (2 x 512 KB) werden durchgängig adressiert
  outa[15..8] := adresse >> 11            'höherwertige adresse setzen
  outa[23] := 1                           'obere adresse in adresslatch übernehmen
  outa[23] := 0
  outa[18..8] := adresse                  'niederwertige adresse setzen

  outa[reg_ram2] := 0                   'ram2 selektieren (wert wird geschrieben)
  wert := ina[7..0]                     'speicherzelle einlesen
  outa[reg_ram2] := 1                   'ram2 deselektieren

PUB wr_word(wert,eadr)                              'schreibt word ab eadr
{{wr_long(wert,eadr) - schreibt long ab eadr}}
  repeat 2
    ram_write(wert,eadr++)
    wert >>= 8

PUB bus_init                                            'bus: initialisiert bussystem
{{bus_init - bus: initialisierung aller bussignale }}
  dira := db_out                ' datenbus auf eingabe schalten  frida
  outa[31..0]:=%0000101_01111000_00000000_00000000
  outa[31..0]:=%0000100_01111000_00000000_00000000
  dira := db_in                 ' datenbus auf eingabe schalten  frida

DAT

sysname           byte "reg.sys", 0                         'name der systemdatei


DAT ' HEAP REGIME-KONF
'#ifdef regime

heap                    long 0[7967] 'Für eine korrekte Funktion müssen 26 Longs frei bleiben


heapend
'#endif

DAT
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
                                                                                        
