{{ Bus-Funktionen für Bellatrix }}

CON

_CLKMODE     = XTAL1 + PLL16X
_XINFREQ     = 5_000_000


'          hbeat   --------+
'          clk     -------+|
'          /wr     ------+||
'          /hs     -----+||| +------------------------- /cs
'                       |||| |                 -------- d0..d7
DB_IN            = %00001000_00000000_00000000_00000000 'maske: dbus-eingabe
DB_OUT           = %00001000_00000000_00000000_11111111 'maske: dbus-ausgabe

M1               = %00000010_00000000_00000000_00000000
M2               = %00000010_10000000_00000000_00000000 'busclk=1? & /cs=0?

M3               = %00000000_00000000_00000000_00000000
M4               = %00000010_00000000_00000000_00000000 'busclk=0?


OBJ

  gc         : "glob-con"       'globale konstanten

PUB init_bus
  dira := db_in                                         'datenbus auf eingabe schalten
  outa[gc#bus_hs] := 1                                  'handshake inaktiv

PUB putchar(zeichen)                                'chip: ein byte an regnatix senden
''funktionsgruppe               : chip
''funktion                      : ein byte an regnatix senden
''eingabe                       : byte
''ausgabe                       : -

  waitpeq(M1,M2,0)                                      'busclk=1? & prop2=0?
  dira := db_out                                        'datenbus auf ausgabe stellen
  outa[7..0] := zeichen                                 'daten ausgeben
  outa[gc#bus_hs] := 0                                  'daten gültig
  waitpeq(M3,M4,0)                                      'busclk=0?
  dira := db_in                                         'bus freigeben
  outa[gc#bus_hs] := 1                                  'daten ungültig

PUB getchar : zeichen                               'chip: ein byte von regnatix empfangen
''funktionsgruppe               : chip
''funktion                      : ein byte von regnatix empfangen
''eingabe                       : -
''ausgabe                       : byte

   waitpeq(M1,M2,0)                                     'busclk=1? & prop2=0?
   zeichen := ina[7..0]                                 'daten einlesen
   outa[gc#bus_hs] := 0                                 'daten quittieren
   waitpeq(M3,M4,0)                                     'busclk=0?
   outa[gc#bus_hs] := 1


CON ''------------------------------------------------- SUBPROTOKOLL-FUNKTIONEN

PUB putlong(wert)                                   'sub: long senden
''funktionsgruppe               : sub
''funktion                      : subprotokoll um einen long-wert an regnatix zu senden
''eingabe                       : 32bit wert der gesendet werden soll
''ausgabe                       : -
''busprotokoll                  : [put.byte1][put.byte2][put.byte3][put.byte4]
''                              : [  hsb    ][         ][         ][   lsb   ]

   putchar(wert >> 24)                              '32bit wert senden hsb/lsb
   putchar(wert >> 16)
   putchar(wert >> 8)
   putchar(wert)
'repeat 4
'       putchar(wert <-= 8)                            '32bit wert senden hsb/lsb

PUB getlong:wert                                    'sub: long empfangen
''funktionsgruppe               : sub
''funktion                      : subprotokoll um einen long-wert von regnatix zu empfangen
''eingabe                       : -
''ausgabe                       : 32bit-wert der empfangen wurde
''busprotokoll                  : [get.byte1][get.byte2][get.byte3][get.byte4]
''                              : [  hsb    ][         ][         ][   lsb   ]

  wert :=        getchar << 24                      '32 bit empfangen hsb/lsb
  wert := wert + getchar << 16
  wert := wert + getchar << 8
  wert := wert + getchar
PUB getword: wert                                  'bus: 16 bit von administra empfangen hsb/lsb

  wert := getchar << 8
  wert := wert + getchar

PUB putword(wert)                                  'bus: 16 bit an administra senden hsb/lsb

   putchar(wert >> 8)
   putchar(wert)


