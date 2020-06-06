Option Explicit On

#Include "memory_fast.inc"
#Include "dict.inc"
#Include "zstring.inc"
#Include "util.inc"

Dim a, s$, x

Cls

mem_init("A:/zmim/stories/minizork.z3")
di_init()

Open "A:/zmim/src/tests/minizork.dic" For Input As #1
Timer = 0
Do While Not Eof(#1)
  Line Input #1, s$
  a = Val(Left$(s$, 6))
  s$ = Mid$(s$, 8)
  x = di_lookup(s$)
  If x = a Then
    Print rpad$(s$, 8); "=>"; x; " - OK"
  Else
    Print rpad$(s$, 8); "=>"; x; " - ERROR"
  EndIf
Loop
Print "Dictionary test took"; Timer; " ms"