' Copyright (c) 2019-20 Thomas Hugo Williams
' For Colour Maximite 2, MMBasic 5.05

Option Explicit On
Option Default Integer

'#Include "../mem_cmm2_fast.inc"
#Include "../mem_cmm2_safe.inc"
#Include "../objects.inc"
#Include "../debug.inc"
#Include "../util.inc"
#Include "../zstring.inc"
#Include "../console.inc"

Dim ad, i, o, x, _

Cls

mem_init("/zmim/stories/minizork.z3")

endl()
cout("Executing object tests") : endl()

' Get attributes and properties from object 1
o = 1

If ob_rel(o, PARENT) <> 36 Then Error
If ob_rel(o, SIBLING) <> 147 Then Error
If ob_rel(o, CHILD) <> 0 Then Error

For i = 0 To 31
  x = ob_attr(o, i)
  If i = 6 And x <> 1 Then Error
  If i <> 6 And x <> 0 Then Error
Next i

For i = 1 To 31
  If i = 17 Then
    ad = ob_prop_addr(o, i)
    If rb(ad) <> &h2D Then Error
    If rb(ad + 1) <> &h23 Then Error
    If rb(ad + 2) <> &h35 Then Error
    If rb(ad + 3) <> &h8F Then Error
  Else
    x = ob_prop_get(o, i)
    If i = 13 And x <> &h05 Then Error
    If i = 18 And x <> &h43A7 Then Error Hex$(x)
    If i <> 13 And i <> 18 And x <> &h00 Then Error
  EndIf
Next i

' Get attributes and properties from object 2
o = 2

If ob_rel(o, PARENT) <> 27 Then Error
If ob_rel(o, SIBLING) <> 119 Then Error
If ob_rel(o, CHILD) <> 95 Then Error

For i = 0 TO 31
  x = ob_attr(o, i)
  If (i = 5 Or i = 7 Or i = 19) And x <> 1 Then Error
  If i <> 5 And i <> 7 And i <> 19 And x <> 0 Then Error
Next i

For i = 1 To 31
  x = ob_prop_get(o, i)
  If i = 12 Then
    If x <> &h4C01 Then Error
  ElseIf i = 13 Then
    If x <> &h05 Then Error
  ElseIf i = 18 Then
    If x <> &h4409 Then Error
  ElseIf i = 22 Then
    If x <> &h77 Then Error
  ElseIf i = 23 Then
    If x <> &h64AE Then Error
  Else
    If x <> &h00 Then Error
  EndIf
Next i

' Set attributes on object 2
o = 2

_ = ob_attr(o, 0, 1, 1)
_ = ob_attr(o, 15, 1, 1)
_ = ob_attr(o, 27, 1, 1)
dmp_obj(o)
If ob_attr(o, 0) <> 1 Then Error
If ob_attr(o, 15) <> 1 Then Error
If ob_attr(o, 27) <> 1 Then Error
_ = ob_attr(o, 27, 1, 1)
If ob_attr(o, 27) <> 1 Then Error
_ = ob_attr(o, 0, 1, 0)
_ = ob_attr(o, 15, 1, 0)
_ = ob_attr(o, 27, 1, 0)
dmp_obj(o)
If ob_attr(o, 0) <> 0 Then Error
If ob_attr(o, 15) <> 0 Then Error
If ob_attr(o, 27) <> 0 Then Error
_ = ob_attr(o, 27, 1, 0)
If ob_attr(o, 27) <> 0 Then Error

cout("PASSED") : endl()
