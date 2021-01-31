{{
┌─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┐               
│ File Allocation Table Engine                                                                                                │
│                                                                                                                             │
│ Author: Kwabena W. Agyeman                                                                                                  │                              
│ Updated: 1/18/2009                                                                                                          │
│ Designed For: P8X32A                                                                                                        │
│                                                                                                                             │
│ Copyright (c) 2009 Kwabena W. Agyeman                                                                                       │              
│ See end of file for terms of use.                                                                                           │               
│                                                                                                                             │
│ Driver Info:                                                                                                                │
│                                                                                                                             │
│ The FATEngine runs a SD/SDHC/MMC driver in the next free cog on the propeller chip when called.                             │
│                                                                                                                             │ 
│ The driver, is only guaranteed and tested to work at an 80Mhz system clock or higher. The driver is designed for the P8X32A │
│ so port B will not be operational.                                                                                          │
│                                                                                                                             │
│ Nyamekye,                                                                                                                   │
└─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┘
}}

{{

ANPASSUNGEN HIVE-PROJECT

Informationen   : hive-project.de
Kontakt         : drohne235@googlemail.com
System          : TriOS
Name            : Komponente von Administra-Flash
Chip            : Administra
Version         : 00
Subversion      : 01

Hinweise        :

Alle Änderungen am Originalquelltext sind mit der Marke "@hive" gekennzeichnet. Die unveränderte
Originalquelle wird nur auskommentiert.

Logbuch         :

25-03-2010-dr235  - änderung der fehlerstrings in fehlernummern für eine bessere auswertung
27-03-2010-dr235  - listVolumeLabel eingefügt
28-03-2010-dr235  - änderung des openFile parameters "modus" von 0-term-string zu 8bit-parameter
12-04-2010-dr235  - getDirCluster & setDirCluster für dir-marker system zugefügt
09-06-2010-dr085  - frida hat den fehler gefunden, welcher eine korrekte funktion der fatengine
                    nach einem bootvorgang von administra verhinderte :)
14-06-2010-dr085  - löschen der semaphore vor dem bootvorgang
10-07-2010        - provisorische behebung eines fehlers in readData (siehe admsid)
02-02-2012-dr235  - fehler in setCharacterPosition: bei einem wechsel von einer position > 0
                    auf position = 0 wurde der erste sektor mit falschen daten überschrieben

Notizen         :


}}
CON
                         '' 
  Data_Out_Pin      = 10 '' ─ Data Out - To SD Card DO Pin.
                         ''
  Clock_Pin         = 11 '' ─ Clock - To SD Card CLK Pin.
                         ''
  Data_In_Pin       = 12 '' ─ Data In - To SD Card DI Pin.
                         ''
  Chip_Select_Pin   = 13                                '13 '' ─ Chip Select - To SD Card CS.

'frida  HUB_Lock = 0 ' Hub Lock To use for multiple files open with multiple copies of this object at once.

' FEHLERNUMMERN                                                                 '@hive

  err_noError            = 0
  err_fsysUnmounted      = 1
  err_fsysCorrupted      = 2
  err_fsysUnsupported    = 3
  err_notFound           = 4
  err_fileNotFound       = 5
  err_dirNotFound        = 6
  err_fileReadOnly       = 7
  err_endOfFile          = 8
  err_endOfDirectory     = 9
  err_endOfRoot          = 10
  err_dirIsFull          = 11
  err_dirIsNotEmpty      = 12
  err_checksumError      = 13
  err_rebootError        = 14
  err_bpbCorrupt         = 15
  err_fsiCorrupt         = 16
  err_dirAlreadyExist    = 17
  err_fileAlreadyExist   = 18
  err_outOfDiskFreeSpace = 19
  err_diskIOError        = 20
  
  
OBJ

                rtc            : "adm-rtc.spin"
'               debugx         : "pterm"               'debug

VAR

  byte dataBlock[512]

  word cardTime
  word cardDate

  byte cardUniqueIDCopy[17]
  byte partitionMountedFlag

  byte fileOpenFlag
  byte fileReadWriteFlag

  long partitionStart
  long partitionSize

  byte sectorsPerCluster
  byte numberOfFATs
  word reservedSectorCount

  long FATSectorSize

  word rootDirectorySectors
  word rootDirectorySectorNumber

  long hiddenSectors
  
  long firstDataSector
  long countOfClusters

  long FATType
  long rootCluster

  word fileSystemInfo
  word backupBootSector 

  long freeClusterCount
  long nextFreeCluster

  long volumeIdentification

  word externalFlags
  byte mediaType
  byte unformatedNameBuffer[13]
  byte formatedNameBuffer[12]

  byte directoryEntryName[12]
  byte directoryEntry[32]

  long currentDirectory
  long currentFile

  long currentCluster
  long currentByte

'  long previousDirectory
  long currentSize 

  long previousCluster 
  long previousByte

  byte sdvolumeLabel[12]          'frida

PUB readShort '' 28 Stack Longs

  readData(@result, 2)

PUB readLong '' 28 Stack Longs

  readData(@result, 4)

PUB writeShort(value) '' 29 Stack Longs

  writeData(@value, 2)

PUB writeLong(value) '' 29 Stack Longs

  writeData(@value, 4)
 
PUB readData(addressToPut, count) | index '' 25 Stack Longs 

'' ┌──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
'' │ Reads data from the file that is currently open for reading and advances the position by that amount of data.            │
'' │                                                                                                                          │
'' │ Will do nothing if a file is not currently open or if the card is not mounted. This throws an error.                     │
'' │                                                                                                                          │
'' │ If an error occurs this function will abort and return a pointer to a string describing that error.                      │
'' │                                                                                                                          │
'' │ AddressToPut - A pointer to the start of a data buffer to read to from disk.                                             │
'' │ Count        - The amount of data to read from disk. The data buffer must be atleast this large.                         │                                                                                        
'' └──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┘

  count #>= 0

'#####################################################################
'  repeat while((count > 0) and readWriteCurrentCluster("R", "F"))

  repeat while (count > 0)                              ' änderung um 4096-Fehler im dmp-player
    if(readWriteCurrentCluster("R", "F"))               ' zu beheben

'#####################################################################

    index := (currentByte & $1FF)
    result := (count <# (512 - index))
    
    bytemove(addressToPut, @dataBlock[index], result)
    
    count -= result
    currentByte += result
    addressToPut += result
    currentByte <#= (currentSize - 1)

PUB writeData(addressToGet, count) | index '' 25 Stack Longs

'' ┌──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
'' │ Writes data to the file that is currently open for writing and advances the position by that amount of data.             │
'' │                                                                                                                          │
'' │ Will do nothing if a file is not currently open or if the card is not mounted. This throws an error.                     │
'' │                                                                                                                          │
'' │ If an error occurs this function will abort and return a pointer to a string describing that error.                      │
'' │                                                                                                                          │
'' │ This throws an error if the file is open for reading only.                                                               │   
'' │                                                                                                                          │
'' │ Max writable file size is 2,147,483,136 bytes. Exceeding this throws an error.                                           │
'' │                                                                                                                          │
'' │ AddressToGet - A pointer to the start of a data buffer to write to disk.                                                 │
'' │ Count        - The amount of data to write to disk. The data buffer must be atleast this large.                          │                                                                               
'' └──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┘

  count #>= 0
  repeat while((count > 0) and readWriteCurrentCluster("W", "F"))

    index := (currentByte & $1FF)
    result := (count <# (512 - index))
    
    bytemove(@dataBlock[index], addressToGet, result)
    flushCharacters
    
    count -= result
    currentByte += result
    addressToGet += result
    currentSize #>= currentByte 

PUB readCharacter '' 22 Stack Longs

'' ┌──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
'' │ Reads a character from the file that is currently open for reading and advances the position by one.                     │
'' │                                                                                                                          │
'' │ Will do nothing if a file is not currently open or if the card is not mounted. This throws an error.                     │
'' │                                                                                                                          │
'' │ If an error occurs this function will abort and return a pointer to a string describing that error.                      │
'' │                                                                                                                          │
'' │ Returns the next character to read from the file. At the end of file returns the last character in the file repeatedly.  │
'' └──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┘

  if(readWriteCurrentCluster("R", "F"))

    result := blockToByte(currentByte++)
    currentByte <#= (currentSize - 1)
                                       
PUB writeCharacter(character) '' 23 Stack Longs

'' ┌──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
'' │ Writes a character to the file that is currently open for writing and advances the position by one.                      │
'' │                                                                                                                          │
'' │ Will do nothing if a file is not currently open or if the card is not mounted. This throws an error.                     │
'' │                                                                                                                          │
'' │ If an error occurs this function will abort and return a pointer to a string describing that error.                      │
'' │                                                                                                                          │
'' │ This throws an error if the file is open for reading only.                                                               │   
'' │                                                                                                                          │
'' │ Max writable file size is 2,147,483,136 bytes. Exceeding this throws an error.                                           │
'' │                                                                                                                          │
'' │ Character - A character to write to the file.                                                                            │                                                                                                                      
'' └──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┘

  if(readWriteCurrentCluster("W", "F"))

    byteToBlock(currentByte++, character)
  
    ifnot($1FF & currentByte--)
      flushCharacters
    
    currentSize #>= ++currentByte

PUB writeCharacters(characters) '' 27 Stack Longs

'' ┌──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
'' │ Writes a string of characters to the file that is currently open for writing and advances the position by string length. │
'' │                                                                                                                          │
'' │ Will do nothing if a file is not currently open or if the card is not mounted. This throws an error.                     │
'' │                                                                                                                          │
'' │ If an error occurs this function will abort and return a pointer to a string describing that error.                      │
'' │                                                                                                                          │
'' │ This throws an error if the file is open for reading only.                                                               │   
'' │                                                                                                                          │
'' │ Max writable file size is 2,147,483,136 bytes. Exceeding this throws an error.                                           │
'' │                                                                                                                          │
'' │ Characters - A pointer to a string of characters to write to the file.                                                   │                                                                                                                      
'' └──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┘

  repeat strsize(characters)
    writeCharacter(byte[characters++])

PUB flushCharacters '' 12 Stack Longs

'' ┌──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
'' │ Writes buffered data to disk. All file writes are buffered and are not written to disk immediantly.                      │
'' │                                                                                                                          │
'' │ If the partition is not mounted or an error occurs this function will abort and return a string describing that error.   │
'' └──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┘  

  if(partitionMountedFlag and fileOpenFlag and fileReadWriteFlag)
    readWriteCurrentSector("W")  

PUB getEOF

  result := currentByte => currentSize-1

PUB getCharacterPosition '' 3 Stack Longs

'' ┌──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
'' │ Gets the current character position within a file for reading and writing.                                               │
'' └──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┘ 

  return (currentByte & (partitionMountedFlag and fileOpenFlag))
  
PUB setCharacterPosition(position) | backUpPosition '' 17 Stack Longs

'' ┌──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
'' │ Sets the current character position within a file for reading and writing.                                               │
'' │                                                                                                                          │
'' │ If the partition is not mounted or an error occurs this function will abort and return a string describing that error.   │ 
'' │                                                                                                                          │
'' │ Position - A character position in the file. Set to false to go to the begining of the file and true to go to the end.   │                                                                                                                      
'' └──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┘

  if(partitionMountedFlag and fileOpenFlag)
  
    position := ((position <# (currentSize - 1)) #> 0)
    backUpPosition := position
    
    if(position <> currentByte)            '@hive: fehlerkorrektur vom originalcode
      flushCharacters

    currentByte >>= 9
    position >>= 9
  
'    if(position <> currentByte)           'dieser abschnitt muss nach oben verschoben werden
'      flushCharacters                     'da flashCharacter in sonderfällen auf currentByte zugreift!

      currentByte /= sectorsPerCluster
      position /= sectorsPerCluster
    
      if(position <> currentByte)
        if(position < currentByte)
          currentByte := 0
          currentCluster := currentFile

        repeat until(position == currentByte++)
                                                       
          readWriteFATBlock(currentCluster, "R")
          currentCluster := readFATEntry(currentCluster)

          if((currentCluster =< 1) or (FATEndOfClusterValue =< currentCluster))
            partitionMountedFlag := false 
'           abort @FSCorrupted                                                  '@hive
            abort err_fsysCorrupted
            
      result := true            

    currentByte := backUpPosition

    if(result)
      readWriteCurrentSector("R")
 
PUB closeFile '' 15 Stack Longs

'' ┌──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
'' │ Closes the currently open file in the current directory. Files opened for writing that are not closed will be corrupted. │                                                                        
'' │                                                                                                                          │
'' │ If the partition is not mounted or an error occurs this function will abort and return a string describing that error.   │                                                                            
'' └──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┘

  flushCharacters
  if(partitionMountedFlag and fileOpenFlag~)

    currentByte := previousByte
    currentCluster := previousCluster

    readWriteCurrentSector("R")

    wordToBlock((currentByte + 18), readClock)

    if(fileReadWriteFlag)

      wordToBlock((currentByte + 22), cardTime)
      wordToBlock((currentByte + 24), cardDate)
      longToBlock((currentByte + 28), currentSize)
            
      dataBlock[(currentByte + 11) & $1FF] |= $20

    readWriteCurrentSector("W")
                               
PUB openFile(fileName, mode) '' 33 Stack Longs

'' ┌──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
'' │ Opens a file in the current directory for reading or writing.                                                            │
'' │                                                                                                                          │
'' │ If the partition is not mounted or an error occurs this function will abort and return a string describing that error.   │
'' │                                                                                                                          │
'' │ The "." and ".." entries are ignored by this function.                                                                   │                                                                   
'' │                                                                                                                          │
'' │ Returns a pointer to the name of the file.                                                                               │ 
'' │                                                                                                                          │
'' │ FileName - The name of the file to open for reading or writing.                                                          │
'' │ Mode     - A string of characters containing the mode to open the file in. R-Read, W-Write, A-Append. Default read.      │                                                                                      
'' │                                                                                                                          │
'' └──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┘
 
' result := unformatName(listFind(formatName(fileName), @fileNotFound))
  result := unformatName(listFind(formatName(fileName), err_fileNotFound))      '@hive

  if(listIsDirectory)
'   abort @fileNotFound                                                         '@hive
    abort err_fileNotFound

  currentFile := listCluster

  ifnot(currentFile)
    currentFile := createClusterChain(0)

    readWriteCurrentSector("R")
    dataBlock[(currentByte + 11) & $1FF] |= $20
    wordToBlock((currentByte + 18), readClock)
    wordToBlock((currentByte + 26), (currentFile & $FFFF))
    wordToBlock((currentByte + 20), (currentFile >> 16))
    readWriteCurrentSector("W")

' fileReadWriteFlag := findCharacter(mode, "W")                                 '@hive
  fileReadWriteFlag := mode == "W"

  if(listIsReadOnly and fileReadWriteFlag)
'   abort string("File Read Only")                                              '@hive
    abort err_fileReadOnly

  currentSize := listSize    
  previousByte := currentByte
  previousCluster := currentCluster  
' currentByte := ((findCharacter(mode, "A") and fileReadWriteFlag) & currentSize) '@hive
  currentByte := (( (mode == "A") and fileReadWriteFlag) & currentSize)
  currentCluster := currentFile 
    
  readWriteCurrentSector("R")
  fileOpenFlag := true  

PUB newFile(fileName) '' 40 Stack Longs

'' ┌──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
'' │ Creates a new file in the current directory.                                                                             │
'' │                                                                                                                          │
'' │ If the partition is not mounted or an error occurs this function will abort and return a string describing that error.   │                                                                   
'' │                                                                                                                          │
'' │ Returns a pointer to the name of the file. List functions are not valid after calling this function.                     │
'' │                                                                                                                          │
'' │ FileName - The name of the new file to create. Must be a new unique name in the current directory.                       │                                                                                                                                                                                                      
'' └──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┘

' result := unformatName(listNew(formatName(fileName), $20, readClock, cardTime, 0, "F"))               '@hive
  unformatName(listNew(formatName(fileName), $20, readClock, cardTime, 0, "F"))                         '@hive
  listReset

PUB newDirectory(directoryName) '' 40 Stack Longs  

'' ┌──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
'' │ Creates a new directory in the current directory.                                                                        │
'' │                                                                                                                          │
'' │ If the partition is not mounted or an error occurs this function will abort and return a string describing that error.   │                                                                   
'' │                                                                                                                          │
'' │ Returns a pointer to the name of the directory. List functions are not valid after calling this function.                │
'' │                                                                                                                          │
'' │ DirectoryName - The name of the new directory to create. Must be a new unique name in the current directory.             │                                                                                                                                                                                                      
'' └──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┘

' result := unformatName(listNew(formatName(directoryName), $30, readClock, cardTime, 0, "D"))          '@hive
  unformatName(listNew(formatName(directoryName), $30, readClock, cardTime, 0, "D"))

  directoryName := currentDirectory
  currentDirectory := currentFile
  
  listNew(@dot, $10, cardDate, cardTime, currentDirectory, "F")
  listNew(@dotdot, $10, cardDate, cardTime, directoryName, "F")

  currentDirectory := directoryName
  listReset

PUB deleteEntry(entryName) '' 32 Stack Longs

'' ┌──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
'' │ Deletes a file or directory in the current directory.                                                                    │                                                                                                     
'' │                                                                                                                          │
'' │ If the partition is not mounted or an error occurs this function will abort and return a string describing that error.   │
'' │                                                                                                                          │
'' │ Cannot delete non empty directories. This throws and error.                                                              │
'' │                                                                                                                          │
'' │ The "." and ".." entries are ignored by this function.                                                                   │                                                                   
'' │                                                                                                                          │
'' │ Returns a pointer to the name of the file or directory. List functions are not valid after calling this function.        │
'' │                                                                                                                          │
'' │ EntryName - The name of the file or directory to delete.                                                                 │                                                                                                                                                                                                                                              
'' └──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┘

' result := unformatName(listFind(formatName(entryName), @fileOrDirectoryNotFound))                     '@hive
  result := unformatName(listFind(formatName(entryName), err_notFound))

  if(listIsDirectory)
  
    previousByte := currentByte~
    previousCluster := currentCluster
    currentCluster := listCluster

    repeat 
      entryName := listDirectory("R")

      ifnot(entryName)
        quit
      
      if(byte[entryName] <> ".")
'       abort string("Directory Is Not Empty")                                                          '@hive
        abort err_dirIsNotEmpty
        
    currentByte := previousByte
    currentCluster := previousCluster

    readWriteCurrentSector("R")

  byteToBlock(currentByte, $E5)
  readWriteCurrentSector("W")

  destroyClusterChain(listCluster)
  listReset    
           
PUB renameEntry(entryNameToChange, entryNameToChangeTo) '' 33 Stack Longs

'' ┌──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
'' │ Renames a file or directory in the current directory. The new name must be unique in the current directory.              │
'' │                                                                                                                          │
'' │ If the partition is not mounted or an error occurs this function will abort and return a string describing that error.   │
'' │                                                                                                                          │
'' │ The "." and ".." entries are ignored by this function.                                                                   │                                                                   
'' │                                                                                                                          │
'' │ Returns a pointer to the name of the file or directory. List functions are not valid after calling this function.        │ 
'' │                                                                                                                          │
'' │ EntryNameToChange   - The name of the file or directory to change.                                                       │ 
'' │ EntryNameToChangeTo - The name of the file or directory to change to.                                                    │                                                                         
'' └──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┘

  listDuplicate(formatName(entryNameToChangeTo))  
' result := unformatName(listFind(formatName(entryNameToChange), @fileOrDirectoryNotFound))             '@hive
  result := unformatName(listFind(formatName(entryNameToChange), err_notFound))

  bytemove(@dataBlock[currentByte & $1FF], formatName(entryNameToChangeTo), 11)
  
  wordToBlock((currentByte + 18), readClock)
  wordToBlock((currentByte + 22), cardTime)
  wordToBlock((currentByte + 24), cardDate)
  dataBlock[(currentByte + 11) & $1FF] |= $20

  readWriteCurrentSector("W")
  listReset
  
PUB changeAttributes(entryName, newAttributes) '' 33 Stack Longs 

'' ┌──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
'' │ Changes the attributes of a file or directory in the current directory.                                                  │                
'' │                                                                                                                          │
'' │ If the partition is not mounted or an error occurs this function will abort and return a string describing that error.   │
'' │                                                                                                                          │
'' │ The "." and ".." entries are ignored by this function.                                                                   │                                                                   
'' │                                                                                                                          │
'' │ Returns a pointer to the name of the file or directory. List functions are not valid after calling this function.        │
'' │                                                                                                                          │                                                                                                                 
'' │ EntryName     - The name of the file or directory to change the attributes of.                                           │
'' │ NewAttributes - A string of characters containing the new set of attributes. A-Archive, S-System, H-Hidden, R-Read Only. │                                                         
'' └──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┘

' result := unformatName(listFind(formatName(entryName), @fileOrDirectoryNotFound))                     '@hive
  result := unformatName(listFind(formatName(entryName), err_notFound))

  byteToBlock((currentByte + 11), (($20 & findCharacter(newAttributes, "A")) | (listIsDirectory & $10) | ($4 & findCharacter(newAttributes, "S")) | ($2 & findCharacter(newAttributes, "H")) | ($1 & findCharacter(newAttributes, "R"))))
  wordToBlock((currentByte + 18), readClock)
  wordToBlock((currentByte + 22), cardTime)
  wordToBlock((currentByte + 24), cardDate)
    
  readWriteCurrentSector("W")
'  listReset                                                                                            '@hive   
               
PUB changeDirectory(directoryName) '' 32 Stack Longs

'' ┌──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
'' │ Searches the current directory for the specified directory and enters that directory.                                    │
'' │                                                                                                                          │
'' │ If the partition is not mounted or an error occurs this function will abort and return a string describing that error.   │
'' │                                                                                                                          │
'' │ Returns a pointer to the name of the direcotry. List functions are not valid after calling this function.                │                                                                                                                                 
'' │                                                                                                                          │
'' │ DirectoryName - The name of the directory to search for in the current directory and enter into.                         │                                                                                                                                                                                                                                  
'' └──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┘ 
      
' result := unformatName(listFind(listCase(directoryName, formatName(directoryName)), @directoryNotFound)) '@hive               
  result := unformatName(listFind(listCase(directoryName, formatName(directoryName)), err_dirNotFound))     

  ifnot(listIsDirectory)
'   abort @directoryNotFound                            '@hive
    abort err_dirNotFound
    
  currentDirectory := listCluster
  listReset

PUB getDirCluster

  result := currentDirectory

PUB setDirCluster(cluster)

  currentDirectory := cluster
  listReset
  
PUB listSearch(entryName) '' 32 Stack Longs

'' ┌──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
'' │ Returns a pointer to the name of the serached for file or direcotry in the current directory.                            │ 
'' │                                                                                                                          │
'' │ Additionally this function validates the other listing functions to get information about the next file or directory.    │
'' │                                                                                                                          │
'' │ If the partition is not mounted or an error occurs this function will abort and return a string describing that error.   │                                                                                                                                 
'' │                                                                                                                          │
'' │ EntryName - The name of the file or directory to search for in the current directory.                                    │                                                                                                                                                                                                                      
'' └──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┘

' return unformatName(listFind(listCase(entryName, formatName(entryName)), @fileOrDirectoryNotFound)) '@hive
  return unformatName(listFind(listCase(entryName, formatName(entryName)), err_notFound))
  
PUB listName '' 26 Stack Longs

'' ┌──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
'' │ Returns a pointer to the name of the next file or direcotry in the current directory. Returns zero on wrap arround.      │ 
'' │                                                                                                                          │
'' │ Additionally this function validates the other listing functions to get information about the next file or directory.    │
'' │                                                                                                                          │
'' │ If the partition is not mounted or an error occurs this function will abort and return a string describing that error.   │
'' │                                                                                                                          │
'' │ After listing the last file or directory "listReset" must be called to to list from the first file or direcotry again.   │                                                                                                                                                                                                                                   
'' └──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┘

  return unformatName(listDirectory("R")) 
 
PUB listReset '' 3 Stack Longs

'' ┌──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
'' │ Resets "listName" to list from the first file or directory in the current directory.                                     │
'' │                                                                                                                          │
'' │ List functions are not valid after calling this function.                                                                │                                                                   
'' └──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┘  

  ifnot(fileOpenFlag) 

    currentByte := 0
    currentCluster := currentDirectory

    bytefill(@directoryEntry, 0, 32)
    bytefill(@directoryEntryName, 0, 12)

PUB listSize '' 3 Stack Longs

'' ┌──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
'' │ Gets the size of current file or directory pointed to by "listName". Directories have no size.                           │
'' │                                                                                                                          │
'' │ If a file is currently open this function will retrieve that files information.                                          │
'' │                                                                                                                          │
'' │ If "listName" did not succed or was not previously called the value returned is invalid.                                 │
'' │                                                                                                                          │
'' │ Returns the size of the file or directory in bytes. Maximum file size is 2,147,483,136 bytes.                            │                                                                                                                                                                                                      
'' └──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┘

  return (((directoryEntry[28] | (directoryEntry[29] << 8) | (directoryEntry[30] << 16) | (directoryEntry[31] << 24)) <# $7FFFFE00) #> 0)
           
PUB listCreationDay '' 3 Stack Longs

'' ┌──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
'' │ Gets the creation day of the current file or directory pointed to by "listName".                                         │
'' │                                                                                                                          │
'' │ If a file is currently open this function will retrieve that file's information.                                         │
'' │                                                                                                                          │
'' │ If "listName" did not succed or was not previously called the value returned is invalid.                                 │
'' │                                                                                                                          │
'' │ Returns the creation day of the file or directory.                                                                       │                                                                                                                                                                                                      
'' └──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┘

  return (directoryEntry[16] & $1F)

PUB listCreationMonth '' 3 Stack Longs

'' ┌──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
'' │ Gets the creation month of the current file or directory pointed to by "listName".                                       │
'' │                                                                                                                          │
'' │ If a file is currently open this function will retrieve that file's information.                                         │
'' │                                                                                                                          │
'' │ If "listName" did not succed or was not previously called the value returned is invalid.                                 │
'' │                                                                                                                          │
'' │ Returns the creation month of the file or directory.                                                                     │                                                                                                                                                                                                      
'' └──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┘

  return (((directoryEntry[17] & $1) << 3) | (directoryEntry[16] >> 5))

PUB listCreationYear '' 3 Stack Longs

'' ┌──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
'' │ Gets the creation year of the current file or directory pointed to by "listName".                                        │
'' │                                                                                                                          │
'' │ If a file is currently open this function will retrieve that file's information.                                         │
'' │                                                                                                                          │
'' │ If "listName" did not succed or was not previously called the value returned is invalid.                                 │
'' │                                                                                                                          │
'' │ Returns the creation year of the file or directory.                                                                      │                                                                                                                                                                                                      
'' └──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┘

  return ((directoryEntry[17] >> 1) + 1980)

PUB listCreationSeconds '' 3 Stack Longs

'' ┌──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
'' │ Gets the creation second of the current file or directory pointed to by "listName".                                      │
'' │                                                                                                                          │
'' │ If a file is currently open this function will retrieve that file's information.                                         │
'' │                                                                                                                          │
'' │ If "listName" did not succed or was not previously called the value returned is invalid.                                 │
'' │                                                                                                                          │
'' │ Returns the creation second of the file or directory.                                                                    │                                                                                                                                                                                                      
'' └──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┘

  return (((directoryEntry[14] & $1F) << 1) + (directoryEntry[13] / 100)) 

PUB listCreationMinutes '' 3 Stack Longs

'' ┌──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
'' │ Gets the creation minute of the current file or directory pointed to by "listName".                                      │
'' │                                                                                                                          │
'' │ If a file is currently open this function will retrieve that file's information.                                         │
'' │                                                                                                                          │
'' │ If "listName" did not succed or was not previously called the value returned is invalid.                                 │
'' │                                                                                                                          │
'' │ Returns the creation minute of the file or directory.                                                                    │                                                                                                                                                                                                      
'' └──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┘

  return (((directoryEntry[15] & $7) << 3) | (directoryEntry[14] >> 5))

PUB listCreationHours '' 3 Stack Longs

'' ┌──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
'' │ Gets the creation hour of the current file or directory pointed to by "listName".                                        │
'' │                                                                                                                          │
'' │ If a file is currently open this function will retrieve that file's information.                                         │
'' │                                                                                                                          │
'' │ If "listName" did not succed or was not previously called the value returned is invalid.                                 │
'' │                                                                                                                          │
'' │ Returns the creation hour of the file or directory.                                                                      │                                                                                                                                                                                                      
'' └──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┘

  return (directoryEntry[15] >> 3)

PUB listAccessDay '' 3 Stack Longs

'' ┌──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
'' │ Gets the last day of access of the current file or directory pointed to by "listName".                                   │
'' │                                                                                                                          │
'' │ If a file is currently open this function will retrieve that file's information.                                         │
'' │                                                                                                                          │
'' │ If "listName" did not succed or was not previously called the value returned is invalid.                                 │
'' │                                                                                                                          │
'' │ Returns the last acess day of the file or directory.                                                                     │                                                                                                                                                                                                      
'' └──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┘

  return (directoryEntry[18] & $1F)

PUB listAccessMonth '' 3 Stack Longs

'' ┌──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
'' │ Gets the last month of access of the current file or directory pointed to by "listName".                                 │
'' │                                                                                                                          │
'' │ If a file is currently open this function will retrieve that file's information.                                         │
'' │                                                                                                                          │
'' │ If "listName" did not succed or was not previously called the value returned is invalid.                                 │
'' │                                                                                                                          │
'' │ Returns the last acess month of the file or directory.                                                                   │                                                                                                                                                                                                      
'' └──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┘

  return (((directoryEntry[19] & $1) << 3) | (directoryEntry[18] >> 5))

PUB listAccessYear '' 3 Stack Longs

'' ┌──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
'' │ Gets the last year of access of the current file or directory pointed to by "listName".                                  │
'' │                                                                                                                          │
'' │ If a file is currently open this function will retrieve that file's information.                                         │
'' │                                                                                                                          │
'' │ If "listName" did not succed or was not previously called the value returned is invalid.                                 │
'' │                                                                                                                          │
'' │ Returns the last acess year of the file or directory.                                                                    │                                                                                                                                                                                                      
'' └──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┘

  return ((directoryEntry[19] >> 1) + 1980)

PUB listModificationDay '' 3 Stack Longs

'' ┌──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
'' │ Gets the last day of modification of the current file or directory pointed to by "listName".                             │
'' │                                                                                                                          │
'' │ If a file is currently open this function will retrieve that file's information.                                         │
'' │                                                                                                                          │
'' │ If "listName" did not succed or was not previously called the value returned is invalid.                                 │
'' │                                                                                                                          │
'' │ Returns the modification day of the file or directory.                                                                   │                                                                                                                                                                                                      
'' └──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┘

  return (directoryEntry[24] & $1F)

PUB listModificationMonth '' 3 Stack Longs

'' ┌──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
'' │ Gets the last month of modification of the current file or directory pointed to by "listName".                           │
'' │                                                                                                                          │
'' │ If a file is currently open this function will retrieve that file's information.                                         │
'' │                                                                                                                          │
'' │ If "listName" did not succed or was not previously called the value returned is invalid.                                 │
'' │                                                                                                                          │
'' │ Returns the modification month of the file or directory.                                                                 │                                                                                                                                                                                                      
'' └──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┘

  return (((directoryEntry[25] & $1) << 3) | (directoryEntry[24] >> 5))

PUB listModificationYear '' 3 Stack Longs

'' ┌──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
'' │ Gets the last year of modification of the current file or directory pointed to by "listName".                            │
'' │                                                                                                                          │
'' │ If a file is currently open this function will retrieve that file's information.                                         │
'' │                                                                                                                          │
'' │ If "listName" did not succed or was not previously called the value returned is invalid.                                 │
'' │                                                                                                                          │
'' │ Returns the modification year of the file or directory.                                                                  │                                                                                                                                                                                                      
'' └──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┘

  return ((directoryEntry[25] >> 1) + 1980)

PUB listModificationSeconds '' 3 Stack Longs

'' ┌──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
'' │ Gets the last second of modification of the current file or directory pointed to by "listName".                          │
'' │                                                                                                                          │
'' │ If a file is currently open this function will retrieve that file's information.                                         │
'' │                                                                                                                          │
'' │ If "listName" did not succed or was not previously called the value returned is invalid.                                 │
'' │                                                                                                                          │
'' │ Returns the modification second of the file or directory.                                                                │                                                                                                                                                                                                      
'' └──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┘

  return ((directoryEntry[22] & $1F) << 1) 

PUB listModificationMinutes '' 3 Stack Longs

'' ┌──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
'' │ Gets the last minute of modification of the current file or directory pointed to by "listName".                          │
'' │                                                                                                                          │
'' │ If a file is currently open this function will retrieve that file's information.                                         │
'' │                                                                                                                          │
'' │ If "listName" did not succed or was not previously called the value returned is invalid.                                 │
'' │                                                                                                                          │
'' │ Returns the modification minute of the file or directory.                                                                │                                                                                                                                                                                                      
'' └──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┘

  return (((directoryEntry[23] & $7) << 3) | (directoryEntry[22] >> 5))

PUB listModificationHours '' 3 Stack Longs

'' ┌──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
'' │ Gets the last hour of modification of the current file or directory pointed to by "listName".                            │
'' │                                                                                                                          │
'' │ If a file is currently open this function will retrieve that file's information.                                         │
'' │                                                                                                                          │
'' │ If "listName" did not succed or was not previously called the value returned is invalid.                                 │
'' │                                                                                                                          │
'' │ Returns the modification hour of the file or directory.                                                                  │                                                                                                                                                                                                      
'' └──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┘

  return (directoryEntry[23] >> 3)  

PUB listIsReadOnly '' 3 Stack Longs

'' ┌──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
'' │ Returns whether or not the current file or directory pointed to by "listName" is read only.                              │
'' │                                                                                                                          │
'' │ If a file is currently open this function will retrieve that file's information.                                         │
'' │                                                                                                                          │
'' │ If "listName" did not succed or was not previously called the value returned is invalid.                                 │
'' │                                                                                                                          │
'' │ Returns true or false.                                                                                                   │                                                                                                                                                                                                      
'' └──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┘

  result or= (directoryEntry[11] & $1)

PUB listIsHidden '' 3 Stack Longs

'' ┌──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
'' │ Returns whether or not the current file or directory pointed to by "listName" is hidden.                                 │
'' │                                                                                                                          │
'' │ If a file is currently open this function will retrieve that file's information.                                         │
'' │                                                                                                                          │
'' │ If "listName" did not succed or was not previously called the value returned is invalid.                                 │
'' │                                                                                                                          │
'' │ Returns true or false.                                                                                                   │                                                                                                                                                                                                      
'' └──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┘

  result or= (directoryEntry[11] & $2)

PUB listIsSystem '' 3 Stack Longs

'' ┌──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
'' │ Returns whether or not the current file or directory pointed to by "listName" is a system file.                          │
'' │                                                                                                                          │
'' │ If a file is currently open this function will retrieve that file's information.                                         │
'' │                                                                                                                          │
'' │ If "listName" did not succed or was not previously called the value returned is invalid.                                 │
'' │                                                                                                                          │
'' │ Returns true or false.                                                                                                   │                                                                                                                                                                                                      
'' └──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┘

  result or= (directoryEntry[11] & $4)  
  
PUB listIsDirectory '' 3 Stack Longs

'' ┌──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
'' │ Returns whether or not the current file or directory pointed to by "listName" is a directory.                            │
'' │                                                                                                                          │
'' │ If a file is currently open this function will retrieve that file's information.                                         │
'' │                                                                                                                          │
'' │ If "listName" did not succed or was not previously called the value returned is invalid.                                 │
'' │                                                                                                                          │
'' │ Returns true or false.                                                                                                   │                                                                                                                                                                                                      
'' └──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┘

  result or= (directoryEntry[11] & $10)

PUB listIsArchive '' 3 Stack Longs

'' ┌──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
'' │ Returns whether or not the current file or directory pointed to by "listName" has been modified since the last backup.   │
'' │                                                                                                                          │
'' │ If a file is currently open this function will retrieve that file's information.                                         │
'' │                                                                                                                          │
'' │ If "listName" did not succed or was not previously called the value returned is invalid.                                 │
'' │                                                                                                                          │
'' │ Returns true or false.                                                                                                   │                                                                                                                                                                                                      
'' └──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┘  

  result or= (directoryEntry[11] & $20)

PUB listVolumeLabel
'' return:  zeiger auf string mit volume-label

  'return unformatName(listDirectory("V"))              'frida
  if(partitionMountedFlag)                              'frida
    return @sdvolumeLabel                               'frida


PUB checkPartitionMounted '' 3 Stack Longs

'' ┌──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
'' │ Returns true if the file system is still currently mounted and false if not.                                             │                                                                                                                                                                                                     
'' └──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┘

  result or= partitionMountedFlag

PUB checkFileOpen '' 3 Stack Longs

'' ┌──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
'' │ Returns true if a file is still currently open and false if not.                                                         │                                                                                                                                                                                                     
'' └──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┘

  result or= fileOpenFlag
 
PUB checkUsedSectorCount(mode) '' 18 Stack Longs

'' ┌──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
'' │ Returns the current used sector count on this partition.                                                                 │
'' │                                                                                                                          │
'' │ Will do nothing if a file is currently open or if the card is not mounted. This throws an error.                         │                                                              
'' │                                                                                                                          │
'' │ If an error occurs this function will abort and return a pointer to a string describing that error.                      │
'' │                                                                                                                          │                                                                                       
'' │ In fast mode this function will return the last valid used sector count if avialable. This is an estimate value.         │
'' │                                                                                                                          │
'' │ In slow mode this function will compute the used sector count by scanning the entire FAT. This can take a long time.     │
'' │                                                                                                                          │
'' │ One sector is equal to 512 bytes. Multiply the used sector count by 512 to determine the number of used bytes.           │
'' │                                                                                                                          │
'' │ This function also finds the next free cluster for creating new files and directories.                                   │
'' │                                                                                                                          │
'' │ Call this function when running out of disk space to find the next free cluster if available.                            │
'' │                                                                                                                          │
'' │ If the last valid used sector count is not avialable when using fast mode this function will enter slow mode,            │                                                                                                                   
'' │                                                                                                                          │                                                                                                                
'' │ Mode - A character specifing the mode to use. F-Fast, S-Slow. Default slow.                                              │
'' └──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┘

  if(partitionMountedFlag)
    return ((countOfClusters * sectorsPerCluster) - checkFreeSectorCount(mode)) 
  
PUB checkFreeSectorCount(mode) '' 14 Stack Longs

'' ┌──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
'' │ Returns the current free sector count on this partition.                                                                 │
'' │                                                                                                                          │
'' │ Will do nothing if a file is currently open or if the card is not mounted. This throws an error.                         │                                                              
'' │                                                                                                                          │
'' │ If an error occurs this function will abort and return a pointer to a string describing that error.                      │
'' │                                                                                                                          │                                                                                       
'' │ In fast mode this function will return the last valid free sector count if avialable. This is an estimate value.         │
'' │                                                                                                                          │
'' │ In slow mode this function will compute the free sector count by scanning the entire FAT. This can take a long time.     │
'' │                                                                                                                          │
'' │ One sector is equal to 512 bytes. Multiply the free sector count by 512 to determine the number of free bytes.           │
'' │                                                                                                                          │
'' │ This function also finds the next free cluster for creating new files and directories.                                   │
'' │                                                                                                                          │
'' │ Call this function when running out of disk space to find the next free cluster if available.                            │
'' │                                                                                                                          │
'' │ If the last valid free sector count is not avialable when using fast mode this function will enter slow mode,            │                                                                                                                   
'' │                                                                                                                          │                                                                                                                
'' │ Mode - A character specifing the mode to use. F-Fast, S-Slow. Default slow.                                              │
'' └──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┘

  if(partitionMountedFlag)
    flushCharacters
  
    if(findByte(mode, "f", "F") and (freeClusterCount <> $FFFFFFFF))
      result := freeClusterCount
 
    else
      repeat mode from 0 to (countOfClusters + 1)

        ifnot(FATEntryNumber(mode))
          readWriteFATBlock(mode, "R")
                                              
        result -= (not(readFATEntry(mode)))

        ifnot(result)
          nextFreeCluster := ((mode + 1) <# (countOfClusters + 1))

      freeClusterCount := result
      readWriteCurrentSector("R")
    
    result *= sectorsPerCluster

PUB bootPartition(fileName, checkDisk) | bootSectors[64] '' 102 Stack Longs

'' ┌──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
'' │ Reboots the propeller chip to run the selected file from memory. The file should be a valid spin BIN or EEPROM file.     │
'' │                                                                                                                          │
'' │ Will do nothing if the card is not mounted. This throws an error.                                                        │                                                              
'' │                                                                                                                          │
'' │ If an error occurs this function will abort and return a pointer to a string describing that error.                      │
'' │                                                                                                                          │
'' │ FileName - The name of the file to reboot from.                                                                          │
'' │ CheckDisk - Unmounts the partition before booting if "C".                                                                │
'' └──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┘
   
  longfill(@bootSectors, 0, 64)
  openFile(fileName~, string("R"))
            
  repeat (listSize <# 32768)
    result += readCharacter

    ifnot($1FF & fileName++)
      bootSectors[fileName >> 9] := (partitionStart + FATFirstSectorInCluster(currentCluster) + FATWorkingSectorInCluster)  

  result &= $FF
  setCharacterPosition(6)
  fileName := readShort
  closeFile
  
  if((result and (result <> $14)) or (fileName <> $10))   
'   abort string("Checksum Error")                                              '@hive
    abort err_checksumError
    
  if(findByte(checkDisk, "c", "C"))
    unmountPartition
    
  readWriteBlock(@bootSectors, "B")
' abort string("Reboot Error")                                                  '@hive
  abort err_rebootError
  
PUB formatPartition(partition, volumeLabel, checkDisk) '' 34 Stack Longs

'' ┌──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
'' │ Permanetly deletes all information on the loaded FAT16/32 file system. Unloads the loaded FAT16/32 file system.          │
'' │                                                                                                                          │
'' │ Will do nothing if the card is not mounted. This throws an error.                                                        │                                                              
'' │                                                                                                                          │
'' │ If an error occurs this function will abort and return a pointer to a string describing that error.                      │
'' └──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┘

  mountPartition(partition, checkdisk)

  repeat while(readWriteCurrentCluster("R", "D"))
    bytefill(@dataBlock, 0, 512)
    readWriteCurrentSector("W")
    currentByte += 512

' result := unformatName(listNew(formatName(volumeLabel), $8, readClock, cardTime, 0, 0)) '@hive                                                    
  unformatName(listNew(formatName(volumeLabel), $8, readClock, cardTime, 0, 0)) '@hive                                                              

  bytefill(@dataBlock, 0, 512) 
  repeat volumeLabel from reservedSectorCount to (rootDirectorySectorNumber - 1)
    readWriteBlock(volumeLabel, "W")
   
  readWriteFATBlock(0, "R")
  writeFATEntry(0, ($0FFFFF00 | mediaType))
  writeFATEntry(1, $0FFFFFFF)
  readWriteFATBlock(0, "W")

  listReset 

PUB mountPartition(partition, checkDisk) '' 28 Stack Longs

'' ┌──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
'' │ Loads a FAT16/32 file system with up to 1,099,511,627,776 bytes for use.                                                 │
'' │                                                                                                                          │
'' │ If an error occurs this function will abort and return a pointer to a string describing that error.                      │
'' │                                                                                                                          │
'' │ File sizes up to 2,147,483,136 bytes are supported.                                                                      │
'' │                                                                                                                          │
'' │ Directory sizes up to 65,536 entries are supported.                                                                      │
'' │                                                                                                                          │
'' │ Additionally check disk flags can be setup so that check disk is called on any improperly unmounted partition.           │
'' │                                                                                                                          │
'' │ Returns a pointer to the volume label.                                                                                   │
'' │                                                                                                                          │
'' │ Parition  - Partition number to mount (between 0 and 3). The default partition number is 0.                              │
'' │ CheckDisk - Raises the check disk flag upon mounting. C-Raise Flag                                                       │                                                                                                                                                                        
'' └──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┘
''  @hive:
''  return: fehlernummer

  unmountPartition

  partitionStart := 0
  readWriteBlock(0, "M")
  
  bytemove(@cardUniqueIDCopy, @cardUniqueID, 17)
  readWriteBlock(0, "R")

  if(blockToWord(510) <> $AA55)
'   abort @FSCorrupted                                                          '@hive
    abort err_fsysCorrupted
    
  partition := (((partition <# 3) #> 0) << 4)
  if((blockToByte(0) <> $EB) and (blockToByte(0) <> $E9))
  
    'case(blockToByte(450 + partition) & $F)      
    '  $0 .. $3, $5, $7 .. $A, $D, $F: abort @FSUnsupported
    
    'volumeIdentification := blockToLong(440)
    'partitionSize := blockToLong(458 + partition)
  
    partitionStart := blockToLong(454 + partition)
    readWriteBlock(0, "R")  
    
  if(blockToWord(510) <> $AA55)
'   abort string("BPB Corrupt")                                                 '@hive
    abort err_bpbCorrupt


    
  if(blockToWord(11) <> 512)
'   abort @FSUnsupported                                                        '@hive
    abort err_fsysUnsupported
    
  sectorsPerCluster := blockToByte(13)
  reservedSectorCount := blockToWord(14)  
  numberOfFATs := blockToByte(16)
  externalFlags := 0

  partitionSize := blockToWord(19)
  ifnot(partitionSize)
    partitionSize := blockToLong(32)

  FATSectorSize := blockToWord(22)
  ifnot(FATSectorSize) 
    FATSectorSize := blockToLong(36)

  mediaType := blockToByte(21)
  hiddenSectors := blockToLong(28)

  rootDirectorySectors := (blockToWord(17) >> 4)
  rootDirectorySectorNumber := (reservedSectorCount + (numberOfFATs * FATSectorSize))

  firstDataSector := (rootDirectorySectorNumber + rootDirectorySectors)
  countOfClusters := ((partitionSize - firstDataSector) / sectorsPerCluster) 

  nextFreeCluster := 2
  freeClusterCount := $FFFFFFFF

  if(countOfClusters < 4085)
'   abort @FSUnsupported                                                        '@hive
    abort err_fsysUnsupported
  
  FATType := false
  if(countOfClusters => 65525) 
    FATType := true

  volumeIdentification := blockToLong(39 + (28 & FATType))
  dataBlock[37 + (28 & FATType)] |= ($3 & findByte(checkDisk, "c", "C"))                  
  readWriteBlock(0, "W")

  if(FATType)
    if(blockToWord(40) & $80)
      numberOfFATs := 1
      externalFlags := (blockToWord(40) & $F)

    if(blockToWord(42))
'     abort @FSUnsupported                                                      '@hive
      abort err_fsysUnsupported
      
    rootCluster := blockToLong(44)
    fileSystemInfo := blockToWord(48) 
    backupBootSector := blockToWord(50)

    readWriteBlock(fileSystemInfo, "R")
    
    if(blockToWord(510) <> $AA55)
'     abort string("FSI Corrupt")                                               '@hive
      abort err_fsiCorrupt
      
    freeClusterCount := blockToLong(488)
    nextFreeCluster := blockToLong(492)

    if(nextFreeCluster == $FFFFFFFF)
      nextFreeCluster := 2

  partitionMountedFlag := true

  currentDirectory := 0
  listReset

' return unformatName(listDirectory("V"))                                       '@hive
  result := listDirectory("V")                          'frida
  bytemove(@sdvolumeLabel, result, 12)                  'frida
  return 0

PUB unmountPartition '' 18 Stack Longs

'' ┌──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
'' │ Unloads the loaded FAT16/32 file system. Closes the currently open file in the current directory.                        │
'' │                                                                                                                          │
'' │ If an error occurs this function will abort and return a pointer to a string describing that error.                      │                                                                                                                                                                                   
'' └──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┘

  closeFile
  if(partitionMountedFlag~)

    currentDirectory := 0
    listReset
  
    readWriteBlock(0, "R")
    dataBlock[37 + (28 & FATType)] &= $FC
    readWriteBlock(0, "W")    
  
    if(FATType)  
      readWriteBlock(fileSystemInfo, "R")
      longToBlock(freeClusterCount, 488)
      longToBlock(nextFreeCluster, 492)
      readWriteBlock(fileSystemInfo, "W")

PUB FATEngine '' 3 Stack Longs

'' ┌──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
'' │ Initializes the file system driver to run on a new cog.                                                                  │
'' │                                                                                                                          │
'' │ Returns the new cog's ID on sucess or -1 on failure.                                                                     │                                                                                  
'' └──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┘

  cardLockID := locknew         'frida

  'debugverbindung
  'debugx.start(115200)                                   ' Start des Debug-Terminals
   
  slowTiming := ((constant(250_000 << 12) / clkfreq) << 20)
  fastTiming := ((constant(2_500_000 << 8) / clkfreq) << 24)

  CCFAddress := @cardCommandFlag
  CEFAddress := @cardErrorFlag

  CDBAddress := @cardDataBlockAddress    
  CSAAddress := @cardSectorAddress  

  CUIDAddress := @cardUniqueID
  return cognew(@initialization, @cardSectorCount)

PRI listDuplicate(entryName) ' 27 Stack Longs

  closeFile
  listReset

  repeat

    result := listDirectory("R")
    
    if(strcomp(result, entryName))
    
      if(listIsDirectory)
'       abort string("Directory Already Exist")                                 '@hive
        abort err_dirAlreadyExist
        
'     abort string("File Already Exist")                                        '@hive
      abort err_fileAlreadyExist
      
  while(result)

{
PRI listFind(entryName, errorMessage) ' 28 Stack Longs                          '@hive

  closeFile
  listReset
  
  repeat

    result := listDirectory("R")

    ifnot(result)
      abort errorMessage
    
  until(strcomp(entryName, result)) 

  currentByte -= 32
}

PRI listFind(entryName, errorMessage) | strptr ' 28 Stack Longs

  closeFile
  listReset
  
  repeat
    result := err_noError
    strptr := listDirectory("R")

    ifnot(strptr)
      abort errorMessage
    
  until(strcomp(entryName, strptr)) 

  currentByte -= 32

PRI listNew(entryName, entryAttributes, entryDate, entryTime, entryCluster, entryType) ' 36 Stack Longs

  listDuplicate(entryName)
  listReset
  
  repeat while(readWriteCurrentCluster("W", "D"))
    
    if((blockToByte(currentByte) <> $E5) and blockToByte(currentByte))
      currentByte += 32 

    else

      if(entryType == "D")
        entryCluster := createClusterChain(0)
        currentFile := entryCluster
        readWriteCurrentSector("R")
 
      bytefill(@dataBlock[currentByte & $1FF], 0, 32) 
      bytemove(@dataBlock[currentByte & $1FF], entryName, 11)

      byteToBlock((currentByte + 11), entryAttributes)

      wordToBlock((currentByte + 14), entryTime)
      wordToBlock((currentByte + 16), entryDate)      
      wordToBlock((currentByte + 18), entryDate)
      wordToBlock((currentByte + 22), entryTime)
      wordToBlock((currentByte + 24), entryDate)      

      wordToBlock((currentByte + 26), (entryCluster & $FFFF))
      wordToBlock((currentByte + 20), (entryCluster >> 16))
      
      readWriteCurrentSector("W") 
      return entryName

' abort string("Directory Is Full")                                             '@hive
  abort err_dirIsFull

PRI listDirectory(volumeIDAttribute) ' 23 Stack Longs

  if(fileOpenFlag)
    closeFile
    'listReset                  'frida

  repeat while(readWriteCurrentCluster("R", "D") and blockToByte(currentByte))
  
    if((blockToByte(currentByte) == $E5) or (((volumeIDAttribute == "V") ^ blockToByte(currentByte + 11)) & $8))
      currentByte += 32

    else
     
      bytemove(@directoryEntry, @dataBlock[currentByte & $1FF], 32)
      bytemove(@directoryEntryName, @directoryEntry, 11)
    
      if(directoryEntryName == $5)
        directoryEntryName := $E5
    
      currentByte += 32
      return @directoryEntryName

  listReset

PRI listCluster ' 3 Stack Longs

  result := directoryEntry[26]
  result.byte[1] := directoryEntry[27]
  result.byte[2] := directoryEntry[20]
  result.byte[3] := directoryEntry[21]
  
  if((result == 1) or (FATEndOfClusterValue =< result))
'   abort @FSCorrupted                                                          '@hive
    abort err_fsysCorrupted
    
PRI listCase(unformatedName, formatedName) ' 5 Stack Longs

  if(byte[unformatedName++] == ".")
    result := @dot

  if(byte[unformatedName++] == ".")
    result := @dotdot

  repeat strsize(unformatedName)
    case byte[unformatedName++] 
      9 .. 10, 13, 32: 
      other:
        result := formatedName 
        quit

PRI readWriteCurrentCluster(readWrite, fileOrDirectory) ' 19 Stack Longs

  ifnot((fileOrDirectory <> "D") or partitionMountedFlag)
'   abort @FSUnmounted                                                          '@hive
    abort err_fsysUnmounted

  'Needs to return true if it got the data and false if it didn't.
  
  ifnot(currentByte & $1FF)

    if(fileOpenFlag and (currentByte => $7FFFFE00))
      return false              'abort string("End of File")                    
      
    ifnot(fileOpenFlag or (currentByte < constant(65536 * 32)))
      return false              'abort string("End of Directory")               
      
    ifnot(currentcluster or FATType or ((currentByte >> 9) < rootDirectorySectors))
      return false              'abort string("End of Root")                   
      
    if(currentByte and (not(FATWorkingSectorInCluster)) and (FATType or currentcluster))
    
      result := currentCluster
      ifnot(result)
        result := rootCluster
        
      readWriteFATBlock(result, "R")  
      fileOrDirectory := readFATEntry(result)

      if(fileOrDirectory =< 1)
        partitionMountedFlag := false     
'       abort @FSCorrupted                                                      '@hive
        abort err_fsysCorrupted
      
      if(fileOrDirectory => FATEndOfClusterValue)
        if(fileOpenFlag and (currentByte < (currentSize - 1)))
          partitionMountedFlag := false
         ' abort @FSCorrupted
          abort err_fsysCorrupted
        
        if(readWrite == "R")
          ifnot(fileOpenFlag)
            ifnot(currentCluster)
'             abort string("End of Root")                                       '@hive
              abort err_endOfRoot
              
'           abort string("End of Directory")                                    '@hive
            abort err_endOfDirectory
            
          else
'           abort string("End of File")                                         '@hive
            abort err_endOfFile
            
        fileOrDirectory := createClusterChain(result)
      currentCluster := fileOrDirectory
    readWriteCurrentSector("R")

  return true
  
PRI readWriteCurrentSector(readWrite) ' 9 Stack Longs

  result := FATFirstSectorInCluster(currentCluster) + FATWorkingSectorInCluster 
  
  ifnot(currentCluster)
    result := rootDirectorySectorNumber + (currentByte >> 9)

    if(FATType)
      result := FATFirstSectorInCluster(rootCluster) + FATWorkingSectorInCluster

  readWriteBlock(result, readWrite) 

PRI findByte(byteToCompare, thisByte, thatByte) ' 6 Stack Longs

  if((byteToCompare == thisByte) or (byteToCompare == thatByte))
    return true
      
PRI findCharacter(charactersToSearch, characterToFind) | convertedCharacter ' 6 Stack Longs
    
  repeat strsize(charactersToSearch)

    convertedCharacter := byte[charactersToSearch++]
    case convertedCharacter
      "a" .. "z": convertedCharacter -= 32  

    if(convertedCharacter == characterToFind)
      return true

PRI unformatName(name) ' 4 Stack Longs

  if(name)    

    unformatedNameBuffer[12] := 0
  
    bytefill(@unformatedNameBuffer, " ", 12)
    bytemove(@unformatedNameBuffer, name, 8)

    repeat while(unformatedNameBuffer[++result] <> " ")
    unformatedNameBuffer[result++] := "."

    bytemove(@unformatedNameBuffer[result], @byte[name][8], 3)

    if(unformatedNameBuffer[result] == " ")
      unformatedNameBuffer[--result] := " "
  
    return @unformatedNameBuffer 

PRI formatName(name) ' 4 Stack Longs

  formatedNameBuffer[11] := 0

  bytefill(@formatedNameBuffer, " ", 11)

  repeat strsize(name--)

    if(byte[++name] == ".")
      result := 0

      repeat strsize(++name)
      
        if((result < 3) and (byte[name] > 31))
          formatedNameBuffer[8 + result++] := byte[name++]

      quit    

    if((result < 8) and (byte[name] > 31))
      formatedNameBuffer[result++] := byte[name]
      
  repeat result from 0 to 10

    case formatedNameBuffer[result]
      "a" .. "z": formatedNameBuffer[result] -= 32                            
      $22, "*" .. ",", "." .. "/", ":" .. "?", "[" .. "]", "|", $7F: formatedNameBuffer[result] := "_"

  if(formatedNameBuffer == " ")
    formatedNameBuffer := "_"            

  if(formatedNameBuffer == $E5)
    formatedNameBuffer := $5
  
  return @formatedNameBuffer

PRI createClusterChain(clusterToLink) ' 14 Stack Longs 

  readWriteFATBlock(nextFreeCluster, "R")
  repeat result from nextFreeCluster to (countOfClusters + 1)
  
    ifnot(FATEntryNumber(result))
      readWriteFATBlock(result, "R")

    ifnot(readFATEntry(result))

      writeFATEntry(result, true)
      readWriteFATBlock(result, "W")

      nextFreeCluster := ((result + 1) <# (countOfClusters + 1))
      
      if(clusterToLink)
           
        readWriteFATBlock(clusterToLink, "R")
        writeFATEntry(clusterToLink, result)
        readWriteFATBlock(clusterToLink, "W")
  
      bytefill(@dataBlock, 0, 512)

      repeat clusterToLink from 0 to (sectorsPerCluster - 1)
        readWriteBlock((FATFirstSectorInCluster(result) + clusterToLink), "W")

      quit

    if(result => (countOfClusters + 1))
'     abort string("Out Of Disk Free Space")                                    '@hive
      abort err_outOfDiskFreeSpace

PRI destroyClusterChain(clusterToDestroy) ' 14 Stack Longs

  repeat while((1 < clusterToDestroy) and (clusterToDestroy < FATEndOfClusterValue))

    ifnot(result and (FATBlockNumber(result) == FATBlockNumber(clusterToDestroy)))
      readWriteFATBlock(clusterToDestroy, "R")

    result := clusterToDestroy
    clusterToDestroy := readFATEntry(clusterToDestroy)
    writeFATEntry(result, false)

    if(FATBlockNumber(result) <> FATBlockNumber(clusterToDestroy))      
      readWriteFATBlock(result, "W")

  if(result)
    readWriteFATBlock(result, "W")               

PRI readFATEntry(cluster) ' 8 Stack Longs

  cluster := FATEntryNumber(cluster)

  ifnot(FATType)
    return blockToWord(cluster)
  
  return (blockTolong(cluster) & $0FFFFFFF)  
      
PRI writeFATEntry(cluster, value) ' 10 Stack Longs

  cluster := FATEntryNumber(cluster)

  ifnot(FATType)
    wordToBlock(cluster, value)
  else
    longToBlock(cluster, ((value & $0FFFFFFF) | (blockTolong(cluster) & $F0000000)))  

PRI readWriteFATBlock(cluster, readWrite) ' 10 Stack Longs

  cluster := FATBlockNumber(cluster)
  result := externalFlags 
                                   
  repeat ((numberOfFATs & (readWrite == "W")) | (-(readWrite == "R")))
    readWriteBlock((reservedSectorCount + cluster + (FATSectorSize * result++)), readWrite)

PRI FATBlockNumber(cluster) ' 4 Stack Longs

  return (cluster >> (8 + FATType))

PRI FATEntryNumber(cluster) ' 4 Stack Longs

  return ((cluster & ($FF >> (-FATType))) << (1 - FATType))
 
PRI FATEndOfClusterValue ' 3 Stack Longs

  return ($FFF0 | (FATType & $0FFFFFF0))

PRI FATWorkingSectorInCluster ' 3 Stack Longs

  return ((currentByte >> 9) // sectorsPerCluster)

PRI FATFirstSectorInCluster(cluster) ' 4 Stack Longs

  return (((cluster - 2) * sectorsPerCluster) + firstDataSector)
  
PRI blockToLong(index) ' 4 Stack Longs

  bytemove(@result, @dataBlock[index & $1FF], 4)
  
PRI blockToWord(index) ' 4 Stack Longs 

  bytemove(@result, @dataBlock[index & $1FF], 2)
      
PRI blockToByte(index) ' 4 Stack Longs

  return dataBlock[index & $1FF]
                 
PRI longToBlock(index, value) ' 5 Stack Longs

  bytemove(@dataBlock[index & $1FF], @value, 4)
                               
PRI wordToBlock(index, value) ' 5 Stack Longs 

  bytemove(@dataBlock[index & $1FF], @value, 2)

PRI byteToBlock(index, value) ' 5 Stack Longs 

  dataBlock[index & $1FF] := value  

PRI readClock ' 3 + 11 Stack Longs 

  repeat while(lockset(cardLockID))
  cardTime := ((rtc.getSeconds >> 1) | (rtc.getMinutes << 5) | (rtc.getHours << 11))
  cardDate := (rtc.getDate | (rtc.getMonth << 5) | ((rtc.getYear - 1980) << 9))

  lockclr(cardLockID)
  return cardDate
  
PRI readWriteBlock(address, command) ' 5 Stack Longs

  if(strcomp(@cardUniqueID, @cardUniqueIDCopy) or (command == "M"))
    repeat while(lockset(cardLockID))

    if command == "B"           'frida
      lockclr(cardLockID)       'frida
      lockret(cardLockID)       'frida

    cardSectorAddress := (address + (partitionStart & (command <> "B")))
    cardDataBlockAddress := (@dataBlock & (command <> "B"))
    cardCommandFlag := command
    repeat while(cardCommandFlag)
      
    command := cardErrorFlag~
    lockclr(cardLockID)

  if(command)
    partitionMountedFlag := false
'   abort string("Disk I/O Error")                                              '@hive
    abort err_diskIOError

DAT 'ASM-Code

' ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////// 
'                       SD/SDHC/MMC Driver
' ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////// 

                        org
                        
' //////////////////////Initialization///////////////////////////////////////////////////////////////////////////////////////// 
                        
initialization          neg     phsa,                 #1                           ' Setup clock counter.
                        movs    ctra,                 #((Clock_Pin <# 31) #> 0)    '
                        movi    ctra,                 #%0_00100_000                '

                        mov     outa,                 chipSelectPin                ' Setup I/O Pins.
                        or      outa,                 dataInPin                    '
                        mov     dira,                 chipSelectPin                '
                        or      dira,                 dataInPin                    '
                        or      dira,                 clockPin                     '

                        mov     cardCounter,          fiveHundredAndTwelve         ' Skip to instruction handle.
                        jmp     #instructionWait                                   ' 
                        
' ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////// 
'                       Command Center
' /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

instructionRetry        cmp     cardBuffer,           #"M" wc, wz                  ' Try at most 8 more times to mount the card.
if_c                    cmp     cardBuffer,           #"F" wc, wz                  '
if_nc_or_z              djnz    cardBuffer,           #mountCard                   '

                        cmp     cardBuffer,           #"R" wz                      ' Try at most twice to read the specified block.
if_z                    djnz    cardBuffer,           #readBlock                   '

                        cmp     cardBuffer,           #"W" wz                      ' Try at most twice to write the specified block.                         
if_z                    djnz    cardBuffer,           #writeBlock                  '

                        cmp     cardBuffer,           #"B" wz                      ' Reboot the chip if booting failure.
if_z                    mov     buffer,               #$80                         ' 
if_z                    clkset  buffer                                             '

instructionError        wrbyte  maxPositiveInteger,   CEFAddress                   ' Assert Error Flag and unmount card.
instructionUnmount      mov     cardMounted,          #0                           '  

' //////////////////////Instruction Handle/////////////////////////////////////////////////////////////////////////////////////

instructionLoop         wrbyte  fiveHundredAndTwelve, CCFAddress                   ' Wait for a command to come.
instructionWait         rdbyte  cardBuffer,           CCFAddress                   ' 
                        test    cardMounted,          maxPositiveInteger wc        ' 

                        cmp     cardBuffer,           #"B" wz                      ' If rebooting was requested do it.
if_z_and_nc             jmp     #instructionError                                  '                        
if_z_and_c              jmp     #rebootChip                                        '

                        cmp     cardBuffer,           #"R" wz                      ' If read block was requested do it.
if_z_and_nc             jmp     #instructionError                                  '
if_z_and_c              jmp     #readBlock                                         '

                        cmp     cardBuffer,           #"W" wz                      ' If write block was requested do it.
if_z_and_nc             jmp     #instructionError                                  '
if_z_and_c              jmp     #writeBlock                                        '

                        djnz    cardCounter,          #instructionSkip             ' Poll the card every so often.
                        mov     cardCounter,          fiveHundredAndTwelve         '
if_nc                   jmp     #instructionSkip                                   ' 
                        call    #cardStatus                                        '

instructionSkip         cmp     cardBuffer,           #"M" wz                      ' If mounting was requested do it.
if_nz                   jmp     #instructionWait                                   ' 

' ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////// 
'                       Mount Card
' /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

mountCard               mov     SPITiming,            slowTiming                   ' Setup SPI parameters.
                                                                               
                        mov     counter,              #80                          ' Send out for more than 1 millisecond.                            
seventyFourClocks       call    #readSPI                                           ' 
                        djnz    counter,              #seventyFourClocks           '

' //////////////////////Go Idle State//////////////////////////////////////////////////////////////////////////////////////////

                        mov     counter,              #80                          ' Setup counter to try a few times.
                                                                    
enterIdleStateLoop      mov     SPICommandOut,        #($40 | 0)                   ' Send out command 0.
                        mov     SPIParameterOut,      #0                           '
                        movs    commandSPICRC,        #$95                         '
                        call    #commandSPI                                        '
                        call    #shutdownSPI                                       '

                        cmp     SPIResponceIn,        #1 wz                        ' Try a few times.
if_nz                   djnz    counter,              #enterIdleStateLoop          '
                        tjz     counter,              #instructionRetry            '

' //////////////////////Send Interface Condition///////////////////////////////////////////////////////////////////////////////
                        
                        mov     SPICommandOut,        #($40 | 8)                   ' Send out command 8.
                        mov     SPIParameterOut,      #$1AA                        '
                        movs    commandSPICRC,        #$87                         '
                        call    #commandSPI                                        '
                        call    #longSPI                                           '
                        call    #shutdownSPI                                       '
                        
                        test    SPIResponceIn,        #$7E wz                      ' If failure goto SD 1.X initialization.
if_nz                   jmp     #exitIdleState_SD                                  '
                                                                                
                        and     SPILongIn,            #$1FF                        ' SD 2.0 initialization.
                        cmp     SPILongIn,            #$1AA wz                     '
if_nz                   jmp     #instructionRetry                                  '
                        
' //////////////////////Send Operating Condition///////////////////////////////////////////////////////////////////////////////

exitIdleState_SD        mov     cardType,             #0                           ' Card type is MMC.

                        mov     counter,              #80                          ' Setup counter to try a few times.

exitIdleStateLoop_SD    mov     SPICommandOut,        #($40 | 55)                  ' Send out command 55.
                        mov     SPIParameterOut,      #0                           '
                        call    #commandSPI                                        '
                        call    #shutdownSPI                                       '

                        test    SPIResponceIn,        #$7E wz                      ' If failure goto MMC initialization.                                 '        
if_nz                   jmp     #exitIdleState_MMC                                 '

                        mov     SPICommandOut,        #($40 | 41)                  ' Send out command 41 with HCS bit set.
                        mov     SPIParameterOut,      HCSBitMask                   '
                        call    #commandSPI                                        '
                        call    #shutdownSPI                                       '

                        cmp     SPIResponceIn,        #0 wz                        ' Try a few times.
if_nz                   djnz    counter,              #exitIdleStateLoop_SD        '
                        tjz     counter,              #instructionRetry            '

                        djnz    cardType,             #readOCR                     ' Card type is SD and skip MMC initialization.

' //////////////////////Send Operating Condition///////////////////////////////////////////////////////////////////////////////
                        
exitIdleState_MMC       mov     counter,              #80                          ' Setup counter to try a few times.
                                                                              
exitIdleStateLoop_MMC   mov     SPICommandOut,        #($40 | 1)                   ' Send out command 1.
                        mov     SPIParameterOut,      #0                           '
                        call    #commandSPI                                        '
                        call    #shutdownSPI                                       '

                        cmp     SPIResponceIn,        #0 wz                        ' Try a few times.
if_nz                   djnz    counter,              #exitIdleStateLoop_MMC       '
                        tjz     counter,              #instructionRetry            '

' //////////////////////Read OCR Register//////////////////////////////////////////////////////////////////////////////////////

readOCR                 mov     SPICommandOut,        #($40 | 58)                  ' Ask the card for its OCR register.
                        mov     SPIParameterOut,      #0                           '
                        call    #commandSPI                                        '
                        call    #longSPI                                           '   
                        call    #shutdownSPI                                       '

                        tjnz    SPIResponceIn,        #instructionRetry            ' If failure abort.

                        test    SPILongIn,            OCRCheckMask wz              ' If voltage not supported abort. 
                        shl     SPILongIn,            #1 wc                        '
if_z_or_nc              jmp     #instructionRetry                                  '
                                                                              
                        shl     SPILongIn,            #1 wc                        ' SDHC supported or not.
if_c                    mov     SPIShift,             #0                           '
if_nc                   mov     SPIShift,             #9                           '

' //////////////////////Set Block Length///////////////////////////////////////////////////////////////////////////////////////
                        
                        mov     SPICommandOut,        #($40 | 16)                  ' Send out command 16.
                        mov     SPIParameterOut,      fiveHundredAndTwelve         '
                        call    #commandSPI                                        '
                        call    #shutdownSPI                                       '

                        tjnz    SPIResponceIn,        #instructionRetry            ' If failure abort.
                        
' //////////////////////Read CSD Register//////////////////////////////////////////////////////////////////////////////////////                        

                        mov     SPICommandOut,        #($40 | 9)                   ' Ask the card for its CSD register.
                        mov     SPIParameterOut,      #0                           '
                        call    #commandSPI                                        '
                                                      
                        tjnz    SPIResponceIn,        #instructionRetry            ' If failure abort.
                        call    #repsonceSPI                                       ' 
                        cmp     SPIResponceIn,        #$FE wz                      '
if_nz                   jmp     #instructionRetry                                  '
                                                      
                        mov     counter,              #16                          ' Setup to read the CSD register.
                        movd    readCSDModify,        #CSDRegister                 '
                                                      
readCSDLoop             call    #readSPI                                           ' Read the CSD register in.
readCSDModify           mov     0,                    SPIDataIn                    '
                        add     readCSDModify,        fiveHundredAndTwelve         '
                        djnz    counter,              #readCSDLoop                 '

                        call    #wordSPI                                           ' Shutdown SPI clock. 
                        call    #shutdownSPI                                       ' 
                                                      
' //////////////////////Read CID Register//////////////////////////////////////////////////////////////////////////////////////

                        mov     SPICommandOut,        #($40 | 10)                  ' Ask the card for its CID register.
                        mov     SPIParameterOut,      #0                           '
                        call    #commandSPI                                        '
                                                      
                        tjnz    SPIResponceIn,        #instructionRetry            ' If failure abort.
                        call    #repsonceSPI                                       ' 
                        cmp     SPIResponceIn,        #$FE wz                      '
if_nz                   jmp     #instructionRetry                                  '
                                                      
                        mov     counter,              #16                          ' Setup to read the CID register.
                        mov     buffer,               CUIDAddress                  '
                                                                          
readCIDLoop             call    #readSPI                                           ' Read the CID register in.
                        wrbyte  SPIDataIn,            buffer                       '
                        add     buffer,               #1                           '
                        djnz    counter,              #readCIDLoop                 '

                        wrbyte  fiveHundredAndTwelve, buffer                       ' Clear the last byte for string compare.

                        call    #wordSPI                                           ' Shutdown SPI clock. 
                        call    #shutdownSPI                                       '

' //////////////////////Setup Card Variables///////////////////////////////////////////////////////////////////////////////////

                        mov     SPITiming,            fastTiming                   ' Setup SPI parameters.

                        testn   cardType,             #0 wz, wc                    ' Determine CSD structure version.
if_nz                   test    CSDRegister,          #$40 wc                      ' 
if_nz                   test    CSDRegister,          #$80 wz                      '

if_nc_and_z             mov     counter,              (CSDRegister + 6)            ' Extract card size.
if_nc_and_z             and     counter,              #$3                          '
if_nc_and_z             shl     counter,              #10                          '
if_nc_and_z             mov     buffer,               (CSDRegister + 7)            '
if_nc_and_z             shl     buffer,               #2                           '
if_nc_and_z             mov     cardSize,             (CSDRegister + 8)            '
if_nc_and_z             shr     cardSize,             #6                           '
if_nc_and_z             or      cardSize,             counter                      '
if_nc_and_z             or      cardSize,             buffer                       '

if_c_and_z              mov     counter,              (CSDRegister + 7)            ' Extract card size.
if_c_and_z              and     counter,              #$3F                         '
if_c_and_z              shl     counter,              #16                          '
if_c_and_z              mov     buffer,               (CSDRegister + 8)            '
if_c_and_z              shl     buffer,               #8                           '
if_c_and_z              mov     cardSize,             (CSDRegister + 9)            '
if_c_and_z              or      cardSize,             counter                      '
if_c_and_z              or      cardSize,             buffer                       '

if_nc_and_z             mov     buffer,               (CSDRegister + 9)            ' Extract card size multiplier.
if_nc_and_z             and     buffer,               #$3                          '
if_nc_and_z             shl     buffer,               #1                           '
if_nc_and_z             mov     cardSizeMultiplier,   (CSDRegister + 10)           '
if_nc_and_z             shr     cardSizeMultiplier,   #7                           '
if_nc_and_z             or      cardSizeMultiplier,   buffer                       '
                                                      
if_nc_and_z             mov     cardReadBlockLength,  (CSDRegister + 5)            ' Extract read block length.
if_nc_and_z             and     cardReadBlockLength,  #$F                          '
                                                                             
if_nc_and_z             sub     cardReadBlockLength,  #9                           ' Compute card sector count for version 1.0 CSD.
if_nc_and_z             add     cardSizeMultiplier,   #2                           '     
if_z                    add     cardSize,             #1                           '
if_nc_and_z             shl     cardSize,             cardReadBlockLength          '                        
if_nc_and_z             shl     cardSize,             cardSizeMultiplier           '
                                                      
if_c_and_z              shl     cardSize,             #10                          ' Compute card sector count for version 2.0 CSD. 

                        max     cardSize,             maxPositiveInteger           ' Limit maximum partition size.

if_nz                   neg     cardSize,             #1                           ' Unknown CSD structure. Card size to -1.   

                        wrlong  cardSize,             par                          ' Update Card Size.

                        mov     cardSizeMinusOne,     cardSize                     ' Compute maximum allowed addressable sector.
                        sub     cardSizeMinusOne,     #1                           '

                        neg     cardMounted,          #1                           ' Return.
                        jmp     #instructionLoop                                   '

' ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////// 
'                       Read Block
' /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
                        
readBlock               rdlong  SPIParameterOut,      CSAAddress                   ' Read a block.  
                        max     SPIParameterOut,      cardSizeMinusOne             '
                        shl     SPIParameterOut,      SPIShift                     '
                        mov     SPICommandOut,        #($40 | 17)                  '
                        call    #commandSPI                                        '

                        tjnz    SPIResponceIn,        #instructionRetry            ' If failure abort.
                        call    #repsonceSPI                                       '     
                        cmp     SPIResponceIn,        #$FE wz                      '
if_nz                   jmp     #instructionRetry                                  '
                                                      
                        mov     counter,              fiveHundredAndTwelve         ' Setup loop.
readBlockModify         rdlong  buffer,               CDBAddress                   '
                                                      
readBlockLoop           call    #readSPI                                           ' Read data into memory.
                        wrbyte  SPIDataIn,            buffer                       '
                        add     buffer,               #1                           ' 
                        djnz    counter,              #readBlockLoop               '

                        call    #wordSPI                                           ' Shutdown SPI clock.
                        call    #shutdownSPI                                       ' 

readBlock_ret           jmp     #instructionLoop                                   ' Return. Become RET instruction when rebooting.
                        
' ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////// 
'                       Write Block
' /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

writeBlock              rdlong  SPIParameterOut,      CSAAddress                   ' Write a block.
                        max     SPIParameterOut,      cardSizeMinusOne             '
                        shl     SPIParameterOut,      SPIShift                     '
                        mov     SPICommandOut,        #($40 | 24)                  '
                        call    #commandSPI                                        '

                        tjnz    SPIResponceIn,        #instructionRetry            ' If failure abort.

                        mov     SPIDataOut,           #$FE                         ' Send start of data token.
                        call    #writeSPI                                          '

                        mov     counter,              fiveHundredAndTwelve         ' Setup loop.
                        rdlong  buffer,               CDBAddress                   '

writeBlockLoop          rdbyte  SPIDataOut,           buffer                       ' Write data out from memory.
                        add     buffer,               #1                           '
                        call    #writeSPI                                          '
                        djnz    counter,              #writeBlockLoop              '          

                        call    #wordSPI                                           ' Write out the 16 bit CRC.

                        call    #repsonceSPI                                       ' If failure abort.
                        and     SPIDataIn,            #$1F                         '
                        cmp     SPIDataIn,            #$5 wz                       '
if_nz                   jmp     #instructionRetry                                  '
                                                                                    
                        call    #cardBusy                                          ' Shutdown SPI clock.
                        call    #shutdownSPI                                       ' 

                        jmp     #instructionLoop                                   ' Return.
                        
' ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////// 
'                       Reboot Chip
' /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
                        
rebootChip              rdlong  buffer,               CDBAddress                   ' Check to make sure a reboot was requested.
                        tjnz    buffer,               #instructionError            '
                        
' //////////////////////Shutdown Cogs////////////////////////////////////////////////////////////////////////////////////////// 
                        
                        mov     counter,              #8                           ' Setup cog stop loop.
                        cogid   buffer                                             '
                        
rebootCogLoop           sub     counter,              #1                           ' Stop all cogs but this one.
                        cmp     counter,              buffer wz                    '
if_nz                   cogstop counter                                            '
                        tjnz    counter,              #rebootCogLoop               '
                        
' //////////////////////Setup Memory///////////////////////////////////////////////////////////////////////////////////////////
                        
                        mov     counter,              #64                          ' Setup to grab all sector addresses.
                        rdlong  buffer,               CSAAddress                   '

rebootSectorLoadLoop    rdlong  cardRebootSectors,    buffer                       ' Get all addresses of the 64 sectors of new code into memory. 
                        add     buffer,               #4                           '
                        add     rebootSectorLoadLoop, fiveHundredAndTwelve         '
                        djnz    counter,              #rebootSectorLoadLoop        '
                        
' //////////////////////Clear Memory///////////////////////////////////////////////////////////////////////////////////////////

                        mov     counter,              fiveHundredAndTwelve         ' Clear all memory. Leave buffer the pointer at 0.
                        shl     counter,              #6                           '
                        mov     buffer,               #0                           '   
rebootCodeClearLoop     sub     counter,              #4                           '
                        wrlong  buffer,               counter                      '
                        tjnz    counter,              #rebootCodeClearLoop         ' 
                                     
' //////////////////////Fill Memory////////////////////////////////////////////////////////////////////////////////////////////

                        mov     readBlock,            #0                           ' Fill these two commands with NOPs.
                        mov     readBlockModify,      #0                           '
                                                                               
                        mov     cardCounter,          #64                          ' Ready to fill all memory. Pointer already at 0.
                        
rebootCodeFillLoop      mov     SPIParameterOut,      cardRebootSectors            ' Reuse read block code. Finish if next sector is 0.
                        tjz     SPIParameterOut,      #rebootReady                 '
                        add     rebootCodeFillLoop,   #1                           '
                        call    #readBlock                                         '
                        djnz    cardCounter,          #rebootCodeFillLoop          '

' //////////////////////Boot Interpreter///////////////////////////////////////////////////////////////////////////////////////
                        
rebootReady             rdword  buffer,               #$A                          ' Setup the stack markers.
                        sub     buffer,               #4                           '
                        wrlong  rebootStackMark,      buffer                       '
                        sub     buffer,               #4                           '
                        wrlong  rebootStackMark,      buffer                       '

                        rdbyte  buffer,               #$4                          ' Switch to new clock mode.
                        clkset  buffer                                             '

                        coginit rebootInterpreter                                  ' Restart running new code.

                        cogid   buffer                                             ' Shutdown.
                        cogstop buffer                                             '

' ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////// 
'                       Card Status
' /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

cardStatus              mov     SPICommandOut,        #($40 | 13)                  ' Send out command 13.
                        mov     SPIParameterOut,      #0                           '
                        call    #commandSPI                                        '
                        call    #byteSPI                                           '
                        call    #shutdownSPI                                       '

                        tjnz    SPIResponceIn,        #instructionUnmount          ' If failure abort.
                        tjnz    SPILongIn,            #instructionUnmount          '

cardStatus_ret          ret                                                        ' Return.

' ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////// 
'                       Card Busy
' /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

cardBusy                mov     counter,              writeTimeout                 ' Setup loop.

cardBusyLoop            call    #readSPI                                           ' Wait until card is not busy.
                        cmp     SPIDataIn,            #0 wz                        '
if_z                    djnz    counter,              #cardBusyLoop                '
                        tjz     counter,              #instructionRetry            '

cardBusy_ret            ret                                                        ' Return.

' ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////// 
'                       Command SPI
' /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

commandSPI              andn    outa,                 chipSelectPin                ' Activate the SPI bus.  
                        call    #readSPI                                           '
                                                   
                        mov     SPIDataOut,           SPICommandOut                ' Send out command.
                        call    #writeSPI                                          '
                                                   
                        movs    writeSPI,             #32                          ' Send out parameter.
                        mov     SPIDataOut,           SPIParameterOut              '
                        call    #writeSPI                                          '
                        movs    writeSPI,             #8                           '
                                                   
commandSPICRC           mov     SPIDataOut,           #0                           ' Send out CRC token.
                        call    #writeSPI                                          '

                        call    #repsonceSPI                                       ' Read in responce.
                                                                               
commandSPI_ret          ret                                                        ' Return.

' ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////// 
'                       Responce SPI
' /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

repsonceSPI             mov     SPIResponceIn,        readTimeout                  ' Setup responce poll counter.
                        
repsonceSPILoop         call    #readSPI                                           ' Poll for responce.
                        cmp     SPIDataIn,            #$FF wz                      '
if_z                    djnz    SPIResponceIn,        #repsonceSPILoop             '
                                                    
                        mov     SPIResponceIn,        SPIDataIn                    ' Move responce into return value.
                                                                         
repsonceSPI_ret         ret                                                        ' Return.

' ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////// 
'                       Long SPI
' /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

longSPI                 add     readSPI,              #16                          ' Read in 32, 16, or 8 bits.
wordSPI                 add     readSPI,              #8                           ' 
byteSPI                 call    #readSPI                                           '
                        movs    readSPI,              #8                           '
                        
                        mov     SPILongIn,            SPIDataIn                    ' Move long into return value.
                        
byteSPI_ret                                                                        ' Return.
wordSPI_ret                                                                        '
longSPI_ret             ret                                                        ' 

' ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////// 
'                       Shutdown SPI
' /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

shutdownSPI             call    #readSPI                                           ' Shutdown SPI bus.
                        or      outa,                 chipSelectPin                '
                        call    #readSPI                                           '
                                                                          
shutdownSPI_ret         ret                                                        ' Return.

' ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////// 
'                       Read SPI
' /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
                                                 
readSPI                 mov     SPICounter,           #8                           ' Setup counter to read in 1 - 32 bits. Default 8.
                        mov     SPIDataIn,            #0 wc                        '

                        mov     phsa,                 #0                           ' Start clock low.
                        mov     frqa,                 SPITiming                    '

readSPILoop             waitpne clockPin,             clockPin                     ' Get bit.
                        rcl     SPIDataIn,            #1                           '
                        waitpeq clockPin,             clockPin                     '
                        test    dataOutPin,           ina wc                       '
                        
                        djnz    SPICounter,           #readSPILoop                 ' Loop

                        mov     frqa,                 #0                           ' Stop clock high.
                        rcl     SPIDataIn,            #1                           ' 
                                                     
readSPI_ret             ret                                                        ' Return.

' ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////// 
'                       Write SPI
' /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

writeSPI                mov     SPICounter,           #8                           ' Setup counter to write out 1 - 32 bits. Default 8.
                        ror     SPIDataOut,           SPICounter                   '

                        mov     phsa,                 #0                           ' Start clock low.
                        mov     frqa,                 SPITiming                    '

writeSPILoop            shl     SPIDataOut,           #1 wc                        ' Set bit.
                        waitpne clockPin,             clockPin                     ' 
                        muxc    outa,                 dataInPin                    '
                        waitpeq clockPin,             clockPin                     '

                        djnz    SPICounter,           #writeSPILoop                ' Loop.     

                        mov     frqa,                 #0                           ' Stop clock high.
                        or      outa,                 dataInPin                    ' 

writeSPI_ret            ret                                                        ' Return.

' ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////// 
'                       CRC7 Augmentation
' /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
                        
CRC7                    mov     CRCCounter,           #7                           ' Get variables ready.
                                
CRC7Loop                shl     CRCBuffer,            #1                           ' Do the CRC7 calculation.  
                        test    CRCBuffer,            #$80 wc                      '
if_c                    xor     CRCBuffer,            #$9                          '
                        djnz    CRCCounter,           #CRC7Loop                    '

CRC7_ret                ret                                                        ' Return.
                        
' ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////// 
'                       CRC16 Augmentation
' /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
                        
CRC16                   mov     CRCCounter,           #16                          ' Get variables ready.
                                                                          
CRC16Loop               shl     CRCBuffer,            #1                           ' Do the CRC16 calculation.
                        test    CRCBuffer,            CRC16TestBit wc              '
if_c                    xor     CRCBuffer,            CRC16Polynomial              '
                        djnz    CRCCounter,           #CRC16Loop                   '
                                                     
CRC16_ret               ret                                                        ' Return. 
                        
' ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////// 
'                       Data
' /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////                        

cardMounted             long    0

' //////////////////////Constants//////////////////////////////////////////////////////////////////////////////////////////////

fiveHundredAndTwelve    long    $200                                               ' Constant 512.
maxPositiveInteger      long    $7FFFFFFF                                          ' Constant 2,147,483,647.
                                                                          
CRC16TestBit            long    $10000                                             ' The CRC16 test bit mask.
CRC16Polynomial         long    $1021                                              ' The CRC16 polynomial bit mask.
                                                                              
OCRCheckMask            long    %00_000000_00110000_00000000_00000000              ' Parameter check mask for OCR bits.
HCSBitMask              long    %01_000000_00000000_00000000_00000000              ' Parameter bit mask for HCS bit.
                                                                              
rebootInterpreter       long    ($0001 << 18) | ($3C01 << 4)                       ' Spin interpreter boot information. 
rebootStackMark         long    $FFF9FFFF                                          ' Stack mark used for spin code.
                          
' //////////////////////Configuration Settings/////////////////////////////////////////////////////////////////////////////////

slowTiming              long    0                                                  ' 250KHz Clock speed.
fastTiming              long    0                                                  ' 2.5MHz Clock speed.
                                                                          
readTimeout             long    250_000                                            ' Read timeout of 100 milliseconds at 2.5Mhz clock.
writeTimeout            long    625_000                                            ' Write timeout of 250 milliseconds at 2.5Mhz clock.
                                                                             
' //////////////////////Pin Masks//////////////////////////////////////////////////////////////////////////////////////////////

dataOutPin              long    (|<((Data_Out_Pin <# 31) #> 0))
clockPin                long    (|<((Clock_Pin <# 31) #> 0))
dataInPin               long    (|<((Data_In_Pin <# 31) #> 0))
chipSelectPin           long    (|<((Chip_Select_Pin <# 31) #> 0))
dataOutOff              long    0

' //////////////////////Addresses//////////////////////////////////////////////////////////////////////////////////////////////

CCFAddress              long    0
CEFAddress              long    0

CUIDAddress             long    0

CDBAddress              long    0
CSAAddress              long    0


DAT 'Variable Array

' //////////////////////Variable Array/////////////////////////////////////////////////////////////////////////////////////////

cardCommandFlag         byte 0
cardErrorFlag           byte 0

cardLockID              byte 0 'frida ((HUB_Lock <# 7) #> 0)
cardUniqueID            byte 0[17]

cardDataBlockAddress    long 0
cardSectorAddress       long 0
cardSectorCount         long 0

DAT 'String Array

' //////////////////////String Array///////////////////////////////////////////////////////////////////////////////////////////

dot                     byte ".          ", 0
dotdot                  byte "..         ", 0

{                                                                               '@hive
FSUnmounted             byte "File System Unmounted", 0
FSCorrupted             byte "File System Corrupted", 0 
FSUnsupported           byte "File System Unsupported", 0

fileOrDirectoryNotFound byte "File Or Directory Not Found", 0
fileNotFound            byte "File Not Found", 0
directoryNotFound       byte "Directory Not Found", 0
}

' //////////////////////Run Time Variables/////////////////////////////////////////////////////////////////////////////////////

buffer                  res     1
counter                 res     1

' //////////////////////Card Variables/////////////////////////////////////////////////////////////////////////////////////////

cardBuffer              res     1
cardCounter             res     1

cardType                res     1
cardSize                res     1

cardSizeMultiplier      res     1
cardSizeMinusOne        res     1

cardReadBlockLength     res     1
cardWriteBlockLength    res     1

CSDRegister             res     16
CIDRegister             res     16

cardRebootSectors       res     64

' //////////////////////SPI Variables//////////////////////////////////////////////////////////////////////////////////////////

SPICommandOut           res     1
SPIParameterOut         res     1
SPIResponceIn           res     1
SPILongIn               res     1

SPIShift                res     1
SPITiming               res     1

SPIDataIn               res     1
SPIDataOut              res     1

SPIBuffer               res     1
SPICounter              res     1

' //////////////////////CRC Variables//////////////////////////////////////////////////////////////////////////////////////////

CRCBuffer               res     1
CRCCounter              res     1

' /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

                        fit     496

' /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
                 
{{

┌─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
│                                                   TERMS OF USE: MIT License                                                 │                                                            
├─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
│Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation   │ 
│files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy,   │
│modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the        │
│Software is furnished to do so, subject to the following conditions:                                                         │         
│                                                                                                                             │
│The above copyright notice and this permission notice shall be included in all copies or substantial portions of the         │
│Software.                                                                                                                    │
│                                                                                                                             │
│THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE         │
│WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR        │
│COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,  │
│ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.                        │
└─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┘
}}
