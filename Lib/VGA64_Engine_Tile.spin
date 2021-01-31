{{
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// VGA64 Tilemap Engine
//
// Author: Kwabena W. Agyeman
// Updated: 7/27/2010
// Designed For: P8X32A
// Version: 1.0
//
// Copyright (c) 2010 Kwabena W. Agyeman
// See end of file for terms of use.
//
// Update History:
//
// v1.0 - Original release - 7/27/2010.
//
// For each included copy of this object only one spin interpreter should access it at a time.
//
// Nyamekye,
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Video Circuit:
//
//     0   1   2   3 Pin Group
//
//                     240OHM
// Pin 0,  8, 16, 24 ----R-------- Vertical Sync
//
//                     240OHM
// Pin 1,  9, 17, 25 ----R-------- Horizontal Sync
//
//                     470OHM
// Pin 2, 10, 18, 26 ----R-------- Blue Video
//                            |
//                     240OHM |
// Pin 3, 11, 19, 27 ----R-----
//
//                     470OHM
// Pin 4, 12, 20, 28 ----R-------- Green Video
//                            |
//                     240OHM |
// Pin 5, 13, 21, 29 ----R-----
//
//                     470OHM
// Pin 6, 14, 22, 30 ----R-------- Red Video
//                            |
//                     240OHM |
// Pin 7, 15, 23, 31 ----R-----
//
//                            5V
//                            |
//                            --- 5V
//
//                            --- Vertical Sync Ground
//                            |
//                           GND
//
//                            --- Hoirzontal Sync Ground
//                            |
//                           GND
//
//                            --- Blue Return
//                            |
//                           GND
//
//                            --- Green Return
//                            |
//                           GND
//
//                            --- Red Return
//                            |
//                           GND
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
}}

CON

  #$FC, Light_Grey, #$A8, Grey, #$54, Dark_Grey
  #$C0, Light_Red, #$80, Red, #$40, Dark_Red
  #$30, Light_Green, #$20, Green, #$10, Dark_Green
  #$0C, Light_Blue, #$08, Blue, #$04, Dark_Blue
  #$F0, Light_Orange, #$A0, Orange, #$50, Dark_Orange
  #$CC, Light_Purple, #$88, Purple, #$44, Dark_Purple
  #$3C, Light_Teal, #$28, Teal, #$14, Dark_Teal
  #$FF, White, #$00, Black

  #0, Cursor_Left, Cursor_Right, #10, Cursor_Down, Cursor_Up
  '# -1, Focus
  #8, Backspace, Tab, Line_feed, Vertical_Tab, Form_Feed, Carriage_Return

VAR

  long bufferaddress[12]
  word puffer[12]
  byte printRow, printColumn, printBoxFGColor[8], printBoxBGColor[8], printStartRow[8], printStartColumn[8], printEndRow[8], printEndColumn[8]
  byte win,thirdcolor
  byte yendwin[8],xendwin[8],yanf[8],xanf[8],cursorx[8],cursory[8]
  byte big

obj ' xmm:"Hiveblade"
{PUB printString(characters) '' 30 Stack Longs

'' ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
'' // Prints a string to the screen inside of the print box defined by the print settings.
'' //
'' // Characters - A pointer to a string of characters to be printed.
'' ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  repeat strsize(characters)
    printCharacter(byte[characters++])
  }
{pub startram
    xmm.start

pub getscreen|adr
    'adr:=0
    'repeat 1200
          xmm.DoCmd("W", @chromabuffer, 0, 4800) 'longs
    '      adr+=4
    'repeat 1200
           xmm.DoCmd("W", @lumabuffer, $12C0, 2400) 'words
    '       adr+=2

pub setscreen|adr

    xmm.DoCmd("R", @chromabuffer, 0, 4800) 'longs
    xmm.DoCmd("R", @lumabuffer, $12C0, 2400) 'words
}
pub printat(y,x)
    printColumn:=x
    printRow:=y

pub dritte_Farbe(n)
    thirdcolor:=n


{pub PlotPixel(startColumn,startRow,c)|punkt,color
    if c
       color:=printBoxFGColor[win]
    else
       color:=printBoxBGColor[win]
'' ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
'' // Displays a Dot on screen.
'' //
'' // Color - A color byte (%RR_GG_BB_xx) to use.
'' // StartRow - The row to start drawing on. Each row is 16 pixels tall so there are 30 rows numbered 0 - 29.
'' // StartColumn - The column to start drawing on. Each column is 16 pixels wide so there are 40 columns numbered 0 - 39.
'' ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  color := computeFillColor(color)
  drawingStart(startRow, startColumn, startRow, startColumn)
  punkt := (startRow*40)+ startColumn
  chromaBuffer[punkt]:=color
  drawingStop
}
pub put(c,x,y)

    displayCharacter(c, printBoxFGColor[win], printBoxBGColor[win], y, x)

pub setx(x)
    printColumn:=x

pub sety(y)
    printRow:=y

pub getx
    return printColumn

pub gety
    return printRow

PUB printCharacter(character,n) '' 26 Stack Longs

'' ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
'' // Prints a character to the screen inside of the print box defined by the print settings.
'' //
'' // 0 - Move the cursor left one space.
'' // 1 - Move the cursor right one space.
'' // 8 - Backspace. Move the cursor back one space and delete the character underneath it.
'' // 9 - Tab. Move the cursor forward eight spaces.
'' // 10 - Line Feed. Move the cursor down.
'' // 11 - Vertical Tab. Move the cursor up.
'' // 12 - Form Feed. Move the cursor back to the start of the print box and clear the print box.
'' // 13 - Carriage Return. Move the cursor back to the start of the line.
'' //
'' // Character - A character to be printed. -1 to focus.
'' ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  if(printStartRow[win] =< printEndRow[win])
    if(character <> -1)

      case character
        2: 'return
        4: printColumn :=0
        5: printColumn -= 1
        6: printColumn += 1
        7: printColumn:=0
           printRow:=0
        8:
          printColumn -= 1
          character:=" "

        9: printColumn += (4 - (printColumn & $3))
        10: printRow +=1+big
        11: printRow -=(1+big)

        12:
          printRow := printStartRow[win]
          printColumn := printStartColumn[win]
          display2DBox(printBoxBGColor[win], printStartRow[win], printStartColumn[win], printEndRow[win], printEndColumn[win])

        13: printColumn := printStartColumn[win]
            printRow +=1 + big
        other: result := true

      if((~printColumn) < printStartColumn[win])
        printColumn := printEndColumn[win]
        printRow -=(1+big)

      if((~printRow) < printStartRow[win])
        printRow := printStartRow[win]
        scrollDown(1+big, printBoxBGColor[win], printStartRow[win], printStartColumn[win], printEndRow[win], printEndColumn[win],1)

      repeat 2

        if((~printColumn) > printEndColumn[win])
          printColumn := printStartColumn[win]
          printRow +=1+big

        if((~printRow) > printEndRow[win])
          printRow := (printEndRow[win]-big)
          scrollUp(1+big, printBoxBGColor[win], printStartRow[win], printStartColumn[win], printEndRow[win], printEndColumn[win],1)

        if(result or (character == " "))
          if big
             displayCharacter2(character~, printBoxFGColor[win],printBoxBGColor[win], printRow, printColumn)
          else
             displayCharacter(n, printBoxFGColor[win],printBoxBGColor[win], printRow, printColumn)

        printColumn -= result~
    printPosition := @chromaBuffer[computeIndex(printRow, printColumn)]
pub bigfont(n)
    big:=n
PUB printqChar(character) '' 26 Stack Longs

'' ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
'' // Prints a character to the screen inside of the print box defined by the print settings.
'' //
'' // 0 - Move the cursor left one space.
'' // 1 - Move the cursor right one space.
'' // 8 - Backspace. Move the cursor back one space and delete the character underneath it.
'' // 9 - Tab. Move the cursor forward eight spaces.
'' // 10 - Line Feed. Move the cursor down.
'' // 11 - Vertical Tab. Move the cursor up.
'' // 12 - Form Feed. Move the cursor back to the start of the print box and clear the print box.
'' // 13 - Carriage Return. Move the cursor back to the start of the line.
'' //
'' // Character - A character to be printed. -1 to focus.
'' ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  if(printStartRow[win] < printEndRow[win])
    'if(character <> -1)

      result := true

      if((~printColumn) < printStartColumn[win])
        printColumn := printEndColumn[win]
        printRow -= (1+big)

      if((~printRow) < printStartRow[win])
        printRow := printStartRow[win]
        scrollDown(1+big, printBoxBGColor[win], printStartRow[win], printStartColumn[win], printEndRow[win], printEndColumn[win],1)

      repeat 2

        if((~printColumn) > printEndColumn[win])
          printColumn := printStartColumn[win]
          printRow += (1+big)

        if((~printRow) > printEndRow[win])
          printRow := (printEndRow[win])
          scrollUp(1+big, printBoxBGColor[win], printStartRow[win], printStartColumn[win], printEndRow[win], printEndColumn[win],1)

        if(result)' or (character == " "))
          displayCharacter(character, printBoxFGColor[win], printBoxBGColor[win], printRow, printColumn)

        printColumn -= result~
    printPosition := @chromaBuffer[computeIndex(printRow, printColumn)]

PUB printBoxColor(fenster,fore, back) '' 5 Stack Longs

'' ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
'' // Changes the print box colors.
'' //
'' // ForegroundColor - A color byte (%RR_GG_BB_xx) for the foreground character color.
'' // BackgroundColor - A color byte (%RR_GG_BB_xx) for the background character color.
'' ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
  win:=fenster
  printBoxFGColor[win] := fore
  printBoxBGColor[win] := back

PUB printBoxSize(fenster,startRow, startColumn, endRow, endColumn) '' 31 Stack Longs

'' ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
'' // Changes the print box size and position.
'' //
'' // StartRow - The row to start printing on. Each row is 16 pixels tall so there are 30 rows numbered 0 - 29.
'' // StartColumn - The column to start printing on. Each column is 16 pixels wide so there are 40 columns numbered 0 - 39.
'' // EndRow - The row to end printing on. Each row is 16 pixels tall so there are 30 rows numbered 0 - 29.
'' // EndColumn - The column to end printing on. Each column is 16 pixels wide so there are 40 columns numbered 0 - 39.
'' ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
  win:=fenster
  yendwin[win]:=endrow
  xendwin[win]:=endColumn
  yanf[win]:=startRow
  xanf[win]:=startColumn
  printEndRow[win]:= limitRow(yendwin[win])
  printEndColumn[win] := limitColumn(xendwin[win])
  printStartRow[win] := computeLimit(yanf[win], printEndRow[win])
  printStartColumn[win] := computeLimit(xanf[win], printEndColumn[win])
  'printEndRow += (not((printEndRow - printStartRow) & 1))
  'printCharacter(12)
   printRow := printStartRow[win]
   printColumn := printStartColumn[win]
   display2DBox(printBoxBGColor[win], printStartRow[win], printStartColumn[win], printEndRow[win], printEndColumn[win])

pub printwindow(fenster)
  cursorx[win]:=printCursorColumn
  cursory[win]:=printCursorRow
  win:=fenster
  'printEndRow[win]:= limitRow(yendwin[win])
  'printEndColumn[win] := limitColumn(xendwin[win])
  'printStartRow[win] := computeLimit(yanf[win], printEndRow[win])
  'printStartColumn[win] := computeLimit(xanf[win], printEndColumn[win])
  printrow:=cursory[win]'printStartrow
  printcolumn:=cursorx[win]'printStartColumn

pub del_win(fenster)
printStartRow[fenster]   :=printStartRow[0]
printStartColumn[fenster]:=printStartColumn[0]
printEndRow[fenster]     :=printEndRow[0]
printEndColumn[fenster]  :=printEndColumn[0]
printBoxBGColor[fenster] :=printBoxBGColor[0]
printBoxFGColor[fenster] :=printBoxFGColor[0]
cursory[fenster]         :=cursory[0]
cursorx[fenster]         :=cursorx[0]
win:=0
printwindow(0)

PUB printCursorColor(color) '' 8 Stack Longs

'' ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
'' // Changes the print cursor color.
'' //
'' // Color - A color byte (%RR_GG_BB_xx) describing the print cusor color.
'' ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  printColor := computeFillColor(color)

PUB printCursorRate(rate) '' 8 Stack Longs

'' ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
'' // Changes the print cursor (blink) rate.
'' //
'' // Rate - A blink rate for the print cursor. 0=0Hz, 1=0.46875Hz, 2=0.9375Hz, 3=1.875Hz, 4=3.75Hz, 5=7.5Hz, 6=15Hz, 7=30Hz.
'' ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  printRate := ($100 >> computeLimit(rate, 7))

PUB printCursorRow '' 3 Stack Longs

'' ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
'' // Returns the current row the print cursor is on.
'' ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  return ~printRow

PUB printCursorColumn '' 3 Stack Longs

'' ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
'' // Returns the current column the print cursor is on.
'' ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  return ~printColumn

PUB scrollUp(lines, color, startRow, startColumn, endRow, endColumn,rate) '' 24 Stack Longs
   'row zeile
   'column spalte
'' ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
'' // Scrolls the contents of whatever is in the specified area up and scrolls in blank space of the selected color.
'' //
'' // Color - A color byte (%RR_GG_BB_xx) to use for the background color being scrolled in.
'' // Lines - Number of rows to scroll up. This function will do nothing if this value is invalid.
'' // StartRow - The row to start scrolling on. Each row is 16 pixels tall so there are 30 rows numbered 0 - 29.
'' // StartColumn - The column to start scrolling on. Each column is 16 pixels wide so there are 40 columns numbered 0 - 39.
'' // EndRow - The row to end scrolling on. Each row is 16 pixels tall so there are 30 rows numbered 0 - 29.
'' // EndColumn - The column to end scrolling on. Each column is 16 pixels wide so there are 40 columns numbered 0 - 39.
'' ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  color := computeFillColor(color)
  endRow := limitRow(endRow)
  endColumn := limitColumn(endColumn)
  startRow := computeLimit(startRow, endRow)
  startColumn := computeLimit(startColumn, endColumn)
  lines := (computeLimit(lines, (endRow - startRow+big)) * 40)

  if(lines)
    drawingStart(startRow, startColumn, endRow, endColumn)
    startRow := computeIndex(startRow, startColumn)
    endRow := computeIndex(endRow, startColumn)
    endColumn -= --startColumn

    if(lines =< (endRow - startRow))
      repeat result from startRow to (endRow - lines) step 40
        wordmove(@lumaBuffer[result], @lumaBuffer[result + lines], endColumn)
        longmove(@chromaBuffer[result], @chromaBuffer[result + lines], endColumn)
        if rate>0
           waitcnt( cnt+=clkfreq / (1000/rate))
    repeat result from (endRow + 40 - lines) to endRow step 40
      longfill(@chromaBuffer[result], color, endColumn)
      if rate >0
         waitcnt( cnt+=clkfreq / (1000/rate))
    drawingStop

PUB scrollDown(lines, color, startRow, startColumn, endRow, endColumn,rate) '' 24 Stack Longs

'' ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
'' // Scrolls the contents of whatever is in the specified area down and scrolls in blank space of the selected color.
'' //
'' // Color - A color byte (%RR_GG_BB_xx) to use for the background color being scrolled in.
'' // Lines - Number of rows to scroll down. This function will do nothing if this value is invalid.
'' // StartRow - The row to start scrolling on. Each row is 16 pixels tall so there are 30 rows numbered 0 - 29.
'' // StartColumn - The column to start scrolling on. Each column is 16 pixels wide so there are 40 columns numbered 0 - 39.
'' // EndRow - The row to end scrolling on. Each row is 16 pixels tall so there are 30 rows numbered 0 - 29.
'' // EndColumn - The column to end scrolling on. Each column is 16 pixels wide so there are 40 columns numbered 0 - 39.
'' ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  color := computeFillColor(color)
  endRow := limitRow(endRow)
  endColumn := limitColumn(endColumn)
  startRow := computeLimit(startRow, endRow)
  startColumn := computeLimit(startColumn, endColumn)
  lines := (computeLimit(lines, (endRow - startRow+big)) * 40)

  if(lines)
    drawingStart(startRow, startColumn, endRow, endColumn)
    startRow := computeIndex(startRow, startColumn)
    endRow := computeIndex(endRow, startColumn)
    endColumn -= --startColumn

    if(lines =< (endRow - startRow))
      repeat result from endRow to (startRow + lines) step 40
        wordmove(@lumaBuffer[result], @lumaBuffer[result - lines], endColumn)
        longmove(@chromaBuffer[result], @chromaBuffer[result - lines], endColumn)
        if rate>0
           waitcnt( cnt+=clkfreq / (1000/rate))
    repeat result from startRow to (startRow - 40 + lines) step 40
      longfill(@chromaBuffer[result], color, endColumn)
      if rate>0
         waitcnt( cnt+=clkfreq / (1000/rate))
    drawingStop

{PUB display3DTextBox(characters, textColor, topColor, centerColor, bottomColor, row, column) '' 35 Stack Longs

'' ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
'' // Displays a 3D text box on screen.
'' //
'' // Characters - A string to display using the internal ROM font. Each character is 1 tile wide and 2 tiles tall.
'' // TextColor - Text color byte (%RR_GG_BB_xx) to use.
'' // TopColor - Top edge and side color byte (%RR_GG_BB_xx) to use.
'' // CenterColor - Center color byte (%RR_GG_BB_xx) to use.
'' // BottomColor - Bottom edge and side color byte (%RR_GG_BB_xx) to use.
'' // Row - Top right corner row of the text box. The box will be 4 rows tall and 2 + string size wide.
'' // Column - Top right corner column of the text box. The box will be 4 rows tall and 2 + string size wide.
'' ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  displayString(characters, textColor, centerColor, ++row, ++column)
  display3DFrame(topColor, centerColor, bottomColor, --row, --column, (row + 3), (++column + strsize(characters)))
}
{PUB display3DpressedTextBox(characters, textColor, topColor, centerColor, bottomColor, row, column) '' 35 Stack Longs

'' ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
'' // Displays a 3D text box on screen.
'' //
'' // Characters - A string to display using the internal ROM font. Each character is 1 tile wide and 2 tiles tall.
'' // TextColor - Text color byte (%RR_GG_BB_xx) to use.
'' // TopColor - Top edge and side color byte (%RR_GG_BB_xx) to use.
'' // CenterColor - Center color byte (%RR_GG_BB_xx) to use.
'' // BottomColor - Bottom edge and side color byte (%RR_GG_BB_xx) to use.
'' // Row - Top right corner row of the text box. The box will be 4 rows tall and 2 + string size wide.
'' // Column - Top right corner column of the text box. The box will be 4 rows tall and 2 + string size wide.
'' ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  displayString(characters, textColor, centerColor, ++row, ++column)
  display3DFrame(topColor, centerColor, bottomColor, --row, --column, (row + 3), (++column + strsize(characters)))
}
'PUB display2DTextBox(characters, forgroundColor, backgroundColor, row, column) '' 31 Stack Longs

'' ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
'' // Displays a 2D text box on screen.
'' //
'' // Characters - A string to display using the internal ROM font. Each character is 1 tile wide and 2 tiles tall.
'' // ForegroundColor - The color to use for the foreground of the text box.
'' // BackgroundColor - The color to use for the background of the text box.
'' // Row - Top right corner row of the text box. The box will be 4 rows tall and 2 + string size wide.
'' // Column - Top right corner column of the text box. The box will be 4 rows tall and 2 + string size wide.
'' ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

'  displayString(characters, forgroundColor, backgroundColor, ++row, ++column)
'  display2DFrame(backgroundColor, --row, --column, (row + 3), (++column + strsize(characters)))

PUB display3DBox(topColor, centerColor, bottomColor, startRow, startColumn, endRow, endColumn) '' 35 Stack Longs

'' ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
'' // Displays a 3D box on screen.
'' //
'' // TopColor - Top edge and side color byte (%RR_GG_BB_xx) to use.
'' // CenterColor - Center color byte (%RR_GG_BB_xx) to use.
'' // BottomColor - Bottom edge and side color byte (%RR_GG_BB_xx) to use.
'' // StartRow - The row to start drawing on. Each row is 16 pixels tall so there are 30 rows numbered 0 - 29.
'' // StartColumn - The column to start drawing on. Each column is 16 pixels wide so there are 40 columns numbered 0 - 39.
'' // EndRow - The row to end drawing on. Each row is 16 pixels tall so there are 30 rows numbered 0 - 29.
'' // EndColumn - The column to end drawing on. Each column is 16 pixels wide so there are 40 columns numbered 0 - 39.
'' ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  display2DBox(centerColor, startRow, startColumn, endRow, endColumn)
  display3DFrame(topColor, centerColor, bottomColor, startRow, startColumn, endRow, endColumn)

PUB display3DFrame(topColor, centerColor, bottomColor, startRow, startColumn, endRow, endColumn) '' 25 Stack Longs

'' ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
'' // Displays a 3D frame on screen.
'' //
'' // TopColor - Top edge and side color byte (%RR_GG_BB_xx) to use.
'' // CenterColor - Center color byte (%RR_GG_BB_xx) to use.
'' // BottomColor - Bottom edge and side color byte (%RR_GG_BB_xx) to use.
'' // StartRow - The row to start drawing on. Each row is 16 pixels tall so there are 30 rows numbered 0 - 29.
'' // StartColumn - The column to start drawing on. Each column is 16 pixels wide so there are 40 columns numbered 0 - 39.
'' // EndRow - The row to end drawing on. Each row is 16 pixels tall so there are 30 rows numbered 0 - 29.
'' // EndColumn - The column to end drawing on. Each column is 16 pixels wide so there are 40 columns numbered 0 - 39.
'' ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  centerColor := computeTileColor(centerColor, bottomColor, topColor)
  endRow := limitRow(endRow)
  endColumn := limitColumn(endColumn)
  startRow := computeLimit(startRow, endRow)
  startColumn := computeLimit(startColumn, endColumn)
  drawingStart(startRow, startColumn, endRow, endColumn)

  startRow := computeIndex(startRow, startColumn)
  endRow := computeIndex(endRow, startColumn)
  endColumn -= startColumn

  longfill(@chromaBuffer[startRow], centerColor, ++endColumn)
  wordfill(@lumaBuffer[startRow], $83_00, endColumn)
  longfill(@chromaBuffer[endRow], centerColor, endColumn)
  wordfill(@lumaBuffer[endRow], $83_40, endColumn--)

  repeat result from startRow to endRow step 40
    lumaBuffer[result] := $82_80
    chromaBuffer[result] := centerColor
    lumaBuffer[result + endColumn] := $82_C0
    chromaBuffer[result + endColumn] := centerColor

  lumaBuffer[endRow] := $80_40
  lumaBuffer[endRow + endColumn] := $82_40
  lumaBuffer[startRow] := $80_00
  lumaBuffer[startRow + endColumn] := $82_00

  drawingStop
pub plot(color,row,column)
    color := computeFillColor(color)
    longfill(@chromaBuffer[(row*40)+column], color, 1)
pub pixel(x,y,s)|c
    if s
       c:=printBoxFGColor[win]
    else
       c:=printBoxBGColor[win]
    plot(c,y,x)

PUB display2DBox(color, startRow, startColumn, endRow, endColumn) '' 23 Stack Longs

'' ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
'' // Displays a 2D box on screen.
'' //
'' // Color - A color byte (%RR_GG_BB_xx) to use.
'' // StartRow - The row to start drawing on. Each row is 16 pixels tall so there are 30 rows numbered 0 - 29.
'' // StartColumn - The column to start drawing on. Each column is 16 pixels wide so there are 40 columns numbered 0 - 39.
'' // EndRow - The row to end drawing on. Each row is 16 pixels tall so there are 30 rows numbered 0 - 29.
'' // EndColumn - The column to end drawing on. Each column is 16 pixels wide so there are 40 columns numbered 0 - 39.
'' ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  color := computeFillColor(color)
  endRow := limitRow(endRow)
  endColumn := limitColumn(endColumn)
  startRow := computeLimit(startRow, endRow)
  startColumn := computeLimit(startColumn, endColumn)
  drawingStart(startRow, startColumn, endRow, endColumn)

  startRow := computeIndex(startRow, startColumn)
  endRow := computeIndex(endRow, startColumn)
  endColumn -= --startColumn

  repeat result from startRow to endRow step 40
    longfill(@chromaBuffer[result], color, endColumn)
    wordfill(@lumabuffer[result],32,endcolumn)                      'Ergänzung um BS-Speicher zu löschen -> für Tileabfragen
  drawingStop

'PUB display2DFrame(color, startRow, startColumn, endRow, endColumn) '' 23 Stack Longs

'' ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
'' // Displays a 2D frame on screen.
'' //
'' // Color - A color byte (%RR_GG_BB_xx) to use.
'' // StartRow - The row to start drawing on. Each row is 16 pixels tall so there are 30 rows numbered 0 - 29.
'' // StartColumn - The column to start drawing on. Each column is 16 pixels wide so there are 40 columns numbered 0 - 39.
'' // EndRow - The row to end drawing on. Each row is 16 pixels tall so there are 30 rows numbered 0 - 29.
'' // EndColumn - The column to end drawing on. Each column is 16 pixels wide so there are 40 columns numbered 0 - 39.
'' ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

'  color := computeFillColor(color)
'  endRow := limitRow(endRow)
'  endColumn := limitColumn(endColumn)
'  startRow := computeLimit(startRow, endRow)
'  startColumn := computeLimit(startColumn, endColumn)
'  drawingStart(startRow, startColumn, endRow, endColumn)

'  startRow := computeIndex(startRow, startColumn)
'  endRow := computeIndex(endRow, startColumn)
'  endColumn -= startColumn

'  longfill(@chromaBuffer[startRow], color, ++endColumn)
'  longfill(@chromaBuffer[endRow], color, endColumn--)
'  repeat result from startRow to endRow step 40
'    chromaBuffer[result] := color
'    chromaBuffer[result + endColumn] := color

'  drawingStop
Pub Change_Backup(tilenr,f1,f2,f3)
    puffer[9]:=tilenr
    BufferAddress[9]:=computeTileColor(f1, f2, f3)

PUB dispBackup(startRow, startColumn,wordBufferAddress)', longBufferAddress) '' 24 Stack Longs
'original displayBackup(startRow, startColumn,endRow, endColumn, wordBufferAddress, longBufferAddress)
'' ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
'' // Backups a section of the screen to the provided buffers.
'' //
'' // The word buffer contains the 16 bit addresses of the backedup tiles.
'' //
'' // The word buffer should be ((endRow - startRow + 1) * (endColumn - startColumn + 1)) words in size.
'' //
'' // The long buffer contains the 32 bit colors of the backedup tiles. (4 Colors Per Tile - 1 Bytes Per Color).
'' //
'' // The long buffer should be ((endRow - startRow + 1) * (endColumn - startColumn + 1)) longs in size.
'' //
'' // StartRow - The row to start on. Each row is 16 pixels tall so there are 30 rows numbered 0 - 29.
'' // StartColumn - The column to start on. Each column is 16 pixels wide so there are 40 columns numbered 0 - 39.
'' // EndRow - The row to end on. Each row is 16 pixels tall so there are 30 rows numbered 0 - 29.
'' // EndColumn - The column to end on. Each column is 16 pixels wide so there are 40 columns numbered 0 - 39.
'' ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    puffer[wordBufferAddress]:= lumaBuffer[(startrow*40)+(startcolumn)]
    BufferAddress[wordBufferAddress]:= chromaBuffer[(startrow*40)+startcolumn]

pub getblock(nummer)
    return lumaBuffer[nummer]

PUB dispRestore(startRow, startColumn,wordBufferAddress)' '' 24 Stack Longs
'' ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
'' // Restores a section of the screen from the provided buffers.
'' //
'' // The word buffer contains the 16 bit addresses of the restored tiles.
'' //
'' // The word buffer should be ((endRow - startRow + 1) * (endColumn - startColumn + 1)) words in size.
'' //
'' // The long buffer contains the 32 bit colors of the restored tiles. (4 Colors Per Tile - 1 Bytes Per Color).
'' //
'' // The long buffer should be ((endRow - startRow + 1) * (endColumn - startColumn + 1)) longs in size.
'' //
'' // StartRow - The row to start on. Each row is 16 pixels tall so there are 30 rows numbered 0 - 29.
'' // StartColumn - The column to start on. Each column is 16 pixels wide so there are 40 columns numbered 0 - 39.
'' // EndRow - The row to end on. Each row is 16 pixels tall so there are 30 rows numbered 0 - 29.
'' // EndColumn - The column to end on. Each column is 16 pixels wide so there are 40 columns numbered 0 - 39.
'' ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    lumaBuffer[(startrow*40)+startcolumn]:=puffer[wordBufferAddress]
    chromaBuffer[(startrow*40)+startcolumn]:=BufferAddress[wordBufferaddress]

pub Backup_luma(x,y):wert
    wert:=lumaBuffer[(y*40)+x]

pub backup_chroma(x,y):wert
    wert:=chromaBuffer[(y*40)+x]

pub restore_luma(x,y,wert)
    lumaBuffer[(y*40)+x]:=wert
pub restore_chroma(x,y,wert)
    chromaBuffer[(y*40)+x]:=wert
PUB displayBackup(startRow, startColumn,endRow, endColumn, wordBufferAddress, longBufferAddress)', longBufferAddress) '' 24 Stack Longs
'original displayBackup(startRow, startColumn,endRow, endColumn, wordBufferAddress, longBufferAddress)
'' ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
'' // Backups a section of the screen to the provided buffers.
'' //
'' // The word buffer contains the 16 bit addresses of the backedup tiles.
'' //
'' // The word buffer should be ((endRow - startRow + 1) * (endColumn - startColumn + 1)) words in size.
'' //
'' // The long buffer contains the 32 bit colors of the backedup tiles. (4 Colors Per Tile - 1 Bytes Per Color).
'' //
'' // The long buffer should be ((endRow - startRow + 1) * (endColumn - startColumn + 1)) longs in size.
'' //
'' // StartRow - The row to start on. Each row is 16 pixels tall so there are 30 rows numbered 0 - 29.
'' // StartColumn - The column to start on. Each column is 16 pixels wide so there are 40 columns numbered 0 - 39.
'' // EndRow - The row to end on. Each row is 16 pixels tall so there are 30 rows numbered 0 - 29.
'' // EndColumn - The column to end on. Each column is 16 pixels wide so there are 40 columns numbered 0 - 39.
'' ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  endRow := limitRow(endRow)
  endColumn := limitColumn(endColumn)
  startRow := computeLimit(startRow, endRow)
  startColumn := computeLimit(startColumn, endColumn)
  drawingStart(startRow, startColumn, endRow, endColumn)

  startRow := computeIndex(startRow, startColumn)
  endRow := computeIndex(endRow, startColumn)
  endColumn -= --startColumn

  repeat result from startRow to endRow step 40
    wordmove(wordBufferAddress, @lumaBuffer[result], endColumn)
    wordBufferAddress += (endColumn << 1)
    longmove(longBufferAddress, @chromaBuffer[result], endColumn)
    longBufferAddress += (endColumn << 2)

  drawingStop
PUB displayRestore(startRow, startColumn,endRow, endColumn, wordBufferAddress, longBufferAddress)' '' 24 Stack Longs
'original displayRestore(startRow, startColumn,endRow, endColumn, wordBufferAddress, longBufferAddress)
'' ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
'' // Restores a section of the screen from the provided buffers.
'' //
'' // The word buffer contains the 16 bit addresses of the restored tiles.
'' //
'' // The word buffer should be ((endRow - startRow + 1) * (endColumn - startColumn + 1)) words in size.
'' //
'' // The long buffer contains the 32 bit colors of the restored tiles. (4 Colors Per Tile - 1 Bytes Per Color).
'' //
'' // The long buffer should be ((endRow - startRow + 1) * (endColumn - startColumn + 1)) longs in size.
'' //
'' // StartRow - The row to start on. Each row is 16 pixels tall so there are 30 rows numbered 0 - 29.
'' // StartColumn - The column to start on. Each column is 16 pixels wide so there are 40 columns numbered 0 - 39.
'' // EndRow - The row to end on. Each row is 16 pixels tall so there are 30 rows numbered 0 - 29.
'' // EndColumn - The column to end on. Each column is 16 pixels wide so there are 40 columns numbered 0 - 39.
'' ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  endRow := limitRow(endRow)
  endColumn := limitColumn(endColumn)
  startRow := computeLimit(startRow, endRow)
  startColumn := computeLimit(startColumn, endColumn)
  drawingStart(startRow, startColumn, endRow, endColumn)

  startRow := computeIndex(startRow, startColumn)
  endRow := computeIndex(endRow, startColumn)
  endColumn -= --startColumn

  repeat result from startRow to endRow step 40
    wordmove(@lumaBuffer[result], wordBufferAddress, endColumn)
    wordBufferAddress += (endColumn << 1)
    longmove(@chromaBuffer[result], longBufferAddress, endColumn)
    longBufferAddress += (endColumn << 2)

  drawingStop

PUB scrollString(characters, characterRate, foregroundColor, backgroundColor, row, startColumn, endColumn) '' 34 Stack Longs

'' ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
'' // Scrolls a string of characters from right to left across a specified area. Will not display box characters.
'' //
'' // Characters - A string to display using the internal ROM font. Each character is 1 tile wide and 2 tiles tall.
'' // CharacterRate - The number of frames to wait before scrolling out the next character. 0=16.66ms, 1=33.33ms, 2=50ms, etc.
'' // ForegroundColor - The color to use for the foreground of the string.
'' // BackgroundColor - The color to use for the background of the string.
'' // Row - Row to scroll the string on, row 29 is not valid to use. Each row is 16 pixels tall. (0 - 29).
'' // StartColumn - Column to scroll the string to. Each column is 16 pixels wide so there are 40 columns numbered 0 - 39.
'' // EndColumn - Column to scroll the string from. Each column is 16 pixels wide so there are 40 columns numbered 0 - 39.
'' ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  endColumn := limitColumn(endColumn)
  startColumn := computeLimit(startColumn, endColumn)
  repeat (strsize(characters) + (endColumn - startColumn) + 1)

    result := " "
    if(byte[characters])
      result := byte[characters++]

    displayWait(characterRate)
    scrollCharacter(result, foregroundColor, backgroundColor, row, startColumn, endColumn)

PUB scrollCharacter(character, foregroundColor, backgroundColor, row, startColumn, endColumn) '' 24 Stack Longs

'' ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
'' // Scrolls a character from right to left across a specified area. Will not display box characters.
'' //
'' // Character - A character to display using the internal ROM font. Each character is 1 tile wide and 2 tiles tall.
'' // ForegroundColor - The color to use for the foreground of the character.
'' // BackgroundColor - The color to use for the background of the character.
'' // Row - Row to scroll the string on, row 29 is not valid to use. Each row is 16 pixels tall. (0 - 29).
'' // StartColumn - Column to scroll the string to. Each column is 16 pixels wide so there are 40 columns numbered 0 - 39.
'' // EndColumn - Column to scroll the string from. Each column is 16 pixels wide so there are 40 columns numbered 0 - 39.
'' ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  endColumn := limitColumn(endColumn)
  startColumn := computeLimit(startColumn, endColumn)
  row := computeLimit(row, 28)

  result := computeIndex(row, startColumn)
  startColumn := (endColumn - startColumn)
  drawingStart(row, startColumn, row + 1, endColumn)

  repeat 2
    wordmove(@lumaBuffer[result], @lumaBuffer[++result], startColumn)
    longmove(@chromaBuffer[--result], @chromaBuffer[++result], startColumn)
    result += 39

  drawingStop
  displayCharacter(character, foregroundColor, backgroundColor, row, endColumn)

{PUB displayString(characters) '' 21 Stack Longs

'' ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
'' // Displays a string of characters starting at the specified column on the specified row. Will not display box characters.
'' //
'' // Characters - A string to display using the internal ROM font. Each character is 1 tile wide and 2 tiles tall.
'' // ForegroundColor - The color to use for the foreground of the string.
'' // BackgroundColor - The color to use for the background of the string.
'' // Row - Row to display the string on, row 29 is not valid to use. Each row is 16 pixels tall. (0 - 29).
'' // Column - Column to start displaying the string on. Each column is 16 pixels wide. (0 - 39).
'' ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  'column #>= 0
  repeat while(byte[characters] )'and (column =< 39))
    displayCharacter2(byte[characters++], printBoxFGColor[win], printBoxBGColor[win], printRow, printColumn++)

        if(printColumn > printEndColumn[win])
          printColumn := printStartColumn[win]
          printRow += 2

        if(printRow > printEndRow[win])
          printRow := (printEndRow[win])
          scrollUp(2, printBoxBGColor[win], printStartRow[win], printStartColumn[win], printEndRow[win], printEndColumn[win],1)
}
{pub print_bigchar(char)
        displayCharacter2(char, printBoxFGColor[win], printBoxBGColor[win], printRow, printColumn++)
}
PUB displayCharacter2(character, foregroundColor, backgroundColor, row, column) '' 13 Stack Longs

'' ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
'' // Displays a character at the specified column on the specified row. Will not display box characters.
'' //
'' // Character - A character to display using the internal ROM font. Each character is 1 tile wide and 2 tiles tall.
'' // ForegroundColor - The color to use for the foreground of the character.
'' // BackgroundColor - The color to use for the background of the character.
'' // Row - Row to display the string on, row 29 is not valid to use. Each row is 16 pixels tall. (0 - 29).
'' // Column - Column to start displaying the string on. Each column is 16 pixels wide. (0 - 39).
'' ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
  if((character =< 1) or ((8 =< character) and (character =< 13)) or (256 =< character))
    character := " "

  result := (character & 1)
  backgroundColor.byte[1 + result] := foregroundColor
  backgroundColor.byte[2 - result] := backgroundColor
  backgroundColor.byte[3] := foregroundColor
  character := (((character >> 1) << 7) + $80_00)                   '$8000 ist der Ort, wo der Propeller-Font steht
  result := computeIndex(computeLimit(row, 28), limitColumn(column))

  repeat while(lockset(lockNumber - 1))
  'displayTile(character,backgroundColor,foregroundColor,0,row,column)

  repeat 2
     lumaBuffer[result] := character
     chromaBuffer[result] := backgroundColor
     result += 40
     character += $40

  lockclr(lockNumber - 1)

PUB displayCharacter(character, foregroundColor, backgroundColor, row, column) '' 13 Stack Longs

'' ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
'' // Displays a character at the specified column on the specified row. Will not display box characters.
'' //
'' // Character - A character to display using the internal ROM font. Each character is 1 tile wide and 2 tiles tall.
'' // ForegroundColor - The color to use for the foreground of the character.
'' // BackgroundColor - The color to use for the background of the character.
'' // Row - Row to display the string on, row 29 is not valid to use. Each row is 16 pixels tall. (0 - 29).
'' // Column - Column to start displaying the string on. Each column is 16 pixels wide. (0 - 39).
'' ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
 ' if((character =< 1) or ((8 =< character) and (character =< 13)) or (256 =< character))
 '   character := " "

'  result := (character & 1)
'  backgroundColor.byte[1 + result] := foregroundColor
'  backgroundColor.byte[2 - result] := backgroundColor
'  backgroundColor.byte[3] := foregroundColor
'  character := (((character >> 1) << 7) + $80_00)                   '$8000 ist der Ort, wo der Propeller-Font steht
  result := computeIndex(computeLimit(row, 28), limitColumn(column))

  'repeat while(lockset(lockNumber - 1))
  displayTile(character,backgroundColor,foregroundColor,thirdcolor,row,column)

'  repeat 2
'    lumaBuffer[result] := character
'    chromaBuffer[result] := backgroundColor
'    result += 40
'    character += $40

'  lockclr(lockNumber - 1)


PUB displayTile(address, primaryColor, secondaryColor, tertiaryColor, row, column) '' 15 Stack Longs

'' ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
'' // Displays a standard three colored tile.
'' //
'' // A tile should be formated in this way, example below:
'' //
'' // address long %%1111111111111112
'' //         long %%1111111111111122
'' //         long %%1111111111111232
'' //         long %%1111111111112332
'' //         long %%1111111111123332
'' //         long %%1111111111233332
'' //         long %%1111111112333332
'' //         long %%1111111123333332
'' //         long %%1111111233333332
'' //         long %%1111112333333332
'' //         long %%1111123333333332
'' //         long %%1111222222223332
'' //         long %%1111111111112332
'' //         long %%1111111111111232
'' //         long %%1111111111111122
'' //         long %%1111111111111112
'' //
'' // The tile image should be reversed to display properly.
'' //
'' // The address of the first long is the address of the mouse tile.
'' //
'' // Each tile has has 16 longs and each long has 16 pixels. Each pixel has a value of 1 - 3 using quaternary encoding.
'' //
'' // A pixel of 0 maps to nothing and a pixel of 1, 2, or 3 maps to the color byte (%RR_GG_BB_xx).
'' //
'' // Address - The address of the tile to display.
'' // PrimaryColor - The color mapping to pixels that have a value of 1 in quaternary.
'' // SecondaryColor - The color mapping to pixels that have a value of 2 in quaternary.
'' // TertiaryColor - The color mapping to pixels that have a value of 3 in quaternary.
'' // Row - The row to display the tile on. Each row is 16 pixels tall so there are 30 rows numbered 0 - 29.
'' // Column - The column to display the tile on. Each column is 16 pixels wide so there are 40 columns numbered 0 - 39.
'' ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  result := computeIndex(limitRow(row), limitColumn(column))
  repeat while(lockset(lockNumber - 1))
  lumaBuffer[result] := address
  chromaBuffer[result] := computeTileColor(primaryColor, secondaryColor, tertiaryColor)
  lockclr(lockNumber - 1)

PUB displayCursor '' 3 Stack Longs

'' ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
'' // Returns the address of the standard mouse cursor tile.
'' ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  return @mousePointer

PUB mouseCursorTile(address) '' 4 Stack Longs

'' ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
'' // Changes the mouse cursor tile.
'' //
'' // A mouse cusor tile should be formated in this way, example below:
'' //
'' // address long %%0000000000000003
'' //         long %%0000000000000033
'' //         long %%0000000000000333
'' //         long %%0000000000003333
'' //         long %%0000000000033333
'' //         long %%0000000000333333
'' //         long %%0000000003333333
'' //         long %%0000000033333333
'' //         long %%0000000333333333
'' //         long %%0000003333333333
'' //         long %%0000033333333333
'' //         long %%0000333333333333
'' //         long %%0000000000003333
'' //         long %%0000000000000333
'' //         long %%0000000000000033
'' //         long %%0000000000000003
'' //
'' // The tile image should be reversed to display properly.
'' //
'' // The address of the first long is the address of the mouse tile.
'' //
'' // Each tile has has 16 longs and each long has 16 pixels. Each pixel has a value of 0 - 3 using quaternary encoding.
'' //
'' // A pixel of 0 maps to nothing and a pixel of 1, 2, or 3 maps to the color byte (%RR_GG_BB_xx).
'' //
'' // Address - The address of the tile to display, null to disable.
'' ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  mouseLuma := address
  if address>0
     longmove(@mousepointer,address,16)     'neuen Mauszeiger verwenden
PUB mouseCursorColor(color) '' 4 Stack Longs

'' ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
'' // Changes the mouse cursor color.
'' //
'' // Color - A color byte (%RR_GG_BB_xx) describing the mouse cursor color.
'' ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
  mouseChroma := color

PUB mouseRowBounds(startRow, endRow) '' 8 Stack Longs

'' ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
'' // Returns true if the mouse is on or between the two provided rows and false if not.
'' //
'' // StartRow - The row to check to see if the mouse is on or after.
'' // EndRow - The row to check to see if the mouse is on or before.
'' ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  result := mouseTileRow
  return ((startRow =< result) and (result =< endRow))

PUB mouseColumnBounds(startColumn, endColumn) '' 8 Stack Longs

'' ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
'' // Returns true if the mouse is on or between the two provided columns and false if not.
'' //
'' // StartColumn - The column to check to see if the mouse is on or after.
'' // EndColumn - The column to check to see if the mouse is on or before.
'' ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  result := mouseTileColumn
  return ((startColumn =< result) and (result =< endColumn))

PUB mouseTileRow '' 3 Stack Longs

'' ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
'' // Return the current row the mouse is on.
'' ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  return (word[mouseYAddress] >> 4)

PUB mouseTileRowOffset '' 3 Stack Longs

'' ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
'' // Return pixel offset from the current row the mouse is on.
'' ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  return (word[mouseYAddress] & $F)

PUB mouseTileColumn '' 3 Stack Longs

'' ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
'' // Return the current column the mouse is on.
'' ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  return (word[mouseXAddress] >> 4)

PUB mouseTileColumnOffset '' 3 Stack Longs

'' ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
'' // Return pixel offset from the current column the mouse is on.
'' ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  return (word[mouseXAddress] & $F)

PUB displayState(state) '' 4 Stack Longs

'' ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
'' // Enables or disables the TMP Driver's video output - turning the monitor off or putting it into standby mode.
'' //
'' // State - True for active and false for inactive.
'' ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  displayIndicator := state

'PUB displayRate(rate) '' 8 Stack Longs

'' ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
'' // Returns true or false depending on the time elasped according to a specified rate.
'' //
'' // Rate - A display rate to return at. 0=0.234375Hz, 1=0.46875Hz, 2=0.9375Hz, 3=1.875Hz, 4=3.75Hz, 5=7.5Hz, 6=15Hz, 7=30Hz.
'' ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

'  result or= (($80 >> computeLimit(rate, 7)) & syncIndicator)

PUB displayWait(frames) '' 4 Stack Longs

'' ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
'' // Waits for the display vertical refresh.
'' //
'' // Frames - Number of vertical refresh frames to wait for.
'' ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  repeat (frames #> 0)
    result := syncIndicator
    repeat until(result <> syncIndicator)

'PUB displayColor(redAmount, greenAmount, blueAmount) '' 6 Stack Longs

'' ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
'' // Builds a color byte (%RR_GG_BB_xx) from red, green, and blue componets.
'' //
'' // RedAmount - The amount of red to add to the color byte. Between 0 and 3.
'' // GreenAmount - The amount of green to add to the color byte. Between 0 and 3.
'' // BlueAmount - The amount of blue to add to the color byte. Between 0 and 3.
'' ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

'  return ( (computeLimit(redAmount, 3) << 6) | (computeLimit(greenAmount, 3) << 4) | (computeLimit(blueAmount, 3) << 2) | $3)

PUB TMPEngineStart(pinGroup, axisXAddress, axisYAddress) '' 9 Stack Longs

'' ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
'' // Starts up the TMP driver running on a cog and checks out a lock for the driver.
'' //
'' // Returns true on success and false on failure.
'' //
'' // PinGroup - Pin group to use to drive the video circuit. Between 0 and 3.
'' // AxisXAddress - Address of the mouse x axis position variable. Must be a word address and not zero.
'' // AxisYAddress - Address of the mouse y axis position variable. Must be a word address and not zero.
'' ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  TMPEngineStop


  pinGroup := ((pinGroup <# 3) #> 0)
  directionState := ($FF << (8 * pinGroup))
  videoState := ($30_00_00_FF | (pinGroup << 9))
  pinGroup := constant((25_175_000 + 1_600) / 4)
  frequencyState := 1

  repeat 32
    pinGroup <<= 1
    frequencyState <-= 1
    if(pinGroup => clkfreq)
      pinGroup -= clkfreq
      frequencyState += 1

  mouseXAddress := axisXAddress
  mouseYAddress := axisYAddress
  chromaBufferAddress := @chromaBuffer
  lumaBufferAddress := @lumaBuffer
  printColorAddress := @printColor
  printPositionAddress := @printPosition
  printRateAddress := @printRate
  mouseChromaAddress := @mouseChroma
  mouseLumaAddress := @mouseLuma
  displayIndicatorAddress := @displayIndicator
  syncIndicatorAddress := @syncIndicator

  lockNumber := locknew
  cogNumber := cognew(@initialization, @mouseCache)
  if((++lockNumber) and (++cogNumber) and (chipver == 1) and axisXAddress and axisYAddress)
    return true

  TMPEngineStop

PUB TMPEngineStop '' 3 Stack Longs

'' ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
'' // Shuts down the TMP driver running on a cog and returns the lock used by the driver.
'' ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  if(cogNumber)
    cogstop(-1 + cogNumber~)

  if(lockNumber)
    lockret(-1 + lockNumber~)

PRI limitRow(row) ' 4 Stack Longs

  return ((row <# 29) #> 0)

PRI limitColumn(column) ' 4 Stack Longs

  return ((column <# 39) #> 0)

PRI computeFillColor(color) ' 4 Stack Longs

  repeat 3
    color.byte[++result] := color

  return color

Pub computeTileColor(primaryColor, secondaryColor, tertiaryColor) ' 6 Stack Longs

  primaryColor.byte[1] := primaryColor
  primaryColor.byte[2] := secondaryColor
  primaryColor.byte[3] := tertiaryColor
  return primaryColor

PRI computeLimit(value, limit) ' 5 Stack Longs

  return ((value <# limit) #> 0)

PRI computeIndex(row, column) ' 5 Stack Longs

  return ((row * 40) + column)

PRI drawingStart(startRow, startColumn, endRow, endColumn) ' 15 Stack Longs

  repeat while(lockset(lockNumber - 1))

  if(mouseRowBounds((startRow - 1), endRow) and mouseColumnBounds((startColumn - 1), endColumn))
    mouseLumaBackup := mouseLuma~

  displayWait(1)

PRI drawingStop ' 3 Stack Longs

  if(mouseLumaBackup)
    mouseLuma := mouseLumaBackup~

  lockclr(lockNumber - 1)

DAT

' /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
'                       TMP Driver
' /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

                        org

' //////////////////////Initialization/////////////////////////////////////////////////////////////////////////////////////////
'chromaBuffer
initialization          mov     vcfg,                 videoState                 ' Setup video hardware.
                        mov     frqa,                 frequencyState             '
                        movi    ctra,                 #%0_00001_101              '

                        mov     mouseAddCaches,       par                        ' Setup mouse buffer.
                        mov     mouseAddCaches + 1,   par                        '
                        mov     mouseAddCaches + 2,   par                        '
                        mov     mouseAddCaches + 3,   par                        '
                        add     mouseAddCaches + 1,   #128                       '
                        add     mouseAddCaches + 2,   #64                        '
                        add     mouseAddCaches + 3,   #192                       '

' /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
'                       Active Video
' /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

loop                    mov     tilesCounter,         #30                        ' Set/Reset tiles fill counter.

tilesDisplay            mov     tileCounter,          #16                        ' Set/Reset tile fill counter.
                        mov     activeCounter,        #0                         '

                        test    tilesCounter,         #1 wc                      ' Set/Reset invisible video.
if_c                    movd    lumaCacheUpdate,      #lumaCache                 '
if_c                    movd    chromaCacheUpdate,    #chromaCache               '
if_nc                   movd    lumaCacheUpdate,      #lumaCache + 40            '
if_nc                   movd    chromaCacheUpdate,    #chromaCache + 40          '

tileDisplay             mov     vscl,                 visibleScale               ' Set/Reset the video scale.
                        mov     counter,              #40                        '

                        test    tilesCounter,         #1 wc                      ' Set/Reset visible video.
if_nc                   movs    lumaUpdate,           #lumaCache                 '
if_nc                   movd    chromaUpdate,         #chromaCache               '
if_c                    movs    lumaUpdate,           #lumaCache + 40            '
if_c                    movd    chromaUpdate,         #chromaCache + 40          '

' //////////////////////Visible Video//////////////////////////////////////////////////////////////////////////////////////////

lumaUpdate              mov     buffer,               0                          ' Update display pixles.
                        add     lumaUpdate,           #1                         '

                        add     buffer,               activeCounter              ' Add in offset and get pixels.
                        rdlong  buffer,               buffer                     '

chromaUpdate            waitvid 0,                    buffer                     ' Update display colors.
                        add     chromaUpdate,         destinationIncrement       '

                        djnz    counter,              #lumaUpdate                ' Repeat.

' //////////////////////Invisible Video////////////////////////////////////////////////////////////////////////////////////////

                        mov     vscl,                 invisibleScale             ' Set/Reset the video scale.
                        add     activeCounter,        #4                         '

                        waitvid HSyncColors,          syncPixels                 ' Horizontal sync.

                        mov     inactiveCounter,      #3                         ' Update the cache.
                        cmp     tileCounter,          #3 wc, wz                  '
if_z                    mov     inactiveCounter,      #1                         '
if_nc                   call    #cacheUpdate                                     '

' //////////////////////Repeat/////////////////////////////////////////////////////////////////////////////////////////////////

                        djnz    tileCounter,          #tileDisplay               ' Repeat.
                        djnz    tilesCounter,         #tilesDisplay              '

' /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
'                       Inactive Video
' /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

                        mov     mousePC,              #displayMouse              ' Setup display and mouse PC.

' //////////////////////Update Cursor//////////////////////////////////////////////////////////////////////////////////////////

                        rdword  printTopPlace,        printPositionAddress       ' Update print cursor places.
                        mov     printBottomPlace,     printTopPlace              '
                        'add     printBottomPlace,     #160                       ' auskommentiert für halben Cursor

                        rdlong  printColorControl,    printColorAddress          ' Update print cursor settings.
                        rdbyte  printRateControl,     printRateAddress           '

                        add     refreshCounter,       #1                         ' Update sync indicator.
                        wrbyte  refreshCounter,       syncIndicatorAddress       '

' //////////////////////Set/Reset Cache Pointers///////////////////////////////////////////////////////////////////////////////

                        mov     displayCounter,       #4                         ' Reset loader.
                        movs    loadCheck,            #mouseAddresses            '
                        movs    loadPixels,           #mouseAddCaches            '
                        movs    loadColors,           #mouseAddColors            '

                        movd    lumaCacheUpdate,      #lumaCache                 ' Setup to update the cache.
                        movd    chromaCacheUpdate,    #chromaCache               '
                        mov     lumaPointer,          lumaBufferAddress          '
                        mov     chromaPointer,        chromaBufferAddress        '

' //////////////////////Front Porch////////////////////////////////////////////////////////////////////////////////////////////

                        mov     counter,              #11                        ' Set loop counter.

frontPorch              mov     vscl,                 blankPixels                ' Invisible lines.
                        waitvid HSyncColors,          #0                         '

                        jmpret  displayPC,            mousePC                    ' Do mouse stuff.

                        mov     vscl,                 invisibleScale             ' Horizontal sync.
                        waitvid HSyncColors,          syncPixels                 '

                        jmpret  displayPC,            mousePC                    ' Do mouse stuff.

                        djnz    counter,              #frontPorch                ' Repeat # times.

' //////////////////////Vertical Sync//////////////////////////////////////////////////////////////////////////////////////////

                        mov     counter,              #(2 + 2)                   ' Set loop counter.

verticalSync            mov     vscl,                 blankPixels                ' Invisible lines.
                        waitvid VSyncColors,          #0                         '

                        mov     inactiveCounter,      #(17 - 9)                  ' Update the cache.
                        call    #cacheUpdate                                     '

                        mov     vscl,                 invisibleScale             ' Vertical sync.
                        waitvid VSyncColors,          syncPixels                 '

                        mov     inactiveCounter,      #(3 - 1)                   ' Update the cache.
                        call    #cacheUpdate                                     '

                        djnz    counter,              #verticalSync              ' Repeat # times.

' //////////////////////Back Porch/////////////////////////////////////////////////////////////////////////////////////////////

                        mov     counter,              #31                        ' Set loop counter.

backPorch               mov     vscl,                 blankPixels                ' Invisible lines.
                        waitvid HSyncColors,          #0                         '

                        jmpret  displayPC,            mousePC                    ' Do mouse stuff.

                        mov     vscl,                 invisibleScale             ' Horizontal sync.
                        waitvid HSyncColors,          syncPixels                 '

                        jmpret  displayPC,            mousePC                    ' Do mouse stuff.

                        djnz    counter,              #backPorch                 ' Repeat # times.

' //////////////////////Update Display Settings////////////////////////////////////////////////////////////////////////////////

                        rdbyte  buffer,               displayIndicatorAddress wz ' Update display settings.
                        muxnz   dira,                 directionState             '

' //////////////////////Loop///////////////////////////////////////////////////////////////////////////////////////////////////

                        jmp     #loop                                            ' Loop.

' /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
'                       Cache Update
' /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

cacheUpdate             rdword  lumaCacheBuffer,      lumaPointer                ' Update luma cache.

loadCheck               cmpsub  lumaPointer,          0 wz, wc, nr               ' Load up mouse overlays on hit or miss.
if_c                    cmpsub  displayCounter,       #1 wc                      '
loadPixels if_z_and_c   mov     lumaCacheBuffer,      0                          '
loadColors if_z_and_c   mov     chromaCacheBuffer,    0                          '
if_c                    add     loadCheck,            #1                         '
if_c                    add     loadPixels,           #1                         '
if_c                    add     loadColors,           #1                         '

lumaCacheUpdate         mov     0,                    lumaCacheBuffer            ' Update luma pointers.
                        add     lumaCacheUpdate,      destinationIncrement       '
                        add     lumaPointer,          #2                         '

if_nz                   rdlong  chromaCacheBuffer,    chromaPointer              ' Update chroma cache.

                        cmp     chromaPointer,        printTopPlace wz           ' Check cursor places.
if_nz                   cmp     chromaPointer,        printBottomPlace wz        '
if_z                    test    refreshCounter,       printRateControl wc        '
if_z_and_c              mov     chromaCacheBuffer,    printColorControl          '

                        or      chromaCacheBuffer,    HVSyncColors               ' Update chroma pointers.
chromaCacheUpdate       mov     0,                    chromaCacheBuffer          '
                        add     chromaCacheUpdate,    destinationIncrement       '
                        add     chromaPointer,        #4                         '

                        djnz    inactiveCounter,      #cacheUpdate               ' Repeat.

cacheUpdate_ret         ret                                                      ' Return.

' /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
'                       Display Mouse
' /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

displayMouse            rdword  mouseRowOffset,       mouseYAddress              ' Compute mouse Y pixel.
                        max     mouseRowOffset,       #479                       '

                        rdword  mouseColumnOffset,    mouseXAddress              ' Compute mouse X pixel.
                        max     mouseColumnOffset,    sixHundredAndThirtyNine    '

                        mov     mouseBuffer,          mouseRowOffset             ' Compute mouse row.
                        shr     mouseBuffer,          #4                         '

                        mov     mouseCounter,         mouseColumnOffset          ' Compute mouse column.
                        shr     mouseCounter,         #4                         '

                        and     mouseRowOffset,       #$F                        ' Compute pixel offsets.
                        and     mouseColumnOffset,    #$F                        '

                        rdbyte  mouseColors,          mouseChromaAddress         ' Get mouse color.

                        mov     mouseAddresses,       #0                         ' Clear triggers.
                        mov     mouseAddresses + 1,   #0                         '
                        mov     mouseAddresses + 2,   #0                         '
                        mov     mouseAddresses + 3,   #0                         '

                        rdword  mousePixels,          mouseLumaAddress wz        ' Get mouse pixel.
if_z                    jmp     #displayMouseRet                                 '

                        mov     mouseAddresses,       mouseBuffer                ' Compute left upper mouse address in luma.
                        mov     buffer,               mouseBuffer                '
                        shl     mouseAddresses,       #5                         '
                        shl     buffer,               #3                         '
                        add     mouseAddresses,       mouseCounter               '
                        add     mouseAddresses,       buffer                     '
                        shl     mouseAddresses,       #1                         '
                        add     mouseAddresses,       lumaBufferAddress          '

                        cmp     mouseCounter,         #39 wc                     ' Compute right upper mouse address in luma.
if_c                    mov     mouseAddresses + 1,   mouseAddresses             '
if_c                    add     mouseAddresses + 1,   #2                         '

                        cmp     mouseBuffer,          #29 wc                     ' Compute left lower mouse address in luma.
if_c                    mov     mouseAddresses + 2,   mouseAddresses             '
if_c                    add     mouseAddresses + 2,   #80                        '

if_c                    cmp     mouseCounter,         #39 wc                     ' Compute right lower mouse address in luma.
if_c                    mov     mouseAddresses + 3,   mouseAddresses             '
if_c                    add     mouseAddresses + 3,   #82                        '

' //////////////////////Cache Pixel Pointers and Colors////////////////////////////////////////////////////////////////////////

                        movs    storeBackup,          #mouseAddresses            ' Reset.
                        movd    storeColors,          #mouseAddColors            '
                        movd    storePixels,          #mouseAddPixels            '
                        movs    storePixels,          #mouseAddresses            '

                        mov     mouseCounter,         #4                         ' Setup counter.

storeBackup             mov     buffer,               0 wz                       ' Cache colors and pixels.
if_nz                   sub     buffer,               lumaBufferAddress          '
if_nz                   shl     buffer,               #1                         '
if_nz                   add     buffer,               chromaBufferAddress        '
storeColors if_nz       rdlong  0,                    buffer                     '
storePixels if_nz       rdword  0,                    0                          '

                        add     storeBackup,          #1                         ' Point to next.
                        add     storeColors,          destinationIncrement       '
                        add     storePixels,          destinationIncrement       '
                        add     storePixels,          #1                         '

                        djnz    mouseCounter,         #storeBackup               ' Repeat.

' //////////////////////Draw Background////////////////////////////////////////////////////////////////////////////////////////

                        mov     mouseBuffer,          mouseAddColors             ' Draw left upper pixels and colors.
                        mov     mousePixelsGet,       mouseAddPixels             '
                        mov     mousePixelsPut,       mouseAddCaches             '
                        movd    drawBackgroundLoad,   #mouseAddColors            '
                        call    #drawBackground                                  '

                        mov     mouseBuffer,          mouseAddColors + 1         ' Draw right upper pixels and colors.
                        mov     mousePixelsGet,       mouseAddPixels + 1         '
                        mov     mousePixelsPut,       mouseAddCaches + 1         '
                        movd    drawBackgroundLoad,   #mouseAddColors + 1        '
                        call    #drawBackground                                  '

                        mov     mouseBuffer,          mouseAddColors + 2         ' Draw left lower pixels and colors.
                        mov     mousePixelsGet,       mouseAddPixels + 2         '
                        mov     mousePixelsPut,       mouseAddCaches + 2         '
                        movd    drawBackgroundLoad,   #mouseAddColors + 2        '
                        call    #drawBackground                                  '

                        mov     mouseBuffer,          mouseAddColors + 3         ' Draw right lower pixels and colors.
                        mov     mousePixelsGet,       mouseAddPixels + 3         '
                        mov     mousePixelsPut,       mouseAddCaches + 3         '
                        movd    drawBackgroundLoad,   #mouseAddColors + 3        '
                        call    #drawBackground                                  '

' //////////////////////Draw Foreground////////////////////////////////////////////////////////////////////////////////////////

                        mov     mouseCounter,         #16                        ' Setup counter.

                        mov     mouseLeftPointer,     mouseAddCaches             ' Setup loading addresses.
                        mov     mouseRightPointer,    mouseAddCaches + 1         '

                        shl     mouseRowOffset,       #2                         ' Setup loading offsets.
                        add     mouseLeftPointer,     mouseRowOffset             '
                        add     mouseRightPointer,    mouseRowOffset             '

drawForegroundLoop      rdlong  mouseLeftPixels,      mousePixels                ' Get mouse pixels.
                        add     mousePixels,          #4                         '

                        mov     buffer,               mouseLeftPixels            ' Promote %01 to %11.
                        or      buffer,               pixelAMask                 '
                        and     buffer,               pixelNAMask                '
                        shl     buffer,               #1                         '
                        or      mouseLeftPixels,      buffer                     '

                        mov     buffer,               mouseLeftPixels            ' Promote %10 to %11.
                        or      buffer,               pixelNAMask                '
                        and     buffer,               pixelAMask                 '
                        shr     buffer,               #1                         '
                        or      mouseLeftPixels,      buffer                     '

                        mov     mouseBuffer,          mouseColumnOffset          ' Compute column pixel offset.
                        shl     mouseBuffer,          #1                         '

                        neg     buffer,               #1                         ' Compute column pixel mask.
                        shr     buffer,               mouseBuffer                '

                        mov     mouseRightPixels,     mouseLeftPixels            ' Backup shift pixels.
                        andn    mouseRightPixels,     buffer                     '

                        shl     mouseLeftPixels,      mouseBuffer                ' Build left pixels and right pixels.
                        rol     mouseRightPixels,     mouseBuffer                '

                        rdlong  buffer,               mouseLeftPointer           ' Load left pixels.
                        andn    buffer,               mouseLeftPixels            '
                        wrlong  buffer,               mouseLeftPointer           '
                        add     mouseLeftPointer,     #4                         '

                        rdlong  buffer,               mouseRightPointer          ' Load right pixels.
                        andn    buffer,               mouseRightPixels           '
                        wrlong  buffer,               mouseRightPointer          '
                        add     mouseRightPointer,    #4                         '

                        jmpret  mousePC,              displayPC                  '

                        djnz    mouseCounter,         #drawForegroundLoop        ' Repeat.

' //////////////////////Return/////////////////////////////////////////////////////////////////////////////////////////////////

displayMouseRet         jmpret  mousePC,              displayPC                  ' Setup to return to display PC.
                        jmp     displayPC                                        '

' /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
'                       Draw Background
' /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

drawBackground          mov     buffer,               mouseBuffer                ' Check if color is... ABABCDCD - lower part.
                        mov     mouseCounter,         mouseBuffer                '
                        and     mouseCounter,         #$FF                       '
                        shr     buffer,               #8                         '
                        and     buffer,               #$FF                       '
                        cmp     buffer,               mouseCounter wz            '

if_z                    mov     buffer,               mouseBuffer                ' Check if color is... ABABCDCD - upper part.
if_z                    mov     mouseCounter,         mouseBuffer                '
if_z                    shr     mouseCounter,         #24                        '
if_z                    shr     buffer,               #16                        '
if_z                    and     buffer,               #$FF                       '
if_z                    cmp     buffer,               mouseCounter wz            '

                        muxz    drawBackgroundPixels, #1                         ' Change pixel affector.

if_z                    shl     mouseBuffer,          #8                         ' Edit color.

                        mov     buffer,               mouseBuffer                ' Check if color is of the form ABCDABCD.
                        mov     mouseCounter,         mouseBuffer                '
                        shl     buffer,               #16                        '
                        shr     buffer,               #16                        '
                        shr     mouseCounter,         #16                        '
                        cmp     mouseCounter,         buffer wz                  '

                        muxz    drawBackgroundPixels, #2                         ' Change pixel affector.

                        andn    mouseBuffer,          #$FF                       ' Edit color.
                        or      mouseBuffer,          mouseColors                '
drawBackgroundLoad      mov     0,                    mouseBuffer                '

                        mov     mouseCounter,         #16                        ' Setup counter.

drawBackgroundLoop      rdlong  mouseBuffer,          mousePixelsGet             ' Get source pixels.
                        add     mousePixelsGet,       #4                         '

                        test    drawBackgroundPixels, #1 wc                      ' Change pixels for interleaved characters.
if_c                    shr     mouseBuffer,          #1                         '
drawBackgroundPixels    test    drawBackgroundPixels, #3 wz                      '
if_nz                   or      mouseBuffer,          pixelAMask                 '

if_z                    mov     buffer,               mouseBuffer                ' Promote pixels %00 to %01.
if_z                    xor     buffer,               pixelXORMask               '
if_z                    and     buffer,               pixelAMask                 '
if_z                    shr     buffer,               #1                         '
if_z                    or      mouseBuffer,          buffer                     '

                        wrlong  mouseBuffer,          mousePixelsPut             ' Put modified source pixels.
                        add     mousePixelsPut,       #4                         '

                        test    mouseCounter,         #$3 wz                     ' Do display stuff every 4 cycles.
if_z                    jmpret  mousePC,              displayPC                  '

                        djnz    mouseCounter,         #drawBackgroundLoop        ' Repeat.

drawBackground_ret      ret                                                      ' Return.


                           fit     496
Dat
' /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
'                       Data
' /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

destinationIncrement    long    $2_00                                            ' Destination incrementor.
sixHundredAndThirtyNine long    639                                              ' Six hundred and thirty nine.

visibleScale            long    (1 << 12) + 16                                   ' Visible pixel scale for scan line.
invisibleScale          long    (16 << 12) + 160                                 ' Invisible pixel scale for horizontal sync.

blankPixels             long    640                                              ' Blank scanline pixel length.
syncPixels              long    $00_00_3F_FC                                     ' FP, HS, & BP Pixels.
HSyncColors             long    $01_01_03_03                                     ' Horizontal sync color mask.
VSyncColors             long    $00_00_02_02                                     ' Vertical sync color mask.
HVSyncColors            long    $03_03_03_03                                     ' Horizontal and vertical sync colors.
pixelAMask              long    $AA_AA_AA_AA                                     ' To select every 2nd pixel.
pixelNAMask             long    $55_55_55_55                                     ' To modify every 2nd pixel.
pixelXORMask            long    $FF_FF_FF_FF                                     ' To invert every 2nd pixel.

' //////////////////////Configuration Settings/////////////////////////////////////////////////////////////////////////////////

directionState          long    0                                                ' Direction state configuration.
videoState              long    0                                                ' Video state configuration.
frequencyState          long    0                                                ' Frequency state configuration.

' //////////////////////Addresses//////////////////////////////////////////////////////////////////////////////////////////////

mouseXAddress           long    0
mouseYAddress           long    0
chromaBufferAddress     long    0
lumaBufferAddress       long    0
printColorAddress       long    0
printPositionAddress    long    0
printRateAddress        long    0
mouseChromaAddress      long    0
mouseLumaAddress        long    0
displayIndicatorAddress long    0
syncIndicatorAddress    long    0

' //////////////////////Cache Variables////////////////////////////////////////////////////////////////////////////////////////

mouseAddCaches          res     4
mouseAddresses          res     4
mouseAddPixels          res     4
mouseAddColors          res     4

' //////////////////////Run Time Variables/////////////////////////////////////////////////////////////////////////////////////

counter                 res     1
buffer                  res     1
displayPC               res     1
mousePC                 res     1
refreshCounter          res     1
displayCounter          res     1

' //////////////////////Display Variables//////////////////////////////////////////////////////////////////////////////////////

tileCounter             res     1
tilesCounter            res     1

activeCounter           res     1
inactiveCounter         res     1

lumaPointer             res     1
chromaPointer           res     1

lumaCacheBuffer         res     1
chromaCacheBuffer       res     1

lumaCache               res     80
chromaCache             res     80

' //////////////////////Print Variables////////////////////////////////////////////////////////////////////////////////////////

printTopPlace           res     1
printBottomPlace        res     1

printRateControl        res     1
printColorControl       res     1

' //////////////////////Mouse Variables////////////////////////////////////////////////////////////////////////////////////////

mouseRowOffset          res     1
mouseColumnOffset       res     1

mousePixels             res     1
mouseColors             res     1

mouseBuffer             res     1
mouseCounter            res     1

mousePixelsGet          res     1
mousePixelsPut          res     1

mouseLeftPointer        res     1
mouseRightPointer       res     1

mouseLeftPixels         res     1
mouseRightPixels        res     1

' /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

                       ' fit     496

DAT

' //////////////////////Variable Array/////////////////////////////////////////////////////////////////////////////////////////

mouseCache              long    0[64]                                            ' Mouse overlay display buffer.
'chromaBuffer_tail       long    0[1_200-((@chromaBuffer_tail- @chromaBuffer)/4)]                                     'Trick von Kuroneko um Speicher zu sparen

chromaBuffer            long    0[1_200]                                         ' Display chroma buffer.
lumaBuffer              word    0[1_200]                                         ' Display luma buffer. Farbbuffer
printColor              long    0                                                ' Print cursor color control.
printPosition           word    0                                                ' Print cursor position control.
printRate               byte    0                                                ' Print curor rate control.
mouseChroma             byte    0                                                ' Mouse color control.
mouseLuma               word    0                                                ' Mouse pixel control.
mouseLumaBackup         word    0                                                ' Mouse pixel control backup.
displayIndicator        byte    1                                                ' Video output control.
syncIndicator           byte    0                                                ' Video update control.
cogNumber               byte    0                                                ' Cog ID.
lockNumber              byte    0                                                ' Lock ID.

' /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

DAT

' //////////////////////Mouse Pointer//////////////////////////////////////////////////////////////////////////////////////////

mousePointer            long    %%0000000000000001
                        long    %%0000000000000011
                        long    %%0000000000000121
                        long    %%0000000000001221
                        long    %%0000000000012321
                        long    %%0000000000123321
                        long    %%0000000001233321
                        long    %%0000000012333321
                        long    %%0000000123333321
                        long    %%0000001233333321
                        long    %%0000012222222221
                        long    %%0000111111221221
                        long    %%0000000001221221
                        long    %%0000000012210121
                        long    %%0000000012100011
                        long    %%0000000111100001

' /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

{{

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                  TERMS OF USE: MIT License
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation
// files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy,
// modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the
// Software is furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all copies or substantial portions of the
// Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE
// WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
// COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
// ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
}}
