' Copyright (c) 2019-20 Thomas Hugo Williams
' For Colour Maximite 2, MMBasic 5.05

Dim ALPHABET$(2) LENGTH 32
ALPHABET$(0) = " 123[]abcdefghijklmnopqrstuvwxyz"
ALPHABET$(1) = " 123[]ABCDEFGHIJKLMNOPQRSTUVWXYZ"
ALPHABET$(2) = " 123[]@^0123456789.,!?_#'" + Chr$(34) + "/\-:()"

' Prints Z-string starting at 'a' incrementing 'a' by the number of bytes read
Sub print_zstring(a)
  Local b, c, i, s, x, zc(2)

'  If Not debug Then Print Chr$(8);

  ' The state of Z-string processing is recorded in 's':
  '   0, 1, 2 - Expecting a character from alphabet 's'
  '   3, 4, 5 - Expecting an abbreviation from table 's - 3'
  '   6       - Expecting the top 5-bits of a ZSCII character
  '   > 6     - Expecting the btm 5-bits of a ZSCII character whose
  '             top 5-bits are 's - 7'

  ' Should be 'Do While x = 0' but there is an MMBasic bug using that
  ' in recursive functions.
  For x = 0 To 0 Step 0
    x = rb(a) * 256 + rb(a + 1)

    For i = 2 To 0 Step -1
      zc(i) = x And 31 ' &b00011111
      x = x \ 32 ' rshift 5
    Next i

    ' x is now the top-bit of the word. If x = 1 then we have reached the end
    ' of the string and will exit the loop after this iteration.

    For i = 0 To 2
      c = zc(i)
      If s < 3 Then
        If c = 0 Then
          Print " ";
        ElseIf c < 4 Then
          s = c + 2
        ElseIf c < 6 Then
          s = c - 3
        Else
          If c = 6 And s = 2 Then
            s = 6
          ElseIf c = 7 And s = 2 Then
            Print
            s = 0
          Else
            Print Mid$(ALPHABET$(s), c + 1, 1);
            s = 0
          EndIf
        EndIf
      ElseIf s < 6 Then
        b = a ' Backup the address
        print_abrv((s - 3) * 32 + c)
        a = b ' Restore the address
        s = 0
      ElseIf s = 6 Then
        s = c + 7
      Else
        Print Chr$((s - 7) * 32 + c);
        s = 0
      EndIf
    Next i

    a = a + 2
  Next x

'  If Not debug Then Print " ";

End Sub

' Prints abbreviation 'x'
Sub print_abrv(x)
  Local a, b
  a = rw(&h18)
  b = rw(a + x * 2)
'  If Not debug Then Print " ";
  print_zstring(b * 2)
'  If Not debug Then Print Chr$(8);
End Sub