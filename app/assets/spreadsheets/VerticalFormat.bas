Attribute VB_Name = "VerticalFormat"
Sub VerticalFormat()
'
' Sometimes when opening in Excel, the commas will separate the values vs semi-colons.
' This macro will convert the file into proper vertical format by concatenating on commas and delimiting on semi-colons.
'

'
CombineColumns
RemoveCarriageReturns
DeleteTextRows
Delimit

End Sub



Function CombineColumns()
'
' CombineColumns Macro
'

'
Dim LastRow As Long

LastRow = Cells(Rows.Count, "A").End(xlUp).Row

' Find all rows split by comma during csv opening and concatenate back into sigle string
    Range("E1:E" & LastRow).Formula = "=CONCATENATE(RC[-4],IF(RC[-3]="""","""","",""),RC[-3],IF(RC[-2]="""","""","",""),RC[-2],IF(RC[-1]="""","""","",""),RC[-1])"

' Paste Special: Values - over Column A
    Range("E1:E" & LastRow).Copy
    Range("A1").PasteSpecial Paste:=xlValues, Operation:=xlNone, SkipBlanks:= _
        False, Transpose:=False

' Delete excess columns
    Columns("B:E").EntireColumn.Delete

End Function

Function RemoveCarriageReturns()
'
' RemoveCarriageReturns Macro
'

'
Dim LastRow As Long
    
LastRow = Cells(Rows.Count, "A").End(xlUp).Row
    
' Find all rows that do not begin with ';' or 1-9 and concatenate to row above, essentially removing all carriage returns
    Range("B1:B" & LastRow).Formula = _
        "=IF(OR(LEFT(R[1]C[-1])="";"",LEFT(R[1]C[-1])={""1"",""2"",""3"",""4"",""5"",""6"",""7"",""8"",""9""}),RC[-1],CONCATENATE(RC[-1],"" "",R[1]C))"
    
' Paste Special: Values
    Range("B1:B" & LastRow).Copy
    Range("C1").PasteSpecial Paste:=xlValues, Operation:=xlNone, SkipBlanks:= _
        False, Transpose:=False

' Delete excess Columns
    Columns("A:B").Delete Shift:=xlToLeft

End Function

Function DeleteTextRows()
'
' DeleteTextRows Macro
'

'
Dim LastRow As Long
Dim curSheet As Worksheet
Dim myColm As Range

Set curSheet = ThisWorkbook.Sheets(ActiveSheet.Name)
    
LastRow = Cells(Rows.Count, "A").End(xlUp).Row
    
' Find all rows that begin with 'Case', ';' or 1-9 and set to 1, otherwise set to 0
    Range("B1:B" & LastRow).Formula = _
        "=IF(OR(LEFT(RC[-1],4)=""Case"",LEFT(RC[-1])="";"",LEFT(RC[-1])={""1"",""2"",""3"",""4"",""5"",""6"",""7"",""8"",""9""}),1,0)"

' Clear contents of all cells set to 0, clearing contents of all rows that beging with text. These rows are the left overs from carriage returns.
    For Each cell In myColm
        If (cell.Value = 0) Then cell.ClearContents
    Next

' Delete all rows that have empty cell in column B which equate to all cells that begin with text.
    On Error Resume Next
    myColm.SpecialCells(xlCellTypeBlanks).EntireRow.Delete
    
' Delete excess Columns
    Columns("B").EntireColumn.Delete
    
End Function

Function Delimit()
'
' Delimit Macro
'

'

' Delimit Column A on ';'
    Columns("A:A").TextToColumns Destination:=Range("A1"), DataType:=xlDelimited, _
        TextQualifier:=xlDoubleQuote, ConsecutiveDelimiter:=False, Tab:=False, _
        Semicolon:=True, Comma:=False, Space:=False, Other:=False, FieldInfo _
        :=Array(Array(1, 1), Array(2, 1), Array(3, 1), Array(4, 1), Array(5, 1), Array(6, 1), _
        Array(7, 1), Array(8, 1), Array(9, 1), Array(10, 1), Array(11, 1))
        
End Function



