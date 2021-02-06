{{      VGA-64Farben
┌──────────────────────────────────────────────────────────────────────────────────────────────────────┐
│ Autor: Ingo Kripahle,Reinhard Zielinski                                                              │
│ Copyright (c) 2013 Ingo Kriphale,Reinhard Zielinski                                                  │
│ See end of file for terms of use.                                                                    │
│ Die Nutzungsbedingungen befinden sich am Ende der Datei                                              │
└──────────────────────────────────────────────────────────────────────────────────────────────────────┘

Informationen   : hive-project.de
Kontakt         : zille9@googlemail.com
System          : Hive
Name            : VGA-Tile-Treiber 640x480 Pixel, 40x28 Tiles
Chip            : Bellatrix
Typ             : Treiber
Version         : 01
Subversion      : 00
Funktion        : Standard VGA-Text- und Tastatur-Treiber

Dieser Bellatrix-Code kann als Stadardcode im EEPROM gespeichert werden Tilebasierten-Textbildschirm
und Tastaturfunktionen. Mit dem integrierten Loader kann Bellatrix
mit einem beliebigen anderen Code geladen werden.

Komponenten     : VGA64 Tilemap Engine // Author: Kwabena W. Agyeman
                  PS/2 Keyboard Driver v1.0.1     Chip Gracey, ogg   MIT

COG's           : MANAGMENT     1 COG
                  VGA           1 COG's
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

02-04-2013-zille9 - Kompletter Umbau durch Einbindung eines anderen Grafiktreibers

02-06-2013-zille9 - Startbild ala Amiga eingebunden, fordert zum Einlegen einer SD-Card mit TRIOS auf

28-12-2013-zille9 - Fensterfunktionen für 8 Windows mit 8 verschiedenen Stilen geschaffen
                  - Button-Funktionen auf Abfrage der Mauskoordinaten beschränkt, grafische Funktionen werden wieder von Regnatix erledigt
                  - dadurch Code gespart, da nur noch die Koordinaten-Puffer und die Button-Nummer benötigt werden
05-01-2014-zille9 - Fensterverwaltung überarbeitet, bei Klick auf ein Fensterbutton wird die Fensternummer*10+Buttonnummer zurückgegeben
                  - Beispiel:Schließen Symbol im Fenster 2 gibt 22 zurück (20 für Fenster 2 und 2 für Fensterbutton 2)
                  - dadurch wird es möglich, mehrere Fenster auf Funktionen abzufragen
                  - 234 Longs frei

Notizen:

}}


CON

_CLKMODE     = XTAL1 + PLL16X
_XINFREQ     = 5_000_000

'signaldefinitionen bellatrixix

#0,     D0,D1,D2,D3,D4,D5,D6,D7                         'datenbus
#8,     BEL_VGABASE                                     'vga-signale (8pin)
#16,    BEL_KEYBC,BEL_KEYBD                             'keyboard-signale
#18,    BEL_MOUSEC,BEL_MOUSED                           'maus-signale
#20,    BEL_VIDBASE                                     'video-signale(3pin)
#23,    BEL_SELECT                                      'belatrix-auswahlsignal
#24,    HBEAT                                           'front-led
        BUSCLK                                          'bustakt
        BUS_WR                                          '/wr - schreibsignal
        BUS_HS '                                        '/hs - quittungssignal
#41,    RTC_GETSECONDS                              'Returns the current second (0 - 59) from the real time clock.
        RTC_GETMINUTES                              'Returns the current minute (0 - 59) from the real time clock.
        RTC_GETHOURS                                'Returns the current hour (0 - 23) from the real time clock.
'                   +----------
'                   |  +------- system     
'                   |  |  +---- version    (änderungen)
'                   |  |  |  +- subversion (hinzufügungen)
'CHIP_VER        = $00_01_02_01
'
'                                           +---------- 
'                                           | +-------- 
'                                           | |+------- vektor
'                                           | ||+------ grafik
'                                           | |||+----- text
'                                           | ||||+---- maus
'                                           | |||||+--- tastatur
'                                           | ||||||+-- vga
'                                           | |||||||+- tv
CHIP_SPEC       = %00000000_00000000_00000000_00011110


KEYB_DPORT   = BEL_KEYBD                               'tastatur datenport
KEYB_CPORT   = BEL_KEYBC                               'tastatur taktport
mouse_dport  = BEL_MOUSED
mouse_cport  = BEL_MOUSEC

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

_pinGroup = 1
_startUpWait = 2

linelen      =39

buttonbuff=33                                                                                            'Buttonanzahl 1-32 Textbutton oder icon

Bel_Treiber_Ver=640                                                                                       'Bellatrix-Treiberversion

  #$FC, Light_Grey, #$A8, Grey, #$54, Dark_Grey
  #$C0, Light_Red, #$80, Red, #$40, Dark_Red
  #$30, Light_Green, #$20, Green, #$10, Dark_Green
  #$1F, Light_Blue, #$09, Blue, #$04, Dark_Blue
  #$F0, Light_Orange, #$E6, Orange, #$92, Dark_Orange
  #$CC, Light_Purple, #$88, Purple, #$44, Dark_Purple
  #$3C, Light_Teal, #$28, Teal, #$14, Dark_Teal
  #$FF, White, #$00, Black


OBJ
  vga        : "VGA64_Engine_Tile"
  keyb       : "bel-keyb"
  mouse      : "mouse64"
  gc         : "glob-con"

VAR

  long keycode                                                                                           'letzter tastencode
  long plen                                                                                              'länge datenblock loader
  long mousetile[16]                                                                                     'User-Mousetilebuffer
  word tnr,XPos,YPos
  word xbound,ybound,xxbound,yybound                                                                     'x und y bereich der Mouse eingrenzen
  byte proghdr[16]                                                                                       'puffer für objektkopf
  byte mouseshow                                                                                         'Mouse-Pfeil anzeigen oder nicht
  byte strkette[40]                                                                                      'stringpuffer fuer Scrolltext
  byte bnumber[buttonbuff],bx[buttonbuff],by[buttonbuff],bxx[buttonbuff]                                 'buttonvariable fuer 33 Buttons
  byte hintergr
  byte actor[5]                                                                                          'Actor-Sprite [Tilenr,col1,col2,col3,x,y] Spielerfigur
  byte action_x,old_action_x
  byte action_y,old_action_y
  byte sprite_x[8],sprite_y[8],sprite_old_x[8],sprite_old_y[8]                                           'x,y-Parameter der Sprites
  byte spritenr[16]                                                                                      'Tilenr der Sprites+Alternativ-Sprites
  byte spritef1[8],spritef2[8],spritef3[8]                                                               'farben der Sprites
  byte sprite_dir[8]                                                                                     'Bewegungsrichtung der Sprites
  byte action_key[5]
  byte sprite_start[8]
  byte sprite_end[8]
  byte Sprite_Move
  byte collision
  byte block_tile[10]
  byte sp_alter
  byte wind[112]
  byte wint[17]                                                                                          'Tilenummern für die Fenster

CON ''------------------------------------------------- BELLATRIX

PUB main | zeichen,n,i,x,y ,speed,bs                             'chip: kommandointerpreter
''funktionsgruppe               : chip
''funktion                      : kommandointerpreter
''eingabe                       : -
''ausgabe                       : -

  init_subsysteme                                                                                        'bus/vga/keyboard/maus initialisieren
  n:=0
  speed:=30

  repeat
    if mouseshow==1                                                                                    'Mauspfeil anzeigen
         x+=mouse.delta_x
         if x=<xbound '<1
            x:=xbound '1
         if x=>xxbound'639
            x:=xxbound'639
         y+= -mouse.delta_y
         if y=<ybound'1
            y:=ybound'1
         if y=>yybound'479
            y:=yybound'479
         XPos :=x
         YPos :=y
      '++++++++++++++++++++++++ Sprite-Bewegung ++++++++++++++++++++++++++++++++++++++++++++++++++
    if Sprite_Move==1
         repeat i from 0 to 7
            if(spritenr[i]<176) and collision==0                                                         'sprite definiert? und noch keine Kollision passiert
               if (sprite_x[i]==action_x) and (sprite_y[i]==action_y)                                    'sprite an Player-Position?
                   collision:=1
                   quit
         n++                                                                                             'Bewegungsgeschwindigkeit
         if n==speed
            Set_Sprite_XY
         if n>speed+1
            n:=0
      '+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++




    zeichen := bus_getchar                                                                               '1. zeichen empfangen
    if zeichen
          bs:=zeichen                                                                                       ' > 0
          if zeichen==8                                                                                  'Backspace
             bs:=32
          vga.printCharacter(zeichen,@tileset[bs*16])


    else
      zeichen := bus_getchar                                                                             '2. zeichen kommando empfangen
      case zeichen
        gc#BEL_KEY_STAT         : bus_putchar(keyb.gotkey)                                                                      '1: Tastaturstatus senden
        gc#BEL_KEY_CODE         : key_code                                                                                      '2: Tastaturzeichen senden
        gc#BEL_DPL_SETY         : vga.sety(bus_getchar)
        gc#BEL_KEY_SPEC         : bus_putchar(keycode >> 8)                                                                     '4: Statustasten ($100..$1FF) abfragen
        gc#BEL_DPL_MOUSE        : displaymouse                                                                                  '5: Mousezeiger anzeigen
        gc#BEL_SCR_CHAR         : vga.printqChar(@tileset[bus_getchar*16])                                                                   '6: zeichen ohne steuerzeichen ausgeben
        gc#BEL_KEY_INKEY        : bus_putchar(keyb.taster)
                                   keyb.clearkeys
        gc#BEL_DPL_SETX         : vga.setx(bus_getchar)                                                                         '8: x-position setzen
        gc#BEL_LD_MOUSEBOUND    : mousebound                                                                                    '9: mousebereich eingrenzen
        gc#BEL_MOUSEX           : bus_putchar(XPOS>>4)                                                                          '10:abfrage absulute x-position
        gc#BEL_MOUSEY           : bus_putchar(YPos>>4)                                                                          '11:abfrage absulute y-position
        gc#BEL_MOUSEZ           : sub_putlong(mouse.abs_z)                                                                      '12:abfrage absulute z-position (Scrollrad)
        gc#BEL_CLEARKEY         : keyb.clearkeys                                                                                'tastaturpuffer loeschen
        gc#BEL_MOUSE_BUTTON     : mouse_button(bus_getchar)                                                                     '14:abfrage Mouse Button
        gc#BEL_BOXSIZE          : BoxSize                                                                                       '15:BoxSize
        gc#BEL_GETLINELEN       : bus_putchar(linelen)                                                                          '16 Zeilenlänge in diesem Treiber
        gc#BEL_CURSORRATE       : vga.printCursorRate(bus_getchar)
        gc#BEL_BOXCOLOR         : PrintBoxColor
        gc#BEL_ERS_3DBUTTON     : destroy_Button
        gc#BEL_SCROLLUP         : scrollup
        gc#BEL_SCROLLDOWN       : scrolldown
       'gc#BEL_DPL_3DBOX        : display3DBox
       'gc#BEL_DPL_3DFRAME      : display3DFrame
        gc#BEL_DPL_2DBOX        : display2DBox
        gc#BEL_Send_BUTTON      : Get_Button_Param
        gc#BEL_SCROLLSTRING     : scrollString
'       gc#BEL_DPL_STRING       : displayString                                                                                 'String mit Propellerfont darstellen
        gc#BEL_THIRDCOLOR       : vga.dritte_Farbe(bus_getchar)                                                                 '3.Tilefarbe
        gc#BEL_LD_MOUSEPOINTER  : mousepointer
        gc#BEL_MOUSE_PRESENT    : bus_putchar(mouse.present)                                                                    'Test auf Maus
        gc#BEL_DPL_SETPOS       : vga.printat(bus_getchar,bus_getchar)
        gc#BEL_DPL_TILE         : displayTile
        gc#BEL_DPL_WIN          : vga.printwindow(bus_getchar)
        gc#BEL_LD_TILESET       : loadtile                                                                                      'Tiledatei in Puffer laden
        gc#BEL_DPL_PIC          : displaypic                                                                                    'komplette Tile-Datei anzeigen
        gc#BEL_GETX             : bus_putchar(vga.getx)                                                                         'Cursor-X-Position abfragen
        gc#BEL_GETY             : bus_putchar(vga.gety)                                                                         'Cursor-Y-Position abfragen
        gc#BEL_DPL_LINE         : line(sub_getword,sub_getword,sub_getword,sub_getword,bus_getchar,bus_getchar)                             'x,y,xx,yy,farbe
        gc#BEL_DPL_PIXEL        : plot
        gc#BEL_SPRITE_PARAM     : Sprite_Parameter                                                                              'Sprite-Parameter
        gc#BEL_SPRITE_POS       : Set_Sprite_XY                                                                                 'Sprite bewegen
        gc#BEL_ACTOR            : Actor_Parameter                                                                               'Player-Parameter
        gc#BEL_ACTORPOS         : actorxy(bus_getchar)                                                                          'Player bewegen
        gc#BEL_ACT_KEY          : Set_Action_Key                                                                                'spielertasten
        gc#BEL_SPRITE_RESET     : Reset_Sprite                                                                                  'Sprite anhalten/loeschen
        gc#BEL_SPRITE_MOVE      : SpriteMove                                                                                    'spritebewegung aktivieren/deaktivieren
        gc#BEL_SPRITE_SPEED     : speed:=bus_getchar                                                                            'spritegeschwindigkeit
        gc#BEL_GET_COLLISION    : bus_putchar(collision)                                                                        'Kollisionsflag abfragen
                                   collision:=0
        gc#BEL_GET_ACTOR_POS    : Get_Actor_Pos                                                                                 'Playerposition
        gc#BEL_SEND_BLOCK       : Get_Block                                                                                     'Tile lesen
        gc#BEL_DPL_PALETTE      : Displaypalette                                                                                'Farbpalette anzeigen
        gc#BEL_DEL_WINDOW       : Del_Window                                                                                    'Fensterparameter löschen
        gc#BEL_SET_TITELSTATUS  : Set_Titel_Status                                                                              'Titeltext oder Statustext in einem Fenster setzen
        gc#BEL_BACK             : Backup_Restore_area(1)                                                                        'Bildschirmbereich sichern
        gc#BEL_REST             : Backup_Restore_area(0)                                                                        'Bildschirmbereich wiederherstellen
        gc#BEL_WINDOW           : Window                                                                                        'Fensterstil erstellen
        gc#BEL_GET_WINDOW       : get_window                                                                                    'Tastendruck im Fenster abfragen
        gc#BEL_CHANGE_BACKUP    : Change_Backuptile                                                                             'Backuptile unter dem Player ändern (Itemsammeln)
        gc#BEL_VGAPUT           : vga.put(@tileset[bus_getchar*16],bus_getchar,bus_getchar)
        gc#BEL_RECT             : rect(sub_getword,sub_getword,sub_getword,sub_getword,bus_getchar,bus_getchar)
        gc#BEL_BIGFONT          : vga.bigfont(bus_getchar)                                                                      'Umschaltung Fontsatz


        gc#BMGR_GETSPEC     : mgr_getspec
        gc#BMGR_LOAD        : mgr_load                                                                   'neuen bellatrix-code laden
        'gc#BMGR_FLASHLOAD   : flash_loader
        gc#BMGR_GETCOGS     : mgr_getcogs                                                                'freie cogs abfragen
        gc#BMGR_GETVER      : sub_putlong(Bel_Treiber_Ver)                                               'Rückgabe Grafiktreiber 64
        gc#BMGR_REBOOT      : reboot                                                                     'bellatrix neu starten

PUB init_subsysteme|i',x,y,tn,tmp                                   'chip: initialisierung des bellatrix-chips
''funktionsgruppe               : chip
''funktion                      : - initialisierung des businterface
''                              : - vga & keyboard-treiber starten
''eingabe                       : -
''ausgabe                       : -
  repeat i from 0 to 7                                                                                   'evtl. noch laufende cogs stoppen
      ifnot i == cogid
            cogstop(i)


  dira := db_in                                                                                          'datenbus auf eingabe schalten
  outa[bus_hs] := 1                                                                                      'handshake inaktiv

  keyb.start(keyb_dport, keyb_cport)                                                                     'tastaturport starten

  ifnot vga.TMPEngineStart(_pinGroup, @XPos, @YPos)
    reboot
  waitcnt((clkfreq * _startUpWait) + cnt)
  mouse.start(BEL_MOUSED, BEL_MOUSEC)

  mouseshow:=0                                                                                           'Mousezeiger aus
  xbound:=1                                                                                              'Mouse-Bereich Grundeinstellung
  xxbound:=639
  ybound:=1
  yybound:=479
  repeat i from 0 to 7
         spritenr[i]:=255                                                                                'sprites abschalten


  action_key[0]:=2                                                                                       'action-tasten vorbelegen
  action_key[1]:=3
  action_key[2]:=4
  action_key[3]:=5
  action_key[4]:=32
  sp_alter:=0
  collision:=0
  vga.bigfont(0)
  vga.printBoxColor(0,orange,black)
  vga.printCursorColor(orange)
  vga.printBoxSize(0,0, 0, 29, 39)
  vga.printCharacter(12,0)                                                                                 'cls
  vga.printCursorRate(3)
  vga.printwindow(0)

  '##### Fensterparameter #####
  wind[0]:=0
  wind[1]:=1
  wind[2]:=0
  wind[3]:=0
  wind[4]:=39
  wind[5]:=29
  wind[6]:=0
  wind[7]:=255
  wind[8]:=0

  'bus_putchar(88)                                                                                        'Treiber-bereit-Rückmeldung

PUB bus_putchar(zeichen)                                'chip: ein byte an regnatix senden
''funktionsgruppe               : chip
''funktion                      : ein byte an regnatix senden
''eingabe                       : byte
''ausgabe                       : -

  waitpeq(M1,M2,0)                                      'busclk=1? & prop2=0?
  dira := db_out                                        'datenbus auf ausgabe stellen
  outa[7..0] := zeichen                                 'daten ausgeben
  outa[bus_hs] := 0                                     'daten gültig
  waitpeq(M3,M4,0)                                      'busclk=0?
  dira := db_in                                         'bus freigeben
  outa[bus_hs] := 1                                     'daten ungültig

PUB bus_getchar : zeichen                               'chip: ein byte von regnatix empfangen
''funktionsgruppe               : chip
''funktion                      : ein byte von regnatix empfangen
''eingabe                       : -
''ausgabe                       : byte
   'outa[hbeat]~~
   waitpeq(M1,M2,0)                                     'busclk=1? & prop2=0?
   zeichen := ina[7..0]                                 'daten einlesen
   outa[bus_hs] := 0                                    'daten quittieren
   waitpeq(M3,M4,0)                                     'busclk=0?
   outa[bus_hs] := 1
   'outa[hbeat]~

CON ''------------------------------------------------- SUBPROTOKOLL-FUNKTIONEN

PUB sub_putlong(wert)                                   'sub: long senden       
''funktionsgruppe               : sub
''funktion                      : subprotokoll um einen long-wert an regnatix zu senden
''eingabe                       : 32bit wert der gesendet werden soll
''ausgabe                       : -
''busprotokoll                  : [put.byte1][put.byte2][put.byte3][put.byte4]
''                              : [  hsb    ][         ][         ][   lsb   ]

   bus_putchar(wert >> 24)                              '32bit wert senden hsb/lsb
   bus_putchar(wert >> 16)
   bus_putchar(wert >> 8)
   bus_putchar(wert)

PUB sub_getlong:wert                                    'sub: long empfangen    
''funktionsgruppe               : sub
''funktion                      : subprotokoll um einen long-wert von regnatix zu empfangen
''eingabe                       : -
''ausgabe                       : 32bit-wert der empfangen wurde
''busprotokoll                  : [get.byte1][get.byte2][get.byte3][get.byte4]
''                              : [  hsb    ][         ][         ][   lsb   ]

  wert :=        bus_getchar << 24                      '32 bit empfangen hsb/lsb
  wert := wert + bus_getchar << 16
  wert := wert + bus_getchar << 8
  wert := wert + bus_getchar
PUB sub_putword(wert)                                   'sub: long senden
''funktionsgruppe               : sub
''funktion                      : subprotokoll um einen long-wert an regnatix zu senden
''eingabe                       : 32bit wert der gesendet werden soll
''ausgabe                       : -
''busprotokoll                  : [put.byte1][put.byte2][put.byte3][put.byte4]
''                              : [  hsb    ][         ][         ][   lsb   ]

   bus_putchar(wert >> 8)
   bus_putchar(wert)

PUB sub_getword:wert                                    'sub: long empfangen
''funktionsgruppe               : sub
''funktion                      : subprotokoll um einen long-wert von regnatix zu empfangen
''eingabe                       : -
''ausgabe                       : 32bit-wert der empfangen wurde
''busprotokoll                  : [get.byte1][get.byte2][get.byte3][get.byte4]
''                              : [  hsb    ][         ][         ][   lsb   ]

  wert := bus_getchar << 8
  wert := wert + bus_getchar

CON ''------------------------------------------------- CHIP-MANAGMENT-FUNKTIONEN

PUB mgr_getcogs: cogs |i,c,cog[8]                                                                        'cmgr: abfragen wie viele cogs in benutzung sind
''funktionsgruppe               : cmgr
''funktion                      : abfrage wie viele cogs in benutzung sind
''eingabe                       : -
''ausgabe                       : cogs - anzahl der cogs
''busprotokoll                  : [0][096][put.cogs]
''                              : cogs - anzahl der belegten cogs

  cogs := i := 0
  repeat                                                                                                 'loads as many cogs as possible and stores their cog numbers
    c := cog[i] := cognew(@entry, 0)
    if c=>0
      i++
  while c => 0
  cogs := i
  repeat                                                                                                 'unloads the cogs and updates the string
    i--
    if i=>0
      cogstop(cog[i])
  while i=>0
  bus_putchar(cogs)

pub mgr_getspec

  sub_putlong(CHIP_SPEC)

PUB mgr_load|i                                          'cmgr: bellatrix-loader
''funktionsgruppe               : cmgr
''funktion                      : funktion um einen neuen code in bellatrix zu laden
''
''bekanntes problem: einige wenige bel-dateien werden geladen aber nicht korrekt gestartet
''lösung: diese datei als eeprom-image speichern

' kopf der bin-datei einlesen                           ------------------------------------------------------
  repeat i from 0 to 15                                                                                  '16 bytes --> proghdr
    byte[@proghdr][i] := bus_getchar

  plen := 0
  plen :=        byte[@proghdr + $0B] << 8
  plen := plen + byte[@proghdr + $0A]
  plen := plen - 8

' objektlänge an regnatix senden
  bus_putchar(plen >> 8)                                                                                 'hsb senden
  bus_putchar(plen & $FF)                                                                                'lsb senden

  repeat i from 0 to 7                                                                                   'alle anderen cogs anhalten
    ifnot i == cogid
      cogstop(i)

  dira := 0                                                                                              'diese cog vom bus trennen
  cognew(@loader, plen)

  cogstop(cogid)                                                                                         'cog 0 anhalten

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

PUB key_code                                                                                             'key: tastencode abfragen

  keycode := keyb.key
  case keycode
    $c8: keycode := $08                                                                                  'backspace wandeln
  bus_putchar(keycode)

CON ''------------------------------------------------- SCREEN-FUNKTIONEN
pub plot|x,y,f
    x:=sub_getword
    y:=sub_getword
    f:=bus_getchar
    vga.plot(f,y,x)

PUB rect(x0, y0, x1, y1,n,dummy)

    line(x0, y0, x1, y0,n,0)
    line(x0, y0, x0, y1,n,0)
    line(x0, y1, x1, y1,n,0)
    line(x1, y0, x1, y1,n,0)

pub Window|win,f1,f2,f3,f4,f5,f6,f7,f8,x,y,xx,yy,modus,a,b,c,d,posi,shd

        win:=bus_getchar                                                                                 'fensternummer
        f1:=bus_getchar                                                                                  'farbe1            'vordergrund
        f2:=bus_getchar                                                                                  'farbe2            'hintergrund
        f3:=bus_getchar                                                                                  'farbe3            'Cursor
        f4:=bus_getchar                                                                                  'farbe4            'frame
        f5:=bus_getchar                                                                                  'farbe5            'titelhintergrund
        f6:=bus_getchar                                                                                  'farbe6            'titeltext
        f7:=bus_getchar                                                                                  'farbe7            'statusback
        f8:=bus_getchar                                                                                  'farbe8            'statustext
        y:=bus_getchar                                                                                   'y
        x:=bus_getchar                                                                                   'x
        yy:=bus_getchar                                                                                  'yy
        xx:=bus_getchar                                                                                  'xx
        modus:=bus_getchar                                                                               'art des Fensters (mit oder ohne Titel,rahmen,Pfeiltasten,Statusleiste)
        shd  :=bus_getchar                                                                               'Schatten
        a:=b:=c:=d:=0
        if shd
           vga.display2DBox($56, y+1, x+1, yy+1, xx+1)                                                   'Fensterschatten
        if modus==2 or modus>3
           rahmen(y,x,yy,xx,modus,f1,f2,f4)
                   a:=b:=c:=d:=1
        if modus==3 or modus==4 or modus>5
           titel(y,x,xx,f1,f2,f5,f4)
           a:=1
        if modus==5 or modus==6 or modus==8
           pfeile(y,yy,xx,f1,f2,f4,modus)
        if modus>6
           status(yy,x,xx,f1,f2,f7)


        vga.printBoxColor(win,f1,f2)                                                                     'fenster vorder und hintergrundfarbe setzen
        vga.printCursorColor(f1)
        vga.printBoxSize(win,y+a, x+b, yy-c, xx-d)                                                       'virtuelles Fenster erstellen
        posi:=win*14
        wind[posi++]:=win
        wind[posi++]:=modus
        wind[posi++]:=x
        wind[posi++]:=y
        wind[posi++]:=xx
        wind[posi++]:=yy
        wind[posi++]:=f1
        wind[posi++]:=f2
        wind[posi++]:=f3
        wind[posi++]:=f4
        wind[posi++]:=f5
        wind[posi++]:=f6
        wind[posi++]:=f7
        wind[posi++]:=f8

pri Set_Titel_Status|win,Tit_Stat,len,posi,x,y                                                           'Titel-oder Statustext in einem Fenster setzen

    win     :=bus_getchar                                                                                'fensternummer
    Tit_Stat:=bus_getchar                                                                                'Titel oder Statustext
    len     :=bus_getchar                                                                                'stringlänge

    posi:=win*14
    x:=wind[posi+2]

    if (wind[posi+1]==3 or  wind[posi+1]==4 or  wind[posi+1]>5) and Tit_Stat==1 and wind[posi]
       y:=wind[posi+3]              'Titeltext
       bus_getstr_plot(posi,len, y, x+1,1,0)
    elseif wind[posi+1]>6 and Tit_Stat==2 and wind[posi]
       y:=wind[posi+5]           'Statustext
       bus_getstr_plot(posi,len,y, x+1,1,2)
    else
       bus_getstr_plot(posi,len,y, x+1,0,0)                                                              'keine Bildschirmausgabe

pri bus_getstr_plot(win,len,y,x,m,b)|c

       repeat len
              c:=bus_getchar
              if x<wind[win+4] and m==1
                 vga.displaytile(@tileset[c*16],wind[win+10+b],wind[win+11+b],wind[win+7], y, x++)
              else
                 next


pri get_window|x,y,a,b,i,sd
    sd:=0
    if mouseshow and mouse.button(0)                                                                     'Mauspfeil anzeigen
       x:=xpos>>4
       y:=ypos>>4

       repeat i from 1 to 7
          b:=i*14
          if wind[b]
            a:=wind[b+1]                                                                                 'Art des Fensters

            case a
                 'Titelleiste linke und rechte obere ecke
                 3,4,6,7,8:if x==wind[b+2] and y==wind[b+3]                                              'linke obere ecke
                              sd:=1
                           if x==wind[b+4] and y==wind[b+3]                                              'rechte obere ecke
                              sd:=2
                           if a==6 or a==8
                              if x==wind[b+4] and y==wind[b+3]+1                                         'oberer pfeil
                                 sd:=3
                           if a==6
                              if x==wind[b+4] and y==wind[b+5]                                           'unterer pfeil
                                 sd:=4
                           if a==8
                              if x==wind[b+4] and y==wind[b+5]-1                                         'unterer pfeil
                                 sd:=4

                           if sd
                              klick_action(x,y,sd,i)
                              sd+=i*10                                                                   'Fensternummer*10+Button
                              quit

                 5:        if x==wind[b+4] and y==wind[b+3]                                              'oberer pfeil
                              sd:=3
                           if x==wind[b+4] and y==wind[b+5]                                              'unterer pfeil
                              sd:=4
                           if sd
                              klick_action(x,y,sd,i)
                              sd+=i*10                                                                   'Fensternummer*10+Button
                              quit



    bus_putchar(sd)

pri klick_action(x,y,sd,w)|tinr,f1,f2,f3,ff,a
    a:=w*14
    f1:=wind[a+6]
    f2:=wind[a+7]
    ff:=wind[a+9]'f4
    f3:=wind[a+10]'f5
    case sd
          1:tinr:=wint[8]'128
          2:tinr:=wint[10]'129
          3:tinr:=wint[11]'133
          4:tinr:=wint[13]'131
    vga.displaytile(@tileset[tinr*16],ff,f2,f1, y, x)                                                    'rechte obere ecke
    repeat while mouse.button(0)                                                                         'warten, bis Maustaste losgelassen wird
    if sd==1 or sd==2                                                                                    'Titelleistensymbole
       vga.displaytile(@tileset[tinr*16],f2,f1,ff, y, x)                                                 'rechte obere ecke
    else                                                                                                 'Pfeilsymbole
       vga.displaytile(@tileset[tinr*16],f2,f1,ff, y, x)                                                 'normal darstellen

pri Del_Window|wnr,i,a
    i:=0
    wnr:=bus_getchar
    repeat 17                                                                                            'neue Tilewerte für die Fenster lesen
        wint[i++]:=bus_getchar

    if wnr==9
       repeat i from 1 to 7
              wind[i*10]:=0
    else
       a:=wnr*14
       vga.del_win(wnr)
       wind[a]:=0


pri titel(y,x,xx,f1,f2,f3,ff)
    vga.displaytile(@tileset[wint[8]*16],f2,f1,ff, y, x)                                                 'linke obere ecke

    W_line(wint[9],x+1, y, xx-1,f2,f1,f3)
    vga.displaytile(@tileset[wint[10]*16],f2,f1,ff, y, xx)                                               'rechte obere ecke

pri status(y,x,xx,f1,f2,f3)
    vga.displaytile(@tileset[wint[15]*16],f2,f1,f3, y, x)                                                'linke untere ecke

    W_line(wint[14],x+1, y, xx-1,f2,f1,f3)
    vga.displaytile(@tileset[wint[16]*16],f2,f1,f3, y, xx)                                               'rechte untere ecke

pri W_line(tinr,x,y,xx,f1,f2,f3)|i
    repeat i from x to xx
          vga.displaytile(@tileset[tinr*16],f1,f2,f3, y, i)

pri rahmen(y,x,yy,xx,modus,f1,f2,f3)|i
    if modus==2 or modus==5
       vga.displaytile(@tileset[wint[0]*16],f2,f1,f3, y, x)                                              'links oben
       repeat i from x+1 to xx-1
            vga.displaytile(@tileset[wint[1]*16],f2,f1,f3, y, i)                                         'oberer rand

       vga.displaytile(@tileset[wint[2]*16],f2,f1,f3, y, xx)                                             'rechts oben

    repeat i from y+1 to yy-1
       vga.displaytile(@tileset[wint[7]*16],f2,f1,f3, i, x)                                              'linker rand
       if modus==2 or modus==4 or modus==7
          vga.displaytile(@tileset[wint[3]*16],f2,f1,f3, i, xx)                                          'rechter rand ohne pfeile
       if modus==5 or modus==6 or modus==8
          vga.displaytile(@tileset[wint[12]*16],f2,f1,f3, i, xx)                                         'rechter rand mit pfeilen

    repeat i from x+1 to xx-1
        vga.displaytile(@tileset[wint[5]*16],f2,f1,f3, yy, i)                                            'unterer rand
    vga.displaytile(@tileset[wint[6]*16],f2,f1,f3, yy, x)                                                'linke untere ecke
    vga.displaytile(@tileset[wint[4]*16],f2,f1,f3, yy, xx)                                               'rechte untere ecke

pri pfeile(y,yy,xx,f1,f2,f3,modus)
    if modus==6 or modus==8
       y+=1
    if modus==8
       yy-=1
    vga.displaytile(@tileset[wint[11]*16],f2,f1,f3, y, xx)
    vga.displaytile(@tileset[wint[13]*16],f2,f1,f3, yy, xx)                                              'unterer pfeil


pub Backup_Restore_Area(n)|x,y,xx,yy,a,b
    x:=bus_getchar
    y:=bus_getchar
    xx:=bus_getchar
    yy:=bus_getchar
    repeat b from y to yy
           repeat a from x to xx
                  if n
                     sub_putlong(vga.backup_chroma(a,b))
                     sub_putword(vga.backup_luma(a,b))
                  else
                     vga.restore_chroma(a,b,sub_getlong)
                     vga.restore_luma(a,b,sub_getword)

pub mousebound
    xbound :=sub_getlong
    ybound:=sub_getlong
    xxbound :=sub_getlong
    yybound:=sub_getlong

pub mouse_button(b)|i,knopf,xp,yp,c
    knopf:=0
    xp:=XPOS>>4
    yp:=YPOS>>4
    c:=mouse.button(b)
    if mouse.button(0)                                                                                   'linke mousetaste gedrueckt?
       repeat i from 1 to buttonbuff-1                                                                   'alle Buttonparameter durchsuchen
          if bnumber[i]
             if xp=>bx[i] and xp=< bxx[i] and yp==by[i]                                                  'abfrage auf Buttonposition
                c:=i                                                                                     'gefunden !
                quit
    bus_putchar(c)                                                                                       'ansonsten 255 senden

pub BoxSize|i,win,y,x,yy,xx
        win:=bus_getchar
        y:=bus_getchar
        x:=bus_getchar
        yy:=bus_getchar
        xx:=bus_getchar
        vga.printBoxSize(win,y,x,yy,xx)

pub PrintBoxColor|w,v,h
    w:=bus_getchar
    v:=bus_getchar
    h:=hintergr:=bus_getchar
    vga.printBoxColor(w,v,h)                                                                             'fenster vorder und hintergrundfarbe setzen
    vga.printCursorColor(v)                                                                            'Cursorfarbe setzen

pub setpos(y,x)
    y:=bus_getchar
    x:=bus_getchar
    vga.printat(y,x)

PUB scrollup | lines,farbe,y,x,yy,xx,rate
        lines:=bus_getchar
        farbe:=bus_getchar
        y    :=bus_getchar
        x    :=bus_getchar
        yy   :=bus_getchar
        xx   :=bus_getchar
        rate :=bus_getchar
        vga.scrollup(lines,farbe,y,x,yy,xx,rate)                                                         'screen: scrollt den screen nach oben

PUB scrolldown | lines,farbe,y,x,yy,xx,rate
        lines:=bus_getchar                                                                               'screen: scrollt den screen nach unten
        farbe:=bus_getchar
        y    :=bus_getchar
        x    :=bus_getchar
        yy   :=bus_getchar
        xx   :=bus_getchar
        rate :=bus_getchar
        vga.scrolldown(lines,farbe,y,x,yy,xx,rate)

pub display3DBox|top,center,bott,y,x,yy,xx
        top:=bus_getchar
        center:=bus_getchar
        bott:=bus_getchar
        y    :=bus_getchar
        x    :=bus_getchar
        yy   :=bus_getchar
        xx   :=bus_getchar

        vga.display3DBox(top, center, bott, y,x,yy,xx)

pub display3DFrame|top,center,bott,y,x,yy,xx
        top:=bus_getchar
        center:=bus_getchar
        bott:=bus_getchar
        y    :=bus_getchar
        x    :=bus_getchar
        yy   :=bus_getchar
        xx   :=bus_getchar

        vga.display3DFrame(top, center, bott, y,x,yy,xx)

pub Get_Button_Param|number,y,x,xx
        number:=bus_getchar
        x    :=bus_getchar
        y    :=bus_getchar
        xx   :=bus_getchar

        bx[number]    :=x
        by[number]    :=y
        bxx[number]   :=xx
        bnumber[number]:=number

pub destroy_Button|number
    number:=bus_getchar
    vga.display2DBox(hintergr,by[number],bx[number],by[number],bxx[number])
    bnumber[number]:=0

pub display2DBox|farbe,y,x,yy,xx,shd
        farbe:=bus_getchar
        y    :=bus_getchar
        x    :=bus_getchar
        yy   :=bus_getchar
        xx   :=bus_getchar
        shd  :=bus_getchar
        if shd
           vga.display2DBox($56,y+1,x+1,yy+1,xx+1)
        vga.display2DBox(farbe,y,x,yy,xx)

pub scrollString|rate,vorder,hinter,y,x,xx,i,len',dir
    rate  :=bus_getchar
    vorder:=bus_getchar
    hinter:=bus_getchar
    y     :=bus_getchar
    x     :=bus_getchar
    xx    :=bus_getchar
    len   :=bus_getchar
    i:=0
    repeat len
         byte[@strkette][i++]:=bus_getchar
    vga.scrollstring(@strkette,rate, vorder, hinter, y, x, xx)
    bytefill(@strkette,0,40)                                                                             'stringbuffer wieder loeschen

pub displayTile|pcol,scol,tcol,y,x                                                                       'einzelnes Tile anzeigen
     tnr:=bus_getchar
    pcol:=bus_getchar
    scol:=bus_getchar
    tcol:=bus_getchar
       y:=bus_getchar
       x:=bus_getchar

    vga.displaytile(@tileset[tnr*16],pcol,scol,tcol, y, x)

pub loadtile|anzahl,i                                                                                    'Tileset in buffer laden

    anzahl:=sub_getlong
    repeat i from 0 to anzahl-1
         tileset[i]:=sub_getlong

pub mousepointer|i
    repeat i from 0 to 15
         mousetile[i]:=sub_getlong
    vga.mouseCursorTile(@mousetile)

pub displaypic|pcol,scol,tcol,y,x,ytile,xtile,xx,c                                                       'komplettes Tileset anzeigen
            pcol:=bus_getchar
            scol:=bus_getchar
            tcol:=bus_getchar
               y:=bus_getchar
               x:=bus_getchar
           ytile:=bus_getchar
           xtile:=bus_getchar
           xx:=x
           c:=0
     repeat ytile '9
        repeat xtile '11

          vga.displayTile(@tileset[c], pcol, scol, tcol, y, xx++)
          c+=16
        y++
        xx:=x
pub displaymouse |on,farbe,i
    on:=bus_getchar
    farbe:=bus_getchar
    if on
        vga.mouseCursorColor(farbe)
        vga.mouseCursorTile(vga.displayCursor)
        mouseshow :=1
        repeat i from 0 to buttonbuff-1                                                                  'buttonanzahl zuruecksetzen
             bnumber[i]:=0
    else
        vga.mouseCursorTile(0)
        mouseshow :=0

PUB line(x0, y0, x1, y1, frbe,dummy) | dX, dY, x, y, err, stp
  result := ((||(y1 - y0)) > (||(x1 - x0)))
  if(result)
    swap(@x0, @y0)
    swap(@x1, @y1)
  if(x0 > x1)
    swap(@x0, @x1)
    swap(@y0, @y1)
  dX := (x1 - x0)
  dY := (||(y1 - y0))
  err := (dX >> 1)
  stp := ((y0 => y1) | 1)
  y := y0
  repeat x from x0 to x1
    if(result)
      vga.Plot(frbe,x,y)
    else
      vga.Plot(frbe,y,x)
    err -= dY
    if(err < 0)
       y += stp
       err += dX

PRI swap(x, y)
  result  := long[x]
  long[x] := long[y]
  long[y] := result

con '************************************************ Spriteparameter **********************************************************
pub Actor_Parameter|i

  repeat 4
      actor[i++]:=bus_getchar                                                                                  'tilenr1
  action_x:=bus_getchar
  action_y:=bus_getchar

  vga.dispBackup(action_y, action_x,9)
  vga.displaytile(@tileset[actor[0]*16],actor[1],actor[2],actor[3], action_y, action_x)
  old_action_x:=action_x
  old_action_y:=action_y

pub Change_Backuptile|tinr,f1,f2,f3                                                                      'Backuptile unter dem Player ändern (für eingesammelte Items)

    tinr:=bus_getchar
    f1:=bus_getchar
    f2:=bus_getchar
    f3:=bus_getchar

    vga.Change_Backup(@tileset[tinr*16],f1,f2,f3)

pub Get_Actor_Pos|a
    a:=bus_getchar
    case a
        1:bus_putchar(action_x)
        2:bus_putchar(action_y)

pub actorxy(k)|b

     case k
        action_key[0]:action_x--
                      b:=1
        action_key[1]:action_x++
                      b:=1
        action_key[2]:action_y--
                      b:=1
        action_key[3]:action_y++
                      b:=1

  if action_x<1
     action_x:=0
  if action_x>39
     action_x:=39
  if action_y<1
     action_y:=0
  if action_y>29
     action_y:=29

  if b==1
     playermove

pri playermove
     vga.dispRestore(old_action_y, old_action_x,9)
     vga.dispBackup(action_y, action_x,9)', farbe)
     vga.displaytile(@tileset[actor[0]*16],actor[1],actor[2],actor[3], action_y, action_x)
     old_action_x:=action_x
     old_action_y:=action_y

pub Sprite_Parameter|nur
    nur:=bus_getchar
    nur-=1
    spritenr[nur]:=bus_getchar
    spritenr[nur+8]:=bus_getchar
    spritef1[nur]:=bus_getchar
    spritef2[nur]:=bus_getchar
    spritef3[nur]:=bus_getchar
    sprite_dir[nur]:=bus_getchar                                                                         'richtung
    sprite_start[nur]:=bus_getchar                                                                       'startposition
    sprite_end[nur]:=bus_getchar                                                                         'endposition
    sprite_x[nur]:=bus_getchar                                                                           'x
    sprite_y[nur]:=bus_getchar                                                                           'y

    vga.dispBackup(sprite_y[nur], sprite_x[nur],nur)
    vga.displaytile(@tileset[spritenr[nur]*16],spritef1[nur],spritef2[nur],spritef3[nur], sprite_y[nur], sprite_x[nur])
    sprite_old_y[nur]:=sprite_y[nur]
    sprite_old_x[nur]:=sprite_x[nur]

pub SpriteMove|nur
    nur:=bus_getchar
    case nur
        0:Sprite_move:=0
        1:Sprite_move:=1
        2:Reset_Sprite
pub get_block|a,b
    a:=bus_getchar
    b:=bus_getchar
    block_tile[a]:=b

pub Set_sprite_XY|num,vx,vy,p,b
  if sp_alter==0                                                                                         'zweites Sprite-Tile
     sp_alter:=8
  else
     sp_alter:=0                                                                                         'erstes Sprite-Tile

  repeat num from 0 to 7

       if spritenr[num]<175                                                                              'sprite belegt?
          case sprite_dir[num]
               1:sprite_x[num]--
                 if sprite_x[num]<sprite_start[num]                                                      'startpos erreicht? dann richtung umkehren
                    sprite_dir[num]:=2
               2:sprite_x[num]++
                 if sprite_x[num]>sprite_end[num]                                                        'endpos erreicht dann richtung umkehren
                    sprite_dir[num]:=1
               3:sprite_y[num]--
                 if sprite_y[num]<sprite_start[num]                                                      'startpos erreicht? dann richtung umkehren
                    sprite_dir[num]:=4
               4:sprite_y[num]++
                 if sprite_y[num]>sprite_end[num]                                                        'endpos erreicht dann richtung umkehren
                    sprite_dir[num]:=3
               5:'einfacher verfolgermodus
                  vx:=(action_x-sprite_x[num])                                                           'Abstand zur Spielerfigur x-Richtung
                  vy:=(action_y-sprite_y[num])                                                           'Abstand zur Spielerfigur y-Richtung

                  if vy<0
                        p:=((sprite_y[num]-1)*40)+sprite_x[num]
                        b:=position(p)                                                                   'Überprüfung auf Blockade-Tile
                        if b==0
                           sprite_y[num]--
                     if sprite_y[num]<1
                        sprite_y[num]:=1
                  if vy>0
                        p:=((sprite_y[num]+1)*40)+sprite_x[num]
                        b:=position(p)
                        if b==0
                           sprite_y[num]++
                     if sprite_y[num]>29
                        sprite_y[num]:=29
                  if vx<0
                        p:=(sprite_y[num]*40)+(sprite_x[num]-1)
                        b:=position(p)
                        if b==0
                           sprite_x[num]--
                     if sprite_x[num]<1
                        sprite_x[num]:=1
                  if vx>0
                        p:=(sprite_y[num]*40)+(sprite_x[num]+1)
                        b:=position(p)
                        if b==0
                           sprite_x[num]++
                     if sprite_x[num]>29
                        sprite_x[num]:=29
          vga.dispRestore(sprite_old_y[num], sprite_old_x[num],num)
          vga.dispBackup(sprite_y[num], sprite_x[num],num)
          vga.displaytile(@tileset[spritenr[num+sp_alter]*16],spritef1[num],spritef2[num],spritef3[num], sprite_y[num], sprite_x[num])
          sprite_old_x[num]:=sprite_x[num]
          sprite_old_y[num]:=sprite_y[num]

pub position(tr):bl|i,block
    block:=read_block(tr)
    bl:=0
    repeat i from 0 to 9
          if block==block_tile[i]
             bl:=1

pub read_block(num):wert|i
    wert:=vga.getblock(num)
    repeat i from 0 to 175                                                                               'Tiles im Tileset mit Wert vergleichen
         if wert== @tileset[i*16]
            quit

pub Reset_Sprite|i
    repeat i from 0 to 7
           if spritenr[i]<177
             vga.dispRestore(sprite_old_y[i], sprite_old_x[i],i)                                         'sprite reset
             spritenr[i]:=255
    vga.dispRestore(old_action_y, old_action_x,9)                                                        'Player reset
    Sprite_move:=0                                                                                       'spritebewegung deaktivieren
    collision:=0

pub Set_Action_Key|i
    repeat 5
         action_key[i++]:=bus_getchar

pub Displaypalette|farbe,hy,hx,a
    hx:=bus_getchar
    hy:=bus_getchar
    a:=hx
    farbe:=0
    repeat 4
        repeat 16
             vga.plot(farbe,hy,hx)
             hx++
             farbe+=4
        hx:=a
        hy++

DAT


                        org
'
' Entry: dummy-assemblercode fuer cogtest
'
entry                   jmp     entry                   'just loops


tileset long 0[2816]



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
