{{      VGA-MULTISCREEN
┌──────────────────────────────────────────────────────────────────────────────────────────────────────┐
│ Autor: Ingo Kripahle                                                                                 │
│ Copyright (c) 2010 Ingo Kripahle                                                                     │
│ See end of file for terms of use.                                                                    │
│ Die Nutzungsbedingungen befinden sich am Ende der Datei                                              │
└──────────────────────────────────────────────────────────────────────────────────────────────────────┘

Informationen   : hive-project.de
Kontakt         : drohne235@googlemail.com
System          : Hive
Name            : VGA-Text-Treiber 1024x768 Pixel, 64x24 Zeichen
Chip            : Bellatrix
Typ             : Treiber
Version         : 00
Subversion      : 01
Funktion        : Standard VGA-Text- und Tastatur-Treiber

Dieser Bellatrix-Code kann als Stadardcode im EEPROM gespeichert werden und bietet drei getrennt
ansteuerbare Textbildschirme und Tastaturfunktionen. Mit dem integrierten Loader kann Bellatrix
mit einem beliebigen andern Code geladen werden.

Komponenten     : VGA 1024x768 Tile Driver v0.9   Chip Gracey        MIT
                  PS/2 Keyboard Driver v1.0.1     Chip Gracey, ogg   MIT

COG's           : MANAGMENT     1 COG
                  VGA           2 COG's
                  KEYB          1 COG
                  -------------------
                                4 COG's

oder            : MANAGMENT     1 COG
                  TV            1 COG
                  KEYB          1 COG
                  -------------------
                                3 COG's


Logbuch         :

23-10-2008-dr235  - erste funktionsfähige version erstellt
                  - cursor eingebaut
06-11-2008-dr235  - keyb auf deutsche zeichenbelegung angepasst (ohne umlaute)
24-11-2008-dr235  - tab, setcur, pos1, setx, sety, getx, gety, setcol, sline, screeninit
                    curon, curoff
                  - beltest
13-03-2009-dr235  - LF als Zeichencode ausgeblendet
22-03-2009-dr235  - abfrage für statustasten eingefügt
05-09-2009-dr235  - abfrage der laufenden cogs eingefügt
                  - deutschen tastaturtreiber mit vollständiger belegung! von ogg eingebunden
22-03-2010-dr235  - anpassung trios
01-05-2010-dr235  - scrollup/scrolldown eingebunden & getestet
03-05-2010-dr235  - settab/getcols/getrows/getresx/getresy eingefügt & getestet
                  - hive-logo eingefügt
-------------------
26-01-2011-dr235  - übernahme und anpassung des treibers aus trios
31-01-2011-dr235  - backspace als direktes steuerzeichen ($C8) eingefügt
01-02-2011-dr235  - multiscreenfähigkeit implementiert
                  - 88 - mgr_wscr: steuert, in welchen screen zeichen geschrieben werden
                  - 89 - mgr_dscr: steuert welcher screen angezeigt wird
05-02-2011-dr235  - umwandlung backspace $c8 --> $08
06-03-2011-dr235  - revision der steuercodes; nur noch funktionen mit parameter
                    werden über eine 0-sequenz aufgerufen, alle anderen steuerzeichen
                    werden auf 1-byte-zeichen abgebildet
20-04-2011-dr235  - integration einer kompatiblen loaderroutine, damit kann der treiber
                    jetzt direkt aus dem rom gestartet und dennoch bella-code nachgeladen
                    werden kann
31.12.2011-dr235  - anpassung für verschiedene zeilenumbrüche in print_char eingefügt
28.06.2012-dr235  - fehler im loader behoben (cog0 wurde nicht in allen fällen beendet)
                    dank dafür geht an pic :)
02-10-2012-uheld  - verzögertes Scrolling bei abgeschaltetem Cursor
21-10-2012-uheld  - Window-Funktionen
28-11-2012-uheld  - wahlweise Einbindung von VGA- oder TV-Treiber über #define
15-04-2013-dr235  - konstanten für bellatrix-funktionen komplett ausgelagert
22.02.2014-dr235  - per compilerflag wählbare monitorsettings eingefügt (57/60hz)

Notizen:
- setheader

ACHTUNG: Mit VGA-Treiber ist row nicht die Zeilenposition, da zwei Tiles untereinander ein
Zeichen bilden. Vielmehr ist die reale Zeilenposition row/2.
...oder allgemeingültig für VGA und TV: row/vdrv#TLINES_PER_ROW


}}

{{      STEUERCODES

Byte1   Byte2   Byte3           Byte4           Byte5

0	1	get.stat		                           KEY_STAT	Tastaturstatus abfragen
0	2	get.key			                           KEY_CODE	Tastaturcode abfragen
0	3	$01	        put.curchar	                   SETCUR       Cursorzeichen setzen
0	3	$02	        put.col		                   SETX	        Cursor in Spalte n setzen
0	3	$03	        put.row		                   SETY	        Cursor in Zeile n setzen
0	3	$04	        get.col		                   GETX	        Cursorspalte abfragen
0	3	$05	        get.row		                   GETY	        Cursorzeile abfragen
0	3	$06	        put.color	                   SETCOL       Farbe setzen
0	3	$09			                           SINIT        Screeninit
0	3	$0A 	        put.tabnr	put.tabpos	   TABSET       Tabulatoren setzen
0	4	get.keyspec			                   KEY_SPEC	Sondertasten abfragen
0	5	put.x	        put.y		                   SCR_LOGO	Hive-Logo anzeigen
0	6	put.char			                   SCR_CHAR	Zeichen ohne Steuerzeichen ausgeben

0	58	put.wscrnr			                   MGR_WSCR	Schreibscreen setzen
0	59	put.wscrnr			                   MGR_DSCR	Anzeigescreen setzen
0	5A	put.cnr	        getlong.color		           MGR_GETCOLOR	Farbregister auslesen
0	5B	put.cnr	        putlong.color		           MGR_SETCOLOR	Farbregister setzen
0	5C	getlong.resx			                   MGR_GETRESX	Abfrage der X-Auflösung
0	5D	getlong.resy			                   MGR_GETRESY	Abfrage der Y-Auflösung
0	5E	get.cols			                   MGR_GETCOLS	Abfrage der Textspalten
0	5F	get.rows			                   MGR_GETROWS	Abfrage der Textzeilen
0	60	get.cogs			                   MGR_GETCOGS	Abfrage der anzahl belegter COG's
0	61	getlong.spec			                   MGR_GETSPEC	Abfrage der Funktionsspezifikationen
0	62	getlong.ver			                   MGR_GETVER	Abfrage der Version
0	63				                           MGR_LOAD	Bellatrix-Code laden

$01					                           CLS	        Bildschirm löschen
$02					                           HOME	        Cursor in obere linke Ecke
$03					                           POS1	        Cursor an Zeilenanfang setzen
$04					                           CURON        Cursor anschalten
$05					                           CUROFF       Cursor abschalten
$06					                           SCRLUP       Zeile nach oben scrollen
$07					                           SCRLDOWN	Zeile nach unten scrollen
$08					                           BS	        Rückschritt (Backspace)
$09					                           TAB	        Tabulatorschritt

$0A..FF					                           CHAR	        Zeichenausgabe


}}

'#define __TV
#define __VGA

'Hier sind verschiedene Timings für den Monitor wählbar.
'Die Settings selbst befinden sich in der Datei /lib/bel-vga.spin und
'können dort auch um weitere Optionen erweitert werden.

#define __VGA_MONSET1           '60Hz
'#define __VGA_MONSET2          '57Hz


CON

_CLKMODE     = XTAL1 + PLL16X
_XINFREQ     = 5_000_000


'                   +----------
'                   |  +------- system     
'                   |  |  +---- version    (änderungen)
'                   |  |  |  +- subversion (hinzufügungen)
CHIP_VER        = $00_01_02_02

#ifdef __TV
CHIP_SPEC = gc#b_tv|gc#b_key|gc#b_txt|gc#b_win
#endif
#ifdef __VGA
CHIP_SPEC = gc#b_vga|gc#b_key|gc#b_txt|gc#b_win
#endif

RESX         = vdrv#COLS * 16
RESY         = vdrv#ROWS * 16

TILES        = vdrv#COLS * vdrv#ROWS

USERCHARS    = 16               '8x2 logo

TABANZ       = 8
SCROLLDIFF   = vdrv#TLINES_PER_ROW * vdrv#COLS

CURSORCHAR   = $0E                                     'cursorzeichen
SCREENS      = 3                                       'anzahl der screens
WIN_P_SCR    = 8                                       'Anzahl der Windows per Screen



OBJ

#ifdef __TV
  vdrv       : "belf-tv"
#endif
#ifdef __VGA
  vdrv       : "belf-vga"
#endif
  keyb       : "bel-keyb"
  bus        : "bel-bus"
  gc         : "glob-con"       'globale konstanten

VAR

  long  wind                                            'index des screens, in welchen aktuell geschrieben wird
  long  dind                                            'index des screens, der aktuell dargestellt wird
  long  keycode                                         'letzter tastencode
  long  array[TILES/vdrv#TLINES_PER_ROW*SCREENS]             'bildschirmpuffer
  byte  tab[TABANZ]                                     'tabulatorpositionen
  word  user_charbase                                   'adresse der userzeichen
  byte  wscrnr                                          'nummer ausgabescreens
  word  lchar                                           'letztes zeichen
  byte  this_win[SCREENS]                               'Nr. des aktuellen Windows pro Screen

  byte  col[SCREENS*WIN_P_SCR]                          'spaltenposition
  byte  row[SCREENS*WIN_P_SCR]                          'zeilenposition
  long  color[SCREENS*WIN_P_SCR]                        'zeichenfarbe
  byte  cursor[SCREENS*WIN_P_SCR]                       'cursorzeichen
  byte  curstat[SCREENS*WIN_P_SCR]                      'cursorstatus 1 = ein
  byte  needs_nl[SCREENS]                               'Flag für verzögertes newline, falls curoff
  ' needs_nl ist ein Bit-Feld!! WIN_P_SCR darf deshalb nicht >8 sein!!
  byte  nnl_idx                                         'Bitmaske für Operationen auf needs_nl
  byte  windows[SCREENS*WIN_P_SCR*4]                    'Window-Grenzen (x0,y0,xn,yn pro Window)

  byte  ccol, crow                                      'current... werden durch win_set gefüllt
'  long  ccolor  ' muss in vdrv definiert werden!!      'current... werden durch win_set gefüllt
  byte  ccursor, ccurstat                               'current...
  byte  cwcols, cwrows                                  'current..., Breite und Höhe des aktuellen Window
  byte  cx0, cy0, cxn, cyn                              'Koordinaten des aktuellen Windows
  byte  cneeds_nl

  long  plen                                            'länge datenblock loader
  byte  proghdr[16]                                     'puffer für objektkopf

CON ''------------------------------------------------- BELLATRIX


PUB main | zeichen,n                                    'chip: kommandointerpreter
''funktionsgruppe               : chip
''funktion                      : kommandointerpreter
''eingabe                       : -
''ausgabe                       : -

  init_subsysteme                                       'bus/vga/keyboard/maus initialisieren
  repeat
    zeichen := bus.getchar                              '1. zeichen empfangen
    if zeichen                                          ' > 0
      print_char(zeichen)
    else
      zeichen := bus.getchar                            '2. zeichen kommando empfangen
      case zeichen
        gc#b_keystat:           key_stat                'tastaturstatus senden
        gc#b_keycode:           key_code                'tastaturzeichen senden
        gc#b_printctrl:         print_ctrl(bus.getchar) 'steuerzeichen ($100..$1FF) ausgeben
        gc#b_keyspec:           key_spec                'statustasten ($100..$1FF) abfragen
        gc#b_printlogo:         print_logo              'hive-logo ausgeben
        gc#b_printqchar:        pchar(bus.getchar)      'zeichen ohne steuerzeichen augeben
'       ----------------------------------------------  WINDOW
        gc#b_wdef:              win_define
        gc#b_wset:              win_set(wscrnr)
        gc#b_wgetcols:          win_getcols
        gc#b_wgetrows:          win_getrows
        gc#b_woframe:           win_oframe
'       ----------------------------------------------  CHIP-MANAGMENT
        gc#b_mgrload:           mgr_load                'neuen bellatrix-code laden
        gc#b_mgrwscr:           mgr_wscr                'setzt screen, in welchen geschrieben wird
        gc#b_mgrdscr:           mgr_dscr                'setzt screen, welcher angezeigt wird
        gc#b_mgrgetcol:         mgr_getcolor            'farbregister auslesen
        gc#b_mgrsetcol:         mgr_setcolor            'farbregister setzen
        gc#b_mgrgetresx:        mgr_getresx             'x-auflösung abfragen
        gc#b_mgrgetresy:        mgr_getresy             'y-auflösung abfragen
        gc#b_mgrgetcols:        mgr_getcols             'spaltenanzahl abfragen
        gc#b_mgrgetrows:        mgr_getrows             'zeilenanzahl abfragen
        gc#b_mgrgetcogs:        mgr_getcogs             'freie cogs abfragen
        gc#b_mgrgetspec:        mgr_getspec             'spezifikation abfragen
        gc#b_mgrgetver:         mgr_getver              'codeversion abfragen
        gc#b_mgrreboot:         reboot                  'bellatrix neu starten


PUB init_subsysteme|i                             'chip: initialisierung des bellatrix-chips
''funktionsgruppe               : chip
''funktion                      : - initialisierung des businterface
''                              : - vga & keyboard-treiber starten
''eingabe                       : -
''ausgabe                       : -

  bus.init_bus

  keyb.start(gc#b_keybd, gc#b_keybc)                    'tastaturport starten

  wind := dind := wscrnr := 0                           'auf ersten screen stellen
  repeat i from 0 to SCREENS-1
    screen_init(i)
  set_current_win  ' wscrnr = 0 --> Window 1 von Screen 0 aktivieren

  vdrv.start(@array)
  repeat i from 0 to TABANZ-1                           'tabulatoren setzen
    tab[i] := i * 4

  ' Ein schönes Logo gibt's z.Z. nur bei VGA
  user_charbase := @uchar & $FFC0                       'berechnet die nächste 64-byte-grenze hinter dem zeichensatz
  longmove(user_charbase,@uchar,16*USERCHARS)           'verschiebt den zeichensatz auf die nächste 64-byte-grenze

  repeat i from 0 to SCREENS-1
    wind := TILES*i                                     'ausgabe-index berechnen
    _print_logo(0,0)                                      'hive-logo anzeigen
  schar(cursor[wscrnr])                                         'cursor an
  wind := 0

PRI screen_init(i) | x, w      ' alle Windows von Screen i auf Standardgröße setzen, Window 1 wählen
  wordfill(@array.word[i*TILES], vdrv#SPACETILE, tiles)  ' CLS
  cursor[i*WIN_P_SCR] := CURSORCHAR                        'cursorzeichen setzen
  curstat[i*WIN_P_SCR] := 1                                'cursor anschalten
  needs_nl[i] := 0                                         'darf nur am Bildschirmende 1 sein
  x := i * WIN_P_SCR * 4
  windows[x++] := 0                                   ' x0
  windows[x++] := 0                                   ' y0
  windows[x++] := vdrv#COLS - 1                       ' xn
  windows[x++] := vdrv#ROWS - vdrv#TLINES_PER_ROW     ' yn
  repeat w from 1 to WIN_P_SCR - 1
    windows[x++] := 0                                 ' x0
    windows[x++] := vdrv#DEFAULT_Y0                   ' y0
    windows[x++] := vdrv#COLS - 1                     ' xn
    windows[x++] := vdrv#ROWS - vdrv#TLINES_PER_ROW   ' yn
    cursor[i*WIN_P_SCR+w] := CURSORCHAR
    curstat[i*WIN_P_SCR+w] := 1
    row[i*WIN_P_SCR+w] := vdrv#DEFAULT_Y0             'home
    col[i*WIN_P_SCR+w] := 0                           'pos1
    color[i*WIN_P_SCR+w] := 0
  this_win[i] := 1


CON ''------------------------------------------------- CHIP-MANAGMENT-FUNKTIONEN

PRI mgr_wscr|scrnr, oldscr                               'cmgr: setzt screen, in welchen geschrieben wird
''funktionsgruppe               : cmgr
''funktion                      : schaltet die ausgabe auf einen bestimmten screen
''eingabe                       : -
''ausgabe                       : -
''busprotokoll                  : [0][088][get.wscrnr]
''                              : wscrnr - nummer des screens 1..SCREENS

  scrnr := bus.getchar - 1
  if scrnr => 0 and scrnr < SCREENS
    oldscr := wscrnr
    wscrnr := scrnr
    wind := TILES*wscrnr        'ausgabe-index berechnen
    win_set_int(oldscr, this_win[wscrnr])

PRI mgr_dscr|scrnr                                      'cmgr: setzt screen, welcher angezeigt wird
''funktionsgruppe               : cmgr
''funktion                      : schaltet die anzeige auf einen bestimmten screen
''eingabe                       : -
''ausgabe                       : -
''busprotokoll                  : [0][089][get.scrnr]
''                              : scrnr - nummer des screens 1..SCREENS

  scrnr := bus.getchar - 1
  if scrnr => 0 and scrnr < SCREENS
'    dind := TILES * vdrv#TLINES_PER_ROW * scrnr               'display-index berechnen
    dind := TILES * 2 * scrnr               'display-index berechnen
    vdrv.set_dscr(@array+dind)

PUB mgr_getcolor|cnr                                    'cmgr: farbregister auslesen
''funktionsgruppe               : cmgr
''funktion                      : farbregister auslesen
''eingabe                       : -
''ausgabe                       : -
''busprotokoll                  : [0][090][get.cnr][bus.putlong.color]
''                              : cnr   - nummer des farbregisters 0..15
''                              : color - erster wert

  cnr := bus.getchar
  bus.putlong(vdrv.get_color(cnr))

PUB mgr_setcolor|cnr, colr                               'cmgr: farbregister setzen
''funktionsgruppe               : cmgr
''funktion                      : farbregister setzen
''eingabe                       : -
''ausgabe                       : -
''busprotokoll                  : [0][091][get.cnr][bus.getlong.color]
''                              : cnr   - nummer des farbregisters 0..15
''                              : color - farbwert

  cnr   := bus.getchar
  colr := bus.getlong
  vdrv.set_color(cnr, colr)

PUB mgr_getresx                                         'cmgr: abfrage der x-auflösung
''funktionsgruppe               : cmgr
''funktion                      : abfrage der x-auflösung
''eingabe                       : -
''ausgabe                       : -
''busprotokoll                  : [0][092][put.resx]
''                              : resx - x-auflösung

  bus.putlong(RESX)

PUB mgr_getresy                                         'cmgr: abfrage der y-auflösung
''funktionsgruppe               : cmgr
''funktion                      : abfrage der y-auflösung
''eingabe                       : -
''ausgabe                       : -
''busprotokoll                  : [0][093][put.resy]
''                              : resy - y-auflösung

  bus.putlong(RESY)


PUB mgr_getcols                                         'cmgr: abfrage der Textspalten
''funktionsgruppe               : cmgr
''funktion                      : abfrage der textspalten
''eingabe                       : -
''ausgabe                       : -
''busprotokoll                  : [0][094][put.cols]
''                              : cols - anzahl der textspalten

  bus.putchar(vdrv#COLS)
  

PUB mgr_getrows                                         'cmgr: abfrage der textzeilen
''funktionsgruppe               : cmgr
''funktion                      : abfrage der textzeilen
''eingabe                       : -
''ausgabe                       : -
''busprotokoll                  : [0][095][put.rows]
''                              : rows - anzahl der textzeilen

  bus.putchar(vdrv#ROWS/vdrv#TLINES_PER_ROW)
  
PUB mgr_getcogs: cogs |i,c,cog[8]                       'cmgr: abfragen wie viele cogs in benutzung sind
''funktionsgruppe               : cmgr
''funktion                      : abfrage wie viele cogs in benutzung sind
''eingabe                       : -
''ausgabe                       : cogs - anzahl der cogs
''busprotokoll                  : [0][096][put.cogs]
''                              : cogs - anzahl der belegten cogs

  cogs := i := 0
  repeat 'loads as many cogs as possible and stores their cog numbers
    c := cog[i] := cognew(@entry, 0)
    if c=>0
      i++
  while c => 0
  cogs := i
  repeat 'unloads the cogs and updates the string
    i--
    if i=>0
      cogstop(cog[i])
  while i=>0
  bus.putchar(cogs)

PUB mgr_getspec                                         'cmgr: abfrage der spezifikation des chips
''funktionsgruppe               : cmgr
''funktion                      : abfrage der version und spezifikation des chips
''eingabe                       : -
''ausgabe                       : cogs - anzahl der cogs
''busprotokoll                  : [097][bus.putlong.spec]
''                              : spec - spezifikation
''
''
''                                          +---------- 
''                                          | +-------- window
''                                          | |+------- vektor
''                                          | ||+------ grafik
''                                          | |||+----- text
''                                          | ||||+---- maus
''                                          | |||||+--- tastatur
''                                          | ||||||+-- vga
''                                          | |||||||+- tv
''CHIP_SPEC     = %00000000_00000000_00000000_10010110

  bus.putlong(CHIP_SPEC)

PUB mgr_getver                                          'cmgr: abfrage der version 
''funktionsgruppe               : cmgr
''funktion                      : abfrage der version und spezifikation des chips
''eingabe                       : -
''ausgabe                       : cogs - anzahl der cogs
''busprotokoll                  : [098][bus.putlong.ver]
''                              : ver - version
''
''                  +----------
''                  |  +------- system     
''                  |  |  +---- version    (änderungen)
''                  |  |  |  +- subversion (hinzufügungen)
''CHIP_VER      = $00_01_02_01

  bus.putlong(CHIP_VER)


PUB mgr_load|i                                          'cmgr: bellatrix-loader
''funktionsgruppe               : cmgr
''funktion                      : funktion um einen neuen code in bellatrix zu laden
''
''bekanntes problem: einige wenige bel-dateien werden geladen aber nicht korrekt gestartet
''lösung: diese datei als eeprom-image speichern

' kopf der bin-datei einlesen                           ------------------------------------------------------
  repeat i from 0 to 15                                 '16 bytes --> proghdr
    byte[@proghdr][i] := bus.getchar

  plen := 0
  plen :=        byte[@proghdr + $0B] << 8
  plen := plen + byte[@proghdr + $0A]
  plen := plen - 8

' objektlänge an regnatix senden
  bus.putchar(plen >> 8)                                'hsb senden
  bus.putchar(plen & $FF)                               'lsb senden

  repeat i from 0 to 7                                  'alle anderen cogs anhalten
    ifnot i == cogid
      cogstop(i)

  dira := 0                                             'diese cog vom bus trennen
  cognew(@loader, plen)

  cogstop(cogid)                                        'cog 0 anhalten

DAT
                        org     0

loader
                        mov     outa,    M_0               'bus inaktiv
                        mov     dira,    DINP              'bus auf eingabe schalten
                        mov     reg_a,   PAR               'parameter = plen
                        mov     reg_b,   #0                'adresse ab 0

                        ' datenblock empfangen
loop
                        call    #get                       'wert einlesen
                        wrbyte  in,      reg_b             'wert --> hubram
                        add     reg_b,   #1                'adresse + 1
                        djnz    reg_a,   #loop

                        ' neuen code starten

                        rdword  reg_a,   #$A               ' Setup the stack markers.
                        sub     reg_a,   #4                '
                        wrlong  SMARK,   reg_a             '
                        sub     reg_a,   #4                '
                        wrlong  SMARK,   reg_a             '

                        rdbyte  reg_a,   #$4               ' Switch to new clock mode.
                        clkset  reg_a                                             '

                        coginit SINT                       ' Restart running new code.


                        cogid   reg_a
                        cogstop reg_a                      'cog hält sich selbst an


get
                        waitpeq M_1,      M_2              'busclk=1? & /cs=0?
                        mov     in,       ina              'daten einlesen
                        and     in,       DMASK            'wert maskieren
                        mov     outa,     M_3              'hs=0
                        waitpeq M_3,      M_4              'busclk=0?
                        mov     outa,     M_0              'hs=1
get_ret                 ret


'     hbeat   --------+
'     clk     -------+|
'     /wr     ------+||
'     /hs     -----+|||+------------------------- /cs
'                  |||||                 -------- d0..d7
DINP    long  %00001000000000000000000000000000  'constant dinp hex  \ bus input
DOUT    long  %00001000000000000000000011111111  'constant dout hex  \ bus output
M_0     long  %00001000000000000000000000000000  'bus inaktiv
M_1     long  %00000010000000000000000000000000
M_2     long  %00000010100000000000000000000000  'busclk=1? & /cs=0?
M_3     long  %00000000000000000000000000000000
M_4     long  %00000010000000000000000000000000  'busclk=0?


DMASK   long  %00000000000000000000000011111111  'datenmaske

SINT    long    ($0001 << 18) | ($3C01 << 4)                       ' Spin interpreter boot information.
SMARK   long    $FFF9FFFF                                          ' Stack mark used for spin code.

in      res   1
reg_a   res   1
reg_b   res   1



CON ''------------------------------------------------- KEYBOARD-FUNKTIONEN

PUB key_stat                                            'key: tastaturstatus abfragen

  bus.putchar(keyb.gotkey)

PUB key_code                                            'key: tastencode abfragen

  keycode := keyb.key
  case keycode
    $c8: keycode := $08                                 'backspace wandeln
  bus.putchar(keycode)

PUB key_spec                                            'key: statustaten vom letzten tastencode abfragen

  bus.putchar(keycode >> 8)


CON ''------------------------------------------------- WINDOW-FUNKTIONEN

PUB win_define | w, x0, y0, xn, yn, x
  w := bus.getchar
  x0 := bus.getchar #> 0 <# vdrv#COLS-1
  y0 := (bus.getchar * vdrv#TLINES_PER_ROW) #> 0 <# vdrv#ROWS-1
  xn := bus.getchar #> x0 <# vdrv#COLS-1
  yn := (bus.getchar * vdrv#TLINES_PER_ROW) #> y0 <# vdrv#ROWS-1
  if w < 1 or w => WIN_P_SCR                    ' Window 0 wird nicht überschrieben!
    return
  x := wscrnr*WIN_P_SCR*4 + w*4
  windows[x++] := x0
  windows[x++] := y0
  windows[x++] := xn
  windows[x] := yn
  x := wscrnr*WIN_P_SCR + w
  col[x] := x0
  row[x] := y0

PUB win_set(oldscr) | w
  w := bus.getchar
  if w < 0 or w => WIN_P_SCR
    return
  win_set_int(oldscr, w)

PRI win_set_int(oldscr, w) | x
  ' current-Werte in altes Window sichern
  x := oldscr*WIN_P_SCR + this_win[oldscr]
  col[x] := ccol
  row[x] := crow
  color[x] := vdrv.get_ccolor
  cursor[x] := ccursor
  curstat[x] := ccurstat
  needs_nl[oldscr] := cneeds_nl
  if ccurstat == 1
    schar($20)

  ' current-Werte für neues Window setzen
  this_win[wscrnr] := w
  set_current_win
  if ccurstat == 1
    schar(ccursor)

PRI set_current_win | x
  x := wscrnr*WIN_P_SCR + this_win[wscrnr]
  ccol := col[x]
  crow := row[x]
  vdrv.set_ccolor(color[x])
  ccursor := cursor[x]
  ccurstat := curstat[x]
  x := wscrnr*WIN_P_SCR*4 + this_win[wscrnr]*4
  cx0 := windows[x++]
  cy0 := windows[x++]
  cxn := windows[x++]
  cyn := windows[x]
  cwcols := cxn - cx0 + 1
  cwrows := cyn - cy0 + vdrv#TLINES_PER_ROW
  nnl_idx := 1 << this_win[wscrnr]
  cneeds_nl := needs_nl[wscrnr]

PUB win_getcols
  bus.putchar(cwcols)

PUB win_getrows
  bus.putchar(cwrows / vdrv#TLINES_PER_ROW)

PUB win_oframe | c, r
  c := ccol  ' aktuelle Werte aufheben und am Ende zuruecksetzen
  r := crow

  if cy0    ' oberer Rand ist sichtbar
    crow := cy0 - vdrv#TLINES_PER_ROW
    if cx0
      ccol := cx0 - 1
      schar(159)
    repeat ccol from cx0 to cxn
      schar(144) '-
    if cxn < vdrv#COLS-1
      ccol := cxn + 1
      schar(158)
  if cx0    ' linke Seite ist sichtbar
    ccol := cx0 - 1
    repeat crow from cy0 to cyn step vdrv#TLINES_PER_ROW
      schar(145) '|
  if cxn < vdrv#COLS-1    ' rechte Seite ist sichtbar
    ccol := cxn + 1
    repeat crow from cy0 to cyn step vdrv#TLINES_PER_ROW
      schar(145) '|
  if cyn < vdrv#ROWS - vdrv#TLINES_PER_ROW    ' unterer Rand ist sichtbar
    crow := cyn + vdrv#TLINES_PER_ROW
    if cx0
      ccol := cx0 - 1
      schar(157)
    repeat ccol from cx0 to cxn
      schar(144) '-
    if cxn < vdrv#COLS-1
      ccol := cxn + 1
      schar(156)
  ccol := c
  crow := r

CON ''------------------------------------------------- SCREEN-FUNKTIONEN

PUB print_char(c) | code,n                              'screen: zeichen auf bildschirm ausgeben
{{zeichen auf bildschirm ausgeben}}

  'anpassung für die  verschiedenen zeilenumbrüche
  'damit sollten alle drei versionen funktionieren:
  'dos/win: $0d $0a
  'unix/linux: $0a
  'mac: $0d
  if c == $0a and lchar == $0d
    c := 0
  lchar := c

  case c
    $0E..$FF:                                           'character?
      pchar(c)
      if ccurstat == 1
        schar(ccursor)
      return
    gc#b_cls:                                           'clear screen?
      n := wind + cy0 * vdrv#COLS + cx0   ' links oben
      repeat cwrows
        wordfill(@array.word[n], vdrv#SPACETILE, cwcols)
        n += vdrv#COLS
      crow := cy0
      ccol := cx0
      needs_nl[wscrnr] &= !nnl_idx
      if ccurstat == 1                                   'cursor einschalten
        schar(ccursor)
    gc#b_home:                                           'home?
      cneeds_nl &= !nnl_idx
      if ccurstat == 1
          schar($20)
      crow := cy0
      ccol := cx0
      if ccurstat == 1
          schar(ccursor)
    gc#b_pos1:                                           'pos1
      cneeds_nl &= !nnl_idx
      if ccurstat == 1
        schar($20)
      ccol := cx0
      if ccurstat == 1
        schar(ccursor)
    gc#b_curon:                                          'curon
      if cneeds_nl & nnl_idx
        newline
        cneeds_nl ^= nnl_idx
      ccurstat := 1
      schar(ccursor)
    gc#b_curoff:                                         'curoff
      if ccurstat == 1
        schar($20)
      ccurstat := 0
    gc#b_scrollup:                                       'scrollup
      if ccurstat == 1
        schar($20)
      scrollup
      if ccurstat == 1
        schar(ccursor)
    gc#b_scrolldown:                                     'scrolldown
      if ccurstat == 1
        schar($20)
      scrolldown
      if ccurstat == 1
        schar(ccursor)
    gc#b_backspace:                                      'backspace?
      cneeds_nl &= !nnl_idx
      if ccol > cx0
        if ccurstat == 1
          schar($20)
        ccol--
        if ccurstat == 1
          schar(ccursor)
    gc#b_tab:                                            'tab
      repeat n from 0 to TABANZ-1
        if ccol < tab[n] + cx0
          if ccurstat == 1
            schar($20)
          ccol := tab[n] + cx0
          if ccurstat == 1
            schar(ccursor)
          quit
    gc#b_lf:                                             'LF ausblenden
      cneeds_nl &= !nnl_idx
      if ccurstat == 1
        schar($20)
      newline
      if ccurstat == 1
        schar(ccursor)
    gc#b_crlf:                                           'return?
      if ccurstat == 1
        schar($20)
      newline
      if ccurstat == 1
        schar(ccursor)


PUB print_ctrl(c) | code,n,m                            'screen: steuerzeichen ausgeben
  case c
    gc#b_setcur:                                        'setcur
      code := bus.getchar
      ccursor := code
      if ccurstat == 1
        schar(code)
    gc#b_setx:                                          'setx
      if ccurstat == 1
        schar($20)
      cneeds_nl &= !nnl_idx
      ccol := bus.getchar #> 0 <# vdrv#COLS-1
      if ccurstat == 1
        schar(ccursor)
    gc#b_sety:                                          'sety
      if ccurstat == 1
        schar($20)
      cneeds_nl &= !nnl_idx
      crow := (bus.getchar * vdrv#TLINES_PER_ROW) #> 0 <# vdrv#ROWS-vdrv#TLINES_PER_ROW
      if ccurstat == 1
        schar(ccursor)
    gc#b_getx:                                           'getx
      bus.putchar(ccol)
    gc#b_gety:                                           'gety
      bus.putchar(crow / vdrv#TLINES_PER_ROW)
    gc#b_setcol:                                         'setcolor
      vdrv.set_ccolor(bus.getchar)
    gc#b_sinit:                                          'screeninit
      screen_init(wscrnr)
      set_current_win
    gc#b_tabset:                                         'tabulator setzen
        n := bus.getchar
        m := bus.getchar
        if n =< (TABANZ-1)
          tab[n] := m
    gc#b_wsetx:                                          'winsetx
      if ccurstat == 1
        schar($20)
      cneeds_nl &= !nnl_idx
      code := bus.getchar
      ccol := ~code #> -cwcols <# cwcols-1  ' negativ --> Abstand von rechts+1
      if code < 0
        ccol += cxn + 1
      else
        ccol += cx0
      if ccurstat == 1
        schar(ccursor)
    gc#b_wsety:                                           'winsety
      if ccurstat == 1
        schar($20)
      cneeds_nl &= !nnl_idx
      code := bus.getchar
      ~code
      crow := (code * vdrv#TLINES_PER_ROW) #> -cwrows <# cwrows-vdrv#TLINES_PER_ROW    '2 tiles pro zeichen!
      if code < 0
        crow += cyn + vdrv#TLINES_PER_ROW
      else
        crow += cy0
      if ccurstat == 1
        schar(ccursor)
    gc#b_wgetx:                                            'wingetx
      bus.putchar(ccol - cx0)
    gc#b_wgety:                                            'wingety
      bus.putchar((crow - cy0) / vdrv#TLINES_PER_ROW)

PRI schar(c)
  vdrv.schar(crow * vdrv#COLS + ccol + wind, c)

PRI pchar(c)                                            'screen: schreibt zeichen mit cursor an aktuelle position
  if cneeds_nl & nnl_idx
    newline
    cneeds_nl ^= nnl_idx
  schar(c)
  if ++ccol > cxn
    if ccurstat == 1
      newline
    else
      cneeds_nl |= nnl_idx

PUB newline | i                                         'screen: zeilenwechsel, inkl. scrolling am screenende
  ccol := cx0
  if (crow += vdrv#TLINES_PER_ROW) > cyn
    crow -= vdrv#TLINES_PER_ROW
    scrollup

PUB scrollup | zadr                                     'screen: scrollt den screen nach oben
' Start: linke obere Ecke, Breite: Window-Breite, Schrittweite: absolute Screen-Breite
  zadr := wind + cy0 * vdrv#COLS + cx0   ' links oben
  repeat cwrows-vdrv#TLINES_PER_ROW
    wordmove(@array.word[zadr], @array.word[zadr+SCROLLDIFF], cwcols)
    zadr += vdrv#COLS
  'clear new line
  wordfill(@array.word[zadr], vdrv#SPACETILE, cwcols)
  if vdrv#TLINES_PER_ROW > 1
    wordfill(@array.word[zadr+vdrv#COLS], vdrv#SPACETILE, cwcols)

PUB scrolldown | zadr                                   'screen: scrollt den screen nach unten
  zadr := wind + (cyn+vdrv#TLINES_PER_ROW-1) * vdrv#COLS + cx0  ' links unten
  repeat cwrows-vdrv#TLINES_PER_ROW
    wordmove(@array.word[zadr], @array.word[zadr-SCROLLDIFF], cwcols)
    zadr -= vdrv#COLS
  'clear new line
  wordfill(@array.word[zadr], vdrv#SPACETILE, cwcols)
  if vdrv#TLINES_PER_ROW > 1
    wordfill(@array.word[zadr-vdrv#COLS], vdrv#SPACETILE, cwcols)

PRI print_logo|x,y                                      'screen: hive-logo ausgeben

  x := bus.getchar
  y := bus.getchar
  _print_logo(x,y)

#ifdef __TV
PRI _print_logo(x,y)|c, r
  c := ccol
  r := crow
  ccol := x #> 0 <# vdrv#COLS-1
  crow := (y * vdrv#TLINES_PER_ROW) #> 0 <# vdrv#ROWS-vdrv#TLINES_PER_ROW            '2 tiles pro zeichen!
  pchar(" ")
  pchar("H")
  pchar("i")
  pchar("v")
  pchar("e")
  ccol := c
  crow := r
#endif
#ifdef __VGA
PRI _print_logo(x,y)|padr
  padr := @hive+user_charbase-@uchar
  print_uchar(padr, x, y, 8, 2, 1)                       'logo zeichnen
#endif

PRI print_uchar(pBMP,xPos,yPos,xSize,ySize,clr)|c,i,j,t 'screen: zeichnet ein einzelnes tilefeld
{
- setzt in der tilemap des vga-treibers die adressen auf das entsprechende zeichen
- setzt mehrer tiles je nach xSize und ySize
- jedes tile besteht aus 16x16 pixel, weshalb die adresse jedes tiles mit c<<6 gebildet wird
- alle 64 byte (c<<6) beginnt im bitmap ein tile
}
  t:=xPos
  c:=0
  repeat j from 0 to (ySize-1)
    repeat i from 0 to (xSize-1)
      array.word[yPos * vdrv#COLS + xPos + wind] := pBMP + (c<<6) + clr
      c++
      xPos++
    yPos++
    xPos:=t


DAT

                        org
'
' Entry: dummy-assemblercode fuer cogtest
'
entry                   jmp     entry                   'just loops



DAT

padding       long 1[16]        '64-byte raum für die ausrichtung des zeichensatzes     
uchar         long

hive    long
file "logo-hive-8x2.dat"         '8x2=16


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
