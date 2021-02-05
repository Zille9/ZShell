{{ ---------------------------------------------------------------------------------------------------------

Hive-Computer-Projekt

Name            : ZShell
Chip            : Regnatix-Code 
Version         : 1.0
Autor           : R.Zielinski (Zille9)

Beschreibung    : Alternative Shell (Regime)

Eigenschaften   : -Komandozeilen-Prozessor mit mathematischen Fähigkeiten
                  -Laden von Bin, Bel und ADM-Dateien in die jeweiligen Propeller-Chips
                  -Grundgerüst vom Basic übernommen, unnötige Funktionen entfernt


'############################################################ Version 1.0 ######################################################################################################
31-02-2021      -Grundfunktionen vorhanden (Dateifunktionen, Commandoprozessor)
                -grafische Cog-Anzeige (F2 oder Befehl Cogs)
                -Befehl Ping zur Abfrage auf I2C Teilnehmer eingefügt
                -4402 Longs frei



 --------------------------------------------------------------------------------------------------------- }}

obj
  ios    :"reg-ios-bas"
  FS     :"BasFloatString2"
  Fl     :"BasF32.spin"
  gc     :"glob-con"

con

_CLKMODE     = XTAL1 + PLL16X
_XINFREQ     = 5_000_000

   version   = 1.01

   fEof      = $FF                     ' dateiende-kennung
   linelen   = 85                      ' Maximum input line length
   quote     = 34                      ' Double quote
   caseBit   = !32                     ' Uppercase/Lowercase bit
   point     = 46                      ' point
   Backslash = 92
   percent   = 37
   STR_MAX   = linelen                 ' maximale Stringlänge für Printausgaben und Rom
'*****************Speicherbereiche**********************************************

   ERROR_RAM = $0 '....$0FFF           ' ERROR-Texte
   VERZ_NAME = $1000 '....$10FF        ' Verzeichnis-Tiefenspeicher
   TILE_RAM  = $40000 '....$667FF      ' hier beginnt der Tile-Speicher fuer 14 Tiledateien(Modus0) oder 8 BMP-Bilder(Modus4)
   SYS_FONT  = $66800 '....$693FF      ' ab hier liegt der System-Font 11kb
   MOUSE_RAM = $69400 '....$6943F      ' User-Mouse-Pointer 64byte
   WTILE_RAM= $7E500 '.... $7E9FF      ' Win-Tile Puffer hier können die Tiles, aus denen die Fenster gebaut werden geändert werden

   SMARK_RAM = $7FFF2                  ' Flag für übergebenen Startparameter Wert = 222



   ADM_SPEC       = gc#A_FAT|gc#A_LDR|gc#A_SID|gc#A_RTC|gc#A_PLX'%00000000_00000000_00000000_11110011

{'Farben im Mode1

'Vordergrundfarben
  vschwarz=0
  vdunkelblau=1
  vdunkelgruen=2
  vblau=3
  vGruen=4
  vhellblau=5
  vhellgruen=6
  vTuerkis = 7
  vrot=8
  vlila=9
  vorange=10
  vpink=11
  vteal=12
  vhellgrau=13
  vgelbgruen=14
  vblaugruen=15

'Hintergrundfarben
  #1, HBlau
  #2, HGruen
  #3, HTuerkis
  #4, HRot
  #5, HLila
  #6, HGelb
  #7, HWeiss
  }
  #$FC, Light_Grey, #$A8, Grey, #$54, Dark_Grey
  #$C0, Light_Red, #$80, Red, #$40, Dark_Red
  #$30, Light_Green, #$20, Green, #$10, Dark_Green
  #$1F, Light_Blue, #$09, Blue, #$04, Dark_Blue
  #$F0, Light_Orange, #$E6, Orange, #$92, Dark_Orange
  #$CC, Light_Purple, #$88, Purple, #$44, Dark_Purple
  #$3C, Light_Teal, #$28, Teal, #$14, Dark_Teal
  #$FF, White, #$00, Black

'*****************Tastencodes*****************************************************
   ENTF_KEY  = 186
   bspKey    = $C8                     ' PS/2 keyboard backspace key
   breakKey  = $CB                     ' PS/2 keyboard escape key
   fReturn   = 13
   fLinefeed = 10
   KEY_LEFT  = 2
   KEY_RIGHT = 3
   KEY_UP    = 4
   KEY_DOWN  = 5

   MIN_EXP   = -99999
   MAX_EXP   =  999999

   set_x        =gc#BEL_DPL_SETX
   Cursor_set   =gc#BEL_CURSORRATE
   Del_button   =gc#BEL_ERS_3DBUTTON'19
   Thirdcolor   =gc#BEL_THIRDCOLOR'28
   Print_Window =gc#BEL_DPL_WIN'33
   SPEED        =gc#BEL_SPRITE_SPEED'48
   MOVE         =gc#BEL_SPRITE_MOVE'47

   _Line        =gc#BEL_DPL_LINE
   _Circ        =gc#BEL_DPL_CIRCLE
   _Rect        =gc#BEL_RECT
   _Setx        =gc#BEL_DPL_SETX

   ntoks        = 55   'Anzahl der Befehle

var
   long tp                                                                    'Kommandozeile
   long prm[10]                                                               'Befehlszeilen-Parameter-Feld (hier werden die Parameter der einzelnen Befehle eingelesen)
   long usermarker,basicmarker                                                'Dir-Marker-Puffer für Datei-und Verzeichnis-Operationen

   word filenumber                                                            'Anzahl der mit Dir gefundenen Dateien

   byte workdir[12]                                                           'aktuelles Verzeichnis
   'byte Pfadname[255]
   byte fileOpened,tline[linelen]                                             'File-Open-Marker,Eingabezeilen-Puffer,Sicherheitskopie für tline ->Input-Befehl
   byte cursor                                                                'cursor on/off
   byte win                                                                   'Fensternummer
   byte farbe,hintergr,farbe3                                                 'vorder,hintergrundfarbe,Rahmenfarbe
   byte file1[12],dzeilen,xz,yz,buff[8],modus                                 'Dir-Befehl-variablen   extension[12]
   byte volume,play                                                           'sidcog-variablen
   byte str0[STR_MAX]                                                         'String fuer Fontfunktion in Fenstern
   byte font[STR_MAX]                                                         'Stringpuffer fuer Font-Funktion und str$-funktion
   byte f0[STR_MAX]                                                           'Hilfsstring
   byte ADDA,PORT                                                             'Puffer der Portadressen der Sepia-Karte
   byte returnmarker
   byte Pfadtiefe                                                             'nummer des wievielten unterpfades

dat
   tok0  byte "?",0        ' PRINT                                                         '128 131    getestet
   tok1  byte "DUMP", 0    ' Speicher-Monitor <startadress>,<0..1> (0 Hram,1 Eram)          129 186    getestet
   tok2  byte "PEEK",0      'Byte aus Speicher lesen momentan nur eram                      130 215    getestet
   tok3  byte "POKE",0      'Byte in Speicher schreiben momentan nur eram                   131 208    getestet
   tok4  byte "INFO",0      'Systeminfo                                                     132 217    getestet

'************************** Dateioperationen **************************************************************
   tok5  byte "OPEN", 0     ' OPEN " <file> ",<mode>                                        133 140    getestet
   tok6  byte "TYPE", 0     ' TYPE <file> Dateiinhalt auf Bildschirm ausgeben               134 141    getestet
   tok7  byte "WRITE", 0    ' WRITE <"text"> :                                              135 142    getestet
   tok8  byte "CLOSE", 0    ' CLOSE                                                         136 143    getestet
   tok9  byte "DEL", 0      ' DELETE " <file> "                                             137 144    getestet
   tok10 byte "REN", 0      ' RENAME " <file> "," <file> "                                  138 145    getestet
   tok11 byte "CHDIR",0      ' Verzeichnis wechseln                                          139 230    getestet      kann nicht CD heissen, kollidiert sonst mit Hex-Zahlen-Auswertung in getanynumber
   tok12 byte "DIR", 0      ' dir anzeige                                                   140 146    getestet      NICHT AENDERN Funktionstaste!!
   tok13 byte "ALOAD", 0     'ALOAD "<file>"  Administra-Code laden                         141 147    getestet      NICHT AENDERN Funktionstaste!!
   tok14 byte "BLOAD", 0    ' BLOAD "<file>"  Bellatrix-Code laden                          142 148    getestet      NICHT AENDERN Funktionstaste!!
   tok15 byte "FILE", 0     ' FILE wert aus datei lesen oder in Datei schreiben             143 182    getestet
   tok16 byte "GFILE",0     ' GETFILE rueckgabe der mit Dir gefundenen Dateien ,Dateinamen  144 152    getestet
   tok17 byte "MKDIR",0     ' Verzeichnis erstellen                                         145 206    getestet
   tok18 byte "GATTR",0     ' Dateiattribute auslesen                                       146 240    getestet
   tok19 byte "LOAD",0       'Regnatix Datei laden                                          147 218    getestet
   tok20 byte "MKFILE", 0    'Datei erzeugen                                                148 185    getestet

'************************* logische Operatoren **********************************************************************
   tok21 byte "NOT" ,0      ' NOT <logical>                                                '149 139    getestet
   tok22 byte "AND" ,0      ' <logical> AND <logical>                                      '150    getestet
   tok23 byte "OR", 0       ' <logical> OR <logical>                                       '151    getestet
'************************* mathematische Funktionen *****************************************************************
   tok24 byte "RND", 0       'Zufallszahl von x                                            '152 139    getestet
   tok25 byte "PI",0         'Kreiszahl PI                                                 '153 174    getestet
   tok26 byte "CHR$",0       'CHR$                                                          154 211    getestet
   tok27 byte "ABS",0        'Frei                                  '                       155 245    getestet
   tok28 byte "SIN",0                                                                     ' 156 246    getestet
   tok29 byte "COS",0                                                                     ' 157 247    getestet
   tok30 byte "TAN",0                                                                  '    158 248    getestet
   tok31 byte "ATN",0                                                                     ' 159 249    getestet
   tok32 byte "LN",0                                                                   '    160 250    getestet
   tok33 byte "SGN",0        'Frei                                                      '   161 251    getestet
   tok34 byte "SQR",0                                                                   '   162 252    getestet
   tok35 byte "EXP",0                                                                  '    163 253    getestet
   tok36 byte "INT",0        'Frei                                                        ' 164 254    getestet


'************************* Bildschirmbefehle ***********************************************************************
   tok37 byte "COLOUR",0    'Farbe setzen  1,2 Vordergrund,Hintergrund                      165 187    getestet
   tok38 byte "CLS",0       'Bildschirm loeschen cursor oberste Zeile Pos1                  166 188    getestet
   tok39 byte "HEX",0       'Ausgabe von Hexzahlen mit Print                              ' 167 235    getestet
   tok40 byte "BNZ",0       'Ausgabe von Binärzahlen mit Print                              168 201    getestet


'************************* Datum und Zeit funktionen ***************************************************************
   tok41 byte "STIME",0    'Stunde:Minute:Sekunde setzen ->                                 169 198    getestet
   tok42 byte "SDATE",0    'Datum setzen                                                    170 199    getestet
   tok43 byte "TIME",0     'Zeit   abfragen                                                 171 204    getestet
   tok44 byte "DATE",0     'Datum abfragen                                                  172 205    getestet
'**************************** diverse Funktionen *******************************************************************
   tok45 byte "COM",0                                                                     ' 173 243 *  getestet
   tok46 byte "SID", 0       'SID_Soundbefehle                                              174 158    getestet
   tok47 byte "PLAY", 0      'SID DMP-Player                                               '175 159    getestet
   tok48 byte "FLASH", 0     'Funktionen für Flash-Speicher                                '176 160    getestet
   tok49 byte "PORT",0       'Port-Funktionen      Port s,i,o,p                             177 207 *  getestet
   tok50 byte "JOY",0        'Joystick abfragen für 2 Joysticks                             178 183    getestet
   tok51 byte "XBUS",0       'Zugriff auf System-Funktionen                                 179 234    getestet
   tok52 byte "COGS",0        'Cog-Anzeige                                                 '180 170
   tok53 byte "PING",0       'Plexbus-Ping                                                 '181
   tok54 byte "ASC",0        'Zeichen in ASCII Code umwandeln                               182
   tok55 byte "REBOOT",0     'Hive Reboot                                                   183
'******************************************************************************************************************

'******************************************************************************************************************

   toks  word @tok0, @tok1, @tok2, @tok3, @tok4, @tok5, @tok6, @tok7
         word @tok8, @tok9, @tok10, @tok11, @tok12, @tok13, @tok14, @tok15
         word @tok16, @tok17, @tok18, @tok19, @tok20, @tok21, @tok22, @tok23
         word @tok24, @tok25, @tok26, @tok27, @tok28, @tok29, @tok30, @tok31
         word @tok32, @tok33, @tok34, @tok35, @tok36, @tok37, @tok38, @tok39
         word @tok40, @tok41, @tok42, @tok43, @tok44, @tok45, @tok46, @tok47
         word @tok48, @tok49, @tok50, @tok51, @tok52, @tok53, @tok54, @tok55

Dat '*************** Grafikparameter **************************

   GmodeLine byte 39  'Spaltenanzahl-1 der Treiber
   Gmodey byte 31     'Zeilenanzahl-1 der Treiber
   gmodexw word 320 'x-weite des Treibers
   gmodeyw word 256 'y-weite des Treibers
   gmodepicsize word 10240 'Bildgröße
   gmodeoffset word 10240 'Speicheroffset für letzte Bild-Zeile

DAT
   ext5          byte "*.*",0                                                   'alle Dateien anzeigen
   tile          byte "Tile",0                                                  'tile-Verzeichnis
   adm           byte "adm.sys",0                                               'Administra-Treiber
   bel           byte "bel.sys",0
   'errortxt      byte "errors.txt",0                                            'Error-Texte
   shelldir      byte "SHELL",0
   sysfont       byte "sysfontb.dat",0                                          'system-font

   ZShell        byte "ZSHELL for Hive",0

   windowtile byte 135,137,136,7,141,134,132,130,128,8,129,133,0,131,8,8,8      'Fenster-Tiles für WIN-Funktion im Modus 0

   name1         byte "Shell",0
   name2         byte "Zshell",0
con'****************************************** Hauptprogramm-Schleife *************************************************************************************************************
PUB main | sa

   init                                                                         'Startinitialisierung

   sa := 0                                                                      'startparameter

   repeat
      \doline(sa)                                                               'eine kommandozeile verarbeiten
      sa  := 0                                                                  'Zeile verwerfen da abgearbeitet

con'****************************************** Initialisierung *********************************************************************************************************************
PRI init |pmark,newmark,x,y,i,f

  ios.start
  ios.sdmount                                                                   'SD-Karte Mounten
  activate_dirmarker(0)                                                         'in's Rootverzeichnis
  ios.sdchdir(@shelldir)                                                        'in's Basicverzeichnis wechseln
  basicmarker:= get_dirmarker                                                   'usermarker von administra holen
  usermarker:=basicmarker

  FS.SetPrecision(6)                                                            'Präzision der Fliesskomma-Arithmetik setzen
  FL.Start
'**************************************************************************************************************************************************************
'*********************************** Startparameter ***********************************************************************************************************
'  pauseTime := 0                                                                'pause wert auf 0
  fileOpened := 0                                                               'keine datei geoeffnet
  volume:=15                                                                    'sid-cog auf volle lautstaerke
  farbe:=green                                                                 'Schreibfarbe
  hintergr:=black                                                              'Hintergrundfarbe
  farbe3:=Dark_Teal                                                             '3.Farbe
'***************************************************************************************************************************************************************

'**************************************************************************************************************************************************************

     ios.ram_fill(VERZ_NAME,$FF,0)                                                'Errortext-Speicher loeschen

     usermarker:=0
     pfadtiefe:=0                                                                   'wir beginnen im Root-Pfad

     mount
'************************** Startbildschirm ***********************************************************************************************************************************
     win:=1                                                                           'aktuelle fensternummer 1 ist das Hauptfenster

  '*************** Bildschirmaufbau ***********************************
     LoadTiletoRam(@sysfont)                                              'Logo und Font in eram laden

     loadtile                                                             'Logo und Font in den Puffer laden
     ios.window(win,farbe,hintergr,farbe3,farbe3,farbe,hintergr,farbe3,hintergr,0,0,29,39,7,0)
     ios.set_func(win,Print_Window)

     ios.printchar(12)                                                             'cls
     ios.Set_Titel_Status(win,1,@zshell)
     ios.Set_Titel_Status(win,2,string("\"))

 '*************** Logo anzeigen **************************************
     x:=y:=0
     cursor:=3                                                                        'cursormarker für Cursor on
     ios.set_func(cursor,Cursor_Set)

'*******************************************************************************************************************************************************************************
  '******************************************************************************************************************************************************
  ios.sid_resetregisters                                                           'SID Reset
  ios.sid_beep(1)
   '************ startparameter fuer Dir-Befehl *********************************************************************************************************
  dzeilen:=30
  xz     :=2
  yz     :=4
  modus  :=2                                                                       'Modus1=compact, 2=lang 0=unsichtbar
   '*****************************************************************************************************************************************************

  ADDA:=$48                                                                        'Portadressen und AD-Adresse für Sepia-Karte vorbelegen
  PORT:=$38
  ios.set_plxAdr(ADDA,PORT)

pri Mode_Ready

         repeat while ios.bus_getchar2<>88                                         'warten auf Grafiktreiber


obj '************************** Datei-Unterprogramme ******************************************************************************************************************************
con '------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
PRI ifexist(dateiname)                                                          'abfrage,ob datei schon vorhanden, wenn ja Überschreiben-Sicherheitsabfrage
   ios.printchar(13)
   mount

   if ios.sdopen("W",dateiname)==0                                              'existiert die dateischon?
      ios.print(string("File exist! Overwrite? y/n"))                           '"File exist! Overwrite? y/n"    'fragen, ob ueberschreiben
      if ios.keywait=="y"
         if ios.sddel(dateiname)                                                'wenn ja, alte Datei loeschen, bei nein ueberspringen
            close
            return 0
         ios.sdnewfile(dateiname)
         ios.sdopen("W",dateiname)
      else
          ios.printchar(13)
          return 2                                                              'datei nicht ueberschreiben
   else                                                                         'wenn die Datei noch nicht existiert
      if ios.sdnewfile(dateiname)
         close
         return 0
      ios.sdopen("W",dateiname)
   ios.printchar(13)
   return 1

PRI close
   ios.sdclose
   ios.sdunmount

PRI mount|i
     'playerstatus
     ios.sdmount
     activate_dirmarker(usermarker)
     if strsize(@workdir)>0
        if strcomp(@workdir,string("\"))                                        'ins Root-Verzeichnis
           activate_dirmarker(0)
        else
           i:=ios.sdchdir(@workdir)
           if i
              sysbeep
              ios.print(string("* Error! *"))
              ios.printnl
              return i
        usermarker:=get_dirmarker
        return 0

con '********************************** Fehler-und System-Texte in den eRam laden ****************************************************************************************************************
pri errortext
    sysbeep
    ios.print(string("* Error ! *"))
    ios.printnl
    abort

PRI sysbeep
    ios.sid_dmpstop
    ios.sid_beep(0)

con '************************************* Basic beenden **************************************************************************************************************************
PRI ende
   ios.admreset
   ios.belreset
   reboot

con'**************************************** Basic-Zeile aus dem Speicher lesen und zur Abarbeitung uebergeben ********************************************************************
PRI doline(s) | c,i,xm
   i:=0
   returnmarker:=0
   ios.print(string(">"))                                               'Promt ausgeben

   getline(0)                                                             'Zeile lesen und

   c := spaces
   tokenize                                                               'keine Programm sondern eine Kommandozeile
   if spaces
      texec                                                               'dann sofort ausfuehren

con'************************************* Basic-Zeile uebernehmen und Statustasten abfragen ***************************************************************************************
PRI getline(laenge):e | i,f, c , x,y,t,m,a                                       'zeile eingeben
   i := laenge
   f:=0'laenge
   e:=0

   repeat
'********************* Playerstatus abfragen, wenn er laeuft und am ende des Titels stoppen und SD-Card freigeben********************************
      if play:=1 and ios.sid_dmppos<20                                          'Player nach abgespielten Titel stoppen
         playerstatus
'************************************************************************************************************************************************

      c := ios.keywait
      case c

                       008:if i > 0                                             'bei backspace ein zeichen zurueck 'solange wie ein zeichen da ist
                              x:=ios.getx
                              y:=ios.gety
                              ios.printchar(8)'printbs                          'funktion backspace ausfueren
                              laenge--
                              i--
                              x--
                              if laenge=>i                                      'dies Abfrage verhindert ein einfrieren bei laenge<1
                                 bytemove(@tline[i],@tline[i+1],laenge-i)
                                 tline[laenge]:=0
                                 ios.print(@tline[i])
                                 ios.printchar(32)
                              if x<0
                                 x:=GmodeLine
                                 y--
                              if y<1
                                 y:=0
                              ios.setpos(y,x)
                              ios.printchar(2)                                  'Treiber 0 braucht das, um die Cursorposition zu aktualisieren

                       002:if i>0                                               'Pfeiltaste links
                              ios.printchar(5)'printleft
                              i--

                       003:if i < linelen-1
                              ios.printchar(6)'printright                       'Pfeiltaste rechts
                              i++

                       162,7,5:repeat while i<laenge                            'Ende,Bild runter,Cursor runter-Taste ans ende der Basiczeile springen
                                   ios.printchar(6)'printright
                                   i++
                       160,6,4:repeat i                                         'POS1,Bild hoch,Cursor hoch-Taste an den Anfang der Basic-Zeile springen
                                   ios.printchar(5)'printleft
                               i:=0
                       027:ios.printchar(13)                                    'Abbruchmarker
                           quit
                       186:'Entf
                            x:=ios.getx
                            y:=ios.gety
                            if laenge>i
                               bytemove(@tline[i],@tline[i+1],laenge-i)
                               laenge--
                               tline[laenge]:=0
                               ios.print(@tline[i])
                               ios.printchar(32)
                               ios.setpos(y,x)
                               ios.printchar(2)

'******************* Funktionstasten abfragen *************************
                       219:ende                                                 'F12 basic beenden
                       218:
                       217:
                       216:                                                     'F9
                       215:                                                     'F8
                       214:                                                     'F7

                       213:ios.Dump(0,99999,1)                                  'F6 Monitor E-Ram
                           return
                       212:ios.Dump(0,99999,0)                                  'F5 Monitor Hub-Ram
                           return

                       211:h_dir(dzeilen,2,@ext5)                               'F4 DIR aufrufen
                       210:ios.print(string("PLEX-PING"))
                           ios.printchar(13)
                           ping
                           return                                                     'F3
                       209:Getcogs                                              'F2 Cogs
                           return
                       208:'repeat a from 46 to 57                               'Funktionstastenbelegung F1
                           '   errortext'(a,0)
                           '   ios.printnl
                           'return
'**********************************************************************
                       13:Returnmarker:=1                                       'wenn return gedrueckt
                           ios.printnl
                           tline[laenge] := 0                                   'statt i->laenge, so wird immer die komplette Zeile übernommen
                           tp := @tline                                         'tp bzw tline ist die gerade eingegebene zeile
                           return
                       32..126:
                           if i < linelen-1
                              if i<laenge and laenge<linelen-1
                                 x:=ios.getx
                                 y:=ios.gety
                                 t:=0
                                 bytemove(@tline[i+1],@tline[i],laenge-i)
                                 tline[i]:=c
                                 x++
                                 laenge++
                                 tline[laenge+1]:=0
                                 ios.print(@tline[i])
                                 if y==Gmodey and (x+laenge-i-1)>GmodeLine          'scroll hoch->dann y-position -1
                                    t:=1
                                 if x>GmodeLine                                           'x>Zeilenlänge des Treibers
                                    y+=1
                                    x:=0
                                 ios.setpos(y-t,x)
                                 ios.printchar(2)
                                 i++
                              else
                                 ios.printchar(c)
                                 tline[i++] :=c
                              if i>laenge
                                 laenge:=i                                                          'laenge ist immer die aktuelle laenge der zeile

pri Getcogs|a,b,r,t

    a:=ios.admgetcogs
    b:=ios.belgetcogs
    r:=ios.reggetcogs
    t:=0
    ios.printchar(13)
    ios.print(string("COG-Belegung:"))
    ios.printchar(13)
    ios.printchar(13)
    ios.print(String("Administra "))
    CogShow(a)
    ios.printboxcolor(win,farbe,hintergr)
    ios.printdec(a)
    ios.printchar(13)
    ios.print(String("Bellatrix  "))
    CogShow(b)
    ios.printboxcolor(win,farbe,hintergr)
    ios.printdec(b)
    ios.printchar(13)
    ios.print(String("Regnatix   "))
    CogShow(r)
    ios.printboxcolor(win,farbe,hintergr)
    ios.printdec(r)
    ios.printchar(13)

pri CogShow(n)|t
    t:=0
    repeat 8

         if t<n
            ios.printboxcolor(win,green,hintergr)
         else
            ios.printboxcolor(win,red,hintergr)
         t++
         ios.printchar(15)
    ios.printchar(32)
pri systeminfo|f,b
    ios.print(string("System-Info !"))
    ios.printnl
    ios.print(string("Bellatrix :"))
    ios.printbin(ios.belgetspec,16)
    ios.printnl
    ios.print(string("Version   :"))
    ios.printbin(ios.bel_get,8)
    ios.printnl
    ios.printnl
    ios.print(string("Administra:"))
    ios.printbin(ios.admgetspec,16)
    ios.printnl
    ios.print(string("Version   :"))
    ios.printbin(ios.admgetver,8)
    ios.printnl
    ios.printnl
    getcogs
    ios.printnl
    ios.print(string("I2C-Belegung"))
    ios.printnl
    ping
    ios.printnl
    mount
    ios.print(string("SD-Card-Info   :"))
    ios.print(ios.sdvolname)
    ios.printnl
    ios.print(string("Speicher frei  :"))
    f:=ios.sdcheckfree/1024
    ios.printdec(f)
    ios.set_func(21,_setx)
    ios.print(string(" KBytes"))
    ios.printnl
    ios.print(string("Speicher belegt:"))
    b:=ios.sdcheckused/1024
    ios.printdec(b)
    ios.set_func(21,_setx)
    ios.print(string(" KBytes"))
    ios.printnl
    ios.print(string("Speicher gesamt:"))
    ios.printdec(f+b)
    ios.set_func(21,_setx)
    ios.print(string(" KBytes"))
    ios.printnl
    mount

con '****************************** Basic-Token erzeugen **************************************************************************************************************************
PRI tokenize | tok, c, at, put, state, i, j', ntoks
   at := tp
   put := tp
   state := 0
   repeat while c := byte[at]                                                   'solange Zeichen da sind schleife ausführen

      if state == 0                                                             'keine Anführungszeichen mehr, also text untersuchen
         repeat i from 0 to ntoks'ntoks-1                                         'alle Kommandos abklappern
            tok := @@toks[i] '@token'                                           'Kommandonamen einlesen
            j := 0
            repeat while byte[tok] and ((byte[tok] ^ byte[j+at]) & caseBit) == 0'zeichen werden in Grossbuchstaben konvertiert und verglichen solange 0 dann gleich
               j++
               tok++

            if byte[tok] == 0 and not isvar(byte[j+at])                         'Kommando keine Variable?
               byte[put++] := 128 + i                                           'dann wird der Token erzeugt
               at += j
               if i == 7                                                        'REM Befehl
                  state := "R"
               else
                  repeat while byte[at] == " "
                     at++
                  state := "F"
               quit
         if state == "F"
            state := 0
         else
            byte[put++] := byte[at++]
      else
         byte[put++] := byte[at++]
   byte[put] := 0                                                               'Zeile abschliessen

obj '******************************************STRINGS*****************************************************************************************************************************
con '************************************* Stringverarbeitung *********************************************************************************************************************
con '*************************************** Dateinamen extrahieren **************************************************************************************************************
PRI scanFilename(f,kennung):chars| c

   chars := 0
   repeat while (c := byte[tp++])<>kennung
      if chars++ < STR_MAX                                                      'Wert stringlänge ist wegen Stringfunktionen
           if c>96
              c^=32
         byte[f++] := c
   byte[f] := 0


PRI getstr:a|nt,b,str ,f                                                          'string in Anführungszeichen oder Array-String einlesen
    a:=0
    nt:=spaces
    bytefill(@font,0,STR_MAX)
    case nt

         32..122:
              scanfilename(@font,44)                                            'Zeichenkette bis Komma

         154: skipspaces                                                        'Chr$-Funktion
              a:=klammer(1)
              byte[@font][0]:=a
              byte[@font][1]:=0
         179: skipspaces
              Bus_Funktionen                                                    'Stringrückgabe von XBUS-Funktion

Pri Input_String
       getstr
       bytemove(@f0,@font,strsize(@font))                                       'string nach f0 kopieren

PRI clearstr
    bytefill(@font,0,STR_MAX)
    bytefill(@str0,0,STR_MAX)

PRI stringfunc(pr,v) | a7,identifier                                              'stringfunktion auswaehlen
   identifier:=0
   a7:=v

   getstr                                                                        'welche Funktion soll ausgeführt werden?

   bytemove(@str0,@font,strsize(@font))
   identifier:=spaces                                                           'welche Funktion kommt jetzt?
   stringschreiben(a7,0,@str0,pr)'-1                                          'String schreiben

PRI stringschreiben(adre,chr,strkette,pr) | c9,zaehler
    zaehler:=0

    case pr
         0:if chr>0
              ios.printchar(chr)
           else
              ios.print(strkette)

         2:ios.sdputstr(strkette)                                               'auf SD-Card schreiben
    clearstr                                                                    'stringpuffer löschen

PRI charactersUpperLower(characters,mode) '' 4 Stack Longs

'' ┌───────────────────────────────────────────────────────────────────────────┐
'' │ Wandelt die Buchstaben in Groß (mode=0) oder Klein(mode=1) um.            │
'' └───────────────────────────────────────────────────────────────────────────┘

  repeat strsize(characters--)

    result := byte[++characters]
    if mode
       if((result > 64) and (result < 91))                                      'nur A -Z in Kleinbuchstaben
          byte[characters] := (result + 32)
    else
       if(result > 96)                                                          'nur a-z in Großbuchstaben
          byte[characters] := (result - 32)

con '********************************* Befehle, welche mit Printausgaben arbeiten *************************************************************************************************
PRI factor | tok, a,b,c,d,e,g,f,fnum                                            'Hier werden nur Befehle ohne Parameter behandelt
   tok := spaces
   e:=0
   tp++

   case tok
      "(":
         a := expr(0)
         if spaces <> ")"
            errortext
         tp++
         return a

      130:'PEEK
          a:=expr(1)                                                            'adresse
          komma
          b:=expr(1)                             '1-byte, 2-word, 4-long
          return fl.ffloat(lookup(b:ios.ram_rdbyte(a),ios.ram_rdword(a),0,ios.ram_rdlong(a)))


      143: ' FILE
           return fl.ffloat(ios.sdgetc)

      178:'JOY
          a:=klammer(1)
          return fl.ffloat(ios.Joy(3+a))


      182:'asc
           klammerauf
              c:=fl.ffloat(spaces) 'Zeichen
              skipspaces
           klammerzu
           return c


      179:'Bus-Funktionen
          return Bus_Funktionen

      146:'GATTR
           a:=klammer(1)
           return fl.ffloat(ios.sdfattrib(a))


      173:'COM
           return Comfunktionen

      156:'sin
           return fl.sin(klammer(0))
      157:'cos
           return fl.cos(klammer(0))
      158:'tan
           return fl.tan(klammer(0))
      159:'ATN
           return fl.ATAN(klammer(0))
      160:'LN
           return fl.LOG(klammer(0))

      162:'SQR
           return fl.fsqr(klammer(0))
      163:'EXP
           return fl.exp(klammer(0))

'****************************ende neue befehle********************************

      "-":
          return fl.FNeg(factor)                                                 'negativwert ->factor, nicht expr(0) verwenden

      153:'Pi
          return pi

      "%","#","0".."9":
         --tp
         return getAnyNumber


      other:
           errortext


Con '******************************************* Operatoren *********************************************************************************************************************
PRI bitTerm | tok, t
   t := factor

   repeat
      tok := spaces
      if tok == "^"                                                             'Power  y^x   y hoch x entspricht y*y (x-mal)
         tp++
         t := fl.pow(t,factor)
      else
         return t

PRI term | tok, t,a
   t := bitTerm
   repeat
      tok := spaces
     if tok == "*"
           tp++
           t := fl.FMUL(t,bitTerm)                                              'Multiplikation
     elseif tok == "/"
        if byte[++tp] == "/"
           tp++
           t := fl.FMOD(t,bitTerm)                                              'Modulo
        else
           a:=bitTerm
           if a<>0
              t  :=fl.FDIV(t,a)                                                 'Division
           else
              errortext
     else
        return t

PRI arithExpr | tok, t
   t := term
   repeat
      tok := spaces
      if tok == "+"
         tp++
         t := fl.FADD(t,term)                                                   'Addition
      elseif tok == "-"
         tp++
         t := fl.FSUB(t,term)                                                   'Subtraktion
      else
         return t

PRI compare | op,a,c,left,right,oder

   a := arithExpr
   op:=left:=right:=oder:=0
   'spaces
   repeat
      c := byte[tp]

      case c
         "<": op |= 1                                   '>
              if right                                  '><
                 op|=64
              if left                                   '>>
                 op|=128
              left++
              tp++
         ">": op |= 2                                   '<
              if right                                  '<<
                 op|=64
              right++
              tp++
         "=": op |= 4
              tp++
         "|": op |= 8                                   '|
              if oder                                   '||
                 op|=32
              oder++
              tp++
         "~": op |=16
              tp++
         "&": op |=16                                   '&
              tp++
         other: quit


   case op
      0: return a
      1: return a<arithExpr
      2: return a > arithExpr
      3: return a <> arithExpr
      4: return a == arithExpr
      5: return a =< arithExpr
      6: return a => arithExpr
      8: return fl.ffloat(fl.ftrunc(a)| fl.fTrunc(arithExpr)) 'or
      16:return fl.ffloat(fl.ftrunc(a)& fl.fTrunc(arithExpr)) 'and
      17:return fl.ffloat(fl.ftrunc(a)<- fl.fTrunc(arithExpr))'rotate left
      18:return fl.ffloat(fl.ftrunc(a)-> fl.fTrunc(arithExpr))'rotate right
      40:return fl.ffloat(fl.ftrunc(a)^ fl.fTrunc(arithExpr)) 'xor
      66:return fl.ffloat(fl.ftrunc(a)>> fl.fTrunc(arithExpr))'shift right
      67:return fl.ffloat(fl.ftrunc(a)>< fl.fTrunc(arithExpr))'reverse
      129:return fl.ffloat(fl.ftrunc(a)<< fl.fTrunc(arithExpr))'shift left
      other:errortext


PRI logicNot | tok
   tok := spaces
   if tok == 149 ' NOT
      tp++
      return not compare
   return compare

PRI logicAnd | t, tok
   t := logicNot
   repeat
      tok := spaces
      if tok == 150 ' AND
         tp++
         t := t and logicNot
      else
         return t

PRI expr(mode) | tok, t
   t := logicAnd
   repeat
      tok := spaces
      if tok == 151 ' OR
         tp++
            t := t or logicAnd
      else
         if mode==1                                                             'Mode1, wenn eine Integerzahl gebraucht wird
            t:=fl.FTrunc(t)
         return t



con '***************************************** Befehlsabarbeitung ****************************************************************************************************************
PRI texec | ht, nt, restart,a,b,c,d,e,f,h,elsa,fvar,tab_typ


   bytefill(@f0,0,STR_MAX)
   restart := 1
   a:=0
   b:=0
   c:=0
   repeat while restart
      restart := 0
      ht := spaces
      if ht == 0
         return
      skipspaces

      if ht => 128

          case ht

             128: ' ? - PRINT
                a := 0
                repeat
                   nt := spaces
                   if nt ==0 or nt==":"
                      quit

                   case nt
                        154,179:stringfunc(0,0) 'Strings
                        167,168:skipspaces
                                a:=klammer(1)
                                d:=a
                                c:=1                                              'Hex-Ausgabe Standard 1 Stelle
                                e:=4                                              'Bin-Ausgabe Standard 4 Stellen
                                repeat while (b:=d/16)>0                          'Anzahl Stellen für Ausgabe berechnen
                                        c++
                                        e+=4
                                        d:=b
                                if nt==167
                                   ios.printhex(a,c)                              'Hex
                                if nt==168
                                   ios.printbin(a,e)                              'Bin
                        other:a:=tp
                              b:=spaces
                              skipspaces
                              tp:=a
                              ios.print(zahlenformat(expr(0)))

                   nt := spaces
                   case nt
                         ";": tp++
                         ",": a:=ios.getx
                              ios.set_func(a+8,set_x)
                              tp++
                         ":",0:ios.printchar(fReturn)
                               quit

             129:' Dump <adr>,ram-typ
                 param(1)
                 ios.dump(prm[0],$8000,prm[1])

             131:'POKE                                                           Poke(adresse, wert, byte;word;long)
                 param(2)
                 if prm[2]==1
                    ios.ram_wrbyte(prm[1],prm[0])
                 elseif prm[2]==2
                    ios.ram_wrword(prm[1],prm[0])
                 else
                    ios.ram_wrlong(prm[1],prm[0])

             132:'Info
                  systeminfo

             133: ' OPEN " <file> ", R/W/A
                 Input_String
                 if spaces <> ","
                    errortext
                 d:=skipspaces
                 tp++
                 mount
                 if ios.sdopen(d,@f0)
                    errortext
                 fileOpened := true

             134:'Type
                 Input_String
                 mount
                 if ios.sdopen(d,@f0)
                    errortext
                 b:=0
                 repeat
                     if c:=ios.sdeof
                        close
                        quit
                     else
                        c:=ios.sdgetc
                        ios.printqchar(c)
                        b++
                     if b == 660
                        ios.printnl
                        ios.print(string("<CONTINUE? */esc:>"))
                        if ios.keywait == 27
                           ios.printnl
                           quit
                        b:=0


             {135: ' WRITE ...
                b:=0                                                             'Marker zur Zeichenketten-Unterscheidung (String, Zahl)
                repeat
                   nt := spaces                                                  'Zeichen lesen
                   if nt == 0 or nt == ":"                                       'raus, wenn kein Zeichen mehr da ist oder Doppelpunkt auftaucht
                      quit
                   if is_string                                                  'handelt es sich um einen String?
                      input_string                                               'String einlesen
                      b:=1                                                       'es ist ein String
                      stringschreiben(0,0,@font,2)                             'Strings schreiben
                   elseif b==0                                                   'kein String, dann eine Zahl
                      stringschreiben(0,0,zahlenformat(expr(0)),2)             'Zahlenwerte schreiben
                   nt := spaces
                   case nt
                        ";": tp++                                                'Semikolon bewirkt, das keine Leerzeichen zwischen den Werten geschrieben werden
                        ",":ios.sdputc(",")                                      'Komma schreiben
                            tp++
                        0,":":ios.sdputc(fReturn)                                'ende der Zeile wird mit Doppelpunkt oder kein weiteres Zeichen markiert
                              ios.sdputc(fLinefeed)
                              quit
                        other:errortext'1,1)
                        }

             136: ' CLOSE
                fileOpened := false
                close

             137: ' DEL <file>
                Input_String
                mount
                if ios.sddel(@f0)
                   errortext
                close

             138: ' REN  <file> , <file>
                Input_String
                bytefill(@file1,32,11)
                bytemove(@file1, @f0, strsize(@f0))                              'ergebnis vom ersten scanfilename in file1 merken
                bytefill(@f0,0,STR_MAX)
                Input_String
                mount
                if ios.sdrename(@file1,@f0)                                      'rename durchfuehren
                   errortext                                                     'fehler wenn rename erfolglos
                close

             139:'CHDIR
                 Input_String
                 bytefill(@workdir,0,12)
                 bytemove(@workdir,@f0,strsize(@f0))
                 a:=mount
                 close
                 Pfadanzeige(a)
                 bytefill(@workdir,0,12)

             140: 'DIR
                 Input_String
                 charactersUpperLower(@f0,0)                                 'in Großbuchstaben umwandeln
                 h_dir(dzeilen,2,@f0)
                 ifnot b
                      h_dir(dzeilen,2,@ext5)                                 'directory ohne parameter nur anzeigen

             141:'Aload
                  Input_String
                  bytemove(@f0[strsize(@f0)],string(".ADM"),4)
                  'ios.print(@f0)
                  mount
                  if ios.sdopen("R",@f0)
                     errortext
                  ios.admload(@f0)

             142:'BLOAD
                  Input_String
                  bytemove(@f0[strsize(@f0)],string(".BEL"),4)
                  'ios.print(@f0)
                  mount
                  if ios.sdopen("R",@f0)
                     errortext
                  ios.belload(@f0)

             145:'MKDIR
                 input_string
                 mount
                 if ios.sdnewdir(@f0)
                    errortext
                 close

             147:'RLOAD
                  Input_String
                  'bytemove(@f0[strsize(@f0)],string(".BIN"),4)
                  'ios.print(@f0)
                  mount
                  if ios.sdopen("R",@f0)
                     errortext
                  ios.ldbin(@f0)

             148:'MKFILE    Datei erzeugen
                 Input_String
                 mount
                 if ios.sdnewfile(@f0)
                    errortext
                 close

             165:'Colour <vordergr>,<hintergr>,<3.Color>(opt)
                 farbe:=expr(1)&255
                 komma
                 hintergr:=expr(1)&255
                 komma
                 farbe3:=expr(1)&255
                 ios.printboxcolor(win,farbe,hintergr)
                 ios.window(win,farbe,hintergr,farbe3,farbe3,farbe,hintergr,farbe3,white,0,0,29,39,7,0)
                 ios.Set_Titel_Status(win,1,@zshell)
                 Pfadname


             166: 'CLS
                 ios.printchar(12)

             169:'stime
                a:=expr(1)
                is_spaces(":",1)
                b:=expr(1)
                is_spaces(":",1)
                c:=expr(1)
                    ios.setHours(a)
                    ios.setMinutes(b)
                    ios.setSeconds(c)

             170:'sdate
                 param(3)
                 ios.setDate(prm[0])
                 ios.setMonth(prm[1])
                 ios.setYear(prm[2])
                 ios.setDay(prm[3])

             171:ios.time                                              'Time-Ausgabe
                     quit
             172:ios.gdate
                     quit
             173:'COM
                 Comfunktionen
             176:'Flash_Funktionen

             175:'PLAY
                   'if is_string
                   input_string
                   mount
                   if ios.sdopen("R",@f0)
                      errortext
                   play:=1
                   ios.sid_sdmpplay(@f0)                                      'DMP-File abspielen
                   if spaces == "0"
                          playerstatus'ios.sid_dmpstop
                          play:=0
                          close
                   elseif spaces == "1"
                          ios. sid_dmppause
             177:'PORT
                 Port_Funktionen
             179:'XBUS-Funktionen
                  BUS_Funktionen

             180:'COGS
                  GetCogs

             181:'PING
                 ping

             183:'Reboot
                 ende

      else
          errortext
      if spaces == ":"                                                          'existiert in der selben zeile noch ein befehl, dann von vorn
         restart := 1
         tp++

pri Pfadanzeige(fehler)|c,i,f,adr

ifnot fehler
    if strcomp(@workdir,string(".."))
       pfadtiefe--

    elseif strcomp(@workdir,string("\"))
       pfadtiefe:=0
    else
       f:=strsize(@workdir)
       adr:=VERZ_NAME+(12*pfadtiefe)
       i:=0
       repeat f                                                                 'String aus Data-Puffer lesen
              c:=byte[@workdir][i++]
              ios.ram_wrbyte(c,adr++)                                           'und nach String-Array schreiben
       ios.ram_wrbyte(0,adr++)                                                  'Null-string-Abschluss
       pfadtiefe++
    Pfadname
pri Pfadname|adr,i,f,c
    adr:=VERZ_NAME
    i:=0
    f:=0
    byte[@str0][f++]:=Backslash                                                 'erster und folgender Backslash

    repeat pfadtiefe
           repeat while (c:=ios.ram_rdbyte(adr++))
                 byte[@str0][f++]:=c
           byte[@str0][f++]:=Backslash
           i++
           adr:=VERZ_NAME+(12*i)
    byte[@str0][f]:=0
    ios.Set_Titel_Status(win,2,string("                                      "))
    ios.Set_Titel_Status(win,2,@str0)

con'***************************************************** XBUS-Funktionen *******************************************************************************************************
PRI BUS_Funktionen |pr,a,b,c,h,r,str,s

    pr:=0                                                                       'pr gibt zurück, ob es sich beim Rückgabewert um einen String oder eine Variable handelt, für die Printausgabe
    klammerauf
    a:=expr(1)                                                                  'Chipnummer (1-Administra,2-Bella,3-Venatrix)
    komma
    r:=expr(1)                                                                  'wird ein Rückgabewert erwartet? 0=nein 1=char 4=long 3=string
    s:=0
                 repeat
                      komma
                      if is_string
                         Input_String
                         s:=1
                      else
                           b:=expr(1)                                           'Kommando bzw Wert
                           if b>255
                              case a
                                   1:ios.bus_putlong1(b)
                                   2:ios.bus_putlong2(b)
                           else
                              case a
                                   1:ios.bus_putchar1(b)
                                   2:ios.bus_putchar2(b)

                      if s==1
                         lookup(a:ios.bus_putstr1(@f0),ios.bus_putstr2(@f0))
                         s:=0

                      if spaces==")"
                         quit

                 skipspaces

                 case r
                     0:pr:=0
                       bytefill(@font,0,STR_MAX)
                       bytefill(@f0,0,STR_MAX)
                       return
                     1:c:=lookup(a:ios.bus_getchar1,ios.bus_getchar2)
                     4:c:=lookup(a:ios.bus_getlong1,ios.bus_getlong2)
                     3:if a==1
                          str:=ios.bus_getstr1
                       bytemove(@font,str,strsize(str))
                       pr:=1
    if r==1 or r==4
       h:=fl.ffloat(c)
       str:=fs.floattostring(h)                                                 'Stringumwandlung für die Printausgabe
       bytemove(@font,str,strsize(str))
       return h


con'******************************************** Port-Funktionen der Sepia-Karte *************************************************************************************************
PRI PORT_Funktionen|function,a,b,c,x,y
    function:=spaces&caseBit
    skipspaces
    klammerauf
    a:=expr(1)                                                                  'Adresse bzw.ADDA Adresse
        case function
            "O"    :komma
                    b:=expr(1)                                                  'Byte-Wert, der gesetzt werden soll
                    klammerzu
                    if a<4 or a>6                                               'nur Digital-Port-Register können für die Ausgabe gesetzt werden
                       errortext
                    c:=a-4                                                      'Portadresse generieren
                    a:=c+PORT                                                   'Port 4=Adresse+0 Port5=Adresse+1 usw. da nur Register 4-6 Ausgaberegister sind
                    ios.plxOut(a,b)                                             'wenn a=4 dann 28+4=32 entspricht Adresse$20 von Digital-Port1


            "S"    :'Port Set                                                   '*Adressen zuweisen
                     komma
                     b:=expr(1)                                                 '*Port-Adresse zuweisen
                     ADDA:=a
                     PORT:=b
                     klammerzu
                     ios.set_plxAdr(ADDA,PORT)

            "I"    : klammerzu
                     ios.clearkey
                     x:=ios.getx
                     y:=ios.gety
                     ios.set_func(0,Cursor_Set)
                     repeat
                       ios.setpos(y,x)

                       ios.printbin(ios.getreg(a),8)
                       ios.printchar(32)
                       ios.printHex(ios.getreg(a),2)
                       ios.printchar(32)
                       ios.printdec(ios.getreg(a))
                       if ios.key==27
                          ios.set_func(cursor,Cursor_Set)
                          quit
            other:
                   errortext
pri ping|i,a,x,y,yt,n
    repeat i from 0 to 128
             ios.plxHalt
             a:=ios.plxping(i)
             ios.plxrun

             ifnot a
                ios.printchar("#")
                ios.printhex(i,2)
                ios.printchar(32)
                ios.printdec(i)
                ios.printchar(13)

con'********************************************* serielle Schnittstellen-Funktionen *********************************************************************************************
PRI Comfunktionen|function,a,b
    function:=spaces&CaseBit
    skipspaces
        case function
            "S"    :klammerauf
                    a:=expr(1)                                                  'serielle Schnittstelle öffnen/schliessen
                    if a==1
                       komma                                                    'wenn öffnen, dann Baudrate angeben
                       b:=expr(1)
                       ios.seropen(b)
                    elseif a==0                                                 'Schnittstelle schliessen
                       ios.serclose
                    else
                       errortext
                    klammerzu

            "G"    :'COM G                                                      'Byte von ser.Schnittstelle lesen ohne warten
                    return fl.ffloat(ios.serread)
            "R"    :'COM R                                                      'Byte von ser.Schnittstelle lesen mit warten
                    return fl.ffloat(ios.serget)
            "T"    :klammerauf
                    getstr
                    ios.serstr(@font)
                    klammerzu
            other:
                   errortext


con '******************************************* diverse Unterprogramme ***********************************************************************************************************
PRI spaces | c                                                                  'Zeichen lesen
   'einzelnes zeichen lesen
   repeat
      c := byte[tp]
      if c == 0 or c > " "
         return c
      tp++

PRI skipspaces                                                                  'Zeichen überspringen
   if byte[tp]
      tp++
   return spaces

PRI parseliteral | r, c                                                         'extrahiere Zahlen aus der Basiczeile
   r := 0
   repeat
      c := byte[tp]
      if c < "0" or c > "9"
         return r
      r := r * 10 + c - "0"
      tp++

PRI fixvar(c)                                                                   'wandelt variablennamen in Zahl um (z.Bsp. a -> 0)
   c&=caseBit
   return c - "A"

PRI isvar(c)                                                                    'Ueberpruefung ob Variable im gueltigen Bereich
   c := fixvar(c)
   return c => 0 and c < 26

pri fixnum(c)
    if c=>"0" and c=<"9"
       c-= 47
    return c

pri isnum(c)
    c:=fixnum(c)
    return c=>1 and c<11

PRI playerstatus
       ios.sid_dmpstop
       ios.sid_resetregisters
       play:=0
       close

PRI param(anzahl)|i
    i:=0
    repeat anzahl
        prm[i++]:=expr(1)                                                       'parameter mit kommatrennung
        komma
    prm[i++]:=expr(1)                                                           'letzter Parameter ohne skipspaces

pri is_string |b,c                                                                  'auf String überprüfen
    result:=0
    b:=tp
    c:=spaces
    c:=spaces
    tp:=b

    case c
          point,quote,"$",144:result:=1

PRI komma
    is_spaces(",",1)

PRI is_spaces(zeichen,t)
    if spaces <> zeichen
       errortext
    else
       skipspaces

PRI dollar
    if spaces=="$"
       skipspaces
       return 1

PRI klammer(m):b
         if spaces=="("
            skipspaces
            if m
               b:=expr(1)
            else
               b:=expr(0)
            if spaces<>")"
               errortext
            skipspaces
         else
            errortext

PRI klammerauf
    is_spaces(40,1)

PRI klammerzu
    is_spaces(41,1)

PRI getAnyNumber | c, t,i,punktmerker,d,zahl[20]

   case c := byte[tp]


      "#":
         c := byte[++tp]
         if (t := hexDigit(c)) < 0
            errortext                                                            '("invalid hex character")
         result := t
         c := byte[++tp]
         repeat until (t := hexDigit(c)) < 0
            result := result << 4 | t
            c := byte[++tp]
         result:=fl.FFLOAT(result)

      "%":
         c := byte[++tp]
         if not (c == "0" or c == "1")
            errortext                                                            '("invalid binary character")
         result := c - "0"
         c := byte[++tp]
         repeat while c == "0" or c == "1"
            result := result << 1 | (c - "0")
            c := byte[++tp]
         result:=fl.FFLOAT(result)

      "0".."9":
          i:=0
          punktmerker:=0
          c:=byte[tp++]
          repeat while c=="." or c=="e" or c=="E" or (c => "0" and c =< "9")    'Zahlen mit oder ohne punkt und Exponent
                 if c==point
                    punktmerker++
                 if punktmerker>1                                               'mehr als ein punkt
                    errortext                                                   'Syntaxfehler ausgeben
                 if c=="e" or c=="E"
                    d:=byte[tp++]
                    if d=="+" or d=="-"
                       byte[@zahl][i++]:=c
                       byte[@zahl][i++]:=d
                       c:=byte[tp++]
                       next
                 byte[@zahl][i++]:=c
                 c:=byte[tp++]
          byte[@zahl][i]:=0
          result:=fs.StringToFloat(@zahl)
          --tp

      other:
           errortext                                                           '("invalid literal value")

PRI hexDigit(c)
'' Convert hexadecimal character to the corresponding value or -1 if invalid.
   if c => "0" and c =< "9"
      return c - "0"
   if c => "A" and c =< "F"
      return c - "A" + 10
   if c => "a" and c =< "f"
      return c - "a" + 10
   return -1

pri zahlenformat(h)|j
    j:=fl.ftrunc(h)
       if (j>MAX_EXP) or (j<MIN_EXP)                                            'Zahlen >999999 oder <-999999  werden in Exponenschreibweise dargestellt
           return FS.FloatToScientific(h)                                       'Zahlenwerte mit Exponent
       else
           return FS.FloatToString(h)                                           'Zahlenwerte ohne Exponent

con '****************************************** Directory-Anzeige-Funktion *******************************************************************************************************
PRI h_dir(z,modes,str) | stradr,n,i,dlen,dd,mm,jj,xstart,dr,ad,ps                 'hive: verzeichnis anzeigen
{{h_dir - anzeige verzeichnis}}                                                 'mode 0=keine Anzeige,mode 1=einfache Anzeige, mode 2=erweiterte Anzeige
  ios.set_func(0,Cursor_Set)                                                    'cursor ausschalten
  ios.printnl                                                                   'Leerzeile
  mount
  xstart:=ios.getx                                                              'Initial-X-Wert
  if strsize(str)<3
     str:=@ext5                                                                 'wenn kein string uebergeben wird, alle Dateien anzeigen
  else
     repeat 3                                                                   'alle Zeichen von STR in Großbuchstaben umwandeln
        if byte[str][i]>96
           byte[str][i]^=32
        i++

  ios.sddir                                                                     'kommando: verzeichnis öffnen
  n := 0                                                                        'dateizaehler
  i := 0                                                                        'zeilenzaehler
 repeat  while (stradr:=ios.sdnext)<>0                                          'wiederholen solange stradr <> 0


    dlen:=ios.sdfattrib(0)                                                      'dateigroesse
    dd:=ios.sdfattrib(10)                                                       'Aenderungsdatum tag
    mm:=ios.sdfattrib(11)                                                       'Aenderungsdatum monat
    jj:=ios.sdfattrib(12)                                                       'Aenderungsdatum Jahr
    dr:=ios.sdfattrib(19)                                                       'Verzeichnis?

      scanstr(stradr,1)                                                         'dateierweiterung extrahieren

      ifnot ios.sdfattrib(17)                                                   'unsichtbare Dateien ausblenden
        if strcomp(@buff,str) or strcomp(str,@ext5)                             'Filter anwenden
             n++

          '################## Bildschrirmausgabe ##################################
           if modes>0                                                           'wenn Verzeichnis,dann andere Farbe
               if dr
                  ios.printBoxColor(win,farbe+8,hintergr)
               ios.print(stradr)

               if modes==2
                  erweitert(xstart,dlen,dd,mm,jj)
               ios.printnl
               ios.set_func(xstart,set_x)
               i++
               ios.printBoxColor(win,farbe,hintergr)                           'wieder Standardfarben setzen
               if i==z                                                             '**********************************

                  if ios.keywait == ios#CHAR_ESC                                   'auf Taste warten, wenn ESC dann Ausstieg

                     ios.set_func(cursor,Cursor_Set)                               '**********************************
                     close                                                         '**********************************
                     filenumber:=n                                                 'Anzal der Dateien merken
                     abort                                                        '**********************************

                 i := 0                                                           '**********************************
                 ios.set_func(xstart,set_x)

 if modes                                                                         'sichtbare Ausgabe
    ios.printnl
    ios.printdec(n)                                                               'Anzahl Dateien
    ios.print(string(" Files"))
    ios.printnl
    n:=ios.sdcheckfree
    i:=ios.sdcheckused
    ios.printdec(i/1024)
    ad:=i*100/(i+n)
    ios.print(string( " Kb used ("))
    ios.printdec(ad)
    ios.print(string("%),"))
    ios.printdec(n/1024)
    ios.print(string( " Kb free"))
    ios.printnl
    ios.printdec((i+n)/1024)
    ios.print(string( " Kb total "))
    ios.printnl

 ios.set_func(cursor,Cursor_Set)
 filenumber:=n                                                                    'Anzal der Dateien merken
 close                                                                            'ins Root Verzeichnis ,SD-Card schliessen und unmounten
 abort

PRI erweitert(startx,laenge,tag,monat,jahr)                               'erweiterte Dateianzeige

         ios.set_func(startx+14,set_x)
         ios.printdec(laenge)
         ios.set_func(startx+21,set_x)
         ios.printdec(tag)
         ios.set_func(startx+24,set_x)
         ios.printdec(monat)
         ios.set_func(startx+27,set_x)
         ios.printdec(jahr)

PRI scanstr(f,mode) | z ,c                                                      'Dateiendung extrahieren
   if mode==1
      repeat while strsize(f)
             if c:=byte[f++] == point                                           'bis punkt springen
                quit
   z:=0
   repeat 3                                                                     'dateiendung lesen
        c:=byte[f++]
        buff[z++] := c
   buff[z++] := 0
   return @buff

PRI activate_dirmarker(mark)                                                    'USER-Marker setzen

     ios.sddmput(ios#DM_USER,mark)                                              'usermarker wieder in administra setzen
     ios.sddmact(ios#DM_USER)                                                   'u-marker aktivieren

PRI get_dirmarker:dm                                                            'USER-Marker lesen

    ios.sddmset(ios#DM_USER)
    dm:=ios.sddmget(ios#DM_USER)

con '********************************* Unterprogramme zur Tile-Verwaltung *********************************************************************************************************
PRI Win_Set_Tiles|i,a                                                           'Tiles, aus denen die Fenster bestehen, in den Ram schreiben
    i:=WTILE_RAM
    a:=0
    repeat 18
           ios.ram_wrbyte(windowtile[a++],i++)                                  'Standard-Wintiles in den Ram schreiben
    ios.windel(9,0,WTILE_RAM)                                                   'alle Fensterparameter löschen und Win Tiles senden

PRI LoadTiletoRam(datei)|adress ,count                       'tile:=tilenr,dateiname,xtile-zahl,ytilezahl

    count:=16*11*64                                                       'anzahl zu ladender Bytes (16*11*16*4=11264)
    adress:=TILE_RAM                                                            'naechster Tilebereich immer 2816 longs (11264 Bytes) 14 Tilesets moeglich Tileset15 ist der Systemfont
    mount
    activate_dirmarker(basicmarker)                                             'ins Basic Stammverzeichnis
    ios.sdchdir(@tile)                                                          'ins tile verzeichnis wechseln
    ios.sdopen("R",datei)                                                        'datei öffnen
    ios.sdxgetblk(adress,count)                                                 'datei in den Speicher schreiben  (der blockbefehl ist viel schneller als der char-Befehl)
    close

PRI loadtile|anzahl,adress                                             'tileset aus eram in bella laden
    Win_Set_Tiles
    adress:=TILE_RAM                                                            'naechster Tilebereich immer 2816 longs (11264 Bytes) 14 Tilesets moeglich
    anzahl:=2816 '(xtiles*ytiles*64)/4                                          'anzahl tilebloecke in long
    ios.loadtilebuffer(adress,anzahl)                                           'laden

DAT

{{
                            TERMS OF USE: MIT License

 Permission is hereby granted, free of charge, to any person obtaining a copy
 of this software and associated documentation files (the "Software"), to deal
 in the Software without restriction, including without limitation the rights
 to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the Software is
 furnished to do so, subject to the following conditions:

 The above copyright notice and this permission notice shall be included in
 all copies or substantial portions of the Software.

 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, exprESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,ARISING FROM,
 OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 THE SOFTWARE.
}}
