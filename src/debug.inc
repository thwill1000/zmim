' Copyright (c) 2019-20 Thomas Hugo Williams
' For Colour Maximite 2, MMBasic 5.05

' Prints 'sz' bytes from 'mem' starting at 'ad'
Sub dmp_mem(ad, sz)
'  If Not debug Then Exit Sub

  Local i, x
  For i = 0 To sz - 1
    x = rb(ad + i)
    Print lpad$(Hex$(x), 2, "0"); " ";
    If (i + 1) Mod 16 = 0 Then Print
  Next i
  Print
End Sub

Sub dmp_obj(o)
  If Not debug Then Exit Sub

  Local ad, i, p, sz, x

  If o = 0 Then
    Print "Property defaults:"
    ad = rw(&h0A)
    For i = 0 To 30
      x = rw(ad)
      Print lpad$(Hex$(x), 4, "0"); " ";
      If (i + 1) Mod 10 = 0 Then Print
      ad = ad + 2
    Next i
    Print
    Exit Sub
  EndIf

  Print Str$(o); ". ";
  Print "Attributes: ";
  For i = 0 To 31
    x = oattr(o, i)
    If x <> 0 Then Print i;
  Next i
  Print

  x = orel(o, PARENT)
  Print "   Parent object:"; x; "  ";
  x = orel(o, SIBLING)
  Print "Sibling object:"; x; "  ";
  x = orel(o, CHILD)
  Print "Child object:"; x

  ad = get_prop_base(o)
  Print "   Property address: "; lpad$(Hex$(ad), 4, "0")
  Print "        Description: '";
  print_obj(o);
  Print "'"
  Print "         Properties:"
  p = 0
  Do
    p = get_next_prop(o, p)
    If p > 0 Then
      ad = get_prop_addr(o, p)
      sz = get_prop_len(o, p)
      x = rb(ad)
      If x\32 + 1 <> sz Then Error
      Print "             ["; Str$(p); "] ";
      For i = 1 To sz
        ad = ad + 1
        x = rb(ad)
        Print lpad$(Hex$(x), 2, "0"); " ";
      Next i
      Print
    EndIf
  Loop Until p = 0
End Sub

Function fmt_operand$(i)
  Local a$, x
  x = ov(i)
  If ot(i) <> VARIABLE Then
    fmt_operand$ = "#" + lpad$(Hex$(x), 2, "0")
    Exit Function
  EndIf
  If x = 0 Then
    a$ = "(SP)+"
  ElseIf x < &h10 Then
    a$ = "L" + lpad$(Hex$(x - 1), 2, "0")
  Else
    a$ = "G" + lpad$(Hex$(x - &h10), 2, "0")
  EndIf
  If x > 0 Then a$ = a$ + " (=" + Hex$(vget(x)) + ")"
  fmt_operand$ = a$
End Function

Function fmt_call_operands$()
  Local a$, i
  If ot(0) = VARIABLE Then
    a$ = fmt_operand$(i)
  Else
    a$ = Hex$(2 * ov(0))
  EndIf
  a$ = a$ + " ("
  For i = 1 To onum - 1
    If i > 1 Then a$ = a$ + ", "
    a$ = a$ + fmt_operand$(i)
  Next i
  a$ = a$ + ")"
  fmt_call_operands$ = a$
End Function

Function fmt_jump_operands$()
  Local of
  If onum > 1 Then Error "Too many operands."
  of = oa(0)
  If of And 2^15 Then of = of - 65536
  fmt_jump_operands$ = Hex$(pc + of - 2)
End Function

Function fmt_store_value$(st)
  If st = 0 Then
    Print "-(SP)";
  ElseIf st < &h10 Then
    Print "L" + lpad$(Hex$(st - 1), 2, "0");
  Else
    Print "G" + lpad$(Hex$(st - &h10), 2, "0");
  EndIf
End Function

Function fmt_store_operands$()
  Local a$, i
  If ot(0) = VARIABLE Then Error "Unexpected VARIABLE operand"
  a$ = a$ + fmt_store_value$(ov(0))
  For i = 1 To onum - 1
    a$ = a$ + ", " + fmt_operand$(i)
  Next i
  fmt_store_operands$ = a$
End Function

Function fmt_normal_operands$()
  Local a$, i
  For i = 0 To onum - 1
    If i > 0 Then a$ = a$ + ", "
    a$ = a$ + fmt_operand$(i)
  Next i
  fmt_normal_operands$ = a$
End Function

Sub dmp_op(m$, st, br)
  If Not debug Then Exit Sub

  Print rpad$(m$, 14);
  If m$ = "CALL" Then
    Print fmt_call_operands$();
  ElseIf m$ = "JUMP" Then
    Print fmt_jump_operands$();
  ElseIf m$ = "STORE" Or m$ = "DEC_CHK" Or m$ = "INC_CHK" Then
    Print fmt_store_operands$();
  ElseIf m$ = "DEC" Or m$ = "INC" Then
    Print fmt_store_operands$();
  Else
    Print fmt_normal_operands$();
  EndIf

  If st > -1 Then Print " -> "; fmt_store_value$(st);

  If br = 0 Then Print : Exit Sub
  If br And &h10000 Then Print " [TRUE] "; Else Print " [FALSE] ";
  If (br And &hFFFF) = pc - 2 Then Print "RFALSE" : Exit Sub
  If (br And &hFFFF) = pc - 1 Then Print "RTRUE" : Exit Sub
  Print Hex$(br And &hFFFF)
End Sub

Sub dmp_routine(new_pc)
  If Not debug Then Exit Sub

  Local i, locals_sz, x
  locals_sz = rb(new_pc)
  Print "Routine "; Hex$(new_pc); ", "; Str$(locals_sz); " locals (";
  For i = 0 To locals_sz - 1
    If i > 0 Then Print ", ";
    x = rw(new_pc + 1 + i * 2)
    Print lpad$(Hex$(x), 4, "0");
  Next i
  Print ")"
End Sub

' Expects global variables:
'  fp    - current frame index/pointer
'  sp    - current stack index/pointer
'  stack - the stack (an array of 32-bit floats)
Sub dmp_stack(s)
  If Not debug Then Exit Sub

  Local i
  Print "TOP: ";
  For i = sp To 0 Step -1
    If i = fp Then
      Print " --> ";
    ElseIf i < sp Then
      Print "     ";
    EndIf
    Print lpad$(Hex$(stack(i)), 4, "0");
    If i = fp Then
      Print " previous fp";
    ElseIf i = fp + 1 Then
      Print " store result";
    ElseIf i = fp + 2 Then
      Print " return address";
    ElseIf i = fp + 3 Then
      Print " num locals";
    ElseIf stack(i) And &h8000 Then
      Print " "; stack(i) - &h10000;
    Else
      Print stack(i);
    EndIf
    Print
    If (s = 0) And (i = fp) Then i = 0
  Next i
End Sub