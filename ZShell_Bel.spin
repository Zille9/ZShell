{{      VGA-Pixel-Treiber
┌──────────────────────────────────────────────────────────────────────────────────────────────────────┐
│ Autor: Reinhard Zielinski                                                                            │
│ Copyright (c) 2015 Reinhard Zielinski                                                                │
│ See end of file for terms of use.                                                                    │
│ Die Nutzungsbedingungen befinden sich am Ende der Datei                                              │
└──────────────────────────────────────────────────────────────────────────────────────────────────────┘

Informationen   : hive-project.de
Kontakt         : zille9@googlemail.com
System          : Hive
Name            : VGA-Pixel-Treiber 320x256 Pixel, 40x32 Zeichen
Chip            : Bellatrix
Typ             : Treiber
Version         : 01
Subversion      : 00
Funktion        : Pixel- VGA-Text- und Tastatur-Treiber

Dieser Bellatrix-Code kann als Stadardcode im EEPROM gespeichert werden Tilebasierten-Textbildschirm
und Tastaturfunktionen. Mit dem integrierten Loader kann Bellatrix
mit einem beliebigen anderen Code geladen werden.

Komponenten     : VGA-Pixel Engine // Author: Marko Lukat
                  PS/2 Keyboard Driver v1.0.1     Chip Gracey, ogg   MIT

COG's           : MANAGMENT     1 COG
                  VGA           1 COG's
                  KEYB          1 COG
                  -------------------
                                3 COG's

Logbuch         :

29-01-2015      -Pixeltreiber 320x256 Pixel (wie KC85), Grundfunktionalität geschaffen
                -Farbänderungen, Printausgaben, Plot-Funktionen und Scroll-Funktion (Up/Down) geschaffen
                -Window-Funktion muss noch erarbeitet werden (8 Fenster?, mal sehen)
                -Cursor On/Off realisiert
                -3427 Longs frei
30-01-2015      -Cursorfunktion weiter ausgebaut, sodass Backspace und Edit funktionieren
                -das Grundgerüst steht, jetzt kommen die Extras
                -Code zusammengefasst
                -Plot-Funktion erweitert -> Farbattribute werden mitgeplottet
                -3428 Longs frei
31-01-2015      -Funktion PTest testet, ob ein Pixel gesetzt wurde
                -2.Variante von Kuroneko's Treiber hat vertikal die doppelte Farbauflösung (wie KC85/3)
                -verbraucht dafür etwas mehr Speicher (logisch)
                -3303 Longs frei
02-02-2015      -mit Window-Funktion begonnen, seltsamerweise merkt er sich die Farbe des Fensters 0 nicht ?!
                -Fenster-Erstellung funktioniert soweit
                -Fensterscrolling fehlt noch
                -Fensterlöschen ok
                -Cursorpositionen merken und wiederherstellen ok
                -Fensterfarben (außer Fenster 0) ok
                -2234 Longs frei
04-02-2015      -Fensterscrolling+Farbscrolling funktioniert
                -2190 Longs frei
05-02-2015      -Fensterwechsel funktioniert jetzt korrekt
                -Win_Del Funktion hinzugefügt (löscht die Fensterparameter eines gesetzten Fensters)
                -Window-Arten ausgebaut -> bis auf die Scrollleiste, sind die Fensterarten jetzt mit Modus 0 identisch
                -print-funktion durch put-funktion ersetzt
                -2201 Longs frei
19-02-2015      -Funktion Displaypalette hinzugefügt
                -2130 Longs frei
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
CHIP_SPEC       = %00000000_00000000_00000000_00110110


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


buttonbuff=33                                                                                            'Buttonanzahl 1-32 Textbutton oder icon
Bel_Treiber_Ver =320                                                                                     'Treiber 320x256Pixel

CON
  res_x = vga#res_x
  res_y = vga#res_y

  quadP = res_x * res_y / 32
  quadC = res_x * res_y / 128

  flash = FALSE

  mbyte = $7F | flash & $80
  mlong = mbyte * $01010101

  linelen       =39
  #1, CX, CY

OBJ
  keyb          : "bel-keyb"
  vga           : "waitvid.320x256.driver.2048a"
  fl            : "float32-Bas"
  gc            : "glob-con"

VAR

  byte proghdr[16]                                                                                       'puffer für objektkopf
  byte strkette[40]                                                                                      'stringpuffer fuer Scrolltext
  byte cursor,cback[8],putback[8]

  long  keycode                                                                                          'letzter tastencode
  long  plen                                                                                             'länge datenblock loader
  long  cursors

  long  screen[quadP]
  long  colour[quadC]
  long  link[vga#res_m], base
  long  x_pos,y_pos

  byte x_start[9], y_start[9], x_end[9], y_end[9],cur_x[9],cur_y[9],vor[9],hinter[9]
  byte fenster
  word screenfarbe[9]
  byte wind[112]

CON ''------------------------------------------------- BELLATRIX

PUB main | zeichen,n,i,x,y ,speed                             'chip: kommandointerpreter
''funktionsgruppe               : chip
''funktion                      : kommandointerpreter
''eingabe                       : -
''ausgabe                       : -

  init_subsysteme                                                                                        'bus/vga/keyboard/maus initialisieren
  n:=0
  speed:=30

  repeat

    zeichen := bus_getchar                                                                               '1. zeichen empfangen
    if zeichen                                                                                           ' > 0

          chr(zeichen)
    else
      zeichen := bus_getchar                                                                             '2. zeichen kommando empfangen
      case zeichen
       gc#BEL_KEY_STAT          : key_stat                                                               '1: Tastaturstatus senden
       gc#BEL_KEY_CODE          : key_code                                                               '2: Tastaturzeichen senden
       gc#BEL_DPL_SETY          : y_pos:=bus_getchar'cursor_rest
       gc#BEL_KEY_SPEC          : key_spec                                                               '4: Statustasten ($100..$1FF) abfragen
       gc#BEL_SCR_CHAR          : qchar(bus_getchar)                                                     '6: zeichen ohne steuerzeichen ausgeben
       gc#BEL_KEY_INKEY         : bus_putchar(keyb.taster)
                                  keyb.clearkeys
       gc#BEL_DPL_SETX          : x_pos:=bus_getchar                                                     '8: x-position setzen
       gc#BEL_CLEARKEY          : keyb.clearkeys                                                         'tastaturpuffer loeschen
       gc#BEL_GETLINELEN        : bus_putchar(linelen)                                                                          '16 Zeilenlänge in diesem Treiber
       gc#BEL_CURSORRATE        : cursor:=bus_getchar & 1
       gc#BEL_BOXCOLOR          : setcolor(bus_getchar,bus_getchar,bus_getchar)
       gc#BEL_SCROLLUP          : scrollup(bus_getchar,bus_getchar)
       gc#BEL_SCROLLDOWN        : scrolldown(bus_getchar,bus_getchar)
       gc#BEL_DPL_2DBOX         : Box(bus_getchar,bus_getchar,bus_getchar,bus_getchar,bus_getchar,bus_getchar)
       gc#BEL_REDEFINE          : redefine
       gc#BEL_DPL_SETPOS        : locate(bus_getchar,bus_getchar)
       gc#BEL_TESTXY            : i:=ptest(sub_getword,sub_getword)
                                  bus_putchar(i)                                                                               'PTest, testet, ob ein Pixel gesetzt ist
       gc#BEL_WINDOW            : printwindow(bus_getchar)
       gc#BEL_GETX              : bus_putchar(x_pos)                                                                             'Cursor-X-Position abfragen
       gc#BEL_GETY              : bus_putchar(y_pos)                                                                             'Cursor-Y-Position abfragen
       gc#BEL_DPL_LINE          : line(sub_getword,sub_getword,sub_getword,sub_getword,bus_getchar,bus_getchar) 'x,y,xx,yy,farbe
       gc#BEL_DPL_PIXEL         : Plot(sub_getword,sub_getword,bus_getchar)
       gc#BEL_DPL_CIRCLE        : circle(sub_getword,sub_getword,sub_getword,sub_getword,bus_getchar,bus_getchar)                            'Kreis
       gc#BEL_RECT              : rect(sub_getword,sub_getword,sub_getword,sub_getword,bus_getchar,bus_getchar)
       gc#BEL_DPL_PALETTE       : Displaypalette
       gc#BEL_DEL_WINDOW        : Del_Window                                                                                    'Fensterparameter löschen
       gc#BEL_SET_TITELSTATUS   : Set_Titel_Status                                                                               'Titeltext oder Statustext in einem Fenster setzen
       gc#BEL_BACK              : Backup_Restore_area(1)                                                                         'Bildschirmbereich sichern
       gc#BEL_REST              : Backup_Restore_area(0)                                                                         'Bildschirmbereich wiederherstellen
       gc#BEL_WINDOW            : Window                                                                                         'Fensterstil erstellen
       gc#BEL_VGAPUT            : put(bus_getchar,bus_getchar,bus_getchar)                                                       'Char an x,y ausgeben
'       ----------------------------------------------  CHIP-MANAGMENT
       gc#BMGR_LOAD             : mgr_load                                                                                      'neuen bellatrix-code laden
       'gc#BMGR_FLASHLOAD        : flash_loader
       gc#BMGR_GETSPEC          : mgr_getspec
       gc#BMGR_GETCOGS          : mgr_getcogs                                                                                   'freie cogs abfragen
       gc#BMGR_GETVER           : mgr_bel                                                                                       'Rückgabe Grafiktreiber 64
       gc#BMGR_REBOOT           : reboot                                                                                        'bellatrix neu starten


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


  link{0} := @screen{0}
  link[1] := @cursors << 16 | @colour{0}
  vga.init(-1, @link)                             ' start driver

  waitcnt(clkfreq+cnt)
  plot_window(0,7,1,0,0,0,0,0,0,0,0,39,31,1,0)
  waitcnt(clkfreq+cnt)
  fl.start
  keyb.start(keyb_dport, keyb_cport)                                                                     'tastaturport starten

  bytefill(@cback,0,8)
  bus_putchar(88)

con'######################################### neue Funktionen ##################################################
pub setcolor(w,v,h)|vordergrund,hintergrund
    vor[w]:=v
    hinter[w]:=h
    v:=v*8
    h:=h+v
    screenfarbe[w]:=0                                      'aktuellen wert löschen
    screenfarbe[w] := v << 8
    screenfarbe[w] := screenfarbe[w] + h

pub qchar(c)
    put(c,x_pos,y_pos)   'qChar
              x_pos++
    scan_limit
pri cursor_rest
    if cursor
       charbackup(0,0)                 'zeichen unter dem Cursor wiederherstellen

PUB chr(ch)|x,y,g
    'Cursor_rest                                 'zeichen unter dem Cursor wiederherstellen
    case ch
        2:return'charbackup(1,1)
        5:x_pos --
        6:x_pos ++
        7:x_pos:=x_start[fenster]              'Home
          y_pos:=y_start[fenster]
        8:x_pos--                              'Backspace
        9:x_pos += (4 - (x_pos & $3))          'Tab
        10:
        12:cls                  'CLS
           x_pos:=x_start[fenster]
           y_pos:=y_start[fenster]

        13:'Cursor_rest
           y_pos++              'Return
           x_pos:=x_start[fenster]
           charbackup(1,0)
        other:put(ch,x_pos,y_pos)   'Char
              x_pos++
        scan_limit

pub scan_limit
    if x_pos<x_start[fenster]
       x_pos:=x_end[fenster]
       y_pos--
    if x_pos>x_end[fenster]
       x_pos:=x_start[fenster]
       y_pos++
    if y_pos>y_end[fenster]
       scrollup(1,0)
    if y_pos<y_start[fenster]
       y_pos:=y_start[fenster]
    Cursor_show

pub Cursor_show
    if cursor
       cursors.byte[CX]:=x_pos
       cursors.byte[CY]:=y_pos

    else
       cursors.byte[CX] := constant(res_x / 8)                ' off

pub locate(y,x)
    cursor_rest
    x_pos:=x
    y_pos:=y
    Cursor_show

pub Displaypalette| hx,hy,h,v,ht,i
    hx:=bus_getchar
    hy:=bus_getchar

    x_pos:=hx
    y_pos:=hy
    h:=0
    v:=vor[0]
    ht:=hinter[0]
    repeat i from 0 to 31
         if i>15 and i//2==0
            h++
         setcolor(0,i,h)
         chr(96)
         if i==15
            y_pos++
            x_pos:=hx

    setcolor(0,v,ht)
    chr(32)

Pub plot(x,y,c)|yy,h,farbe,v
    if x => 0 and x < 320 and y => 0 and y < 256
      yy:=y*10
      v:=c*8
      h:=hinter[fenster]
      h+=v
      farbe:=0                                      'aktuellen wert löschen
      farbe := v << 8
      farbe := farbe + h
      if c<31
         colour.byte[(x/8) + ((y/4) * 40)] :=farbe  'dieser Treiber hat eine Farbauflösung von 40x64 Tiles 8x4 Pixel (10 Longs*64 Farbzeilen)
         screen[yy+x>>5]|= |<x
      else
         screen[yy+x>>5]&= ! |<x

pub ptest(x,y):c|t,yy
  if x => 0 and x < 320 and y => 0 and y < 256
     yy:=y*10
     c:=(screen[yy + x >> 5] >> x)&1                  'get

pub fill(x,y,yy,f)|i,a,b,c,d
    a:=x
    b:=x+1
    c:=0
    repeat i from y to yy
       repeat while (not c or not d)
          ifnot ptest(a,i)
                plot(a,i,f)
                a:=a-1
          else
              c:=1
          ifnot ptest(b,i)
                plot(b,i,f)
                b:=b+1
          else
              d:=1
       d:=c:=0
       a:=x
       b:=x+1

Pub CLS|a,b

    repeat a from y_start[fenster] to y_end[fenster]
           b:=x_start[fenster] + (a * 320)
           repeat 8
                  bytefill(@screen.byte[b],0,x_end[fenster]-x_start[fenster]+1)
                  b+=40
           bytefill(@colour.byte[x_start[fenster] + (a * 80)],screenfarbe[fenster],x_end[fenster]-x_start[fenster]+1)
           bytefill(@colour.byte[x_start[fenster] + (a * 80) + 40], screenfarbe[fenster],x_end[fenster]-x_start[fenster]+1)

pub str(strg)
    repeat strsize(strg)
         chr(byte[strg++])

PUB line(x0, y0, x1, y1,n,dummy) | dX, dY, x, y, err, stp
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
      plot(y, x,n)
    else
      plot(x, y,n)
    err -= dY
    if(err < 0)
      y += stp
      err += dX

PRI swap(x, y)
  result  := long[x]
  long[x] := long[y]
  long[y] := result

{Pub Triangle(x,y,xx,yy,z,zz,n)
    line(x,y,xx,yy,n)
    line(x,y,z,zz,n)
    line(z,zz,xx,yy,n)
}
PUB rect(x0, y0, x1, y1,n,fil) | i

    line(x0, y0, x1, y0,n,0)
    line(x0, y0, x0, y1,n,0)
    line(x0, y1, x1, y1,n,0)
    line(x1, y0, x1, y1,n,0)
    if fil
       fill(x0,y0,y1-1,n)

PUB circle(x,y,r,r2,set,fil)|i,xp,yp,a,b,c,d,hd,rp
    d:=630 '(2*pi*100)
    hd:=fl.ffloat(100)
    xp:=x
    yp:=y
    rp:=r2

    x:=fl.ffloat(x)
    y:=fl.ffloat(y)
    r:=fl.ffloat(r)
    r2:=fl.ffloat(r2)

    repeat i from 0 to d 'step 2
          c:=fl.fdiv(fl.ffloat(i),hd)
          a:=fl.fadd(x,fl.fmul(fl.cos(c),r))
          b:=fl.fadd(y,fl.fmul(fl.sin(c),r2))
          Plot(fl.FRound(a),fl.FRound(b),set)
    if fil
       fill(xp,(yp+1)-rp,(yp+rp)-1,set)

pub box(f,y,x,yy,xx,sh)
    if y<31 and yy<31 and x<39 and xx<39
       if sh
          Plotbox(f,y+1,x+1,yy+1,xx+1,199)
       Plotbox(f,y,x,yy,xx,32)

pub plotBox(f,y,x,yy,xx,ch)|a,b,c,tmph
    tmph:=hinter[fenster]
    setcolor(fenster,vor[fenster],f)
    a:=xx-x
    b:=yy-y
    c:=x
    repeat b from y to yy
         repeat a from x to xx
              put(ch,a,b)

    setcolor(fenster,vor[fenster],tmph)

pub charbackup(n,x)|i,b
    b := x_pos+ x + y_pos * 320
    i:=0
  repeat 8
    if n
       cback.byte[i++] := screen.byte[b]                'backup
    else
       screen.byte[b]:=cback.byte[i++]                  'restore
    b += 40

pub put(c,x,y)|b
  b := x + y * 320
  c *= 8
  'c&=255

  repeat 8
    screen.byte[b] := font[c++]
    b += 40
    'c += 256

  colour.byte[x + y * 80] := screenfarbe[fenster]{& $7F}
  colour.byte[x + y * 80 + 40] := screenfarbe[fenster]

pub redefine|n,c
    c:=bus_getchar
    c*=8
    repeat 8
          font[c++]:=bus_getchar

pub scrollup(n,r)|a,b,c
repeat n
  repeat a from y_start[fenster] to y_end[fenster]-1
           b:=x_start[fenster] + (a * 320)
           c:=x_start[fenster] + (a * 80)
           repeat 8
                  bytemove(@screen.byte[b],@screen.byte[b+320],x_end[fenster]+1-x_start[fenster])
                  b+=40
           bytemove(@colour.byte[c],@colour.byte[c+80],x_end[fenster]-x_start[fenster]+1)
           bytemove(@colour.byte[c + 40],@colour.byte[c+120],x_end[fenster]-x_start[fenster]+1)

  repeat 8
         bytefill(@screen.byte[b], 0,(x_end[fenster]+1-x_start[fenster]))
         b+=40

  'bytefill(@colour.byte[c],screenfarbe[fenster],x_end[fenster]-x_start[fenster])
  'bytefill(@colour.byte[c + 40], screenfarbe[fenster],x_end[fenster]-x_start[fenster])
  y_pos--
  if y_pos<y_start[fenster]
     y_pos:=y_start[fenster]
  x_pos:=x_start[fenster]
  if r
     waitcnt( cnt+=clkfreq / (1000/r))

pub scrolldown(n,r)|i,pos,co

  repeat n
      waitVBL
      repeat i from 0 to 31
           pos:=2480-(i*80)
           co:=620-(i*20)
           longmove(@screen[pos],@screen[pos-80], 80)
           longmove(@colour[co],@colour[co-20],20)

      longfill(@screen[0], 0, 80)
      bytefill(@colour[0], screenfarbe[fenster], 80)
      y_pos++
      if y_pos>31
         y_pos:=31
      x_pos:=0
      if r
         waitcnt( cnt+=clkfreq / (1000/r))


pub Window|win,f1,f2,f3,f4,f5,f6,f7,f8,x,y,xx,yy,modus,shd

        win:=bus_getchar                                                                                 'fensternummer
        f1:=bus_getchar                                                                                  'farbe1            'vordergrund
        f2:=bus_getchar                                                                                  'farbe2            'hintergrund
        f3:=bus_getchar                                                                                  'farbe3            'titel
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

        plot_window(win,f1,f2,f3,f4,f5,f6,f7,f8,x,y,xx,yy,modus,shd)

pri Del_Window|wnr,i,a
    i:=0
    wnr:=bus_getchar
    if a==9
       return
    a:=wnr*14
    wind[a]:=0

  printwindow(0)

  x_start[wnr]       :=x_start[0]
  x_end[wnr]         :=x_end[0]
  y_start[wnr]       :=y_start[0]
  y_end[wnr]         :=y_end[0]
  screenfarbe[wnr]   :=screenfarbe[0]
  vor[wnr]           :=vor[0]
  hinter[wnr]        :=hinter[0]
  cur_x[wnr]         :=cur_x[0]
  cur_y[wnr]         :=cur_y[0]

pri plot_window(win,f1,f2,f3,f4,f5,f6,f7,f8,x,y,xx,yy,modus,shd)|a,b,c,d,posi

        fenster:=win
        a:=b:=c:=d:=0

        if shd
           Plotbox(f2,y+1,x+1,yy+1,xx+1,199)
        if modus==2 or modus>3
           rect(x*8-1, y*8+7, xx*8+8, yy*8+8,f3,0)
           a:=1
        if modus==3 or modus==4 or modus>5              'Titelzeile
           plotbox(f5,y,x,y,xx,32)
           a:=1
        if modus>6
           plotbox(f7,yy,x,yy,xx,32)                      'Statuszeile                                        'status(yy,x,xx,f1,f2,f7)
           b:=1

        setcolor(win,f1,f2)
        Plotbox(f2,y+a,x,yy-b,xx,32)
        x_pos:=x
        y_pos:=y+a

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

     x_start[win]:=x_pos
     y_start[win]:=y_pos
     x_end[win]:=xx
     y_end[win]:=yy-b
     cur_x[win]:=x_pos
     cur_y[win]:=y_pos

pub printwindow(w)|v

  cur_x[fenster]:=x_pos         'aktuelle Cursorposition speichern
  cur_y[fenster]:=y_pos
  fenster:=w
  y_pos:=cur_y[fenster]         'alte Cursorposition setzen
  x_pos:=cur_x[fenster]

pri Set_Titel_Status|win,Tit_Stat,len,posi,x,y,tmp                                                           'Titel-oder Statustext in einem Fenster setzen
    tmp:=fenster
    win     :=bus_getchar                                                                                'fensternummer
    Tit_Stat:=bus_getchar                                                                                'Titel oder Statustext
    len     :=bus_getchar                                                                                'stringlänge
    posi:=win*14
    x:=wind[posi+2]

    printwindow(win)

    if (wind[posi+1]==3 or  wind[posi+1]==4 or  wind[posi+1]>5) and Tit_Stat==1 and wind[posi]
       y:=wind[posi+3]              'Titeltext
       plotbox(wind[posi+10],y,x,y,wind[posi+4],32)                                                       'Titelleiste löschen
       bus_getstr_plot(posi,len, y, x+1,1,0)                                                             'neuen Titeltext schreiben
    elseif wind[posi+1]>6 and Tit_Stat==2 and wind[posi]
       y:=wind[posi+5]           'Statustext
       plotbox(wind[posi+10],y,x,y,wind[posi+4],32)                                                       'Statusbalken löschen
       bus_getstr_plot(posi,len,y, x+1,1,2)                                                              'neuen Statustest schreiben
    else
       bus_getstr_plot(posi,len,y, x+1,0,0)                                                              'keine Bildschirmausgabe
    printwindow(tmp)

pri bus_getstr_plot(win,len,y,x,m,b)|c


       repeat len
              c:=bus_getchar
              if x<wind[win+4] and m==1
                 put(c,x++,y)
              else
                 next

pub Backup_Restore_Area(n)|x,y,xx,yy,a,b,zaehler,y2
    x:=bus_getchar
    y:=bus_getchar
    xx:=bus_getchar
    yy:=bus_getchar

    repeat b from y to yy
           repeat a from x to xx
                  y2:=a+b*320
                  if n
                     repeat 8
                            bus_putchar(screen.byte[y2]]
                            y2+=40
                     bus_putchar(colour.byte[a + b * 80])
                     bus_putchar(colour.byte[a + b * 80 + 40])
                  else
                     repeat 8
                            screen.byte[y2]:=bus_getchar
                            y2+=40
                     colour.byte[a + b * 80] := bus_getchar
                     colour.byte[a + b * 80 + 40] := bus_getchar

pub waitVBL : n

  n := link[3]
  repeat
  while n == link[3]

con'
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

pub mgr_bel
    sub_putlong(Bel_Treiber_Ver)                                                                         'rückgabe 65 für tile-driver 64 farben stark geänderte Version
PUB mgr_getspec                                         'cmgr: abfrage der spezifikation des chips
  sub_putlong(CHIP_SPEC)

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

PUB key_stat                                                                                             'key: tastaturstatus abfragen

  bus_putchar(keyb.gotkey)

PUB key_code                                                                                             'key: tastencode abfragen

  keycode := keyb.key
  case keycode
    $c8: keycode := $08                                                                                  'backspace wandeln
  bus_putchar(keycode)

PUB key_spec                                                                                             'key: statustaten vom letzten tastencode abfragen

  bus_putchar(keycode >> 8)

DAT


                        org
'
' Entry: dummy-assemblercode fuer cogtest
'
entry                   jmp     entry                   'just loops

font byte $03,$04,$02,$01,$07,$00,$00,$00       ' 2  0
     byte $0C,$08,$0B,$08,$00,$00,$00,$00       ' -1 1
     byte $03,$04,$02,$04,$03,$00,$00,$00       '3 2

     byte $18,$7C,$36,$7C,$D8,$D8,$7E,$18       '$ 3
     byte $00,$63,$33,$18,$0C,$66,$63,$00       '% 4
     byte $1C,$36,$1C,$6E,$3B,$33,$6E,$00       '& 5
     byte $38,$30,$18,$00,$00,$00,$00,$00       ' ' 6
     byte $18,$0C,$06,$06,$06,$0C,$18,$00       '( 7
     byte $06,$0C,$18,$18,$18,$0C,$06,$00       ') 8
     byte $00,$66,$3C,$FF,$3C,$66,$00,$00       '* 9
     byte $00,$0C,$0C,$3F,$0C,$0C,$00,$00       '+ 10
     byte $00,$00,$00,$00,$00,$38,$30,$18       ', 11
     byte $00,$00,$00,$7F,$00,$00,$00,$00       '- 12
     byte $00,$00,$00,$00,$00,$0C,$0C,$00       '. 13
     byte $60,$30,$18,$0C,$06,$03,$01,$00       '/ 14
     byte $3C,$7E,$FF,$FF,$FF,$FF,$7E,$3C       '• 15

     byte $00,$00,$08,$14,$22,$41,$7F,$00       'Δ 16
     byte $00,$00,$3E,$14,$14,$14,$16,$00       'π 17
     byte $3F,$21,$02,$04,$02,$21,$3F,$00       'Σ 18
     byte $00,$3E,$63,$63,$36,$36,$77,$00       'Ω 19

     byte $3F,$03,$1F,$30,$30,$33,$1E,$00       '5 20

     byte $70,$10,$10,$16,$14,$1C,$18,$00       '√ 21

     byte $3F,$33,$30,$18,$0C,$0C,$0C,$00       '7 22
     byte $1E,$33,$33,$1E,$33,$33,$1E,$00       '8 23
     byte $1E,$33,$33,$3E,$30,$18,$0E,$00       '9 24
     byte $00,$00,$0C,$0C,$00,$0C,$0C,$00       ': 25
     byte $00,$00,$0C,$0C,$00,$0C,$0C,$06       '; 26
     byte $18,$0C,$06,$03,$06,$0C,$18,$00       '< 27
     byte $00,$00,$3F,$00,$3F,$00,$00,$00       '= 28
     byte $06,$0C,$18,$30,$18,$0C,$06,$00       '> 29
     byte $1E,$33,$30,$18,$0C,$00,$0C,$00       '? 30
     byte $3E,$63,$7B,$7B,$7B,$03,$1E,$00       '@ 31

     byte $00,$00,$00,$00,$00,$00,$00,$00       'Space  32
     byte $0C,$0C,$0C,$0C,$0C,$00,$0C,$00       '!      33
     byte $EE,$CC,$66,$00,$00,$00,$00,$00       ' "     34
     byte $6C,$6C,$7F,$36,$7F,$1B,$1B,$00       '# 35
     byte $18,$7C,$36,$7C,$D8,$D8,$7E,$18       '$ 36
     byte $00,$63,$33,$18,$0C,$66,$63,$00       '% 37
     byte $1C,$36,$1C,$6E,$3B,$33,$6E,$00       '& 38
     byte $38,$30,$18,$00,$00,$00,$00,$00       ' ' 39
     byte $18,$0C,$06,$06,$06,$0C,$18,$00       '( 40
     byte $06,$0C,$18,$18,$18,$0C,$06,$00       ') 41
     byte $00,$66,$3C,$FF,$3C,$66,$00,$00       '* 42
     byte $00,$0C,$0C,$3F,$0C,$0C,$00,$00       '+ 43
     byte $00,$00,$00,$00,$00,$38,$30,$18       ', 44
     byte $00,$00,$00,$7F,$00,$00,$00,$00       '- 45
     byte $00,$00,$00,$00,$00,$0C,$0C,$00       '. 46
     byte $60,$30,$18,$0C,$06,$03,$01,$00       '/ 47
     byte $3E,$63,$73,$7B,$6F,$67,$3E,$00       '0 48
     byte $0C,$0E,$0C,$0C,$0C,$0C,$3F,$00       '1 49
     byte $1E,$33,$30,$1C,$06,$33,$3F,$00       '2 50
     byte $3F,$18,$0C,$1E,$30,$33,$1E,$00       '3 51
     byte $38,$3C,$36,$33,$7F,$30,$78,$00       '4 52
     byte $3F,$03,$1F,$30,$30,$33,$1E,$00       '5 53
     byte $1C,$06,$03,$1F,$33,$33,$1E,$00       '6 54
     byte $3F,$33,$30,$18,$0C,$0C,$0C,$00       '7 55
     byte $1E,$33,$33,$1E,$33,$33,$1E,$00       '8 56
     byte $1E,$33,$33,$3E,$30,$18,$0E,$00       '9 57
     byte $00,$00,$0C,$0C,$00,$0C,$0C,$00       ': 58
     byte $00,$00,$0C,$0C,$00,$0C,$0C,$06       '; 59
     byte $18,$0C,$06,$03,$06,$0C,$18,$00       '< 60
     byte $00,$00,$3F,$00,$3F,$00,$00,$00       '= 61
     byte $06,$0C,$18,$30,$18,$0C,$06,$00       '> 62
     byte $1E,$33,$30,$18,$0C,$00,$0C,$00       '? 63
     byte $3E,$63,$7B,$7B,$7B,$03,$1E,$00       '@ 64
     byte $0C,$1E,$33,$33,$3F,$33,$33,$00       'A 65
     byte $3F,$66,$66,$3E,$66,$66,$3F,$00       'B 66
     byte $3C,$66,$03,$03,$03,$66,$3C,$00       'C 67
     byte $1F,$36,$66,$66,$66,$36,$1F,$00       'D 68
     byte $7F,$46,$16,$1E,$16,$46,$7F,$00       'E 69
     byte $7F,$46,$16,$1E,$16,$06,$0F,$00       'F 70
     byte $3C,$66,$03,$03,$73,$66,$3C,$00       'G 71
     byte $33,$33,$33,$3F,$33,$33,$33,$00       'H 72
     byte $1E,$0C,$0C,$0C,$0C,$0C,$1E,$00       'I 73
     byte $78,$30,$30,$30,$33,$33,$1E,$00       'J 74
     byte $67,$66,$36,$0E,$36,$66,$67,$00       'K 75
     byte $0F,$06,$06,$06,$46,$66,$7F,$00       'L 76
     byte $63,$77,$7F,$6B,$63,$63,$63,$00       'M 77
     byte $63,$67,$6F,$7B,$73,$63,$63,$00       'N 78
     byte $1C,$36,$63,$63,$63,$36,$1C,$00       'O 79
     byte $3F,$66,$66,$3E,$06,$06,$0F,$00       'P 80
     byte $1E,$33,$33,$33,$33,$3B,$1E,$38       'Q 81
     byte $3F,$66,$66,$3E,$36,$66,$67,$00       'R 82
     byte $3E,$63,$0F,$3C,$70,$63,$3E,$00       'S 83
     byte $3F,$2D,$0C,$0C,$0C,$0C,$1E,$00       'T 84
     byte $33,$33,$33,$33,$33,$33,$1E,$00       'U 85
     byte $33,$33,$33,$1E,$1E,$0C,$0C,$00       'V 86
     byte $63,$63,$63,$6B,$7F,$77,$63,$00       'W 87
     byte $63,$63,$36,$1C,$36,$63,$63,$00       'X 88
     byte $33,$33,$33,$1E,$0C,$0C,$1E,$00       'Y 89
     byte $7F,$63,$31,$18,$4C,$66,$7F,$00       'Z 90
     byte $3C,$0C,$0C,$0C,$0C,$0C,$3C,$00       '[ 91
     byte $18,$18,$18,$18,$18,$18,$18,$00       '| 92
     byte $3C,$30,$30,$30,$30,$30,$3C,$00       '] 93
     byte $08,$1C,$36,$63,$00,$00,$00,$00       '^ 94
     byte $00,$00,$00,$00,$00,$00,$00,$FF       '_ 95
     byte $18,$18,$18,$18,$18,$18,$18,$18       '96    (162)
     byte $00,$00,$1E,$30,$3E,$33,$6E,$00       'a 97
     byte $07,$06,$3E,$66,$66,$66,$3B,$00       'b 98
     byte $00,$00,$1E,$33,$03,$33,$1E,$00       'c 99
     byte $38,$30,$3E,$33,$33,$33,$6E,$00       'd 100
     byte $00,$00,$1E,$33,$3F,$03,$1E,$00       'e 101
     byte $1C,$36,$06,$0F,$06,$06,$0F,$00       'f 102
     byte $00,$00,$6E,$33,$33,$3E,$30,$1F       'g 103
     byte $07,$06,$36,$6E,$66,$66,$67,$00       'h 104
     byte $0C,$00,$0E,$0C,$0C,$0C,$3F,$00       'i 105
     byte $30,$00,$38,$30,$30,$33,$33,$1E       'j 106
     byte $07,$66,$36,$1E,$16,$36,$67,$00       'k 107
     byte $0E,$0C,$0C,$0C,$0C,$0C,$3F,$00       'l 108
     byte $00,$00,$33,$7F,$7F,$6B,$63,$00       'm 109
     byte $00,$00,$1F,$33,$33,$33,$33,$00       'n 110
     byte $00,$00,$1E,$33,$33,$33,$1E,$00       'o 111
     byte $00,$00,$3B,$66,$66,$3E,$06,$0F       'p 112
     byte $00,$00,$6E,$33,$33,$3E,$30,$78       'q 113
     byte $00,$00,$3B,$6E,$66,$06,$0F,$00       'r 114
     byte $00,$00,$3E,$03,$1E,$30,$1F,$00       's 115
     byte $08,$0C,$3E,$0C,$0C,$2C,$18,$00       't 116
     byte $00,$00,$33,$33,$33,$33,$6E,$00       'u 117
     byte $00,$00,$33,$33,$33,$1E,$0C,$00       'v 118
     byte $00,$00,$63,$6B,$7F,$7F,$36,$00       'w 119
     byte $00,$00,$63,$36,$1C,$36,$63,$00       'x 120
     byte $00,$00,$33,$33,$33,$3E,$30,$1F       'y 121
     byte $00,$00,$3F,$19,$0C,$26,$3F,$00       'z 122
     byte $80,$40,$40,$20,$40,$40,$80,$03       '{123
     byte $10,$10,$10,$10,$10,$10,$10,$00       '|124
     byte $01,$02,$02,$04,$02,$02,$01,$00       '}125
     byte $00,$00,$00,$26,$19,$00,$00,$00       '~126
     byte $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF       '‣127

'############## Platz für Sonderzeichen KC87 Zeichensatz ######################
     byte $03,$04,$08,$08,$08,$08,$04,$03       '128
     byte $C0,$20,$10,$10,$10,$10,$20,$C0       '129
     byte $81,$81,$42,$3C,$00,$00,$00,$00       '130
     byte $00,$00,$00,$00,$3C,$42,$81,$81       '131
     byte $08,$08,$04,$03,$00,$00,$00,$00       '132
     byte $10,$10,$20,$C0,$00,$00,$00,$00       '133
     byte $00,$00,$00,$00,$C0,$20,$10,$10       '134
     byte $00,$00,$00,$00,$03,$04,$08,$08       '135
     byte $01,$01,$01,$01,$01,$01,$01,$FF       '136
     byte $FF,$80,$80,$80,$80,$80,$80,$80       '137
     byte $00,$08,$14,$22,$41,$22,$14,$08       '138
     byte $FF,$F7,$E3,$C1,$80,$C1,$E3,$F7       '139
     byte $3C,$42,$81,$81,$81,$81,$42,$3C       '140
     byte $C3,$81,$00,$00,$00,$00,$81,$C3       '141
     byte $FF,$7F,$3F,$1F,$0F,$07,$03,$01       '142
     byte $01,$03,$07,$0F,$1F,$3F,$7F,$FF       '143
     byte $80,$40,$20,$10,$08,$04,$02,$01       '144
     byte $01,$02,$04,$08,$10,$20,$40,$80       '145
     byte $00,$00,$00,$00,$C0,$30,$0C,$03       '146
     byte $C0,$30,$0C,$03,$00,$00,$00,$00       '147
     byte $C0,$30,$0C,$03,$03,$0C,$30,$C0       '148
     byte $00,$00,$00,$00,$03,$0C,$30,$C0       '149
     byte $03,$0C,$30,$C0,$00,$00,$00,$00       '150
     byte $03,$0C,$30,$C0,$C0,$30,$0C,$03       '151
     byte $08,$08,$04,$04,$02,$02,$01,$01       '152
     byte $80,$80,$40,$40,$20,$20,$10,$10       '153
     byte $81,$81,$42,$42,$24,$24,$18,$18       '154
     byte $01,$01,$02,$02,$04,$04,$08,$08       '155
     byte $10,$10,$20,$20,$40,$40,$80,$80       '156
     byte $18,$18,$24,$24,$42,$42,$81,$81       '157
     byte $FF,$00,$00,$00,$00,$00,$00,$00       '158
     byte $01,$01,$01,$01,$01,$01,$01,$01       '159
     byte $00,$00,$00,$FF,$FF,$00,$00,$00       '160
     byte $00,$00,$00,$00,$00,$00,$00,$00       'Cursor leer 161
'     byte $18,$18,$18,$18,$18,$18,$18,$18       '162
     byte $18,$18,$18,$FF,$FF,$00,$00,$00       '162
     byte $18,$18,$18,$F8,$F8,$18,$18,$18       '163
     byte $00,$00,$00,$FF,$FF,$18,$18,$18       '164
     byte $18,$18,$18,$1F,$1F,$18,$18,$18       '165
     byte $18,$18,$18,$FF,$FF,$18,$18,$18       '166
     byte $18,$18,$18,$F8,$F8,$00,$00,$00       '167
     byte $00,$00,$00,$F8,$F8,$18,$18,$18       '168
     byte $00,$00,$00,$1F,$1F,$18,$18,$18       '169
     byte $18,$18,$18,$1F,$1F,$00,$00,$00       '170
     byte $01,$01,$01,$02,$02,$04,$18,$E0       '171
     byte $80,$80,$80,$40,$40,$20,$18,$07       '172
     byte $07,$18,$20,$40,$40,$80,$80,$80       '173
     byte $E0,$18,$04,$02,$02,$01,$01,$01       '174
     byte $81,$42,$24,$18,$18,$24,$42,$81       '175
     byte $0F,$0F,$0F,$0F,$00,$00,$00,$00       '176
     byte $F0,$F0,$F0,$F0,$00,$00,$00,$00       '177
     byte $00,$00,$00,$00,$F0,$F0,$F0,$F0       '178
     byte $00,$00,$00,$00,$0F,$0F,$0F,$0F       '179
     byte $0F,$0F,$0F,$0F,$0F,$0F,$0F,$0F       '180
     byte $F0,$F0,$F0,$F0,$F0,$F0,$F0,$F0       '181
     byte $FF,$FF,$FF,$FF,$00,$00,$00,$00       '182
     byte $00,$00,$00,$00,$FF,$FF,$FF,$FF       '183
     byte $0F,$0F,$0F,$0F,$F0,$F0,$F0,$F0       '184
     byte $F0,$F0,$F0,$F0,$0F,$0F,$0F,$0F       '185
     byte $F0,$F0,$F0,$F0,$FF,$FF,$FF,$FF       '186
     byte $0F,$0F,$0F,$0F,$FF,$FF,$FF,$FF       '187
     byte $FF,$FF,$FF,$FF,$0F,$0F,$0F,$0F       '188
     byte $FF,$FF,$FF,$FF,$F0,$F0,$F0,$F0       '189
     byte $80,$C0,$E0,$F0,$F8,$FC,$FE,$FF       '190
     byte $FF,$FE,$FC,$F8,$F0,$E0,$C0,$80       '191
     byte $80,$80,$80,$80,$80,$80,$80,$80       '192
     byte $FF,$01,$01,$01,$01,$01,$01,$01       '193
     byte $FF,$01,$01,$39,$39,$39,$01,$01       '194
     byte $FF,$FF,$FF,$E7,$E7,$FF,$FF,$FF       '195
     byte $18,$3C,$7E,$3C,$18,$3C,$7E,$FF       '196
     byte $FF,$00,$FF,$00,$FF,$00,$FF,$00       '197
     byte $55,$55,$55,$55,$55,$55,$55,$55       '198
     byte $55,$AA,$55,$AA,$55,$AA,$55,$AA       '199
     byte $80,$80,$80,$80,$80,$80,$80,$FF       '200
     byte $00,$08,$1C,$3E,$7F,$3E,$1C,$08       '201
     byte $1C,$08,$49,$7F,$49,$08,$1C,$3E       '202
     byte $00,$36,$7F,$7F,$7F,$3E,$1C,$08       '203
     byte $08,$1C,$3E,$7F,$7F,$3E,$08,$3E       '204
     byte $E7,$E7,$42,$FF,$FF,$42,$E7,$E7       '205
     byte $DB,$FF,$DB,$18,$18,$DB,$FF,$DB       '206
     byte $3C,$7E,$FF,$FF,$FF,$FF,$7E,$3C       '207
     byte $03,$03,$00,$00,$00,$00,$00,$00       '208
     byte $0C,$0C,$00,$00,$00,$00,$00,$00       '209
     byte $30,$30,$00,$00,$00,$00,$00,$00       '210
     byte $C0,$C0,$00,$00,$00,$00,$00,$00       '211
     byte $00,$00,$03,$03,$00,$00,$00,$00       '212
     byte $00,$00,$0C,$0C,$00,$00,$00,$00       '213
     byte $00,$00,$30,$30,$00,$00,$00,$00       '214
     byte $00,$00,$C0,$C0,$00,$00,$00,$00       '215
     byte $00,$00,$00,$00,$03,$03,$00,$00       '216
     byte $00,$00,$00,$00,$0C,$0C,$00,$00       '217
     byte $00,$00,$00,$00,$30,$30,$00,$00       '218
     byte $00,$00,$00,$00,$C0,$C0,$00,$00       '219
     byte $00,$00,$00,$00,$00,$00,$03,$03       '220
     byte $00,$00,$00,$00,$00,$00,$0C,$0C       '221
     byte $00,$00,$00,$00,$00,$00,$30,$30       '222
     byte $00,$00,$00,$00,$00,$00,$C0,$C0       '223
     byte $00,$00,$00,$00,$00,$00,$F0,$F0       '224
     byte $00,$00,$00,$00,$00,$00,$FC,$FC       '225
     byte $00,$00,$00,$00,$00,$00,$FF,$FF       '226
     byte $00,$00,$00,$00,$00,$00,$3F,$3F       '227
     byte $00,$00,$00,$00,$00,$00,$0F,$0F       '228
     byte $00,$00,$00,$00,$00,$00,$03,$03       '229
     byte $00,$00,$00,$00,$03,$03,$03,$03       '230
     byte $00,$00,$03,$03,$03,$03,$03,$03       '231
     byte $03,$03,$03,$03,$03,$03,$03,$03       '232
     byte $03,$03,$03,$03,$03,$03,$00,$00       '233
     byte $03,$03,$03,$03,$00,$00,$00,$00       '234
     byte $03,$03,$00,$00,$00,$00,$00,$00       '235
     byte $0F,$0F,$00,$00,$00,$00,$00,$00       '236
     byte $3F,$3F,$00,$00,$00,$00,$00,$00       '237
     byte $FF,$FF,$00,$00,$00,$00,$00,$00       '238
     byte $FC,$FC,$00,$00,$00,$00,$00,$00       '239
     byte $F0,$F0,$00,$00,$00,$00,$00,$00       '240
     byte $C0,$C0,$00,$00,$00,$00,$00,$00       '241
     byte $C0,$C0,$C0,$C0,$00,$00,$00,$00       '242
     byte $C0,$C0,$C0,$C0,$C0,$C0,$00,$00       '243
     byte $C0,$C0,$C0,$C0,$C0,$C0,$C0,$C0       '244
     byte $00,$00,$C0,$C0,$C0,$C0,$C0,$C0       '245
     byte $00,$00,$00,$00,$C0,$C0,$C0,$C0       '246
     byte $00,$00,$00,$00,$00,$00,$C0,$C0       '247
     byte $00,$00,$00,$00,$00,$00,$00,$FF       '248
     byte $00,$00,$00,$00,$00,$00,$FF,$FF       '249
     byte $00,$00,$00,$00,$00,$FF,$FF,$FF       '250
     byte $00,$00,$00,$00,$FF,$FF,$FF,$FF       '251
     byte $00,$00,$00,$FF,$FF,$FF,$FF,$FF       '252
     byte $00,$00,$FF,$FF,$FF,$FF,$FF,$FF       '253
     byte $00,$FF,$FF,$FF,$FF,$FF,$FF,$FF       '254
     byte $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF       '255


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
