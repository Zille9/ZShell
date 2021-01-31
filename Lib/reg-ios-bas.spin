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
Name            : [I]nput-[O]utput-[S]ystem - System-API
Chip            : Regnatix
Typ             : Objekt
Version         : 01
Subversion      : 1
Funktion        : System-API - Schnittstelle der Anwendungen zu allen Systemfunktionen

Regnatix
                  system        : Systemübergreifende Routinen
                  loader        : Routinen um BIN-Dateien zu laden
                  ramdisk       : Strukturierte Speicherverwaltung: Ramdisk
                  eram          : Einfache Speicherverwaltung: Usermem
                  bus           : Kommunikation zu Administra und Bellatrix

Administra
                  sd-card       : FAT16 Dateisystem auf SD-Card
                  scr           : Screeninterface
                  hss           : Hydra-Soundsystem
                  sfx           : Sound-FX

Bellatrix
                  key           : Keyboardroutinen
                  screen        : Bildschirmsteuerung
                  g0            : grafikmodus 0,TV-Modus 256 x 192 Pixel, Vektorengine

Venatrix          diverse Buserweiterungen


Komponenten     : -
COG's           : -
Logbuch         :

13-03-2009-dr235  - string für parameterübergabe zwischen programmen im eram eingerichtet
19-11-2008-dr235  - erste version aus dem ispin-projekt extrahiert
26-03-2010-dr235  - errormeldungen entfernt (mount)
05-08-2010-dr235  - speicherverwaltung für eram eingefügt
18-09-2010-dr235  - fehler in bus_init behoben: erste eram-zelle wurde gelöscht durch falsche initialisierung
25-11-2011-dr235  - funktionsset für grafikmodus 0 eingefügt
28-11-2011-dr235  - sfx_keyoff, sfx_stop eingefügt
01-12-2011-dr235  - printq zugefügt: ausgabe einer zeichenkette ohne steuerzeichen
25-01-2012-dr235  - korrektur char_ter_bs
15-09-2013-zille9 - erste Venatrix-Routinen bus_getchar3 und bus_putchar3 ,put/getword,long hinzugefügt

'######################## Besonderheiten HIVE-MAX ######################################################

29-07-2019-zille9 - offensichtlich durch ungünstiges PCB-Layout (Laufzeitfehler?) kam es in den Routinen bus_getchar1 und bus_putchar1 zu Lesefehlern
                  - von SD-Karte (Administra)mit einhergehender Zerstörung der Directory Einträge.
                  - Der Fehler wurde durch eine Repeatschleife innerhalb der Routinen (putchar1 und getchar1)offensichtlich behoben
                  - Welche der beiden Routinen der Fehlerverursacher war, muss noch erforscht werden

                  - Es ist die Routine bus_putchar1, offensichtlich waren die Pegel auf dem Bus nicht stabil genug, um richtig gelesen zu werden
                  - Glücklicherweise gibt es fühlbar keine Geschwindigkeitseinbuße


Notizen         :

 --------------------------------------------------------------------------------------------------------- }}

CON 'Signaldefinitionen
'signaldefinition regnatix
#0,     D0,D1,D2,D3,D4,D5,D6,D7                         'datenbus
#8,     A0,A1,A2,A3,A4,A5,A6,A7,A8,A9,A10               'adressbus
#19,    REG_RAM1,REG_RAM2                               'selektionssignale rambank 1 und 2
#21,    REG_PROP1,REG_PROP2                             'selektionssignale für administra und bellatrix
#23,    REG_AL                                          'strobesignal für adresslatch
#24,    REG_AL2                                         'Funktions-Latch-Strobesignal
        BUSCLK                                          'bustakt
        BUS_WR                                          '/wr - schreibsignal
        BUS_HS '                                        '/hs - quittungssignal

CON 'Zeichencodes
'zeichencodes
CHAR_RETURN     = $0D                                   'eingabezeichen
CHAR_NL         = $0D                                   'newline
CHAR_SPACE      = $20                                   'leerzeichen
CHAR_BS         = $08                                   'tastaturcode backspace
CHAR_TER_BS     = $08                                   'terminalcode backspace
CHAR_ESC        = $1B
CHAR_LEFT       = $02
CHAR_RIGHT      = $03
CHAR_UP         = $0B
CHAR_DOWN       = $0A
KEY_CTRL        = $02
KEY_ALT         = $04
KEY_OS          = $08

CON 'Systemvariablen
'systemvariablen
LOADERPTR       = $0FFFFB       '4 Byte                 'Zeiger auf Loader-Register im hRAM
MAGIC           = $0FFFFA       '1 Byte                 'Warmstartflag
SIFLAG          = $0FFFF9       '1 byte                 'Screeninit-Flag
BELDRIVE        = $0FFFED       '12 Byte                'Dateiname aktueller Grafiktreiber
PARAM           = $0FFFAD       '64 Byte                'Parameterstring
RAMDRV          = $0FFFAC       '1 Byte                 'Ramdrive-Flag
RAMEND          = $0FFFA8       '4 Byte                 'Zeiger auf oberstes freies Byte (einfache Speicherverwaltung)
RAMBAS          = $0FFFA4       '4 Byte                 'Zeiger auf unterstes freies Byte (einfache Speicherverwaltung)

SYSVAR          = $0FFFA3                               'Adresse des obersten freien Bytes, darüber folgen Systemvariablen

CON 'Sonstiges
'CNT_HBEAT       = 5_000_0000                            'blinkgeschw. front-led
DB_IN           = %00000110_11111111_11111111_00000000  'maske: dbus-eingabe
DB_OUT          = %00000110_11111111_11111111_11111111  'maske: dbus-ausgabe

OS_TIBLEN       = 64                                    'größe des inputbuffers
ERAM            = 1024 * 512 * 2                        'größe eram
HRAM            = 1024 * 32                             'größe hram

RMON_ZEILEN     = 16                                    'speichermonitor - angezeigte zeilen
RMON_BYTES      = 8                                     'speichermonitor - zeichen pro byte

STRCOUNT        = 64                                    'größe des stringpuffers

CON 'ADMINISTRA-FUNKTIONEN --------------------------------------------------------------------------



'dateiattribute
#0,     F_SIZE
        F_CRDAY
        F_CRMONTH
        F_CRYEAR
        F_CRSEC
        F_CRMIN
        F_CRHOUR
        F_ADAY
        F_AMONTH
        F_AYEAR
        F_CDAY
        F_CMONTH
        F_CYEAR
        F_CSEC
        F_CMIN
        F_CHOUR
        F_READONLY
        F_HIDDEN
        F_SYSTEM
        F_DIR
        F_ARCHIV
'dir-marker
#0,     DM_ROOT
        DM_SYSTEM
        DM_USER
        DM_A
        DM_B
        DM_C



CON 'BELLATRIX-FUNKTIONEN --------------------------------------------------------------------------

' einzeichen-steuercodes

#$0,    BEL_CMD              'esc-code für zweizeichen-steuersequenzen
        BEL_LEFT
        BEL_HOME
        BEL_POS1
        BEL_CURON
        BEL_CUROFF
        BEL_SCRLUP
        BEL_SCRLDOWN
        BEL_BS
        BEL_TAB

' zweizeichen-steuersequenzen
' [BEL_CMD][...]
{
#$1,    BEL_KEY_STAT
        BEL_KEY_CODE
        BEL_DPL_SETY'SCRCMD           'esc-code für dreizeichen-sequenzen
        BEL_KEY_SPEC
        BEL_DPL_MOUSE
        BEL_SCR_CHAR
        BEL_BLKTRANS
        BEL_DPL_SETX
        BEL_LD_MOUSEBOUND
        BEL_MOUSEX
        BEL_MOUSEY
        BEL_MOUSEZ
        BEL_MOUSE_PRESENT
        BEL_MOUSE_BUTTON
        BEL_BOXSIZE
        BEL_GETLINELEN
        BEL_CURSORRATE
        BEL_BOXCOLOR
        BEL_ERS_3DBUTTON
        BEL_SCOLLUP
        BEL_SCOLLDOWN
        BEL_DPL_3DBOX
        BEL_DPL_3DFRAME
        BEL_DPL_2DBOX
        BEL_Send_BUTTON
        BEL_SCROLLSTRING
        BEL_DPL_STRING
        BEL_DPL_SETXalt
        BEL_DPL_SETYalt
        BEL_LD_MOUSEPOINTER
        BEL_DPL_SETPOS
        BEL_DPL_TILE
        BEL_DPL_WIN
        BEL_DPL_TCOL
        BEL_LD_TILESET
        BEL_DPL_PIC
        BEL_GETX
        BEL_GETY
        BEL_DPL_LINE
        BEL_DPL_PIXEL
        BEL_SPRITE_PARAM
        BEL_SPRITE_POS
        BEL_ACTOR
        BEL_ACTORPOS
        BEL_ACT_KEY
        BEL_SPRITE_RESET
        BEL_SPRITE_MOVE
        BEL_SPRITE_SPEED
        BEL_GET_COLLISION
        BEL_GET_ACTOR_POS
        BEL_SEND_BLOCK
        BEL_FIRE_PARAM
        BEL_FIRE
        BEL_DPL_PALETTE
        BEL_DEL_WINDOW
        BEL_SET_TITELSTATUS
        BEL_BACK
        Bel_REST
        BEL_WINDOW
        BEL_GET_WINDOW
        BEL_CHANGE_BACKUP
        BEL_PRINTFONT
        BEL_PUT



#$50,   BMGR_WIN_DEFINE
        BMGR_FREI
        BMGR_WIN_SET
        BMGR_FREI2
        BMGR_WIN_GETCOLS
        BMGR_WIN_GETROWS
        BMGR_WIN_OFRAME
        BMGR_LOAD
        BMGR_WSCR
        BMGR_DSCR
        BMGR_GETCOLOR
        BMGR_SETCOLOR
        BMGR_GETRESX
        BMGR_GETRESY
        BMGR_GETCOLS
        BMGR_GETROWS
        BMGR_GETCOGS
        BMGR_GETSPEC
        BMGR_GETVER
        BMGR_REBOOT
}
' dreizeichen-steuersequenzen
' [BEL_CMD][BEL_SCRCMD][...]

#$1,    BEL_SETCUR
        BEL_SETX
        BEL_SETY
        BEL_GETXalt
        BEL_GETYalt
        BEL_SETCOL
        BEL_SLINE
        BEL_ELINE
        BEL_SINIT
        BEL_TABSET

CON 'Venatrix-Funktionen -------------------------------------
#$0,    VEN_CMD
#96,    VEN_GETCGS
        VEN_LOAD
        VEN_GETVER
        VEN_REBOOT

#220,   VEN_PORT_RESET
        VEN_PORT_WR
        VEN_PORT_RD
        VEN_JOYSTICK

'                   +----------
'                   |  +------- system     
'                   |  |  +---- version    (änderungen)
'                   |  |  |  +- subversion (hinzufügungen)
CHIP_VER        = $00_01_01_01
'
'                                           +---------- 
'                                           | +-------- 
'                                           | |+------- 
'                                           | ||+------ 
'                                           | |||+----- 
'                                           | ||||+---- 
'                                           | |||||+--- 
'                                           | ||||||+-- multi
'                                           | |||||||+- loader
CHIP_SPEC       = %00000000_00000000_00000000_00000001
{
LIGHTBLUE       = 0
YELLOW          = 1
RED             = 2
GREEN           = 3
BLUE_REVERSE    = 4
WHITE           = 5
RED_INVERSE     = 6
MAGENTA         = 7
}
' konstante parameter für die sidcog's
{
scog_pal        = 985248.0
scog_ntsc       = 1022727.0
scog_maxf       = 1031000.0
scog_triangle   = 16
scog_saw        = 32
scog_square     = 64
scog_noise      = 128
}
obj
    ram_rw :"ram"
    ser    :"RS232_ComEngine"
    gc     :"glob-con"

VAR
        long lflagadr                                   'adresse des loaderflag
        byte strpuffer[STRCOUNT]                        'stringpuffer
        byte tmptime
        byte serial                                     'serielle Schnittstelle geöffnet?
        byte parapos
        'byte big_font

PUB start: wflag                                    'system: ios initialisieren
''funktionsgruppe               : system
''funktion                      : ios initialisieren
''eingabe                       : -
''ausgabe                       : wflag - 0: kaltstart
''                              :         1: warmstart
''busprotokoll                  : -

  bus_init                                              'bus initialisieren
  ram_rw.start                                          'Ram-Treiber starten

  serial:=0                                             'serielle Schnittstelle geschlossen

  sddmact(DM_USER)                                      'wieder in userverzeichnis wechseln
  lflagadr := ram_rdlong(LOADERPTR)                     'adresse der loader-register setzen
  
  if ram_rdbyte(MAGIC) == 235
    'warmstart
    wflag := 1

  else
    'kaltstart
    ram_wrbyte(235,MAGIC)
    wflag := 0
    ram_wrbyte(0,RAMDRV)                         'Ramdrive ist abgeschaltet

PUB stop                                                'loader: beendet anwendung und startet os
''funktionsgruppe               : system
''funktion                      : beendet die laufende  anwendung und kehrt zum os (reg.sys) zurück
''eingabe                       : -
''ausgabe                       : -
''busprotokoll                  : -
  ram_rw.stop
  ser.stop
  'sd_mount
  sddmact(DM_ROOT)
  admreset
  belreset
  'sdopen("r",@regsys)
  'ldbin(@regsys)
  'repeat
   reboot
PUB paraset(stradr) | i,c                               'system: parameter --> eram
''funktionsgruppe               : system
''funktion                      : parameter --> eram - werden programme mit dem systemloader gestartet, so kann
''                              : mit dieser funktion ein parameterstring im eram übergeben werden. das gestartete
''                              : programm kann diesen dann mit "parastart" & "paranext" auslesen und verwenden
''eingabe                       : -
''ausgabe                       : stradr - adresse des parameterstrings
''busprotokoll                  : -

  paradel                                               'parameterbereich löschen
  repeat i from 0 to 63                                 'puffer ist mx. 64 zeichen lang
    c := byte[stradr+i]
    ram_wrbyte(c,PARAM+i)
    if c == 0                                           'bei stringende vorzeitig beenden
      return

pub paracopy(adr)|i,c
  paradel                                               'parameterbereich löschen
  repeat i from 0 to 63                                 'puffer ist mx. 64 zeichen lang
    c := ram_rdbyte(adr++)
    ram_wrbyte(c,PARAM+i)
    if c == 0                                           'bei stringende vorzeitig beenden
      return
PUB paradel | i                                         'system: parameterbereich löschen
''funktionsgruppe               : system
''funktion                      : parameterbereich im eram löschen
''eingabe                       : -
''ausgabe                       : -
''busprotokoll                  : -

  repeat i from 0 to 63
    ram_wrbyte(0,PARAM+i)

PUB parastart                                           'system: setzt den zeiger auf parameteranfangsposition
''funktionsgruppe               : system
''funktion                      : setzt den index auf die parameteranfangsposition
''eingabe                       : -
''ausgabe                       : -
''busprotokoll                  : -

  parapos := 0

PUB paranext(stradr): err | i,c                         'system: überträgt den nächsten parameter in stringdatei
''funktionsgruppe               : system
''funktion                      : überträgt den nächsten parameter in stringdatei
''eingabe                       : stradr - adresse einer stringvariable für den nächsten parameter
''ausgabe                       : err - 0: kein weiterer parameter
''                              :       1: parameter gültig
''busprotokoll                  : -

  if ram_rdbyte(PARAM+parapos) <> 0                   'stringende?
    repeat until ram_rdbyte(PARAM+parapos) > CHAR_SPACE 'führende leerzeichen ausblenden
      parapos++
    i := 0
    repeat                                              'parameter kopieren
      c := ram_rdbyte(PARAM + parapos++)
      if c <> CHAR_SPACE                                'space nicht kopieren
        byte[stradr++] := c
    until (c == CHAR_SPACE) or (c == 0)
    byte[stradr] := 0                                   'string abschließen
    return 1
  else
    return 0

PUB reggetcogs:regcogs |i,c,cog[8]                      'system: fragt freie cogs von regnatix ab
''funktionsgruppe               : system
''funktion                      : fragt freie cogs von regnatix ab
''eingabe                       : -
''ausgabe                       : regcogs - anzahl der belegten cogs
''busprotokoll                  : -

  regcogs := i := 0
  repeat 'loads as many cogs as possible and stores their cog numbers
    c := cog[i] := cognew(@entry, 0)
    if c=>0
      i++
  while c => 0
  regcogs := i
  repeat 'unloads the cogs and updates the string
    i--
    if i=>0
      cogstop(cog[i])
  while i=>0  

PUB ldbin(stradr) | len,i,stradr2               'loader: startet bin-datei über loader
''funktionsgruppe               : system
''funktion                      : startet bin-datei über den systemloader
''eingabe                       : stradr - adresse eines strings mit dem dateinamen der bin-datei
''ausgabe                       : -
''busprotokoll                  : -

  len := strsize(stradr)
  stradr2 := lflagadr + 1                               'adr = flag, adr + 1 = string
  repeat i from 0 to len - 1                            'string in loadervariable kopieren
    byte[stradr2][i] := byte[stradr][i]
  byte[stradr2][++i] := 0                               'string abschließen
  byte[lflagadr][0] := 1                                'loader starten

pub ld_rambin(n)

    byte[lflagadr][0] := n                              'loader starten

PUB os_error(err):error                                 'sys: fehlerausgabe

  {if err
    printnl
    print(string("Fehlernummer : "))
    printdec(err)
    print(string(" : $"))
    printhex(err,2)
    printnl
    print(string("Fehler       : "))
    case err
      0:  print(string("no error"))
      1:  print(string("fsys unmounted"))
      2:  print(string("fsys corrupted"))
      3:  print(string("fsys unsupported"))
      4:  print(string("not found"))
      5:  print(string("file not found"))
      6:  print(string("dir not found"))
      7:  print(string("file read only"))
      8:  print(string("end of file"))
      9:  print(string("end of directory"))
      10: print(string("end of root"))
      11: print(string("dir is full"))
      12: print(string("dir is not empty"))
      13: print(string("checksum error"))
      14: print(string("reboot error"))
      15: print(string("bpb corrupt"))
      16: print(string("fsi corrupt"))
      17: print(string("dir already exist"))
      18: print(string("file already exist"))
      19: print(string("out of disk free space"))
      20: print(string("disk io error"))
      21: print(string("command not found"))
      22: print(string("timeout"))
      23: print(string("out of memory"))
      OTHER: print(string("undefined"))}
    'printnl
  error := err

OBJ' SERIAL-FUNKTIONEN
CON' -------------------------------------------------- Funktionen der seriellen Schnittstelle -----------------------------------------------------------
pub seropen(baud)            'ser. Schnittstelle virtuell öffnen
    ser.start(31, 30,0,baud)'0, baud)                              'serielle Schnittstelle starten
    'serial:=1

pub serclose           'ser. Schnittstelle virtuell schliessen
    'serial:=0
    ser.stop
pub serget:c           'warten bis Zeichen an ser. Schnittstelle anliegt
    c:=ser.rx
pub serread:c          ' Zeichen von ser. Schnittstelle lesen ohne zu warten -1 wenn kein Zeichen da ist
    c:=ser.rxcheck

pub sertx(c)
    ser.tx(c)

pub serdec(c)
    ser.dec(c)

pub serstr(strg)
    ser.str(strg)

pub serflush
    ser.rxflush
'pub printser_out(n)
'    serial:=n
pub serhex(c,n)
    ser.hex(c,n)

OBJ '' A D M I N I S T R A

CON ''------------------------------------------------- CHIP-MANAGMENT

PUB admload(stradr)                                 'chip-mgr: neuen administra-code booten
''funktionsgruppe               : cmgr
''funktion                      : administra mit neuem code booten
''busprotokoll                  : [096][sub_putstr.fn]
''                              : fn - dateiname des neuen administra-codes

  bus_putchar1(gc#a_mgrALoad)      'aktuelles userdir retten
  bus_putstr1(stradr)
  waitcnt(cnt + clkfreq*3)      'warte bis administra fertig ist

PUB admgetver:ver                                       'chip-mgr: version abfragen
''funktionsgruppe               : cmgr
''funktion                      : abfrage der version und spezifikation des chips
''busprotokoll                  : [098][sub_getlong.ver]
''                              : ver - version
''                  +----------
''                  |  +------- system     
''                  |  |  +---- version    (änderungen)
''                  |  |  |  +- subversion (hinzufügungen)
''version :       $00_00_00_00
''

  bus_putchar1(gc#a_mgrGetVer)
  ver := bus_getlong1

PUB admgetspec:spec                                     'chip-mgr: spezifikation abfragen
''funktionsgruppe               : cmgr
''funktion                      : abfrage der version und spezifikation des chips
''busprotokoll                  : [089][sub_getlong.spec]
''                              : spec - spezifikation
''
''                                          +---------- com
''                                          | +-------- i2c
''                                          | |+------- rtc
''                                          | ||+------ lan
''                                          | |||+----- sid
''                                          | ||||+---- wav
''                                          | |||||+--- hss
''                                          | ||||||+-- bootfähig
''                                          | |||||||+- dateisystem
''spezifikation : %00000000_00000000_00000000_01001111

  bus_putchar1(gc#a_mgrGetSpec)
  spec := bus_getlong1

PUB admgetcogs:cogs                                     'chip-mgr: verwendete cogs abfragen
''funktionsgruppe               : cmgr
''funktion                      : abfrage wie viele cogs in benutzung sind
''busprotokoll                  : [097][get.cogs]
''                              : cogs - anzahl der belegten cogs

  bus_putchar1(gc#a_mgrGetCogs)
  cogs := bus_getchar1

PUB admreset                                            'chip-mgr: administra reset
''funktionsgruppe               : cmgr
''funktion                      : reset im administra-chip auslösen - loader aus dem eeprom wird neu geladen
''busprotokoll                  : -

  bus_putchar1(gc#a_mgrReboot)

'PUB admdebug: wert                                      'chip-mgr: debug-funktion

'  bus_putchar1(AMGR_DEBUG)
'  wert := bus_getlong1
Con '------------------------------------------------- Winbond-Funktionen (Flash-Rom)

pub Read_Flash_Data(adr)
    bus_putchar1(gc#a_ReadData)
    bus_putlong1(adr)
    return bus_getchar1

pub GET_FlashByte:d
    bus_putchar1(gc#a_GET_FLASH_BYTE)
    d:=bus_getchar1

pub PUT_FlashByte(c)
    bus_putchar1(gc#a_PUT_FLASH_BYTE)
    bus_putchar1(c)

pub SET_FlashAdress(adr)
    bus_putchar1(gc#a_SET_Flash_Adress)
    bus_putlong1(adr)

pub flash_id:d
    bus_putchar1(gc#a_FlashID)
    d:=bus_getlong1

pub flashsize:d
    bus_putchar1(gc#a_FlashSize)
    d:=bus_getlong1

pub Write_Flash_Data(adr,c)
    bus_putchar1(gc#a_WriteData)
    bus_putlong1(adr)
    bus_putchar1(c)

pub erase_Flash_Data(adr)
    bus_putchar1(gc#a_EraseData)
    bus_putlong1(adr)

pub Write_FlashBL2(adr,count)
    bus_putchar1(gc#a_WR_FlashBL2)
    bus_putlong1(adr)
    bus_putlong1(count)

pub rd_flashlong(adr):wert
    bus_putchar1(gc#a_RD_Flash_Long)
    bus_putlong1(adr)
    wert:=bus_getlong1

pub wr_flashlong(adr,wert)
    bus_putchar1(gc#a_WR_Flash_Long)
    bus_putlong1(adr)
    bus_putlong1(wert)

pub sdtoflash(adr,count)
    bus_putchar1(gc#a_sdtoflash)
    bus_putlong1(adr)
    bus_putlong1(count)

pub flxgetblk(adr,adr2,count)
    bus_putchar1(gc#a_RD_FlashBL)
    bus_putlong1(adr2)
    bus_putlong1(count)
    repeat count
           ram_wrbyte(bus_getchar1,adr++)

pub copytoflash(adr)
    bus_putchar1(gc#a_sdtoFlash)
    bus_putlong1(adr)

CON ''------------------------------------------------- SD_LAUFWERKSFUNKTIONEN

PUB sdmount: err                                        'sd-card: mounten
''funktionsgruppe               : sdcard
''funktion                      : eingelegtes volume mounten
''busprotokoll                  : [001][get.err]
''                              : err - fehlernummer entspr. list

  bus_putchar1(gc#a_SDMOUNT)
  err := bus_getchar1
  
PUB sddir                                               'sd-card: verzeichnis wird geöffnet
''funktionsgruppe               : sdcard
''funktion                      : verzeichnis öffnen
''busprotokoll                  : [002]

  bus_putchar1(gc#a_SDOPENDir)

PUB sdnext: stradr | flag                               'sd-card: nächster dateiname aus verzeichnis
''funktionsgruppe               : sdcard
''funktion                      : nächsten eintrag aus verzeichnis holen
''busprotokoll                  : [003][get.status=0]
''                              : [003][get.status=1][sub_getstr.fn]
''                              : status - 1 = gültiger eintrag
''                              :          0 = es folgt kein eintrag mehr
''                              : fn - verzeichniseintrag string

    bus_putchar1(gc#a_SDNEXTFILE)                           'kommando: nächsten eintrag holen
    flag := bus_getchar1                                'flag empfangen
    if flag 
      return bus_getstr1
    else
      return 0

PUB sdopen(modus,stradr):err | len,i                    'sd-card: datei öffnen
''funktionsgruppe               : sdcard
''funktion                      : eine bestehende datei öffnen
''busprotokoll                  : [004][put.modus][sub_putstr.fn][get.error]
''                              : modus - "A" Append, "W" Write, "R" Read (Großbuchstaben!)
''                              : fn - name der datei
''                              : error - fehlernummer entspr. list

  bus_putchar1(gc#a_SDOPEN)
  bus_putchar1(modus)
  len := strsize(stradr)
  bus_putchar1(len)
  repeat i from 0 to len - 1
    bus_putchar1(byte[stradr++])
  err := bus_getchar1

PUB sdclose:err                                         'sd-card: datei schließen
''funktionsgruppe               : sdcard
''funktion                      : die aktuell geöffnete datei schließen
''busprotokoll                  : [005][get.error]
''                              : error - fehlernummer entspr. list

  bus_putchar1(gc#a_SDCLOSE)
  err := bus_getchar1

PUB sdgetc: char                                        'sd-card: zeichen aus datei lesen
''funktionsgruppe               : sdcard
''funktion                      : zeichen aus datei lesen
''busprotokoll                  : [006][get.char]
''                              : char - gelesenes zeichen

  bus_putchar1(gc#a_SDGETC)
  char := bus_getchar1

PUB sdputc(char)                                        'sd-card: zeichen in datei schreiben
{{sdputc(char) - sd-card: zeichen in datei schreiben}}
  bus_putchar1(gc#a_SDPUTC)
  bus_putchar1(char)

PUB sdgetstr(stringptr,len)                             'sd-card: eingabe einer zeichenkette
  repeat len
    byte[stringptr++] := bus_getchar1

PUB sdputstr(stringptr)                                 'sd-card: ausgabe einer zeichenkette (0-terminiert)
{{sdstr(stringptr) - sd-card: ausgabe einer zeichenkette (0-terminiert)}}
  repeat strsize(stringptr)
    sdputc(byte[stringptr++])

PUB sddec(value) | i                                    'sd-card: dezimalen zahlenwert auf bildschirm ausgeben
{{sddec(value) - sd-card: dezimale bildschirmausgabe zahlenwertes}}
  if value < 0                                          'negativer zahlenwert
    -value
    sdputc("-")
  i := 1_000_000_000
  repeat 10                                             'zahl zerlegen
    if value => i
      sdputc(value / i + "0")
      value //= i
      result~~
    elseif result or i == 1
      sdputc("0")
    i /= 10                                             'n?chste stelle

PUB sdeof: eof                                          'sd-card: eof abfragen
''funktionsgruppe               : sdcard
''funktion                      : eof abfragen
''busprotokoll                  : [030][get.eof]
''                              : eof - eof-flag

  bus_putchar1(gc#a_SDEOF)
  eof := bus_getchar1
pub sdpos:c
    bus_putchar1(gc#a_SDPOS)
    c:=bus_getlong1

pub sdcopy(cm,pm,source)
    bus_putchar1(gc#a_SDCOPY)
    bus_putlong1(cm)
    bus_putlong1(pm)

    bus_putstr1(source)


PUB sdgetblk(count,bufadr) | i                          'sd-card: block lesen
''funktionsgruppe               : sdcard
''funktion                      : block aus datei lesen
''busprotokoll                  : [008][sub_putlong.count][get.char(1)]..[get.char(count)]
''                              : count - anzahl der zu lesenden zeichen
''                              : char - gelesenes zeichen

  i := 0
  bus_putchar1(gc#a_SDGETBLK)
  bus_putlong1(count)
  repeat count
    byte[bufadr][i++] := bus_getchar1
    
PUB sdputblk(count,bufadr) | i                          'sd-card: block schreiben
''funktionsgruppe               : sdcard
''funktion                      : zeichen in datei schreiben
''busprotokoll                  : [007][put.char]
''                              : char - zu schreibendes zeichen

  i := 0
  bus_putchar1(gc#a_SDPUTBLK)
  bus_putlong1(count)
  repeat count
    bus_putchar1(byte[bufadr][i++])
con'************************************************ Blocktransfer test modifizieren fuer Tiledateien und Datendateien (damit es schneller geht ;-) **************************************
PUB sdxgetblk(adr,count)|i                              'sd-card: block lesen --> eRAM
''funktionsgruppe               : sdcard
''funktion                      : block aus datei lesen und in ramdisk speichern
''busprotokoll                  : [008][sub_putlong.count][get.char(1)]..[get.char(count)]
''                              : count - anzahl der zu lesenden zeichen
''                              : char - gelesenes zeichen
  i := 0
  bus_putchar1(gc#a_SDGETBLK)
  bus_putlong1(count)          'laenge der Datei in byte
  repeat count
     ram_wrbyte(bus_getchar1,adr++)


con '*********************************************** Blocktransfer test **************************************************************************************************
PUB sdxputblk(adr,count)                              'sd-card: block schreiben <-- eRAM
''funktionsgruppe               : sdcard
''funktion                      : zeichen aus ramdisk in datei schreiben
''busprotokoll                  : [007][put.char]
''                              : char - zu schreibendes zeichen

  bus_putchar1(gc#a_SDPUTBLK)
  bus_putlong1(count)
  repeat count
    bus_putchar1(ram_rdbyte(adr++))'rd_get(fnr))

PUB sdseek(wert)                                        'sd-card: zeiger auf byteposition setzen
''funktionsgruppe               : sdcard
''funktion                      : zeiger in datei positionieren
''busprotokoll                  : [010][sub_putlong.pos]
''                              : pos - neue zeichenposition in der datei

  bus_putchar1(gc#a_SDSEEK)
  bus_putlong1(wert)

PUB sdfattrib(anr): attrib                              'sd-card: dateiattribute abfragen
''funktionsgruppe               : sdcard
''funktion                      : dateiattribute abfragen
''busprotokoll                  : [011][put.anr][sub_getlong.wert]
''                              : anr - 0  = Dateigröße
''                              :       1  = Erstellungsdatum - Tag
''                              :       2  = Erstellungsdatum - Monat
''                              :       3  = Erstellungsdatum - Jahr
''                              :       4  = Erstellungsdatum - Sekunden
''                              :       5  = Erstellungsdatum - Minuten
''                              :       6  = Erstellungsdatum - Stunden
''                              :       7  = Zugriffsdatum - Tag
''                              :       8  = Zugriffsdatum - Monat
''                              :       9  = Zugriffsdatum - Jahr
''                              :       10 = Änderungsdatum - Tag
''                              :       11 = Änderungsdatum - Monat
''                              :       12 = Änderungsdatum - Jahr
''                              :       13 = Änderungsdatum - Sekunden
''                              :       14 = Änderungsdatum - Minuten
''                              :       15 = Änderungsdatum - Stunden
''                              :       16 = Read-Only-Bit
''                              :       17 = Hidden-Bit
''                              :       18 = System-Bit
''                              :       19 = Direktory
''                              :       20 = Archiv-Bit
''                              : wert - wert des abgefragten attributes


  bus_putchar1(gc#a_SDFATTRIB)
  bus_putchar1(anr)
  attrib := bus_getlong1                               
  
  
PUB sdvolname: stradr                            'sd-card: volumelabel abfragen
''funktionsgruppe               : sdcard
''funktion                      : name des volumes überragen
''busprotokoll                  : [012][sub_getstr.volname]
''                              : volname - name des volumes
''                              : len   - länge des folgenden strings

  bus_putchar1(gc#a_SDVOLNAME)                              'kommando: volumelabel abfragen
  return bus_getstr1
  
PUB sdcheckmounted: flag                                'sd-card: test ob volume gemounted ist
''funktionsgruppe               : sdcard
''funktion                      : test ob volume gemounted ist
''busprotokoll                  : [013][get.flag]
''                              : flag  - 0: unmounted
''                              :         1: mounted

  bus_putchar1(gc#a_SDCHECKMOUNTED)
  return bus_getchar1
  
PUB sdcheckopen: flag                                   'sd-card: test ob datei geöffnet ist
''funktionsgruppe               : sdcard
''funktion                      : test ob eine datei geöffnet ist
''busprotokoll                  : [014][get.flag]
''                              : flag  - 0: not open
''                              :         1: open

  bus_putchar1(gc#a_SDCHECKOPEN)
  return bus_getchar1

PUB sdcheckused                                         'sd-card: abfrage der benutzten sektoren
''funktionsgruppe               : sdcard
''funktion                      : anzahl der benutzten sektoren senden 
''busprotokoll                  : [015][sub_getlong.used]
''                              : used - anzahl der benutzten sektoren

  bus_putchar1(gc#a_SDCHECKUSED)
  return bus_getlong1

PUB sdcheckfree                                         'sd_card: abfrage der freien sektoren
''funktionsgruppe               : sdcard
''funktion                      : anzahl der freien sektoren senden 
''busprotokoll                  : [016][sub_getlong.free]
''                              : free - anzahl der freien sektoren

  bus_putchar1(gc#a_SDCHECKFREE)
  return bus_getlong1

PUB sdnewfile(stradr):err                               'sd_card: neue datei erzeugen
''funktionsgruppe               : sdcard
''funktion                      : eine neue datei erzeugen 
''busprotokoll                  : [017][sub_putstr.fn][get.error]
''                              : fn - name der datei
''                              : error - fehlernummer entspr. liste

  bus_putchar1(gc#a_SDNEWFILE)
  bus_putstr1(stradr)
  err := bus_getchar1

PUB sdnewdir(stradr):err                                'sd_card: neues verzeichnis erzeugen
''funktionsgruppe               : sdcard
''funktion                      : ein neues verzeichnis erzeugen
''busprotokoll                  : [018][sub_putstr.fn][get.error]
''                              : fn - name des verzeichnisses
''                              : error - fehlernummer entspr. liste

  bus_putchar1(gc#a_SDNEWDIR)
  bus_putstr1(stradr)
  err := bus_getchar1

PUB sddel(stradr):err                                   'sd_card: datei/verzeichnis löschen
''funktionsgruppe               : sdcard
''funktion                      : eine datei oder ein verzeichnis löschen
''busprotokoll                  : [019][sub_putstr.fn][get.error]
''                              : fn - name des verzeichnisses oder der datei
''                              : error - fehlernummer entspr. liste

  bus_putchar1(gc#a_SDDEL)
  bus_putstr1(stradr)
  err := bus_getchar1

PUB sdrename(stradr1,stradr2):err                       'sd_card: datei/verzeichnis umbenennen
''funktionsgruppe               : sdcard
''funktion                      : datei oder verzeichnis umbenennen
''busprotokoll                  : [020][sub_putstr.fn1][sub_putstr.fn2][get.error]
''                              : fn1 - alter name 
''                              : fn2 - neuer name 
''                              : error - fehlernummer entspr. liste

  bus_putchar1(gc#a_SDRENAME)
  bus_putstr1(stradr1)
  bus_putstr1(stradr2)
  err := bus_getchar1

PUB sdchattrib(stradr1,stradr2):err                     'sd-card: attribute ändern
''funktionsgruppe               : sdcard
''funktion                      : attribute einer datei oder eines verzeichnisses ändern
''busprotokoll                  : [021][sub_putstr.fn][sub_putstr.attrib][get.error]
''                              : fn - dateiname
''                              : attrib - string mit attributen (AHSR)
''                              : error - fehlernummer entspr. liste

  bus_putchar1(gc#a_SDCHATTRIB)
  bus_putstr1(stradr1)
  bus_putstr1(stradr2)
  err := bus_getchar1

PUB sdchdir(stradr):err                                 'sd-card: verzeichnis wechseln
''funktionsgruppe               : sdcard
''funktion                      : verzeichnis wechseln
''busprotokoll                  : [022][sub_putstr.fn][get.error]
''                              : fn - name des verzeichnisses
''                              : error - fehlernummer entspr. list

  bus_putchar1(gc#a_SDCHDIR)
  bus_putstr1(stradr)
  err := bus_getchar1

PUB sdformat(stradr):err                                'sd-card: medium formatieren
''funktionsgruppe               : sdcard
''funktion                      : medium formatieren
''busprotokoll                  : [023][sub_putstr.vlabel][get.error]
''                              : vlabel - volumelabel
''                              : error - fehlernummer entspr. list

  bus_putchar1(gc#a_SDFORMAT)
  bus_putstr1(stradr)
  err := bus_getchar1

PUB sdunmount:err                                       'sd-card: medium abmelden
''funktionsgruppe               : sdcard
''funktion                      : medium abmelden
''busprotokoll                  : [024][get.error]
''                              : error - fehlernummer entspr. list

  bus_putchar1(gc#a_SDUNMOUNT)
  err := bus_getchar1

PUB sddmact(marker):err                                 'sd-card: dir-marker aktivieren
''funktionsgruppe               : sdcard
''funktion                      : ein ausgewählter dir-marker wird aktiviert
''busprotokoll                  : [025][put.dmarker][get.error]
''                              : dmarker - dir-marker      
''                              : error   - fehlernummer entspr. list

  bus_putchar1(gc#a_SDDMACT)
  bus_putchar1(marker)
  err := bus_getchar1

PUB sddmset(marker)                                     'sd-card: dir-marker setzen
''funktionsgruppe               : sdcard
''funktion                      : ein ausgewählter dir-marker mit dem aktuellen verzeichnis setzen
''busprotokoll                  : [026][put.dmarker]
''                              : dmarker - dir-marker      

  bus_putchar1(gc#a_SDDMSET)
  bus_putchar1(marker)

PUB sddmget(marker):status                              'sd-card: dir-marker abfragen
''funktionsgruppe               : sdcard
''funktion                      : den status eines ausgewählter dir-marker abfragen
''busprotokoll                  : [027][put.dmarker][sub_getlong.dmstatus]
''                              : dmarker  - dir-marker     
''                              : dmstatus - status des markers

  bus_putchar1(gc#a_SDDMGET)
  bus_putchar1(marker)
  status := bus_getlong1
  
PUB sddmclr(marker)                                     'sd-card: dir-marker löschen
''funktionsgruppe               : sdcard
''funktion                      : ein ausgewählter dir-marker löschen
''busprotokoll                  : [028][put.dmarker]
''                              : dmarker - dir-marker      

  bus_putchar1(gc#a_SDDMCLR)
  bus_putchar1(marker)

PUB sddmput(marker,status)                              'sd-card: dir-marker status setzen
''funktionsgruppe               : sdcard
''funktion                      : dir-marker status setzen
''busprotokoll                  : [027][put.dmarker][sub_putlong.dmstatus]
''                              : dmarker  - dir-marker
''                              : dmstatus - status des markers

  bus_putchar1(gc#a_SDDMPUT)
  bus_putchar1(marker)
  bus_putlong1(status)

con'--------------------------------------------------- DCF77-Funktionen --------------------------------------------------------------------------------------------------------
{pub dcf_sync:on
    bus_putchar1(gc#a_DCF_INSYNC)
    on:=bus_getchar1

pub dcf_update
    bus_putchar1(gc#a_DCF_UPDATE_CLOCK)

pub dcf_geterror:on
    bus_putchar1(gc#a_DCF_GETBITERROR)
    on:=bus_getchar1
pub dcf_getdatacount:on
    bus_putchar1(gc#a_DCF_GETDatacount)
    on:=bus_getchar1
pub dcf_getbitnumber:on
    bus_putchar1(gc#a_DCF_GetBitNumber)
    on:=bus_getchar1
pub dcf_getbitlevel:on
    bus_putchar1(gc#a_DCF_GetBitLevel)
    on:=bus_getchar1
pub dcf_gettimezone:on
    bus_putchar1(gc#a_DCF_GetTimeZone)
    on:=bus_getchar1
pub dcf_getactive:on
    bus_putchar1(gc#a_DCF_GetActiveSet)
    on:=bus_getchar1
pub dcf_startup
    bus_putchar1(gc#a_DCF_start)

pub dcf_down
    bus_putchar1(gc#a_DCF_stop)

pub dcf_status:on
    bus_putchar1(gc#a_DCF_dcfon)
    on:=bus_getchar1

pub dcf_getseconds:on
    bus_putchar1(gc#a_DCF_Getseconds)
    on:=bus_getchar1
pub dcf_getminutes:on
    bus_putchar1(gc#a_DCF_GetMinutes)
    on:=bus_getchar1
pub dcf_gethours:on
    bus_putchar1(gc#a_DCF_Gethours)
    on:=bus_getchar1
pub dcf_getweekday:on
    bus_putchar1(gc#a_DCF_GetWeekDay)
    on:=bus_getchar1
pub dcf_getday:on
    bus_putchar1(gc#a_DCF_GetDay)
    on:=bus_getchar1
pub dcf_getmonth:on
    bus_putchar1(gc#a_DCF_GetMonth)
    on:=bus_getchar1
pub dcf_getyear:on
    bus_putchar1(gc#a_DCF_GetYear)
    on:=bus_getword1
    }
con'--------------------------------------------------- Bluetooth-Funktionen -----------------------------------------------------------------------------------------------------
pub Set_Bluetooth_Command_Mode
    bus_putchar1(gc#a_bl_Command_On)
pub Clear_Bluetooth_Command_Mode
    bus_putchar1(gc#a_bl_Command_Off)

CON ''------------------------------------------------- DATE TIME FUNKTIONEN
pub time|h,m,s
   ' setpos(y,x)
    s:=getSeconds
   if s<>tmptime
      h:=gethours
      m:=getMinutes
        if h<10
           printchar("0")
        printdec(h)
        printchar(":")
        if m<10
           printchar("0")
        printdec(m)
        printchar(":")
        if s<10
           printchar("0")
        printdec(s)
        tmptime:=s
'pub ReadClock
'    bus_putchar1(gc#a_rtcReadClock)
{
PUB getSeconds                                          'Returns the current second (0 - 59) from the real time clock.
  bus_putchar1(gc#a_rtcGetSeconds)
  return bus_getchar1

PUB getMinutes                                          'Returns the current minute (0 - 59) from the real time clock.
  bus_putchar1(gc#a_rtcGetMinutes)
  return bus_getchar1

PUB getHours                                            'Returns the current hour (0 - 23) from the real time clock.
  bus_putchar1(gc#a_rtcGetHours)
  return bus_getchar1

PUB getDay                                              'Returns the current day (1 - 7) from the real time clock.
  bus_putchar1(gc#a_rtcGetDay)
  return bus_getchar1

PUB getDate                                             'Returns the current date (1 - 31) from the real time clock.
  bus_putchar1(gc#a_rtcGetDate)
  return bus_getchar1

PUB getMonth                                            'Returns the current month (1 - 12) from the real time clock.
  bus_putchar1(gc#a_rtcGetMonth)
  return bus_getchar1

PUB getYear                                             'Returns the current year (2000 - 2099) from the real time clock.
  bus_putchar1(gc#a_rtcGetYear)
  return bus_getword1
}
{Pub setTime(second, minute, hour, day, date, month, year)
    bus_putchar1(gc#a_rtcSetTime)
    bus_putchar1(second)
    bus_putchar1(minute)
    bus_putchar1(hour)
    bus_putchar1(day)
    bus_putchar1(date)
    bus_putchar1(month)
    bus_putword1(year)}
PUB getSeconds                                          'Returns the current second (0 - 59) from the real time clock.
  bus_putchar1(gc#a_rtcGetSeconds)
  return bus_getlong1

PUB getMinutes                                          'Returns the current minute (0 - 59) from the real time clock.
  bus_putchar1(gc#a_rtcGetMinutes)
  return bus_getlong1

PUB getHours                                            'Returns the current hour (0 - 23) from the real time clock.
  bus_putchar1(gc#a_rtcGetHours)
  return bus_getlong1

PUB getDay                                              'Returns the current day (1 - 7) from the real time clock.
  bus_putchar1(gc#a_rtcGetDay)
  return bus_getlong1

PUB getDate                                             'Returns the current date (1 - 31) from the real time clock.
  bus_putchar1(gc#a_rtcGetDate)
  return bus_getlong1

PUB getMonth                                            'Returns the current month (1 - 12) from the real time clock.
  bus_putchar1(gc#a_rtcGetMonth)
  return bus_getlong1

PUB getYear                                             'Returns the current year (2000 - 2099) from the real time clock.
  bus_putchar1(gc#a_rtcGetYear)
  return bus_getlong1

PUB setSeconds(seconds)                                 'Sets the current real time clock seconds.
                                                        'seconds - Number to set the seconds to between 0 - 59.
  if seconds => 0 and seconds =< 59
    bus_putchar1(gc#a_rtcSetSeconds)
    bus_putlong1(seconds)

PUB setMinutes(minutes)                                 'Sets the current real time clock minutes.
                                                        'minutes - Number to set the minutes to between 0 - 59.
  if minutes => 0 and minutes =< 59
    bus_putchar1(gc#a_rtcSetMinutes)
    bus_putlong1(minutes)

PUB setHours(hours)                                     'Sets the current real time clock hours.
                                                        'hours - Number to set the hours to between 0 - 23.

  if hours => 0 and hours =< 23
    bus_putchar1(gc#a_rtcSetHours)
    bus_putlong1(hours)

PUB setDay(day)                                         'Sets the current real time clock day.
                                                        'day - Number to set the day to between 1 - 7.
  if day => 1 and day =< 7
    bus_putchar1(gc#a_rtcSetDay)
    bus_putlong1(day)

PUB setDate(date)                                       'Sets the current real time clock date.
                                                        'date - Number to set the date to between 1 - 31.
  if date => 1 and date =< 31
    bus_putchar1(gc#a_rtcSetDate)
    bus_putlong1(date)

PUB setMonth(month)                                     'Sets the current real time clock month.
                                                        'month - Number to set the month to between 1 - 12.
  if month => 1 and month =< 12
    bus_putchar1(gc#a_rtcSetMonth)
    bus_putlong1(month)

PUB setYear(year)                                       'Sets the current real time clock year.
                                                        'year - Number to set the year to between 2000 - 2099.
  if year => 2000 and year =< 2099
    bus_putchar1(gc#a_rtcSetYear)
    bus_putlong1(year)

CON ''------------------------------------------------- SIDCog DMP-Player

'PUB sid_mdmpplay(stradr): err                           'sid: dmp-datei mono auf sid2 abspielen
''funktionsgruppe               : sid
''funktion                      : dmp-datei auf sid2 von sd-card abspielen
''busprotokoll                  : [157][sub.putstr][get.err]
''                              : err - fehlernummer entspr. liste

'  bus_putchar1(SCOG_MDMPPLAY)
'  bus_putstr1(stradr)
'  err := bus_getchar1

PUB sid_sdmpplay(stradr): err                           'sid: dmp-datei stereo auf beiden sid's abspielen
''funktionsgruppe               : sid
''funktion                      : sid: dmp-datei stereo auf beiden sid's abspielen
''busprotokoll                  : [158][sub.putstr][get.err]
''                              : err - fehlernummer entspr. liste

  bus_putchar1(gc#a_s_sdmpplay)
  bus_putstr1(stradr)
  err := bus_getchar1

PUB sid_dmpstop
  bus_putchar1(gc#a_s_dmpstop)

PUB sid_dmppause
  bus_putchar1(gc#a_s_dmppause)

PUB sid_dmpstatus: status
  bus_putchar1(gc#a_s_dmpstatus)
  status := bus_getchar1

PUB sid_dmppos: wert
  bus_putchar1(gc#a_s_dmppos)
  wert := bus_getlong1


PUB sid_dmplen: wert
  bus_putchar1(gc#a_s_dmplen)
         ' bus_getlong1
  wert := bus_getlong1

PUB sid_mute                                     'sid: chips stummschalten
  bus_putchar1(gc#a_s_mute)
  'bus_putchar1(sidnr)

pub sid_resetRegisters
  'bus_putchar1(196)
  bus_putchar1(gc#a_s_ResetRegister)

PUB sid_dmpreg: stradr | i                              'sid: dmp-register empfangen
' daten im puffer
' word  frequenz kanal 1
' word  frequenz kanal 2
' word  frequenz kanal 3
' byte  volume

  i := 0
  bus_putchar1(gc#a_s_dmpreg)
  repeat 7
    byte[@strpuffer + i++] := bus_getchar1
  return @strpuffer
CON ''------------------------------------------------- SIDCog1-Funktionen

PUB sid1_setRegister(reg,val)
  bus_putchar1(gc#a_s1_setRegister)
  bus_putchar1(reg)
  bus_putchar1(val)

PUB sid1_updateRegisters(regadr)
  bus_putchar1(gc#a_s1_updateRegisters)
  repeat 25
    bus_putchar1(byte[regadr++])                        'Register1
  repeat 25
    bus_putchar1(byte[regadr++])                        'Register2

PUB sid1_setVolume(vol)
  bus_putchar1(gc#a_s1_setVolume)
  bus_putchar1(vol)

PUB sid1_play(channel, freq, waveform, attack, decay, sustain, release)
  bus_putchar1(gc#a_s1_play)
  bus_putchar1(channel)
  bus_putchar1(freq)
  bus_putchar1(waveform)
  bus_putchar1(attack)
  bus_putchar1(decay)
  bus_putchar1(sustain)
  bus_putchar1(release)

PUB sid1_noteOn(channel, freq)
  bus_putchar1(gc#a_s1_noteOn)
  bus_putchar1(channel)
  bus_putchar1(freq)
  'bus_putlong1(freq)

PUB sid1_noteOff(channel)
  bus_putchar1(gc#a_s1_noteOff)
  bus_putchar1(channel)

PUB sid1_setFreq(channel,freq)
  bus_putchar1(gc#a_s1_setFreq)
  bus_putchar1(channel)
  bus_putlong1(freq)

PUB sid1_setWaveform(channel,waveform)
  bus_putchar1(gc#a_s1_setWaveform)
  bus_putchar1(channel)
  bus_putchar1(waveform)

PUB sid1_setPWM(channel, val)
  bus_putchar1(gc#a_s1_setPWM)
  bus_putchar1(channel)
  bus_putlong1(val)

PUB sid1_setADSR(channel, attack, decay, sustain, release )
  bus_putchar1(gc#a_s1_setADSR)
  bus_putchar1(channel)
  bus_putchar1(attack)
  bus_putchar1(decay)
  bus_putchar1(sustain)
  bus_putchar1(release)

PUB sid1_setResonance(val)
  bus_putchar1(gc#a_s1_setResonance)
  bus_putchar1(val)

PUB sid1_setCutoff(freq)
  bus_putchar1(gc#a_s1_setCutoff)
  bus_putlong1(freq)

PUB sid1_setFilterMask(ch1,ch2,ch3)
  bus_putchar1(gc#a_s1_setFilterMask)
  bus_putchar1(ch1)
  bus_putchar1(ch2)
  bus_putchar1(ch3)

PUB sid1_setFilterType(lp,bp,hp)
  bus_putchar1(gc#a_s1_setFilterType)
  bus_putchar1(lp)
  bus_putchar1(bp)
  bus_putchar1(hp)

PUB sid1_enableRingmod(ch1,ch2,ch3)
  bus_putchar1(gc#a_s1_enableRingmod)
  bus_putchar1(ch1)
  bus_putchar1(ch2)
  bus_putchar1(ch3)

PUB sid1_enableSynchronization(ch1,ch2,ch3)
  bus_putchar1(gc#a_s1_enableSynchronization)
  bus_putchar1(ch1)
  bus_putchar1(ch2)
  bus_putchar1(ch3)

pub sid_beep(n)
  bus_putchar1(gc#a_s_SidBeep)
  bus_putchar1(n)

OBJ '' B E L L A T R I X

CON ''------------------------------------------------- CHIP-MANAGMENT

PUB belgetcogs:belcogs                                  'chip-mgr: verwendete cogs abfragen

  bus_putchar2(gc#BEL_CMD)                                 'kommandosequenz einleiten
  bus_putchar2(gc#BMGR_GETCOGS)                            'code 5 = freie cogs
  belcogs := bus_getchar2                               'statuswert empfangen

pub bel_get:vers
  bus_putchar2(gc#BEL_CMD)                                 'kommandosequenz einleiten
  bus_putchar2(gc#BMGR_GETVER)                             'code 95 = tiledriver 64 farben
  vers := bus_getlong2                                  'statuswert empfangen

PUB belgetspec:spec                                     'chip-mgr: spezifikationen abfragen
''funktionsgruppe               : cmgr
''funktion                      : abfrage der version und spezifikation des chips
''busprotokoll                  : [089][sub_getlong.spec]
''                              : spec - spezifikation
''
''
''                                          +----------
''                                          | +--------
''                                          | |+------- vektor
''                                          | ||+------ grafik
''                                          | |||+----- text
''                                          | ||||+---- maus
''                                          | |||||+--- tastatur
''                                          | ||||||+-- vga
''                                          | |||||||+- tv
''spezifikation = %00000000_00000000_00000000_00010110

  bus_putchar2(gc#BEL_CMD)                                 'kommandosequenz einleiten
  bus_putchar2(gc#BMGR_GETSPEC)
  spec := bus_getlong2

PUB belreset                                            'chip-mgr: bellatrix reset
{{breset - bellatrix neu starten}}

  bus_putchar2(gc#BEL_CMD)                                 'kommandosequenz einleiten
  bus_putchar2(gc#BMGR_REBOOT)                             'code 99 = reboot

PUB belload(stradr)                                     'chip-mgr: neuen bellatrix-code booten

  bus_putchar2(gc#BEL_CMD)                                 'kommandosequenz einleiten
  bus_putchar2(gc#BMGR_LOAD)                               'code 87 = code laden
  bload(stradr)

PUB bload(stradr) | n,rc,ii,plen                        'system: bellatrix mit grafiktreiber initialisieren
{{bload(stradr) - bellatrix mit grafiktreiber initialisieren
  wird zusätzlich zu belload gebraucht, da situationen auftreten, in denen bella ohne reset (kaltstart) mit
  einem treiber versorgt werden muß. ist der bella-loader aktiv, reagiert er nicht auf das reset-kommando.
  stradr  - adresse eines 0-term-strings mit dem dateinamen des bellatrixtreibers
}}

' kopf der bin-datei einlesen                           ------------------------------------------------------
  rc := sdopen("r",stradr)                              'datei öffnen
  repeat ii from 0 to 15                                '16 bytes header --> bellatrix
    n := sdgetc
    bus_putchar2(n)
  sdclose                                               'bin-datei schießen

' objektgröße empfangen
  plen := bus_getchar2 << 8                             'hsb empfangen
  plen := plen + bus_getchar2                           'lsb empfangen

' bin-datei einlesen                                    ------------------------------------------------------
  sdopen("r",stradr)                                    'bin-datei öffnen
  repeat ii from 0 to plen-1                            'datei --> bellatrix
    n := sdgetc
    bus_putchar2(n)
  sdclose

pub bload_flash(adr,mode)|plen,c
    plen:=Read_Flash_Data(adr+$b)<<8
    plen:=plen+Read_Flash_Data(adr+$a)
    bus_putchar1(gc#a_RD_FlashBL)
    bus_putlong1(adr)
    bus_putlong1(plen-8)
    bus_putchar2(gc#BEL_CMD)
    bus_putchar2(gc#BMGR_FLASHLOAD)                               'code 87 = code laden
    bus_putword2(plen)
    repeat plen
          c:=bus_getchar1
          bus_putchar2(c)
    if mode
       repeat while bus_getchar2<>88
CON ''------------------------------------------------- KEYBOARD

PUB key:wert                                            'key: holt tastaturcode
{{key:wert - key: übergibt tastaturwert}}
  bus_putchar2(gc#BEL_CMD)                                 'kommandosequenz einleiten
  bus_putchar2(gc#BEL_KEY_CODE)                            'code 2 = tastenwert holen
  wert := bus_getchar2                                  'tastenwert empfangen

PUB keyspec:wert                                        'key: statustasten zum letzten tastencode
  bus_putchar2(gc#BEL_CMD)                                 'kommandosequenz einleiten
  bus_putchar2(gc#BEL_KEY_SPEC)                            'code 2 = tastenwert holen
  wert := bus_getchar2                                  'wert empfangen


PUB keystat:status                                      'key: übergibt tastaturstatus
{{keystat:status - key: übergibt tastaturstatus}}
  bus_putchar2(gc#BEL_CMD)                                 'kommandosequenz einleiten
  bus_putchar2(gc#BEL_KEY_STAT)                            'code 1 = tastaturstatus
  status := bus_getchar2                                'statuswert empfangen

PUB keywait:n                                           'key: wartet bis taste gedrückt wird
{{keywait: n - key: wartet bis eine taste gedrückt wurde}}
  repeat
  until keystat > 0
  return key

pub inkey:n
  bus_putchar2(gc#BEL_CMD)                                 'kommandosequenz einleiten
  bus_putchar2(gc#BEL_KEY_INKEY)                           'code 2 = tastenwert holen
  n := bus_getchar2                                     'wert empfangen

pub clearkey
  bus_putchar2(gc#BEL_CMD)
  bus_putchar2(gc#BEL_CLEARKEY)

CON ''------------------------------------------------- SCREEN
'var byte globalcolor 'gesetzte hintergrundfarbe
PUB print(stringptr)|c                                    'screen: bildschirmausgabe einer zeichenkette (0-terminiert)
{{print(stringptr) - screen: bildschirmausgabe einer zeichenkette (0-terminiert)}}
     repeat strsize(stringptr)
        c:=byte[stringptr++]
           bus_putchar2(c)

pub displayString(char)',foregroundColor, backgroundColor, y, x)
    bus_putchar2(gc#BEL_CMD)
    bus_putchar2(gc#BEL_DPL_STRING)
    bus_putstr2(char)

pub bigfont(n)                                          'Umschaltung Fontsatz
    bus_putchar2(gc#BEL_CMD)
    bus_putchar2(gc#BEL_BIGFONT)
    bus_putchar2(n)


pub put(c,x,y)
    bus_putchar2(gc#BEL_CMD)
    bus_putchar2(gc#BEL_VGAPUT)
    bus_putchar2(c)
    bus_putchar2(x)
    bus_putchar2(y)

pub get_window:a
    bus_putchar2(gc#BEL_CMD)
    bus_putchar2(gc#BEL_Get_Window)
    a:=bus_getchar2

pub windel(num,m,i)|c
    bus_putchar2(gc#BEL_CMD)
    bus_putchar2(gc#BEL_Del_Window)
    bus_putchar2(num)
    ifnot m                                             'nur im modus0
          repeat 17
               c:=ram_rdbyte(i++)
               bus_putchar2(c)
pub printCursorRate(rate)
    bus_putchar2(gc#BEL_CMD)
    bus_putchar2(gc#BEL_CursorRate)
    bus_putchar2(rate)

pub window(win,farbe1,farbe2,farbe3,farbe4,farbe5,farbe6,farbe7,farbe8,y,x,yy,xx,modus,shd)',frm)
    bus_putchar2(gc#BEL_CMD)
    bus_putchar2(gc#BEL_Window)
    bus_putchar2(win)
    bus_putchar2(farbe1)
    bus_putchar2(farbe2)
    bus_putchar2(farbe3)
    bus_putchar2(farbe4)
    bus_putchar2(farbe5)
    bus_putchar2(farbe6)
    bus_putchar2(farbe7)
    bus_putchar2(farbe8)
    bus_putchar2(y)
    bus_putchar2(x)
    bus_putchar2(yy)
    bus_putchar2(xx)
    bus_putchar2(modus)
    bus_putchar2(shd)

{pub printfont(win,str,f1,f2,f3,y,x,offset)
    bus_putchar2(BEL_CMD)
    bus_putchar2(BEL_PRINTFONT)
    bus_putchar2(win)
    bus_putchar2(f1)
    bus_putchar2(f2)
    bus_putchar2(f3)
    bus_putchar2(y)
    bus_putchar2(x)
    bus_putchar2(offset)
    bus_putstr2(str)
}
pub Set_Titel_Status(win,modus,char)
    bus_putchar2(gc#BEL_CMD)
    bus_putchar2(gc#BEL_SET_TITELSTATUS)
    bus_putchar2(win)       'Fensternummer
    bus_putchar2(modus)     'titel oder statustext
    bus_putstr2(char)       'String

pub printBoxSize(win,y, x,yy, xx)
    bus_putchar2(gc#BEL_CMD)
    bus_putchar2(gc#BEL_BoxSize)
    bus_putchar2(win)
    bus_putchar2(y)
    bus_putchar2(x)
    bus_putchar2(yy)
    bus_putchar2(xx)

pub printBoxColor(win,vor,hinter)
    bus_putchar2(gc#BEL_CMD)
    bus_putchar2(gc#BEL_BOXCOLOR)
    bus_putchar2(win)
    bus_putchar2(vor)
    bus_putchar2(hinter)

pub set_func(wert,f)
    bus_putchar2(gc#BEL_CMD)
    bus_putchar2(f)                                     'funktion sety=3 , setx=8, Sprite_Move=47, Sprite_Speed=48, thirdcolor=28,Cursorrate=17,Printwindow=33,del_button=19
    bus_putchar2(wert)


pub scrollup(lines, farbe, y, x, yy, xx,rate)
    bus_putchar2(gc#BEL_CMD)
    bus_putchar2(gc#BEL_SCROLLUP)
    bus_putchar2(lines)
    bus_putchar2(farbe)
    bus_putchar2(y)
    bus_putchar2(x)
    bus_putchar2(yy)
    bus_putchar2(xx)
    bus_putchar2(rate)

pub scrolldown(lines, farbe, y, x, yy, xx,rate)
    bus_putchar2(gc#BEL_CMD)
    bus_putchar2(gc#BEL_SCROLLDOWN)
    bus_putchar2(lines)
    bus_putchar2(farbe)
    bus_putchar2(y)
    bus_putchar2(x)
    bus_putchar2(yy)
    bus_putchar2(xx)
    bus_putchar2(rate)

pub display3DFrame(topColor, centerColor, bottomColor, y, x, yy, xx)

    bus_putchar2(gc#BEL_CMD)
    bus_putchar2(gc#BEL_DPL_3DFRAME)
    bus_putchar2(topColor)
    bus_putchar2(centerColor)
    bus_putchar2(bottomColor)
    bus_putchar2(y)
    bus_putchar2(x)
    bus_putchar2(yy)
    bus_putchar2(xx)

pub display2dbox(farbe, y, x, yy, xx,shd)
    bus_putchar2(gc#BEL_CMD)
    bus_putchar2(gc#BEL_DPL_2DBOX)
    bus_putchar2(farbe)
    bus_putchar2(y)
    bus_putchar2(x)
    bus_putchar2(yy)
    bus_putchar2(xx)
    bus_putchar2(shd)

pub send_button_param(number,x,y,xx)
    bus_putchar2(gc#BEL_CMD)
    bus_putchar2(gc#BEL_Send_BUTTON)
    bus_putchar2(number)
    bus_putchar2(x)
    bus_putchar2(y)
    bus_putchar2(xx)

con' Modus 1 und 2
pub redefine(n,f1,f2,f3,f4,f5,f6,f7,f8)
    bus_putchar2(gc#BEL_CMD)
    bus_putchar2(gc#BEL_REDEFINE)
    bus_putchar2(n)
    bus_putchar2(f1)
    bus_putchar2(f2)
    bus_putchar2(f3)
    bus_putchar2(f4)
    bus_putchar2(f5)
    bus_putchar2(f6)
    bus_putchar2(f7)
    bus_putchar2(f8)

pub plotfunc(x,y,xx,yy,set,fl,f)
    bus_putchar2(gc#BEL_CMD)
    bus_putchar2(f)            'art der funktion Plot_Line, circle, rectangle
    bus_putword2(x)
    bus_putword2(y)
    bus_putword2(xx)
    bus_putword2(yy)
    bus_putchar2(set)
    bus_putchar2(fl)

pub PlotPixel(x,y,set)
    bus_putchar2(gc#BEL_CMD)
    bus_putchar2(gc#BEL_DPL_PIXEL)
    bus_putword2(x)
    bus_putword2(y)
    bus_putchar2(set)

pub PTest(x,y)
    bus_putchar2(gc#BEL_CMD)
    bus_putchar2(gc#BEL_TESTXY)
    bus_putword2(x)
    bus_putword2(y)
    return bus_getchar2

pub Backup_M1(x,y,xx,yy,adr,m)|ax,bx
    bus_putchar2(gc#BEL_CMD)
    bus_putchar2(gc#Bel_REST-m)   'm=0 Restore; m=1 Backup
    bus_putchar2(x)
    bus_putchar2(y)
    bus_putchar2(xx)
    bus_putchar2(yy)
    repeat ax from y to yy
        repeat bx from x to xx
           repeat 8
                  if m
                     ram_wrbyte(bus_getchar2,adr++)
                  else
                     bus_putchar2(ram_rdbyte(adr++))
           if m
              ram_wrbyte(bus_getchar2,adr++)
              ram_wrbyte(bus_getchar2,adr++)
           else
              bus_putchar2(ram_rdbyte(adr++))
              bus_putchar2(ram_rdbyte(adr++))

PUB  SaveLoadBMP(mo,adr,xw,yw,offset,dis)|i,yl,j,color3,ps,adre,stepy,stepx,restx                    'Bildschirm als BMP-Datei speichern (mo=1), BMP-Datei in E-Ram laden(mo=0)
  'Save VGA screen as BMP on SD card                                            'Laden funktioniert nur mit Mode4-Treiber
  'First, write the header

  adr+=offset                                                                   'Bild wird von unten nach oben in den Speicher geschrieben, deshalb Adressoffset auf letzte Zeile
  if mo                                                                         'BMP-Header
    biWidth:=xw
    biHeight:=yw
    bfSize:=biWidth*biHeight*3+54
    sdputblk(2,@bfType)
    sdputblk(4,@bfSize)
    sdputblk(2,@bfReserved1)
    sdputblk(2,@bfReserved2)
    sdputblk(4,@bfOffBits)
    sdputblk(4,@biSize)
    sdputblk(4,@biWidth)   '
    sdputblk(4,@biHeight)  '
    sdputblk(2,@biPlanes)
    sdputblk(2,@biBitCount)
    sdputblk(4,@biCompression)
    sdputblk(4,@biSizeImage)
    sdputblk(4,@biXPelsPerMeter)
    sdputblk(4,@biYPelsPerMeter)
    sdputblk(4,@biClrUsed)
    sdputblk(4,@biClrImportant)
    stepx:=1
    stepy:=1
  else
    sdseek(18)
    sdgetblk(4,@biWidth)                                                        '4byte width
    sdgetblk(4,@biHeight)                                                       '4byte height

    stepx:=(biWidth/160)-1                                                      'Bildspalten auf 160 pixel skalieren
    stepy:=(biHeight/120)-1                                                     'Bildzeilen auf 120 pixel skalieren
    restx:=biWidth//160                                                         'bei ungeraden Bildmaßen Restpixel ermitteln
    sdseek(54)                                                                  'BMP-Header überspringen
  'next, spit out 24-bit color pixels (in reverse order)
  j:=0

  repeat yl from yw-1 to 0
        adre:=adr-(j*160)                                                       'Anfangsadresse der jeweiligen Bildzeile (es wird von unten nach oben gelesen ->BMP Standard)
        repeat i from 0 to xw-1
            ps:=i+yl*xw
            if key==27
               return 1
            if mo                                                               'Modus speichern
               color3:=displaypoint(i,yl)                                       'gelesenes Farbbyte
               r:=(color3 & %%3000)                                             'Farbbyte in die RGB Farbanteile aufteilen
               g:=(color3 & %%0300)<<2
               b:=(color3 & %%0030)<<4
               sdputblk(3,@RGB)
            else
               sdgetblk(3,@RGB)
               color3:=r & %%3000                                               'RGB-Farbanteile wieder zusammenführen
               color3:=color3 + ((g >> 2) & %%0300)
               color3:=color3 + ((b >> 4) & %%0030)
               if dis
                  pointdisplay(ps,color3)
               ram_wrbyte(color3,adre++)
               if stepx
                  sdseek(sdpos+(3*stepx))
        ifnot mo
              if restx>0
                 sdseek(sdpos+(3*(restx+stepx+1)))
              sdseek(sdpos+(3*biWidth*stepy))
        j++

PUB BELRAM_W(n)

  bus_putchar2(gc#BEL_CMD)
  bus_putchar2(gc#BEL_WRITE_RAM)
  bus_putchar2(n)

PUB BELRAM_R(n)
  bus_putchar2(gc#BEL_CMD)
  bus_putchar2(gc#BEL_READ_RAM)
  bus_putchar2(n)

PUB belputblk(adr,count)                              'Bildschirm: block schreiben <-- eRAM
''funktionsgruppe               : sdcard
''funktion                      : zeichen aus ramdisk in bildschirm schreiben
''busprotokoll                  : [007][put.char]
''                              : char - zu schreibendes zeichen
  bus_putchar2(gc#BEL_CMD)
  bus_putchar2(gc#BEL_SEND_BLOCK)
  bus_putword2(count)
  repeat count
    bus_putchar2(ram_rdbyte(adr++))

pub displaypoint(x,y):a
    bus_putchar2(gc#BEL_CMD)
    bus_putchar2(gc#BEL_DISPLAYPOINT)
    bus_putword2(x)
    bus_putword2(y)
    a:=bus_getchar2

pub pointdisplay(n,c)
    bus_putchar2(gc#BEL_CMD)
    bus_putchar2(gc#BEL_POINTDISPLAY)
    bus_putword2(n)
    bus_putchar2(c)

DAT
RGB byte
b byte 0
g byte 0
r byte 0

BMPHeader  'Mostly using info from here:  http://www.fortunecity.com/skyscraper/windows/364/bmpffrmt.html
bfType byte "B","M"  ' 19778
bfSize long 0
bfReserved1 word 0
bfReserved2 word 0
bfOffBits long 54
biSize long 40
biWidth long 0
biHeight long 0
biPlanes word 1
biBitCount word 24
biCompression long 0
biSizeImage long 0
biXPelsPerMeter long 0
biYPelsPerMeter long 0
biClrUsed long 0
biClrImportant long 0

pub scrollup_M1(l,rt)
    bus_putchar2(gc#BEL_CMD)
    bus_putchar2(gc#BEL_SCROLLUP)
    bus_putchar2(l)
    bus_putchar2(rt)

pub scrolldown_M1(l,rt)
    bus_putchar2(gc#BEL_CMD)
    bus_putchar2(gc#BEL_SCROLLDOWN)
    bus_putchar2(l)
    bus_putchar2(rt)

con'
pub Actorset(tnr1,col1,col2,col3,x,y)
    bus_putchar2(gc#BEL_CMD)
    bus_putchar2(gc#BEL_ACTOR)
    bus_putchar2(tnr1)
    bus_putchar2(col1)
    bus_putchar2(col2)
    bus_putchar2(col3)
    bus_putchar2(x)
    bus_putchar2(y)
pub setactor_xy(k)
    bus_putchar2(gc#BEL_CMD)
    bus_putchar2(gc#BEL_ACTORPOS)
    bus_putchar2(k)
    'bus_putchar2(y)
pub setactionkey(k1,k2,k3,k4,k5)
    bus_putchar2(gc#BEL_CMD)
    bus_putchar2(gc#BEL_ACT_KEY)
    bus_putchar2(k1)
    bus_putchar2(k2)
    bus_putchar2(k3)
    bus_putchar2(k4)
    bus_putchar2(k5)
pub reset_sprite
    bus_putchar2(gc#BEL_CMD)
    bus_putchar2(gc#BEL_SPRITE_RESET)
    
pub set_sprite(num,tnr,tnr2,f1,f2,f3,dir,strt,end,x,y)
    bus_putchar2(gc#BEL_CMD)
    bus_putchar2(gc#BEL_SPRITE_PARAM)
    bus_putchar2(num)
    bus_putchar2(tnr)        'tilenrnummer
    bus_putchar2(tnr2)       'tilenrnummer2
    bus_putchar2(f1)         'farben 1-3
    bus_putchar2(f2)
    bus_putchar2(f3)
    bus_putchar2(dir)        'richtung
    bus_putchar2(strt)      'startposition
    bus_putchar2(end)        'endposition
    bus_putchar2(x)          'x und y parameter
    bus_putchar2(y)

pub get_Collision
    bus_putchar2(gc#BEL_CMD)
    bus_putchar2(gc#BEL_GET_COLLISION)
    return bus_getchar2
pub get_actor_pos(n)
    bus_putchar2(gc#BEL_CMD)
    bus_putchar2(gc#BEL_GET_ACTOR_POS)
    bus_putchar2(n)
    return bus_getchar2
pub send_block(n,tnr)
    bus_putchar2(gc#BEL_CMD)
    bus_putchar2(gc#BEL_SEND_BLOCK)
    bus_putchar2(n)
    bus_putchar2(tnr)
pub Change_Backuptile(tnr,f1,f2,f3)
    bus_putchar2(gc#BEL_CMD)
    bus_putchar2(gc#BEL_CHANGE_BACKUP)
    bus_putchar2(tnr)
    bus_putchar2(f1)
    bus_putchar2(f2)
    bus_putchar2(f3)

pub scrollString(str,characterRate, foregroundColor, backgroundColor, y, x, xx)
    bus_putchar2(gc#BEL_CMD)
    bus_putchar2(gc#BEL_SCROLLSTRING)
    bus_putchar2(characterRate)
    bus_putchar2(foregroundColor)
    bus_putchar2(backgroundColor)
    bus_putchar2(y)
    bus_putchar2(x)
    bus_putchar2(xx)
    bus_putstr2(str)



pub setpos(y,x)
    bus_putchar2(gc#BEL_CMD)
    bus_putchar2(gc#BEL_DPL_SETPOS)
    bus_putchar2(y)
    bus_putchar2(x)


pub displayTile(tnr,pcol,scol,tcol, row, column)

                bus_putchar2(gc#BEL_CMD)
                bus_putchar2(gc#BEL_DPL_TILE)
                bus_putchar2(tnr)
                bus_putchar2(pcol)
                bus_putchar2(scol)
                bus_putchar2(tcol)
                bus_putchar2(row)
                bus_putchar2(column)

pub Mousepointer(adr)|c
    bus_putchar2(gc#BEL_CMD)
    bus_putchar2(gc#BEL_LD_MOUSEPOINTER)

    repeat 16
          c:=ram_rdlong(adr)
          bus_putlong2(c)
          adr+=4
pub mousebound(x,y,xx,yy)
    bus_putchar2(gc#BEL_CMD)
    bus_putchar2(gc#BEL_LD_MOUSEBOUND)
    bus_putlong2(x)
    bus_putlong2(y)
    bus_putlong2(xx)
    bus_putlong2(yy)

pub loadtilebuffer(adr,anzahl)|c
          bus_putchar2(gc#BEL_CMD)
          bus_putchar2(gc#BEL_LD_TILESET)
          bus_putlong2(anzahl)

          repeat anzahl
                  c:=ram_rdlong(adr)
                  bus_putlong2(c)
                  adr+=4
pub displaypic(pcol,scol,tcol,y,x,ytile,xtile)
                bus_putchar2(gc#BEL_CMD)
                bus_putchar2(gc#BEL_DPL_PIC)
                bus_putchar2(pcol)
                bus_putchar2(scol)
                bus_putchar2(tcol)
                bus_putchar2(y)
                bus_putchar2(x)
                bus_putchar2(ytile)
                bus_putchar2(xtile)

pub getx |x
    bus_putchar2(gc#BEL_CMD)
    bus_putchar2(gc#BEL_GETX)
    x:=bus_getchar2
    return x
pub gety |y
    bus_putchar2(gc#BEL_CMD)
    bus_putchar2(gc#BEL_GETY)
    y:=bus_getchar2
    return y

pub DisplayMouse(on,color)
    bus_putchar2(gc#BEL_CMD)
    bus_putchar2(gc#BEL_DPL_MOUSE)
    bus_putchar2(on)
    bus_putchar2(color)
pub Displaypalette(x,y)
    bus_putchar2(gc#BEL_CMD)
    bus_putchar2(gc#BEL_DPL_PALETTE)
    bus_putchar2(x)
    bus_putchar2(y)

pub Backup_Area(x,y,xx,yy,adr)|a,c,d
    bus_putchar2(gc#BEL_CMD)
    bus_putchar2(gc#BEL_BACK)
    bus_putchar2(x)
    bus_putchar2(y)
    bus_putchar2(xx)
    bus_putchar2(yy)
    repeat a from y to yy
        repeat c from x to xx
           d:=bus_getlong2
           ram_wrlong(d,adr)
           adr+=4
           ram_wrword(bus_getword2,adr)
           adr+=2

pub restore_Area(x,y,xx,yy,adr)|a,c
    bus_putchar2(gc#BEL_CMD)
    bus_putchar2(gc#BEL_REST)
    bus_putchar2(x)
    bus_putchar2(y)
    bus_putchar2(xx)
    bus_putchar2(yy)
    repeat a from y to yy
          repeat c from x to xx
                bus_putlong2(ram_rdlong(adr))
                adr+=4
                bus_putword2(ram_rdword(adr))
                adr+=2

PUB printdec(value) | i ,c ,x                             'screen: dezimalen zahlenwert auf bildschirm ausgeben
{{printdec(value) - screen: dezimale bildschirmausgabe zahlenwertes}}
  if value < 0                                          'negativer zahlenwert
    -value
    printchar("-")

  i := 1_000_000_000
  repeat 10                                             'zahl zerlegen
    if value => i
      x:=value / i + "0"
      printchar(x)
      c:=value / i + "0"
      value //= i
      result~~
    elseif result or i == 1
      printchar("0")
    i /= 10                                             'nächste stelle

PUB printhex(value, digits)                             'screen: hexadezimalen zahlenwert auf bildschirm ausgeben
{{hex(value,digits) - screen: hexadezimale bildschirmausgabe eines zahlenwertes}}
  value <<= (8 - digits) << 2
  repeat digits
    printchar(lookupz((value <-= 4) & $F : "0".."9", "A".."F"))

PUB printbin(value, digits) |c                            'screen: binären zahlenwert auf bildschirm ausgeben

  value <<= 32 - digits
  repeat digits
     c:=(value <-= 1) & 1 + "0"
     printchar(c)

PUB printchar(c)':c2                                     'screen: einzelnes zeichen auf bildschirm ausgeben
{{printchar(c) - screen: bildschirmausgabe eines zeichens}}
  bus_putchar2(c)               'Zeichen mit Tilefont

PUB printqchar(c)':c2                                    'screen: zeichen ohne steuerzeichen ausgeben
{{printqchar(c) - screen: bildschirmausgabe eines zeichens}}

     bus_putchar2(gc#BEL_CMD)
     bus_putchar2(gc#BEL_SCR_CHAR)
     bus_putchar2(c)

PUB printnl                                             'screen: $0D - CR ausgeben
{{printnl - screen: $0D - CR ausgeben}}

     bus_putchar2(CHAR_NL)


pub mousex
  bus_putchar2(gc#BEL_CMD)         'kommandosequenz einleiten
  bus_putchar2(gc#BEL_MOUSEX)       'MOUSE-X-Position abfragen
  return bus_getchar2
pub mousey
  bus_putchar2(gc#BEL_CMD)         'kommandosequenz einleiten
  bus_putchar2(gc#BEL_MOUSEY)       'MOUSE-Y-Position abfragen

  return bus_getchar2                     'y-signal invertieren sonst geht der Mauszeiger hoch, wenn man runterscrollt

pub mousez
  bus_putchar2(gc#BEL_CMD)         'kommandosequenz einleiten
  bus_putchar2(gc#BEL_MOUSEZ)       'MOUSE-Z-Position abfragen
  return bus_getlong2

pub mouse_button(c)
  bus_putchar2(gc#BEL_CMD)         'kommandosequenz einleiten
  bus_putchar2(gc#BEL_MOUSE_BUTTON)       'MOUSE-Button abfragen
  bus_putchar2(c)
  return bus_getchar2
OBJ ''################################################## V E N A T R I X #############################################################################################################
CON ''------------------------------------------------- CHIP MANAGEMENT

{PUB VEN_GET:vers
'  bus_putchar3(VEN_CMD)
  bus_putchar3(VEN_GETVER)
  vers := bus_getlong3                                  'statuswert empfangen
PUB VEN_GETCOGS:cogs
'  bus_putchar3(VEN_CMD)
  bus_putchar3(Ven_getcgs)
  cogs:=bus_getchar3
PUB Venreset                                            'chip-mgr: bellatrix reset
{{breset - Venatrix neu starten}}
'  bus_putchar3(VEN_CMD)
  bus_putchar3(VEN_REBOOT)                             'code 99 = reboot

PUB venload(stradr)                                     'chip-mgr: neuen Venatrix-code booten
'  bus_putchar3(VEN_CMD)
  bus_putchar3(VEN_LOAD)                                'code 97 = code laden
  waitcnt(cnt + 2_000_000)                              'warte bis ven fertig ist
  vload(stradr)

PUB vload(stradr) | n,rc,ii,plen                        'system: venatrix mit neuen Code versorgen

' kopf der bin-datei einlesen                           ------------------------------------------------------
  rc := sdopen("r",stradr)                              'datei öffnen
  repeat ii from 0 to 15                                '16 bytes header --> Venatrix
    n := sdgetc
    bus_putchar3(n)
  sdclose                                               'bin-datei schießen

' objektgröße empfangen
  plen := bus_getchar3 << 8                             'hsb empfangen
  plen := plen + bus_getchar3                           'lsb empfangen

' bin-datei einlesen                                    ------------------------------------------------------
  sdopen("r",stradr)                                    'bin-datei öffnen
  repeat ii from 0 to plen-1                            'datei --> bellatrix
    n := sdgetc
    bus_putchar3(n)
  sdclose
}

CON ''------------------------------------------------- Plexbus und Gamedevices

{pub plxdira(bits)                                       'Direction PortA-Bits 0=Output, 1=Input
    bus_putchar1(gc#a_plxdira)
    bus_putchar1(bits)

pub plxdirb(bits)                                       'Direction PortB-Bits 0=Output, 1=Input
    bus_putchar1(gc#a_plxdirb)
    bus_putchar1(bits)

pub plxpola(bits)                                       'Polarität PortA-Bits 0=Normal, 1=Invertiert
    bus_putchar1(gc#a_plxpola)
    bus_putchar1(bits)

pub plxpolb(bits)                                       'Polarität PortA-Bits 0=Normal, 1=Invertiert
    bus_putchar1(gc#a_plxpolb)
    bus_putchar1(bits)

pub plxpua(bits)                                        'Pullupwiderstand PortA-Bits einschalten 0=Abgeschaltet, 1=Pullup 100k
    bus_putchar1(gc#a_plxpua)
    bus_putchar1(bits)

pub plxpub(bits)                                        'Pullupwiderstand PortB-Bits einschalten 0=Abgeschaltet, 1=Pullup 100k
    bus_putchar1(gc#a_plxpub)
    bus_putchar1(bits)
}
{pub plxwra(bits)                                        'PortA-Bits schreiben
    bus_putchar1(gc#a_plxwra)
    bus_putchar1(bits)

pub plxwrb(bits)                                        'PortB-Bits schreiben
    bus_putchar1(gc#a_plxwrb)
    bus_putchar1(bits)
}
{pub plxrda:wert                                         'PortA-Bits lesen
    bus_putchar1(a_getJoystick1)
    wert:=bus_getchar1

pub plxrdb:wert                                         'PortB-Bits lesen
    bus_putchar1(a_getJoystick1)
    wert:=bus_getchar1
pub plxping(adr):wert
    bus_putchar1(gc#a_plxPing)
    bus_putchar1(adr)
    wert:=bus_getchar1
pub plxhalt
    bus_putchar1(gc#a_plxhalt)

pub plxrun
    bus_putchar1(gc#a_plxrun)
}
PUB plxrun                                              'plx: bus freigeben, poller starten

  bus_putchar1(gc#a_plxRun)

PUB plxhalt                                             'plx: bus anfordern, poller anhalten

  bus_putchar1(gc#a_plxHalt)

PUB plxin(adr):wert                                     'plx: port einlesen

  bus_putchar1(gc#a_plxIn)
  bus_putchar1(adr)
  wert := bus_getchar1

PUB plxout(adr,wert)                                    'plx: port ausgeben

  bus_putchar1(gc#a_plxOut)
  bus_putchar1(adr)
  bus_putchar1(wert)

PUB joy(chan):wert                                            'game: joystick abfragen

  bus_putchar1(gc#a_Joy)
  bus_putchar1(chan)
  wert := bus_getchar1

PUB paddle:wert                                         'game: paddle abfrage

  bus_putchar1(gc#a_Paddle)
  wert := wert + bus_getchar1 << 8
  wert := wert + bus_getchar1

PUB pad:wert                                            'game: pad abfrage

  bus_putchar1(gc#a_Pad)
  wert := wert + bus_getchar1 << 16
  wert := wert + bus_getchar1 << 8
  wert := wert + bus_getchar1

pub getreg(reg):wert
   bus_putchar1(gc#a_plxGetReg)
   bus_putchar1(reg)
   wert:=bus_getchar1

pub set_plxAdr(adda,Port)
   bus_putchar1(gc#a_plxSetAdr)                                     'adressen adda/ports für poller setzen
   bus_putchar1(adda)
   bus_putchar1(port)

pub plxping(adr):wert
   bus_putchar1(gc#a_plxPing)                                       'adressen adda/ports für poller setzen
   bus_putchar1(adr)
   wert:=bus_getchar1

pub plxstart
    bus_putchar1(gc#a_plxStart)                                     'I2C Start-Befehl

pub plxstop
    bus_putchar1(gc#a_plxStop)                                      'I2C Stop-Befehl

pub plxwrite(data):wert
    bus_putchar1(gc#a_plxWrite)                                     'I2C Write
    bus_putchar1(data)                                              'Daten
    wert:=bus_getchar1                                              'ack bit

pub plxread(ack):wert
    bus_putchar1(gc#a_plxRead)                                      'I2C Read
    bus_putchar1(ack)                                               'ack Bit
    wert:=bus_getchar1                                              'Rückgabewert
pub get_Joya:wert               'lese Joystickport 1
    bus_putchar1(gc#a_getJoystick1)
    wert:=bus_getchar1

pub get_Joyb:wert               'lese Joystickport 2
    bus_putchar1(gc#a_getJoystick2)
    wert:=bus_getchar1

OBJ '' R E G N A T I X

CON ''------------------------------------------------- BUS
'prop 1  - administra   (bus_putchar1, bus_getchar1)
'prop 2  - bellatrix    (bus_putchar2, bus_getchar2)
'prop 3  - venatrix     (bus_putchar3, bus_getchar3)
{{PUB bus_init                                            'bus: initialisiert bussystem

  outa[bus_wr]    := 1          ' schreiben inaktiv
  outa[reg_ram1]  := 1          ' ram1 inaktiv
  outa[reg_ram2]  := 1          ' ram2 inaktiv
  outa[reg_prop1] := 1          ' prop1 inaktiv
  outa[reg_prop2] := 1          ' prop2 inaktiv
  outa[busclk]    := 0          ' busclk startwert
  outa[reg_al]    := 0          ' strobe aus
  outa[reg_al2]   := 0
  dira := db_in                 ' datenbus auf eingabe schalten
  outa[18..8]     := 0          ' adresse a0..a10 auf 0 setzen
  outa[23]        := 1          ' obere adresse in adresslatch übernehmen
  outa[23]        := 0          ' und Latch2 auf null setzen
}}
PUB bus_init                                            'bus: initialisiert bussystem
{{bus_init - bus: initialisierung aller bussignale }}
  outa[bus_wr]    := 1          ' schreiben inaktiv
  outa[reg_ram1]  := 1          ' ram1 inaktiv
  outa[reg_ram2]  := 1          ' ram2 inaktiv
  outa[reg_prop1] := 1          ' prop1 inaktiv
  outa[reg_prop2] := 1          ' prop2 inaktiv
  outa[busclk]    := 0          ' busclk startwert
  outa[reg_al]    := 0          ' strobe aus
  dira := db_in                 ' datenbus auf eingabe schalten
  outa[18..8]     := 0          ' adresse a0..a10 auf 0 setzen
  outa[reg_al]    := 1 ' obere adresse in adresslatch übernehmen
  outa[reg_al]    := 0 ' und in Latch2 übernehmen (Sound auf Administra, VGA-on, RAM-Erweiterung auf Bellatrix)

  dira[reg_al2]   := 1
  outa[reg_al2]   := 1
  outa[reg_al2]   := 0
  dira[reg_al2]   := 0


PUB bus_getword1: wert                                  'bus: 16 bit von administra empfangen hsb/lsb

  wert := bus_getchar1 << 8
  wert := wert + bus_getchar1

PUB bus_putword1(wert)                                  'bus: 16 bit an administra senden hsb/lsb

   bus_putchar1(wert >> 8)
   bus_putchar1(wert)

PUB bus_getlong1: wert |sh                                 'bus: long von bellatrix empfangen hsb/lsb
  sh:=24
  repeat 4
    wert:=wert+bus_getchar1<<sh'(wert <-= 8)                            '32bit wert senden hsb/lsb
    sh-=8

PUB bus_putlong1(wert)                                  'bus: long zu administra senden hsb/lsb
  repeat 4
    bus_putchar1(wert <-= 8)                            '32bit wert senden hsb/lsb

PUB bus_getstr1: stradr | len,i                         'bus: string von administra empfangen

    len  := bus_getchar1                                'längenbyte empfangen
    repeat i from 0 to len - 1                          '20 zeichen dateinamen empfangen
      strpuffer[i] := bus_getchar1
    strpuffer[i] := 0
    return @strpuffer

PUB bus_putstr1(stradr) | len,i                         'bus: string zu administra senden

  len := strsize(stradr)
  bus_putchar1(len)
  repeat i from 0 to len - 1
    bus_putchar1(byte[stradr++])

PUB bus_putstr2(stradr) | len,i                         'bus: string zu bellatrix senden

  len := strsize(stradr)
  bus_putchar2(len)
  repeat i from 0 to len - 1
    bus_putchar2(byte[stradr++])

PUB bus_getstr2: stradr | len,i                         'bus: string von administra empfangen

    len  := bus_getchar2                                'längenbyte empfangen
    repeat i from 0 to len - 1                          '20 zeichen dateinamen empfangen
      strpuffer[i] := bus_getchar2
    strpuffer[i] := 0
    return @strpuffer

PUB bus_putchar1(c)                                     'bus: byte an administra senden
{{bus_putchar1(c) - bus: byte senden an prop1 (administra)}}

  dira := db_out                                        'datenbus auf ausgabe stellen
  outa := %00000000_01011000_00000000_00000000          'prop1=0, wr=0
  outa[7..0] := c                                       'daten --> dbus
  'repeat 10
  outa[busclk] := 1                                     'busclk=1
  waitpeq(%00000000_00000000_00000000_00000000,%00001000_00000000_00000000_00000000,0) 'hs=0?
  dira := db_in                                         'bus freigeben
  outa := %00001100_01111000_00000000_00000000           'wr=1, prop1=1, busclk=0

PUB bus_getchar1: wert                                  'bus: byte vom administra empfangen
{{bus_getchar1:wert - bus: byte empfangen von prop1 (administra)}}
  outa := %00000110_01011000_00000000_00000000          'prop1=0, wr=1, busclk=1
  waitpeq(%00000000_00000000_00000000_00000000,%00001000_00000000_00000000_00000000,0) 'hs=0?
  wert := ina[7..0]                                     'daten einlesen
  outa := %00000100_01111000_00000000_00000000          'prop1=1, busclk=0

PUB bus_putchar2(c)                                     'bus: byte an prop1 (bellatrix) senden
{{bus_putchar2(c) - bus: byte senden an prop2 (bellatrix)}}
  dira := db_out                                        'datenbus auf ausgabe stellen
  outa := %00000000_00111000_00000000_00000000          'prop2=0, wr=0
  outa[7..0] := c                                       'daten --> dbus
  outa[busclk] := 1                                     'busclk=1
  waitpeq(%00000000_00000000_00000000_00000000,%00001000_00000000_00000000_00000000,0) 'hs=0?
  dira := db_in                                         'bus freigeben
  outa := %00001100_01111000_00000000_00000000           'wr=1, prop2=1, busclk=0

  'ram_rw.putchar2(c)
PUB bus_getchar2: wert                                  'bus: byte vom prop1 (bellatrix) empfangen
{{bus_getchar2:wert - bus: byte empfangen von prop2 (bellatrix)}}
  outa := %00000110_00111000_00000000_00000000          'prop2=0, wr=1, busclk=1
  waitpeq(%00000000_00000000_00000000_00000000,%00001000_00000000_00000000_00000000,0) 'hs=0?
  wert := ina[7..0]                                     'daten einlesen
  outa := %00000100_01111000_00000000_00000000          'prop2=1, busclk=0


PUB bus_getword2: wert                                  'bus: 16 bit von bellatrix empfangen hsb/lsb

  wert := bus_getchar2 << 8
  wert := wert + bus_getchar2

PUB bus_putword2(wert)                                  'bus: 16 bit an bellatrix senden hsb/lsb

   bus_putchar2(wert >> 8)
   bus_putchar2(wert)

PUB bus_getlong2: wert |sh                                 'bus: long von bellatrix empfangen hsb/lsb
  sh:=24
  repeat 4
    wert:=wert+bus_getchar2<<sh'(wert <-= 8)                            '32bit wert senden hsb/lsb
    sh-=8

PUB bus_putlong2(wert)                                  'bus: long zu administra senden hsb/lsb
  repeat 4
    bus_putchar2(wert <-= 8)                            '32bit wert senden hsb/lsb

{PUB bus_getword3: wert                                  'bus: 16 bit von venatrix empfangen hsb/lsb

  wert := bus_getchar3 << 8
  wert := wert + bus_getchar3

PUB bus_putword3(wert)                                  'bus: 16 bit an venatrix senden hsb/lsb

   bus_putchar3(wert >> 8)
   bus_putchar3(wert)

PUB bus_getlong3: wert |sh                                 'bus: long von bellatrix empfangen hsb/lsb
  sh:=24
  repeat 4
    wert:=wert+bus_getchar3<<sh'(wert <-= 8)                            '32bit wert senden hsb/lsb
    sh-=8

PUB bus_putlong3(wert)                                  'bus: long zu administra senden hsb/lsb
  repeat 4
    bus_putchar3(wert <-= 8)                            '32bit wert senden hsb/lsb

PUB bus_getstr3: stradr | len,i                         'bus: string von administra empfangen

    len  := bus_getchar3                                'längenbyte empfangen
    repeat i from 0 to len - 1                          '20 zeichen dateinamen empfangen
      strpuffer[i] := bus_getchar3
    strpuffer[i] := 0
    return @strpuffer

PUB bus_putstr3(stradr) | len,i                         'bus: string zu administra senden

  len := strsize(stradr)
  bus_putchar3(len)
  repeat i from 0 to len - 1
    bus_putchar3(byte[stradr++])
}
CON ''------------------------------------------------- eRAM/SPEICHERVERWALTUNG
PUB ram_rdbyte(adresse):wert                        'eram: liest ein byte vom eram
{{ram_rdbyte(adresse):wert - eram: ein byte aus externem ram lesen}}
 wert:=ram_rw.rd_value(adresse,ram_rw#JOB_PEEK)'ram_rw.peek(adresse)

pub ram_fill(adresse,adresse2,wert)
    ram_rw.ram_fill(adresse,adresse2,wert)

pub ram_copy(von,ziel,anzahl)
    ram_rw.ram_copy(von,ziel,anzahl)

pub ram_keep(adr):w
    w:=ram_rw.ram_keep(adr)

PUB ram_wrbyte(wert,adresse)                        'eram: schreibt ein byte in eram
{{ram_wrbyte(wert,adresse) - eram: ein byte in externen ram schreiben}}
ram_rw.wr_value(adresse,wert,ram_rw#JOB_POKE)

PUB ram_rdlong(eadr): wert                          'eram: liest long ab eadr
{{ram_rdlong - eram: liest long ab eadr}}
wert:=ram_rw.rd_value(eadr,ram_rw#JOB_RDLONG)'ram_rw.rd_long(eadr)

PUB ram_rdword(eadr): wert                          'eram: liest word ab eadr
{{ram_rdlong(eadr):wert - eram: liest word ab eadr}}
wert:=ram_rw.rd_value(eadr,ram_rw#JOB_RDWORD)'ram_rw.rd_word(eadr)

PUB ram_wrlong(wert,eadr)                        'eram: schreibt long ab eadr
{ram_wrlong(wert,eadr) - eram: schreibt long ab eadr}
  ram_rw.wr_value(eadr,wert,ram_rw#JOB_WRLONG)

PUB ram_wrword(wert,eadr)                        'eram: schreibt word ab eadr
{{wr_word(wert,eadr) - eram: schreibt word ab eadr}}
  ram_rw.wr_value(eadr,wert,ram_rw#JOB_WRWORD)


CON ''------------------------------------------------- TOOLS

{PUB hram_print(adr,rows)

  repeat rows
    printnl
    printhex(adr,4)
    printchar(":")
    printchar(" ")
    repeat 8
      printhex(byte[adr++],2)
      printchar(" ")
    adr := adr - 8
    repeat 8
      printqchar(byte[adr++])
}
PUB Dump(adr,line,mod) |zeile ,c[8] ,p,i  'adresse, anzahl zeilen,ram oder xram
  zeile:=0
  p:=getx+23
  repeat line
    printnl
    printhex(adr,5)
    printchar(":")

    repeat i from 0 to 7
      if mod==2
         c[i]:=Read_Flash_Data(adr++)
      if mod==1
           c[i]:=ram_rdbyte(adr++)
      if mod==0
         c[i]:=byte[adr++]
      printhex(c[i],2)
      printchar(" ")

    repeat i from 0 to 7
      printqchar(c[i])

    zeile++
    if zeile == 12
       printnl
       print(string("<CONTINUE? */esc:>"))
       if keywait == 27
          printnl
            quit
       zeile:=0

DAT
                        org 0
'
' Entry
'
entry                   jmp     #entry                   'just loops


regsys        byte  "reg.sys",0

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

                                                                                                                                            
