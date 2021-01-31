{{

Hive-Computer-Projekt

Name            : Peek and Poke
Chip            : Regnatix-Code (ramtest)
Version         : 0.1
Dateien         : ram_pasm.spin

Beschreibung    :
}}
CON

_CLKMODE     = XTAL1 + PLL16X
_XINFREQ     = 5_000_000
DB_IN           = %00000110_11111111_11111111_00000000  'maske: dbus-eingabe

#0,JOB_NONE,JOB_POKE,JOB_PEEK,JOB_FILL,JOB_WRLONG,JOB_RDLONG,JOB_WRWORD,JOB_RDWORD,DO_READ,DO_WRITE,JOB_COPY,JOB_KEEP
VAR
  long CogNr
  long JobNr     ' 3 continue params
  long Address
  long Value
  long Anzahl
  long Werte

pub rd_value(adr,m):w
    Address := adr
    Value   := m
    dira    := 0
    JobNr   := DO_READ
    repeat until JobNr == JOB_NONE
    dira   := DB_IN
    w := Werte

pub wr_value(adr,val,m)
  Address := adr
  Value   := val
  Anzahl   := m
  dira    := 0
  JobNr   := DO_WRITE
  repeat until JobNr == JOB_NONE
  dira := DB_IN


pub ram_fill(adr,anz,wert)

    Address:=adr
    Value  :=wert
    Anzahl :=anz
    dira   :=0
    JobNr  :=JOB_FILL
    repeat until JobNr==JOB_NONE
    dira:=DB_IN

pub ram_copy(von,ziel,zahl)
    Address:=von
    Value:=ziel
    Anzahl:=zahl
    dira :=0
    JobNr:=Job_Copy
    repeat until JobNr==JOB_NONE
    dira:=DB_IN

pub ram_keep(adr):w
    address:=adr
'    Value:=0
'    Anzahl:=0
    dira  := 0
    JobNr:=Job_keep
    repeat until JobNr == JOB_NONE
    dira   := DB_IN
    w := Werte+1

Pub Start
  CogNr := cognew(@cog_loop,@JobNr)

Pub Stop
  if CogNr==-1
    return
  cogstop(CogNr)
  CogNr:=-1
DAT                     ORG 0

cog_loop                rdlong  _job,par wz   ' get job id
              if_z      jmp     #cog_loop
              '********** Parameter einlesen **********************
                        mov     _ptr,par        ' pointer of params
                        add     _ptr,#4         ' move to param 1
                        rdlong  _adr,_ptr       ' lese 1.Parameter
                        add     _ptr,#4         ' move to param 2
                        rdlong  _val,_ptr       ' lese 2.Parameter
                        add     _ptr,#4         ' move to param 3
                        rdlong  _count,_ptr     ' lese 3-Parameter
                        mov     _ftemp,_adr     ' Kopie von _adr
              '********** Kommandoabfrage *************************
                        cmp     _job,#DO_WRITE wz
              if_z      jmp     #cog_write

                        cmp     _job,#DO_READ wz
              if_z      jmp     #cog_read

                        cmp     _job,#JOB_FILL wz
              if_z      jmp     #cog_fill

                        cmp     _job,#JOB_COPY wz
              if_z      jmp     #cog_copy

              if_z      cmp     _job,#JOB_KEEP wz
                        jmp     #cog_keeping

                        jmp     #cog_loop


'**************************************************************************************

cog_ready               mov     _ptr,par        'Parameter
                        mov     _job,#JOB_NONE  'Job mit null füllen
                        wrlong  _job,_ptr       'nach hubram
                        jmp     #cog_loop       'zurück zur Abfrageschleife
'######################################################################################

'**************************************************************************************

cog_subpeek             add     _ptr,#4         ' Ergebnis nach Werte übergeben next param
                        wrlong  _tmp,_ptr       ' Wert -> hubram
                        jmp     #cog_ready      ' ausstieg

'**************************** eine Zeile überspringen (testet auf 0)***************

cog_keeping             call    #sub_peek
                        cmp     _tmp,#0   wz     'Wert 0?
                if_z    jmp     #cog_keepout     'dann raus
                        call    #moving          'Adresse erhöhen
                        jmp     #cog_keeping     'weiter

cog_keepout             mov     _tmp,_ftemp      'Adresse nach tmp
                        jmp     #cog_subpeek

'************************Ram-Bereich kopieren**************************************

cog_copy
                        mov     _REGA,_val       'zieladresse merken

loop_copy               call    #sub_peek        'Wert aus Quellspeicher lesen
                        mov     _val,_tmp        'peekwert nach _val kopieren
                        mov     _adr,_REGA       'zieladresse nach _adr
                        call    #sub_poke        'wert in Zielspeicher schreiben
                        add     _REGA,#1         'Zieladresse erhöhen
                        call    #moving          'Quelladresse erhöhen und nach _adr zurückschreiben
                        djnz    _count,#loop_copy 'counter runterzählen
                        jmp     #cog_ready        'raus

'************************Ram-Bereich mit einem Wert füllen*****************************

cog_fill                call    #sub_poke         'schreiben
                        call    #moving
                        djnz    _count, #cog_fill'nächste zelle bis _count = 0
                        jmp     #cog_ready

'************************Byte,Word oder Long schreiben*********************************
cog_write
                        mov     _RegA,_val      ' wert merken
                        mov     _RegB,#8        ' shiftwert
                        mov     _RegC,#3        ' Zaehlerschleifenwert
                        call    #sub_poke

                        cmp     _count,#JOB_POKE wz 'wenn nur poke hier aussteigen
              if_z      jmp     #cog_ready

loop_wrlong             mov     _val,_RegA
                        shr     _val,_RegB      'wert>>8
                        add     _RegB,#8        'shiftwert um 8 erhoehen

                        call    #moving
                        call    #sub_poke

                        cmp     _count,#JOB_WRWORD wz 'wenn wrword hier aussteigen
              if_z      jmp     #cog_ready

                        djnz    _RegC,#loop_wrlong

                        jmp     #cog_ready

'***********************Byte, Word oder Long lesen*************************************
cog_read
                        mov     _RegA,#8        ' shiftwert
                        mov     _RegC,#3        ' Schleifenzaehler

                        call    #sub_peek

                        cmp     _val,#JOB_PEEK wz 'wenn nur peek hier aussteigen
              if_z      jmp     #cog_subpeek

                        call    #rd_wr

loop_rd                 call    #sub_peek
                        shl     _tmp,_RegA
                        add     _tmp,_RegB
                        call    #rd_wr

                        cmp     _val,#JOB_RDWORD wz 'wenn rdword, dann hier raus
              if_z      jmp     #cog_subrdword

                        add     _regA,#8
                        djnz    _RegC,#loop_rd

cog_subrdword           add     _ptr,#4         ' next param
                        wrlong  _RegB,_ptr

                        jmp     #cog_ready


'**************************************************************************************
rd_wr                   mov     _RegB,_tmp
moving                  add     _ftemp,#1        'adresse+1
                        mov     _adr,_ftemp      'adresse zurueckschreiben
moving_ret
rd_wr_ret               ret
'**************************************************************************************

'*****************************ein Byte in den RAM schreiben****************************
sub_poke                mov     _tmp,_adr       ' make a copy
                        and     _val,#$FF       ' only D7-D0
                        ' BUS
                        mov     outa,_BUS_INIT  ' all de-selected
                        mov     dira,_DIR_OUT   ' D7..D0 as output
                        call     #setadr

                        or      _adr,_val       ' D7-D0
                        or      _adr,_BUS_INIT  ' BUS
                        and     _tmp,_m_A19 wz  ' MSB of address
                        mov     _tmp,_adr
              if_z      and     _adr,_BUS_WR_R1 ' address <= $07FFFF
              if_nz     and     _adr,_BUS_WR_R2 ' address >= $800000
                        mov     outa,_adr       ' /WR+/RAMx + A10-A0 + D7-D0
                        nop
                        nop
                        mov     outa,_tmp       ' BUS + A10-A0 + D7-D0
                        nop
                        nop
                        mov     dira,#0

sub_poke_ret            ret
'*****************************Ein Byte aus dem Ram lesen*******************************

sub_peek                mov     _tmp,_adr       ' make a copy

                        ' BUS

                        mov     outa,_BUS_INIT  ' all de-selected
                        mov     dira,_DIR_IN    ' D7..D0 as input
                        call    #setadr
                        and     _tmp,_m_A19 wz  ' MSB of address
                        'mov     _tmp,_adr
              if_z      or      _adr,_BUS_RD_R1 ' address <= $07FFFF
              if_nz     or      _adr,_BUS_RD_R2 ' address >= $800000
                        mov     outa,_adr       ' /RAMx + A10-A0
                        nop
                        nop
                        mov     _tmp,ina
                        nop
                        nop
                        and     _tmp,#$FF       ' only D7-D0
                        mov     dira,#0
sub_peek_ret            ret
'******************************RAM-Adresse setzen***************************************

setadr                  ' ADR HI
                        and     _adr,_m_A18_A11 ' hi part
                        shr     _adr,#3         ' move to latch port
                        or      _adr,_BUS_AL_HI ' BUS + AL hi
                        mov     outa,_adr       ' BUS + AL hi + ADR
                        and     _adr,_BUS_AL_LO
                        mov     outa,_adr       ' BUS + AL lo + LATCH
                        ' ADR LO
                        mov     _adr,_tmp       ' from copy
                        and     _adr,_m_A10_A00 ' lo part
                        shl     _adr,#8         ' mov to address port
setadr_ret              ret
'**************************************************************************************

'                       __    ____
'                       HWCA AABRR    Latch
'                       SRLL LDEAA    A18-A11
'                         k2 1MLMMAAA AAAAAAAA DDDDDDDD
'                               21098 76543210 76543210
_DIR_OUT      long %00000110_11111111_11111111_11111111
_DIR_IN       long %00000110_11111111_11111111_00000000
_BUS_INIT     long %00000100_01111000_00000000_00000000
_BUS_AL_HI    long %00000100_11111000_00000000_00000000
_BUS_AL_LO    long %00000100_01111000_11111111_00000000
_BUS_WR_R1    long %00000000_01110111_11111111_11111111
_BUS_WR_R2    long %00000000_01101111_11111111_11111111
_BUS_RD_R1    long %00000100_01110000_00000000_00000000
_BUS_RD_R2    long %00000100_01101000_00000000_00000000
_m_A19        long %00000100_00001000_00000000_00000000
_m_A18_A11    long %00000000_00000111_11111000_00000000
_m_A10_A00    long %00000000_00000000_00000111_11111111
                          '|_________________________________ HBEAT
{
' ======================================================================================
' KONSTANTEN & VARIABELN
' ======================================================================================
'                      +------------------------------- /hs
'                      |+------------------------------ /wr
'                      ||+----------------------------- busclk
'                      |||+---------------------------- hbeat
'                      |||| +-------------------------- al
'                      |||| |+------------------------- /bel
'                      |||| ||+------------------------ /adm
'                      |||| |||+----------------------- /ram2
'                      |||| ||||+---------------------- /ram1
'                      |||| |||||           +---------- a0..10
'                      |||| |||||           |
'                      |||| |||||           |        +- d0..7
'                      |||| |||||+----------+ +------+
_b1         long  %00000001_00111000_00000000_00000000  ' adm=1, bel=0, wr=0, busclk=0
_b2         long  %00000011_00111000_00000000_00000000  ' adm=1, bel=0, wr=0, busclk=1
_b3         long  %00000111_00111000_00000000_00000000  ' adm=1, bel=0, wr=1, busclk=1
_a1         long  %00000001_01011000_00000000_00000000  ' adm=0, bel=1, wr=0, busclk=0
_a2         long  %00000011_01011000_00000000_00000000  ' adm=0, bel=1, wr=0, busclk=1
_a3         long  %00000111_01011000_00000000_00000000  ' adm=0, bel=1, wr=1, busclk=1
_hs         long  %00001000_00000000_00000000_00000000  ' hs=1?
_zero       long  %00000000_00000000_00000000_00000000  '
}
_job          res 1
_ptr          res 1
_adr          res 1
_val          res 1
_count        res 1
_tmp          res 1
_ftemp        res 1
_regA         res 1
_RegB         res 1
_RegC         res 1
                                                       fit 496
