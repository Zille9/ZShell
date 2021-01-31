{{      Bellatrix-Code
┌──────────────────────────────────────────────────────────────────────────────────────────────────────┐
│ Autor: Ingo Kripahle                                                                                 │
│ Copyright (c) 2012 Ingo Kripahle                                                                     │
│ See end of file for terms of use.                                                                    │
│ Die Nutzungsbedingungen befinden sich am Ende der Datei                                              │
└──────────────────────────────────────────────────────────────────────────────────────────────────────┘

Informationen   : hive-project.de
Kontakt         : drohne235@googlemail.com
System          : trios
Name            :
Chip            : global
Typ             : konstanten


}}

CON 'Signaldefinitionen --------------------------------------------------------------------------

'signaldefinitionen global

#0,     D0,D1,D2,D3,D4,D5,D6,D7                         'datenbus
#24,    LATCH                                           'front-led
        BUSCLK                                          'bustakt
        BUS_WR                                          '/wr - schreibsignal
        BUS_HS '                                        '/hs - quittungssignal
        I2C_SCL
        I2C_SDA
        SER_TX
        SER_RX


'signaldefinitionen bellatrix

#8,     B_VGABASE                                     'vga-signale (8pin)
#16,    B_KEYBC,B_KEYBD                               'keyboard-signale
#18,    B_MOUSEC,B_MOUSED                             'maus-signale
#20,    B_VIDBASE                                     'video-signale(3pin)
#23,    B_SELECT                                      'belatrix-auswahlsignal


'signaldefinitionen administra

#8,     A_SOUNDL,A_SOUNDR                             'sound (stereo 2 pin)
#10,    A_SDD0,A_SDCLK,A_SDCMD,A_SDD3                 'sd-cardreader (4 pin)
#23,    A_SELECT                                      'administra-auswahlsignal

CON 'KEY_CODES -------------------------------------------------------------------------------------

KEY_CTRL        = 2
KEY_ALT         = 4
KEY_OS          = 8

KEY_ESC         = 27
KEY_TAB         = 9
KEY_RETURN      = 13
KEY_BS          = 8
KEY_POS1        = 6

KEY_CURUP       = 04
KEY_CURDOWN     = 05
KEY_CURLEFT     = 02
KEY_CURRIGHT    = 03
KEY_PAGEUP      = 160
KEY_PAGEDOWN    = 162
KEY_SPACE       = 32

KEY_F01         = 208
KEY_F02         = 209
KEY_F03         = 210
KEY_F04         = 211
KEY_F05         = 212
KEY_F06         = 213
KEY_F07         = 214
KEY_F08         = 215
KEY_F09         = 216
KEY_F10         = 217
KEY_F11         = 218
KEY_F12         = 219


CON 'ADMINISTRA-FUNKTIONEN --------------------------------------------------------------------------

'                                          +----------- ays
'                                          |+---------- com
'                                          || +-------- plexbus
'                                          || |+------- rtc
'                                          || ||+------ lan
'                                          || |||+----- sid
'                                          || ||||+---- wav
'                                          || |||||+--- hss
'                                          || ||||||+-- chiploader
'                                          || |||||||+- dateisystem
A_FAT           = %00000000_00000000_00000000_00000001
A_LDR           = %00000000_00000000_00000000_00000010
A_HSS           = %00000000_00000000_00000000_00000100
A_WAV           = %00000000_00000000_00000000_00001000
A_SID           = %00000000_00000000_00000000_00010000
A_LAN           = %00000000_00000000_00000000_00100000
A_RTC           = %00000000_00000000_00000000_01000000
A_PLX           = %00000000_00000000_00000000_10000000
A_COM           = %00000000_00000000_00000001_00000000
A_AYS           = %00000000_00000000_00000010_00000000
'                                  |
'                                  ym


'       ----------------------------------------------  SD-FUNKTIONEN
#1,     a_sdMount                                       'sd-card mounten                                              '
        a_sdOpenDir                                     'direktory öffnen
        a_sdNextFile                                    'verzeichniseintrag lesen
        a_sdOpen                                        'datei öffnen
        a_sdClose                                       'datei schließen
        a_sdGetC                                        'zeichen lesen
        a_sdPutC                                        'zeichen schreiben
        a_sdGetBlk                                      'block lesen
        a_sdPutBlk                                      'block schreiben
        a_sdSeek         '10                            'zeiger in datei positionieren
        a_sdFAttrib                                     'dateiattribute übergeben
        a_sdVolname                                     'volumelabel abfragen
        a_sdCheckMounted                                'test ob volume gemounted ist
        a_sdCheckOpen                                   'test ob eine datei geöffnet ist
        a_sdCheckUsed                                   'test wie viele sektoren benutzt sind
        a_sdCheckFree                                   'test wie viele sektoren frei sind
        a_sdNewFile                                     'neue datei erzeugen
        a_sdNewDir                                      'neues verzeichnis wird erzeugt
        a_sdDel                                         'verzeichnis oder datei löschen
        a_sdRename       '20                            'verzeichnis oder datei umbenennen
        a_sdChAttrib                                    'attribute ändern
        a_sdChDir                                       'verzeichnis wechseln
        a_sdFormat                                      'medium formatieren
        a_sdUnmount                                     'medium abmelden
        a_sdDmAct                                       'dir-marker aktivieren
        a_sdDmSet                                       'dir-marker setzen
        a_sdDmGet                                       'dir-marker status abfragen
        a_sdDmClr                                       'dir-marker löschen
        a_sdDmPut                                       'dir-marker status setzen
        a_sdEOF          '30                            'eof abfragen
        a_sdPOS                                         'Position innerhalb einer Datei abfragen
        a_sdCOPY                 '32                    'Datei kopieren
        a_loadblock                                     'block lesen
'       ----------------------------------------------  COM-FUNKTIONEN
#34,    a_comStart
        a_comTx
        a_comRx
        a_comRxCheck
        a_comStop         '38
        a_comStr                '39


'       ----------------------------------------------  Bluetooth-Funktionen
#40,    a_bl_Command_On
        a_bl_Command_Off          '40
'       ----------------------------------------------  RTC-FUNKTIONEN
#42,    a_rtcGetSeconds                                 'Returns the current second (0 - 59) from the real time clock.
        a_rtcGetMinutes                                 'Returns the current minute (0 - 59) from the real time clock.
        a_rtcGetHours                                   'Returns the current hour (0 - 23) from the real time clock.
        a_rtcGetDay                                     'Returns the current day (1 - 7) from the real time clock.
        a_rtcGetDate                                    'Returns the current date (1 - 31) from the real time clock.
        a_rtcGetMonth                                   'Returns the current month (1 - 12) from the real time clock.
        a_rtcGetYear                                    'Returns the current year (2000 - 2099) from the real time clock.
        a_rtcSetSeconds                                 'Sets the current real time clock seconds. Seconds - Number to set the seconds to between 0 - 59.
        a_rtcSetMinutes                                 'Sets the current real time clock minutes. Minutes - Number to set the minutes to between 0 - 59.
        a_rtcSetHours                                   'Sets the current real time clock hours. Hours - Number to set the hours to between 0 - 23.
        a_rtcSetDay                                     'Sets the current real time clock day. Day - Number to set the day to between 1 - 7.
        a_rtcSetDate   '52                              'Sets the current real time clock date. Date - Number to set the date to between 1 - 31.
        a_rtcSetMonth                                   'Sets the current real time clock month. Month - Number to set the month to between 1 - 12.
        a_rtcSetYear                                    'Sets the current real time clock year. Year - Number to set the year to between 2000 - 2099.
        a_rtcSetNVSRAM                                  'Sets the NVSRAM to the selected value (0 - 255) at the index (0 - 55).
        a_rtcGetNVSRAM                                  'Gets the selected NVSRAM value at the index (0 - 55).
        a_rtcPauseForSec                                'Pauses execution for a number of seconds. Returns a puesdo random value derived from the current clock frequency and the time when called. Number - Number of seconds to pause for between 0 and 2,147,483,647.
        a_rtcPauseForMSec '58                           'Pauses execution for a number of milliseconds. Returns a puesdo random value derived from the current clock frequency and the time when called. Number - Number of milliseconds to pause for between 0 and 2,147,483,647.
        a_rtcTest         '59                           'Test if RTC Chip is available
{        a_DCF_InSync                                    'Sync-Status senden
        a_DCF_Update_Clock                              'RTC Synchronisieren
        a_DCF_GetBitError
        a_DCF_GetDatacount
        a_DCF_GetBitNumber '64
        a_DCF_GetBitLevel
        a_DCF_GetTimeZone
        a_DCF_GetActiveSet
        a_DCF_start                                     'DCF-Empfang starten 68
        a_DCF_stop                                      'DCF-Empfang stoppen 69
        a_DCF_dcfon        '70                          'Status des DCF-Empfängers

'       ----------------------------------------------  LAN-FUNKTIONEN
#72,    a_LANStart                                      'Start SeriellNetwork
        a_LANStop                                       'Stop SeriellNetwork
        a_lanConnect                                    'ausgehende TCP-Verbindung öffnen
        a_lanListen                                     'auf eingehende TCP-Verbindung lauschen
        a_lanWaitConnTimeout                            'bestimmte Zeit auf Verbindung warten
        a_lanClose                                      'TCP-Verbindung schließen
        a_lanRXTime                                     'bestimmte Zeit warten auf Byte aus Empfangspuffer
        a_lanRXData                                     'Daten aus Empfangspuffer lesen
        a_lanTXData                                     'Daten senden
        a_lanRXByte                                     'wenn vorhanden, Byte aus Empfangspuffer lesen
        a_lanIsConnected '87                            'TRUE, wenn Socket verbunden, sonst FALSE

}
'       ----------------------------------------------  CHIP-MANAGMENT
#92,    a_mgrSetSound                                   'soundsubsysteme verwalten
        a_mgrGetSpec                                    'spezifikation abfragen
        a_mgrSetSysSound                                'systemsound ein/ausschalten
        a_mgrGetSoundSys                                'abfrage welches soundsystem aktiv ist
        a_mgrALoad                                      'neuen code booten
        a_mgrGetCogs                                    'freie cogs abfragen
        a_mgrGetVer                                     'codeversion abfragen
        a_mgrReboot             '99                     'neu starten

'       ----------------------------------------------  HSS-FUNKTIONEN
#100,   a_hssLoad                                       'hss-datei in puffer laden
        a_hssPlay                                       'play
        a_hssStop                                       'stop
        a_hssPause                                      'pause
        a_hssPeek                                       'register lesen
        a_hssIntReg                                     'interfaceregister auslesen
        a_hssVol                                        'lautstärke setzen
        a_sfxFire                                       'sfx abspielen
        a_sfxSetSlot                                    'sfx-slot setzen
        a_sfxKeyOff
        a_sfxStop               '110

#111,   a_getJoystick1                                  'lese Joystick-Register1
        a_getJoystick2                                  'lese Joystick-Register2

        {a_DCF_getseconds
        a_DCF_GetMinutes
        a_DCF_gethours
        a_DCF_GetWeekDay
        a_DCF_GetDay
        a_DCF_GetMonth
        a_DCF_GetYear           '117}
'       ----------------------------------------------  PLX-Funktionen
#120,   a_plxRun                                        'plx-bus freigeben
        a_plxHalt                                       'plx-bus anfordern
        a_plxIn                                         'port einlesen
        a_plxOut                                        'port ausgeben
        a_plxCh                                         'ad-wandler auslesen
        a_plxGetReg                                     'poller-register lesen
        a_plxSetReg                                     'poller-register setzen
        a_plxStart                                      'i2c-dialog starten
        a_plxStop                                       'i2c-dialog beenden
        a_plxWrite                                      'i2c byte senden
        a_plxRead                                       'i2c byte empfangen
        a_plxPing                                       'abfrage ob device vorhanden ist
        a_plxSetAdr                                     'adressen adda/ports für poller setzen
'       ----------------------------------------------  GAMEDEVICES
        a_Joy                                           'Joystick abfragen (1 x 8bit Port)
        a_Paddle                                        'Paddle abfragen (1 x 8bit Port 1 x Analog)
        a_Pad                                           'Pad abfragen (1 x 8bit Port 2 x Analog)
        a_SetJoy                                        'Port für Joystick setzen
        a_SetPad                '137                    'Chan für Pad setzen
        a_i2cStart                                      'PLX starten
        a_i2cStop               '139                    'PLX stoppen

'       ----------------------------------------------  Soundumschaltung und Bellatrix-Ram-Aktivierung
#140,   a_SoundSwitch                                   'Sound von Administra nach Bellatrix routen
        a_RAMCS                                         'Bellatrix-Ram-Erweiterung aktivieren

'       ----------------------------------------------  WAV-FUNKTIONEN
#150,   a_sdwStart                                      'spielt wav-datei direkt von sd-card ab
        a_sdwStop                                       'stopt wav-cog
        a_sdwStatus                                     'fragt status des players ab
        a_sdwLeftVol                                    'lautstärke links
        a_sdwRightVol                                   'lautstärke rechts
        a_sdwPause                                      'player pause/weiter-modus
        a_sdwPosition           '156

'       ----------------------------------------------  AY-SOUNDFUNKTIONEN
#200,   a_ayStart
        a_ayStop
        a_ayUpdateRegisters

'       ----------------------------------------------  SIDCog: DMP-Player-Funktionen (SIDCog2)
#156,   a_s_dmplen                                 'Anzahl dmp-Samples
        a_s_mdmpplay                               'dmp-file mono auf sid2 abspielen
        a_s_sdmpplay                               'dmp-file stereo auf beiden sids abspielen
        a_s_dmpstop                                'dmp-player beenden
        a_s_dmppause                               'dmp-player pausenmodus
        a_s_dmpstatus                              'dmp-player statusabfrage
        a_s_dmppos                                 'player-position im dumpfile
        a_s_mute                                   'alle register löschen

'       ----------------------------------------------  SIDCog1-Funktionen
        a_s1_setRegister
        a_s1_updateRegisters
        a_s1_setVolume
        a_s1_play
        a_s1_noteOn
        a_s1_noteOff
        a_s1_setFreq
        a_s1_setWaveform
        a_s1_setPWM
        a_s1_setADSR
        a_s1_setResonance
        a_s1_setCutoff
        a_s1_setFilterMask
        a_s1_setFilterType
        a_s1_enableRingmod
        a_s1_enableSynchronization

'       ----------------------------------------------  SIDCog2-Funktionen
        a_s2_setRegister
        a_s2_updateRegisters
        a_s2_setVolume
        a_s2_play
        a_s2_noteOn
        a_s2_noteOff
        a_s2_setFreq
        a_s2_setWaveform
        a_s2_setPWM
        a_s2_setADSR
        a_s2_setResonance
        a_s2_setCutoff
        a_s2_setFilterMask
        a_s2_setFilterType
        a_s2_enableRingmod
        a_s2_enableSynchronization

'       ----------------------------------------------  Zusatzfunktionen
        a_s_dmpreg    '196                              'soundinformationen senden
        a_s_SidBeep
        a_s_ResetRegister


'       ---------------------------------------------- Funktionsgenerator
#210,   a_startFunctionGenerator
        a_stopFunctionGenerator
        a_PulseWidth
        a_Frequency_HZ
        a_Frequency_Centihz
        a_SetWaveform
        a_SetDampLevel
        a_SetUserWaveform
        a_setParameter

'       ---------------------------------------------- Flash-Chip anstatt Lan-Chip
#220,   a_FlashID
        a_FlashSize
        a_ReadData
        a_WriteData
        a_EraseData
        a_RD_FlashBL
        a_RD_FlashBL2
        a_WR_FlashBL
        a_WR_FlashBL2
        a_RD_Flash_Long
        a_WR_Flash_Long
        a_sdtoFlash
        a_flashtosd
        a_SET_Flash_Adress
        a_GET_FLASH_BYTE
        a_PUT_FLASH_BYTE
        a_freeSize
        a_firstFile
        a_NextFile
        a_OpenFile
        a_eraseFile
        a_readFile
        a_writeFile
        a_bootfile
        a_sd_flash_copy
        a_Drive
        {244}
'       ---------------------------------------------- Bluetooth Statusabfrage im Plexus-Modul
#254,   a_HC05_Status
CON 'NVRAM Konstanten --------------------------------------------------------------------------

' todo: nach glob-con.spin auslagern!!!

#4,     NVRAM_IPADDR
#8,     NVRAM_IPMASK
#12,    NVRAM_IPGW
#16,    NVRAM_IPDNS
#20,    NVRAM_IPBOOT
#24,    NVRAM_HIVE       ' 4 Bytes

'signaldefinitionen administra (todo: nach glob-con.spin auslagern!!!)

#14,     A_NETCS,A_NETSCK,A_NETSI,A_NETSO              'Pins zum ENC28J60

CON 'BELLATRIX-FUNKTIONEN --------------------------------------------------------------------------

'                                           +----------
'                                           | +-------- window
'                                           | |+------- vektor
'                                           | ||+------ grafik
'                                           | |||+----- text
'                                           | ||||+---- maus
'                                           | |||||+--- tastatur
'                                           | ||||||+-- vga
'                                           | |||||||+- tv
B_TV            = %00000000_00000000_00000000_00000001
B_VGA           = %00000000_00000000_00000000_00000010
B_KEY           = %00000000_00000000_00000000_00000100
B_MOUSE         = %00000000_00000000_00000000_00001000
B_TXT           = %00000000_00000000_00000000_00010000
B_PIX           = %00000000_00000000_00000000_00100000
B_VEC           = %00000000_00000000_00000000_01000000
B_WIN           = %00000000_00000000_00000000_10000000

' einzeichen-steuercodes

#$0,    BEL_CMD              'esc-code für zweizeichen-steuersequenzen
        BEL_FREE
        BEL_FREE1
        BEL_FREE2
        BEL_POS1
        BEL_LEFT
        BEL_RIGHT
        BEL_HOME
        BEL_BS
        BEL_TAB
        BEL_DOWN
        BEL_UP
        BEL_CLS
        BEL_CRLF


#1,     BEL_KEY_STAT
        BEL_KEY_CODE
        BEL_KEY_SPEC
        BEL_KEY_INKEY
        BEL_CLEARKEY
        BEL_SCR_CHAR
        BEL_DPL_SETX
        BEL_DPL_SETY'SCRCMD           'esc-code für dreizeichen-sequenzen
        BEL_MOUSE_PRESENT
        BEL_DPL_MOUSE
        BEL_LD_MOUSEBOUND
        BEL_MOUSEX
        BEL_MOUSEY
        BEL_MOUSEZ
        BEL_MOUSE_BUTTON
        BEL_LD_MOUSEPOINTER
        BEL_BOXSIZE
        BEL_CURSORCOLOR
        BEL_CURSORRATE
        BEL_BOXCOLOR
        BEL_ERS_3DBUTTON
        BEL_SCROLLUP
        BEL_SCROLLDOWN
        BEL_DPL_3DBOX
        BEL_DPL_3DFRAME
        BEL_DPL_2DBOX
        BEL_Send_BUTTON
        BEL_SCROLLSTRING
        BEL_DPL_STRING
        BEL_DPL_SETPOS
        BEL_DPL_TILE
        BEL_DPL_WIN
        BEL_LD_TILESET
        BEL_DPL_PIC
        BEL_GETX
        BEL_GETY
        BEL_DPL_LINE
        BEL_DPL_PIXEL
        '--------- BASIC-GRAFIKFUNKTIONEN -------
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
        '--------- BASIC-GRAFIKFUNKTIONEN -------
        BEL_DPL_PALETTE
        BEL_DEL_WINDOW
        BEL_SET_TITELSTATUS
        BEL_BACK
        BEL_REST
        BEL_CHANGE_BACKUP
        BEL_WINDOW
        BEL_GET_WINDOW
        BEL_PRINTFONT   '60
        BEL_VGAPUT
        BEL_BIGFONT
        BEL_RECT
        BEL_THIRDCOLOR
        BEL_DPL_CIRCLE
        BEL_TESTXY
        BEL_REDEFINE
        BEL_GETLINELEN
        BEL_DISPLAYPOINT
        BEL_POINTDISPLAY '70
        BEL_WRITE_RAM
        BEL_READ_RAM
        BEL_GETZEIL      'aktuelle Zeilennummer für Nanotex
        BEL_SEND_STRING
        BEL_SETZEIL


#80,    BMGR_WIN_DEFINE
        BMGR_FREI
        BMGR_WIN_SET
        BMGR_FREI2
        BMGR_WIN_GETCOLS
        BMGR_WIN_GETROWS
        BMGR_WIN_OFRAME
        BMGR_LOAD
        BMGR_WSCR
        BMGR_DSCR
        BMGR_GETCOLOR '90
        BMGR_SETCOLOR
        BMGR_GETRESX
        BMGR_GETRESY
        BMGR_GETCOLS
        BMGR_GETROWS
        BMGR_GETCOGS
        BMGR_GETSPEC
        BMGR_GETVER
        BMGR_REBOOT
        BMGR_FLASHLOAD '100
        BMGR_UPDATE
        BMGR_UPPERSTART
        BMGR_LOWERSTART
        BMGR_DUMP
'--------------------------------- TRIOS -----------------------------------
#1,     B_KEYSTAT               'tastaturstatus senden
        B_KEYCODE               'tastaturzeichen senden
        B_PRINTCTRL             'steuerzeichen ($100..$1FF) ausgeben
        B_KEYSPEC               'statustasten ($100..$1FF) abfragen
        B_PRINTLOGO             'hive-logo ausgeben
        B_PRINTQCHAR   '6       'zeichen ohne steuerzeichen augeben

#80,    B_WDEF
        B_WSET
        B_WGETCOLS
        B_WGETROWS
        B_WOFRAME      '84

#87,    B_MGRLOAD               'neuen bellatrix-code laden
        B_MGRWSCR               'setzt screen, in welchen geschrieben wird
        B_MGRDSCR               'setzt screen, welcher angezeigt wird
        B_MGRGETCOL             'farbregister auslesen
        B_MGRSETCOL             'farbregister setzen
        B_MGRGETRESX            'x-auflösung abfragen
        B_MGRGETRESY            'y-auflösung abfragen
        B_MGRGETCOLS            'spaltenanzahl abfragen
        B_MGRGETROWS            'zeilenanzahl abfragen
        B_MGRGETCOGS            'freie cogs abfragen
        B_MGRGETSPEC            'spezifikation abfragen
        B_MGRGETVER             'codeversion abfragen
        B_MGRREBOOT     '99     'bellatrix neu starten

' steuerzeichen
#0,     B_CMD                   'esc-code für zweizeichen-steuersequenzen
        B_CLS
        B_HOME
        B_POS1
        B_CURON
        B_CUROFF
        B_SCROLLUP
        B_SCROLLDOWN
        B_BACKSPACE
        B_TAB
        B_LF
        B_FREE1
        B_FREE2
        B_CRLF

' dreizeichen-steuersequenzen
' [B_CMD][B_SCRCMD][...]

#01,    B_SETCUR
        B_SETX
        B_SETY
        B_GETX
        B_GETY
        B_SETCOL
        B_FREE3
        B_FREE4
        B_SINIT
        B_TABSET
        B_WSETX
        B_WSETY
        B_WGETX
        B_WGETY


{CON 'G0-FUNKTIONEN --------------------------------------------------------------------------

#1,	G0_KEYSTAT
	G0_KEYCODE
	G0_KEYSPEC

#10,	G0_CLEAR
	G0_COPY
	G0_COLOR
	G0_WIDTH
	G0_COLORWIDTH
	G0_PLOT
	G0_LINE
	G0_ARC
	G0_VEC
	G0_VECARC
	G0_PIX
	G0_PIXARC
	G0_TEXT
	G0_TEXTARC
	G0_TEXTMODE
	G0_BOX
	G0_QUAD
	G0_TRI

#93,	G0_COLORTAB
	G0_SCREEN
	G0_DATBLK
	G0_DATLEN
	G0_DYNAMIC
	G0_STATIC
	G0_REBOOT
}
PUB glob_con_dummy
  return

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
