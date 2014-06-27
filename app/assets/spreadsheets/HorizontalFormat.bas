Attribute VB_Name = "HorizontalFormat"

'
' THIS REQUIRES SPREADSHEET TO BE IN PROPER VERTICAL FORMAT
'

Sub ChangeLayout()
'
' This macro will convert the vertical format into a horizontal format.
' This is accomplished by moving Step Actions and Results into 2 columns at the end of the Case row.
'
    HeaderAdd
    MoveSteps
    FormatCells
    
End Sub

Function HeaderAdd()
'
' HeaderAdd Macro
'

' Add new header rows
    Range("L1").Value = "Action"
    Range("M1").Value = "Result"
    
End Function

Function ConvertToLetter(iCol As Integer) As String
'
' Change the number of a column into the associated letter
'

   Dim iAlpha As Integer
   Dim iRemainder As Integer
   iAlpha = Int(iCol / 27)
   iRemainder = iCol - (iAlpha * 26)
   If iAlpha > 0 Then
      ConvertToLetter = Chr(iAlpha + 64)
   End If
   If iRemainder > 0 Then
      ConvertToLetter = ConvertToLetter & Chr(iRemainder + 64)
   End If
End Function

Function MoveSteps()
'
' MoveSteps Macro
'

    Dim sRow As Integer
    Dim cRow As Integer
    Dim curSheet As Worksheet
    Dim oSheet As Worksheet
    Dim cRange As Range
    Dim uRow As Range
    Dim uCell As Range
    Dim tmp As Variant
    Dim colSet As Integer
    Dim myCol As Integer
    Dim myColm As Range
    

    Set curSheet = ThisWorkbook.Sheets(ActiveSheet.Name)
    Set cRange = curSheet.Range("A1")
    Set uCell = curSheet.Range("A1")
    Set uRow = uCell
    sRow = 1
    
    Do While curSheet.Range("C" & sRow).Value <> ""
       sRow = sRow + 1
    Loop
       
    Do While sRow > 1
       ' Drop header rows
       If InStr(LCase(curSheet.Range("B" & sRow).Value), "step id") > 0 Then
             curSheet.Cells(sRow, "A").EntireRow.Delete
       End If
       
       ' Move steps
       If IsNumeric(curSheet.Range("A" & sRow).Value) And curSheet.Range("A" & sRow).Value <> "" Then
            cRow = sRow + 1
            Do While IsNumeric(curSheet.Range("B" & cRow).Value) And curSheet.Range("B" & cRow).Value <> ""
                cRow = cRow + 1
            Loop
            
            For myCol = 3 To 4
                cCol = ConvertToLetter(myCol)
                nCol = ConvertToLetter((myCol + 9))
                Set cRange = curSheet.Range(cCol & (sRow + 1) & ":" & cCol & (cRow - 1))
                cRange.Select
                If cRange.Count > 0 Then
                    For Each uRow In Selection
                        For Each uCell In uRow.Cells
                            tmp = tmp & uCell.Value & vbNewLine & vbNewLine
                            curSheet.Range(nCol & sRow).Value = tmp
                        Next uCell
                    Next uRow
                End If
' Reset tmp to blank
                tmp = ""
' Advance to Column 4
            Next myCol
            
       End If
       
       sRow = sRow - 1
    Loop
    
    Set myColm = curSheet.Range("A:A")
    myColm.SpecialCells(xlCellTypeBlanks).EntireRow.Delete
        
End Function

Function FormatCells()
    Dim curSheet As Worksheet
    
    Set curSheet = ThisWorkbook.Sheets(ActiveSheet.Name)
    
    curSheet.Range("A1:A" & Rows.Count).RowHeight = 50
    curSheet.Columns("A:M").ColumnWidth = 50
    
    curSheet.Columns("A:M").AutoFit
    curSheet.Range("A1:A" & Rows.Count).Rows.AutoFit

End Function

