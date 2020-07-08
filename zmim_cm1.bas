' Autogenerated on 04-07-2020 15:13:59

If Mm.Device$<>"Colour Maximite"Then
 Option Explicit On
 Option Default Integer
EndIf
Mode 1
Dim FSZ
Dim BST
Dim FSP
Dim m(60*512\4)
Dim pf
Dim MF$
Dim mpv(60-1)
Dim mvp(256-1)
Dim mnx

Function rp()
 Local pp,vp
 vp=pc\512
 pp=mvp(vp)
 If pp=0 Then pp=mem_load(vp):pf=pf+1
 rp=Peek(Var m(0),pp*512+(pc Mod 512))
 pc=pc+1
End Function

Function rb(a)
 Local pp,vp
 If a<BST Then rb=Peek(Var m(0),a):Exit Function
 vp=a\512
 pp=mvp(vp)
 If pp=0 Then pp=mem_load(vp):pf=pf+1
 rb=Peek(Var m(0),pp*512+(a Mod 512))
End Function

Function rw(a)
 rw=rb(a)*256+rb(a+1)
End Function

Sub wb(a,x)
 Poke Var m(0),a,x
End Sub

Sub ww(a,x)
 Poke Var m(0),a,x\256
 Poke Var m(0),a+1,x Mod 256
End Sub

Function mem_load(vp)
 Local ad,buf$,buf_sz,i,pp,to_read
 pp=mnx
 mnx=mnx+1
 If mnx=60 Then mnx=FSP
 Open MF$ For random As #1
 Seek #1,vp*512+1
 ad=pp*512
 to_read=512
 buf_sz=255
 Do While to_read>0
  If to_read<255 Then buf_sz=to_read
  buf$=Input$(buf_sz,1)
  For i=1 To buf_sz
   Poke Var m(0),ad,Peek(Var buf$,i)
   ad=ad+1
  Next i
  to_read=to_read-buf_sz
 Loop
 Close #1
 mvp(mpv(pp))=0
 mvp(vp)=pp
 mpv(pp)=vp
 mem_load=pp
End Function

Sub mem_init(f$)
 Local i
 MF$=f$
 cou("Loading '"+MF$+"'"):cen()
 cou("  Header page: 0"):cen()
 If mem_load(0)<>0 Then Error
 BST=Peek(Var m(0),&h0E)*256+Peek(Var m(0),&h0F)
 FSZ=(Peek(Var m(0),&h1A)*256+Peek(Var m(0),&h1B))*2
 FSP=BST\512
 If BST Mod 512>0 Then FSP=FSP+1
 cou("  Dynamic pages: ")
 For i=1 To FSP-1
  If i>1 Then cou(", ")
  cou(Str$(i))
  If mem_load(i)<>i Then Error
 Next i
 cen()
 cou("  Paged memory starts at page "+Str$(FSP)):cen()
End Sub

Dim stk(511)
Dim sp

Function spo()
 sp=sp-1
 spo=stk(sp)
End Function

Sub spu(x)
 stk(sp)=x
 sp=sp+1
End Sub

Function spe(i)
 If i>=sp Then Error"Attempt to peek beyond stack pointer"
 spe=stk(i)
End Function

Sub spk(i,x)
 If i>=sp Then Error"Attempt to poke beyond stack pointer"
 If x<0 Or x>&hFFFF Then Error"Invalid unsigned 16-bit value"
 stk(i)=x
End Sub

Dim GVA

Function vge(i)
 If i=0 Then
  vge=spo()
 ElseIf i<&h10 Then
  vge=stk(fp+i+4)
 ElseIf i<=&hFF Then
  vge=rw(GVA+2*(i-&h10))
 Else
  Error"Unknown variable "+Str$(i)
 EndIf
End Function

Sub vse(i,x)
 If i=0 Then
  spu(x)
 ElseIf i<&h10 Then
  stk(fp+i+4)=x
 ElseIf i<=&hFF Then
  ww(GVA+2*(i-&h10),x)
 Else
  Error"Unknown variable "+Str$(i)
 EndIf
End Sub

Dim pc
Dim oc=0
Dim osz=0
Dim oa(4)
Dim ot(4)
Dim ov(4)
Dim st=0
Dim br=0

Sub de_init()
 Local i,s$,x
 Read x
 Dim O0$(x-1)LENGTH 12
 For i=0 To x-1:Read s$:O0$(i)=de_format$(s$):Next i
 Read x
 Dim O1$(x-1)LENGTH 14
 For i=0 To x-1:Read s$:O1$(i)=de_format$(s$):Next i
 Read x
 Dim O2$(x-1)LENGTH 15
 For i=0 To x-1:Read s$:O2$(i)=de_format$(s$):Next i
 Read x
 Dim O3$(x-1)LENGTH 14
 For i=0 To x-1:Read s$:O3$(i)=de_format$(s$):Next i
End Sub

Function dec(tr)
 Local op,s$
 If tr Then cou(Hex$(pc)+": ")
 op=rp()
 If op<&h80 Then
  dlo(op)
  s$=O2$(oc)
 ElseIf op<&hC0 Then
  dsh(op)
  If op<&hB0 Then s$=O1$(oc)Else s$=O0$(oc)
 Else
  dva(op)
  If op<&hE0 Then s$=O2$(oc)Else s$=O3$(oc)
 EndIf
 If Left$(s$,1)="B"Then
  st=-1
  br=dbr()
 ElseIf Left$(s$,1)="S"Then
  st=rp()
  br=0
 ElseIf Left$(s$,1)="X"Then
  st=rp()
  br=dbr()
 Else
  st=-1
  br=0
 EndIf
 If tr Then dmp_op(Mid$(s$,2))
 dec=op
End Function

Sub dlo(op)
 oc=op And &b11111
 osz=2
 ov(0)=rp()
 ov(1)=rp()
 If op<=&h1F Then
  ot(0)=&b01:oa(0)=ov(0)
  ot(1)=&b01:oa(1)=ov(1)
 ElseIf op<=&h3F Then
  ot(0)=&b01:oa(0)=ov(0)
  ot(1)=&b10:oa(1)=vge(ov(1))
 ElseIf op<=&h5F Then
  ot(0)=&b10:oa(0)=vge(ov(0))
  ot(1)=&b01:oa(1)=ov(1)
 Else
  ot(0)=&b10:oa(0)=vge(ov(0))
  ot(1)=&b10:oa(1)=vge(ov(1))
 EndIf
End Sub

Sub dsh(op)
 oc=op And &b1111
 osz=1
 If op<=&h8F Then
  ot(0)=&b00:ov(0)=rp()*256+rp():oa(0)=ov(0)
 ElseIf op<=&h9F Then
  ot(0)=&b01:ov(0)=rp():oa(0)=ov(0)
 ElseIf op<=&hAF Then
  ot(0)=&b10:ov(0)=rp():oa(0)=vge(ov(0))
 Else
  osz=0
 EndIf
End Sub

Sub dva(op)
 Local i,x
 oc=op And &b11111
 osz=4
 x=rp()
 For i=0 To 3
  ot(i)=(x And &b11000000)\64
  If ot(i)=&b00 Then
   ov(i)=rp()*256+rp():oa(i)=ov(i)
  ElseIf ot(i)=&b01 Then
   ov(i)=rp():oa(i)=ov(i)
  ElseIf ot(i)=&b10 Then
   ov(i)=rp():oa(i)=vge(ov(i))
  Else
   osz=osz-1
  EndIf
  x=x*4
 Next i
End Sub

Function dbr()
 Local a,of,x
 a=rp()
 of=a And &b111111
 If(a And &b1000000)=0 Then
  of=256*of+rp()
  If a And &b100000 Then of=of-16384
 EndIf
 x=pc+of-2
 If a And &h80 Then x=x Or &h80000
 dbr=x
End Function

Function de_format$(a$)
 Local p,s$
 If Instr(a$," SB")>0 Then
  s$="X"
 ElseIf Instr(a$," B")>0 Then
  s$="B"
 ElseIf Instr(a$," S")>0 Then
  s$="S"
 Else
  s$=" "
 EndIf
 p=Instr(a$," ")
 If p=0 Then p=Len(a$)+1
 s$=s$+Left$(a$,p-1)
 de_format$=s$
End Function

Data 14
Data"RTRUE","RFALSE","PRINT","PRINT_RET","NOP"
Data"SAVE B","RESTORE B","RESTART","RET_POPPED","POP"
Data"QUIT","NEW_LINE","SHOW_STATUS","VERIFY B"
Data 16
Data"JZ B","GET_SIBLING SB","GET_CHILD SB","GET_PARENT S","GET_PROP_LEN S"
Data"INC","DEC","PRINT_ADDR","Unknown&h8","REMOVE_OBJ"
Data"PRINT_OBJECT","RET","JUMP","PRINT_PADDR","LOAD S"
Data"NOT S"
Data 25
Data"Unknown&h0","JE B","JL B","JG B","DEC_CHK B"
Data"INC_CHK B","JIN B","TEST B","OR S","AND S"
Data"TEST_ATTR B","SET_ATTR","CLEAR_ATTR","STORE","INSERT_OBJ"
Data"LOADW S","LOADB S","GET_PROP S","GET_PROP_ADDR S","GEN_NEXT_PROP S"
Data"ADD S","SUB S","MUL S","DIV S","MOD S"
Data 22
Data"CALL S","STOREW","STOREB","PUT_PROP","READ"
Data"PRINT_CHAR","PRINT_NUM","RANDOM S","PUSH","PULL"
Data"SPLIT_WINDOW","SET_WINDOW","Unknown&hC","Unknown&hD","Unknown&hE"
Data"Unknown&hF","Unknown&h10","Unknown&h11","Unknown&h12","OUTPUT_STREAM"
Data"INPUT_STREAM","SOUND_EFFECT"
Dim fp
Dim num_bp
Dim nop
Dim ztrace

Function exe(tr)
 Local op,pc_old,sp_old
 pc_old=pc:sp_old=sp
 op=dec(tr)
 nop=nop+1
 If op<&h80 Then
  exe=e2o()
 ElseIf op<&hB0 Then
  exe=e1o()
 ElseIf op<&hC0 Then
  exe=e0o()
 ElseIf op<&hE0 Then
  exe=e2o()
 Else
  exe=evo()
 EndIf
 If exe=1 Then
  cou("Unsupported instruction "+hx$(op,2)):cen()
 ElseIf exe=2 Then
  cou("Unimplemented instruction "+hx$(op,2)):cen()
 EndIf
 If exe<>0 Then pc=pc_old:sp=sp_old
End Function

Function e2o()
 Local a,b,x,y,_
 a=oa(0)
 b=oa(1)
 If oc=&h1 Then
  x=(a=b)
  If(Not x)And(osz>2)Then x=(a=oa(2))
  If(Not x)And(osz>3)Then x=(a=oa(3))
  ebr(x,br)
 ElseIf oc=&h2 Then
  If a>32767 Then a=a-65536
  If b>32767 Then b=b-65536
  ebr(a<b,br)
 ElseIf oc=&h3 Then
  If a>32767 Then a=a-65536
  If b>32767 Then b=b-65536
  ebr(a>b,br)
 ElseIf oc=&h4 Then
  x=vge(a)
  If x>32767 Then x=x-65536
  If b>32767 Then b=b-65536
  x=x-1
  y=x<b
  If x<0 Then x=65536+x
  vse(a,x)
  ebr(y,br)
 ElseIf oc=&h5 Then
  x=vge(a)
  If x>32767 Then x=x-65536
  If b>32767 Then b=b-65536
  x=x+1
  y=x>b
  If x<0 Then x=65536+x
  vse(a,x)
  ebr(y,br)
 ElseIf oc=&h6 Then
  x=ob_rel(a,4)
  ebr(x=b,br)
 ElseIf oc=&h7 Then
  ebr((a And b)=b,br)
 ElseIf oc=&h8 Then
  vse(st,a Or b)
 ElseIf oc=&h9 Then
  vse(st,a And b)
 ElseIf oc=&hA Then
  x=oat(a,b)
  ebr(x=1,br)
 ElseIf oc=&hB Then
  _=oat(a,b,1,1)
 ElseIf oc=&hC Then
  _=oat(a,b,1,0)
 ElseIf oc=&hD Then
  If a=0 Then spk(sp-1,b)Else vse(a,b)
 ElseIf oc=&hE Then
  oin(a,b)
 ElseIf oc=&hF Then
  x=rw(a+2*b)
  vse(st,x)
 ElseIf oc=&h10 Then
  x=rb(a+b)
  vse(st,x)
 ElseIf oc=&h11 Then
  x=opg(a,b)
  vse(st,x)
 ElseIf oc=&h12 Then
  x=opa(a,b)
  vse(st,x)
 ElseIf oc=&h13 Then
  x=onp(a,b)
  vse(st,x)
 ElseIf oc<&h19 Then
  If a>32767 Then a=a-65536
  If b>32767 Then b=b-65536
  If oc=&h14 Then
   x=a+b
  ElseIf oc=&h15 Then
   x=a-b
  ElseIf oc=&h16 Then
   x=a*b
  ElseIf oc=&h17 Then
   x=a\b
  Else
   x=a Mod b
  EndIf
  If x<0 Then x=65536+x
  vse(st,x)
 Else
  e2o=1
 EndIf
End Function

Function e1o()
 Local a,x
 a=oa(0)
 If oc=&h0 Then
  ebr(a=0,br)
 ElseIf oc=&h1 Then
  x=ob_rel(a,5)
  vse(st,x)
  ebr(x<>0,br)
 ElseIf oc=&h2 Then
  x=ob_rel(a,6)
  vse(st,x)
  ebr(x<>0,br)
 ElseIf oc=&h3 Then
  x=ob_rel(a,4)
  vse(st,x)
 ElseIf oc=&h4 Then
  x=opl(a)
  vse(st,x)
 ElseIf oc=&h5 Then
  x=vge(a)
  If x>32767 Then x=x-65536
  x=x+1
  If x<0 Then x=65536+x
  vse(a,x)
 ElseIf oc=&h6 Then
  x=vge(a)
  If x>32767 Then x=x-65536
  x=x-1
  If x<0 Then x=65536+x
  vse(a,x)
 ElseIf oc=&h7 Then
  pzs(a)
 ElseIf oc=&h9 Then
  ore(a)
 ElseIf oc=&hA Then
  opr(a)
 ElseIf oc=&hB Then
  ert(a)
 ElseIf oc=&hC Then
  If a And &h8000 Then a=a-65536
  pc=pc+a-2
 ElseIf oc=&hD Then
  pzs(a*2)
 ElseIf oc=&hE Then
  If a=0 Then x=spe(sp-1)Else x=vge(a)
  vse(st,x)
 ElseIf oc=&hF Then
  x=a Xor &b1111111111111111
  vse(st,x)
 Else
  e1o=1
 EndIf
End Function

Function e0o()
 Local x
 If oc=&h0 Then
  ert(1)
 ElseIf oc=&h1 Then
  ert(0)
 ElseIf oc=&h2 Then
  pzs(pc)
 ElseIf oc=&h3 Then
  pzs(pc)
  cen()
  ert(1)
 ElseIf oc=&h4 Then
 ElseIf oc=&h5 Then
  If csc AND &b10 Then
   cou("IGNORED 'save' command read from script"):cen()
  Else
   x=zsv()
   ebr(x,br)
  EndIf
 ElseIf oc=&h6 Then
  If csc AND &b10 Then
   cou("IGNORED 'restore' command read from script"):cen()
  Else
   x=zsv(1)
  EndIf
 ElseIf oc=&h7 Then
  If csc AND &b10 Then
   cou("IGNORED 'restart' command read from script"):cen()
  Else
   main_init()
   For x=0 To 10:cen():Next x
  EndIf
 ElseIf oc=&h8 Then
  x=spo()
  ert(x)
 ElseIf oc=&h9 Then
  sp=sp-1
 ElseIf oc=&hA Then
  e0o=4
 ElseIf oc=&hB Then
  cen()
 ElseIf oc=&hC Then
  ess()
 ElseIf oc=&hD Then
  ebr(1,br)
 Else
  e0o=1
 EndIf
End Function

Function evo()
 Local x,_
 If oc=&h0 Then
  ecl(st)
 ElseIf oc=&h1 Then
  ww(oa(0)+2*oa(1),oa(2))
 ElseIf oc=&h2 Then
  wb(oa(0)+oa(1),oa(2))
 ElseIf oc=&h3 Then
  ob_prop_set(oa(0),oa(1),oa(2))
 ElseIf oc=&h4 Then
  evo=erd(oa(0),oa(1))
 ElseIf oc=&h5 Then
  cou(Chr$(oa(0)))
 ElseIf oc=&h6 Then
  x=oa(0)
  If x>32767 Then x=x-65536
  cou(Str$(x))
 ElseIf oc=&h7 Then
  x=oa(0)
  If x>32767 Then x=x-65536
  x=era(x)
  vse(st,x)
 ElseIf oc=&h8 Then
  spu(oa(0))
 ElseIf oc=&h9 Then
  x=spo()
  If oa(0)=0 Then spk(sp-1,x)Else vse(oa(0),x)
 ElseIf oc=&h13 Then
  evo=2
 ElseIf oc=&h14 Then
  evo=2
 ElseIf oc=&h15 Then
 Else
  evo=1
 EndIf
End Function

Sub ebr(z,br)
 Local x
 If Not(z=(br And &h80000)>0)Then Exit Sub
 x=br And &h7FFFF
 If x=pc-1 Then ert(1):Exit Sub
 If x=pc-2 Then ert(0):Exit Sub
 pc=x
End Sub

Sub ert(x)
 Local st,_
 sp=fp+4
 pc=spo()*&h10000+spo()
 st=spo()
 fp=spo()
 vse(st,x)
 If ztrace Then dmp_stack()
End Sub

Sub ecl(st)
 Local i,nl,x
 If oa(0)=0 Then vse(st,0):Exit Sub
 spu(fp)
 fp=sp-1
 spu(st)
 spu(pc Mod &h10000)
 spu(pc\&h10000)
 pc=2*oa(0)
 nl=rp()
 spu(nl)
 For i=1 To nl
  x=rp()*256+rp()
  If i<osz Then spu(oa(i))Else spu(x)
 Next i
 If ztrace Then dmp_routine(2*oa(0)):dmp_stack()
End Sub

Function erd(text_buf,parse_buf)
 Local ad,c,i,n,word$,s$,t,wc
 t=Timer
 s$=LCase$(ci$("> ",1))
 If Left$(s$,1)="*"Then erd=esp(s$)
 Timer=t
 If erd<>0 Then Exit Function
 n=Len(s$)
 For i=1 To n:wb(text_buf+i,Peek(Var s$,i)):Next i
 wb(text_buf+n+1,0)
 s$=s$+" "
 For i=1 To n+1
  c=Peek(Var s$,i)
  If c=&h20 Or Instr(DS$(0),Chr$(c))>0 Then
   If Len(word$)>0 Then
    ad=dlk(word$)
    ww(parse_buf+2+wc*4,ad)
    wb(parse_buf+4+wc*4,Len(word$))
    wb(parse_buf+5+wc*4,i-Len(word$))
    wc=wc+1
    word$=""
   EndIf
   If c<>&h20 Then
    ad=dlk(Chr$(c))
    ww(parse_buf+2+wc*4,ad)
    wb(parse_buf+4+wc*4,1)
    wb(parse_buf+5+wc*4,i-1)
    wc=wc+1
   EndIf
  Else
   word$=word$+Chr$(c)
  EndIf
 Next i
 wb(parse_buf+1,wc)
End Function

Function esp(cmd$)
 Local f$,_
 esp=6
 If cmd$="*break"Then
  esp=0
 ElseIf cmd$="*credits"Then
  cecho(ss$(1)+"\cred_cm1.txt")
 ElseIf cmd$="*replay"Then
  If csc AND &b10 Then
   cou("IGNORED '*replay' command read from script")
  Else
   cou("Select a script file from '")
   cou(ss$(3)+"\"+ss$(5)+"':")
   cen()
   f$=fi_choose$(ss$(3)+"\"+ss$(5),"*.scr")
   If f$<>""Then
    Open f$ For Input As #3
    csc=csc Or &b10
   EndIf
  EndIf
  cen()
 ElseIf cmd$="*status"Then
  ess()
 Else
  esp=0
 EndIf
 If esp=6 Then cou(">")
End Function

Function era(range)
 If range=0 Then
  Randomize Timer
 Exit Function
 ElseIf range<0 Then
  Randomize Abs(range)
 Exit Function
 EndIf
 era=1+CInt((range-1)*Rnd())
End Function

Sub ess()
 Local x
 x=vge(&h10):opr(x):cou(", ")
 x=vge(&h11):cou("Score: "+Str$(x)+", ")
 x=vge(&h12):cou("Moves: "+Str$(x))
 cen()
End Sub

Dim csc
Dim cb$
Dim csp
Dim cli
Dim cem

Function ci$(p$,r)
 Local s$
 cou(p$)
 cfl()
 cli=0
 If csc And &b10 Then
  Line Input #3,ci$
  If ci$=""Then
   csc=csc And &b01
   Close #3
  Else
   s$=ci$:cou(s$):cen()
  EndIf
 EndIf
 If Not(csc And &b10)Then Line Input ci$
 If(r=1)And(csc AND &b01)And(ci$<>"")Then Print #2,ci$
End Function

Sub cou(s$)
 Local c,i
 For i=1 To Len(s$)
  c=Peek(Var s$,i)
  If(c=&h20)Xor csp Then cfl():csp=(c=&h20)
  cb$=cb$+Chr$(c)
 Next i
End Sub

Sub cfl()
 If Pos=1 And cli>36-2 Then
  Print"[MORE] ";
  Do While Inkey$<>"":Loop
  Do While Inkey$="":Loop
  Print
  cli=0
 EndIf
 If Pos+Len(cb$)>80 Then
  Print
  cli=cli+1
  If Not csp Then cfl()
 Else
  Print cb$;
 EndIf
 cb$=""
End Sub

Sub cen()
 cfl()
 If Pos=1 Then cem=cem+1 Else cem=0
 If cem>=0 Then Print:cli=cli+1
 If cem>10 Then
  Local i
  For i=0 To 36-cem-1:Print:Next i
  cem=-999
  cli=0
 EndIf
End Sub

Sub cecho(f$)
 Local s$
 Open f$ For Input As #1
 Do
  Line Input #1,s$
  cou(s$)
  cen()
 Loop While Not Eof(#1)
 Close #1
End Sub

Dim AL$(2)LENGTH 32
AL$(0)=" 123[]abcdefghijklmnopqrstuvwxyz"
AL$(1)=" 123[]ABCDEFGHIJKLMNOPQRSTUVWXYZ"
AL$(2)=" 123[]@^0123456789.,!?_#'"+Chr$(34)+"/\-:()"

Sub pzs(a)
 Local b,c,i,s,x,zc(2)
 For x=0 To 0 Step 0
  x=rw(a)
  zc(0)=(x And &h7C00)\&h400
  zc(1)=(x And &h3E0)\&h20
  zc(2)=(x And &h1F)
  x=x\&h8000
  For i=0 To 2
   c=zc(i)
   If s<3 Then
    If c=0 Then
     cou(" ")
    ElseIf c<4 Then
     s=c+2
    ElseIf c<6 Then
     s=c-3
    Else
     If c=6 And s=2 Then
      s=6
     ElseIf c=7 And s=2 Then
      cen()
      s=0
     Else
      cou(Mid$(AL$(s),c+1,1))
      s=0
     EndIf
    EndIf
   ElseIf s<6 Then
    b=a
    pab((s-3)*32+c)
    a=b
    s=0
   ElseIf s=6 Then
    s=c+7
   Else
    cou(Chr$((s-7)*32+c))
    s=0
   EndIf
  Next i
  a=a+2
 Next x
End Sub

Sub pab(x)
 Local a,b
 a=rw(&h18)
 b=rw(a+x*2)
 pzs(b*2)
End Sub

Function oat(o,a,s,x)
 Local ad,m,y
 If o=0 Then Exit Function
 ad=rw(&h0A)+62+(o-1)*9+a\8
 y=rb(ad)
 m=2^(7-a Mod 8)
 If s=0 Then oat=(y And m)>0:Exit Function
 If x=0 Then y=(y And(m Xor &hFF))Else y=(y Or m)
 wb(ad,y)
 oat=x
End Function

Function ob_rel(o,r,s,x)
 Local ad
 ad=rw(&h0A)+62+(o-1)*9+r
 If s=0 Then ob_rel=rb(ad):Exit Function
 wb(ad,x)
 ob_rel=x
End Function

Function onp(o,p)
 Local ad,x
 If o=0 Then
 Exit Function
 ElseIf p=0 Then
  ad=opb(o)
  ad=ad+1+2*rb(ad)
 Else
  ad=opa(o,p)
  If ad=0 Then Error"Property does not exist"
  x=rb(ad-1)
  ad=ad+1+x\32
 EndIf
 x=rb(ad)
 onp=x And &b11111
End Function

Function opl(ad)
 Local x
 If ad=0 Then Exit Function
 x=rb(ad-1)
 opl=x\32+1
End Function

Function opb(o)
 Local ad
 ad=rw(&h0A)+62+(o-1)*9+7
 opb=rw(ad)
End Function

Function opa(o,p)
 Local ad,x
 ad=opb(o)
 ad=ad+1+2*rb(ad)
 Do
  x=rb(ad)
  If(x And &b11111)=p Then opa=ad+1:Exit Function
  If(x And &b11111)<p Then opa=0:Exit Function
  ad=ad+2+x\32
 Loop
End Function

Function opg(o,p)
 Local ad,sz,x
 ad=opa(o,p)
 If ad>0 Then
  x=rb(ad-1)
  If(x And &b11111)<>p Then Error
  sz=x\32+1
  If sz=1 Then opg=rb(ad):Exit Function
  If sz=2 Then opg=rw(ad):Exit Function
  Error"Property length > 2"
 EndIf
 ad=rw(&h0A)+2*(p-1)
 opg=rw(ad)
End Function

Sub ob_prop_set(o,p,x)
 Local a,sz
 a=opa(o,p)
 If a=0 Then Error"Object "+Str$(o)+" does not have property "+Str$(p)
 sz=opl(a)
 If sz<0 Or sz>2 Then Error"Object "+Str$(o)+" has length "+Str$(sz)
 If sz=1 Then wb(a,x And &hFF)
 If sz=2 Then ww(a,x)
End Sub

Sub opr(o)
 Local ad
 ad=opb(o)+1
 pzs(ad)
End Sub

Sub oin(o,d)
 Local c,_
 ore(o)
 c=ob_rel(d,6)
 _=ob_rel(d,6,1,o)
 _=ob_rel(o,4,1,d)
 _=ob_rel(o,5,1,c)
End Sub

Sub ore(o)
 Local c,p,s,_
 p=ob_rel(o,4)
 s=ob_rel(o,5)
 c=ob_rel(p,6)
 _=ob_rel(o,4,1,0)
 _=ob_rel(o,5,1,0)
 If o=c Then
  _=ob_rel(p,6,1,s)
 Else
  Do
   If ob_rel(c,5)=o Then _=ob_rel(c,5,1,s):Exit Do
   c=ob_rel(c,5)
  Loop Until c=0
 EndIf
End Sub

Function lp$(s$,i,c$)
 Local a
 a=Len(s$)
 If c$=""Then c$=" "
 If a<i Then lp$=String$(i-a,c$)+s$ Else lp$=s$
End Function

Function rd$(s$,i,c$)
 Local a
 a=Len(s$)
 If c$=""Then c$=" "
 If a<i Then rd$=s$+String$(i-a,c$)Else rd$=s$
End Function

Function hx$(x,i)
 If i<1 Then i=4
 hx$="&h"+lp$(Hex$(x),i,"0")
End Function

Dim DAD
Dim DS$(1)Length 5
Dim DEL
Dim DSZ
Dim DEA

Sub di_init()
 Local i,ns
 DAD=rw(&h08)
 ns=rb(DAD)
 Poke Var DS$(0),0,ns
 For i=1 To ns:Poke Var DS$(0),i,rb(DAD+i):Next i
 DEL=rb(DAD+ns+1)
 DSZ=rw(DAD+ns+2)
 DEA=DAD+ns+4
End Sub

Function dlk(w$)
 Local c,i,j,nz,sz,z(9)
 sz=Len(w$):If sz>6 Then sz=6
 i=1
 Do While i<7 And nz<7
  If i>sz Then
   z(nz)=5:nz=nz+1
  Else
   c=Asc(Mid$(w$,i,1))
   j=Instr(AL$(0),Chr$(c))-1
   If j>-1 Then
    z(nz)=j:nz=nz+1
   Else
    j=Instr(AL$(2),Chr$(c))-1
    If j>-1 Then
     z(nz)=5:nz=nz+1
     z(nz)=j:nz=nz+1
    Else
     z(nz)=5:nz=nz+1
     z(nz)=6:nz=nz+1
     z(nz)=c\32:nz=nz+1
     z(nz)=c And &b11111:nz=nz+1
    EndIf
   EndIf
  EndIf
  i=i+1
 Loop
 Local x(1)
 x(0)=z(0)*1024+z(1)*32+z(2)
 x(1)=z(3)*1024+z(4)*32+z(5)+32768
 Local a,lb,ub,y(1)
 lb=0
 ub=DSZ-1
 Do
  i=(lb+ub)\2
  a=DEA+DEL*i
  y(0)=rw(a)
  y(1)=rw(a+2)
  If x(0)>y(0)Then
   lb=i+1
  ElseIf x(0)<y(0)Then
   ub=i-1
  ElseIf x(1)>y(1)Then
   lb=i+1
  ElseIf x(1)<y(1)Then
   ub=i-1
  Else
   dlk=a
   ub=lb-1
  EndIf
 Loop Until ub<lb
End Function

Function zsv(res)
 Local exists(10),i,old_dir$,s$,s2$(2)Length 40
 If res Then
  cou("Select game to restore:"):cen()
 Else
  cou("Select save game slot:"):cen()
 EndIf
 old_dir$=Cwd$
 ChDir ss$(2)+"\"+ss$(5)
 For i=1 To 10
  s$=Dir$("game"+Str$(i)+".sav")
  cou("  ["+Format$(i,"%2g")+"] ")
  If s$=""Then
   cou("Empty"):cen()
  Else
   exists(i)=1
   Open"game"+Str$(i)+".sav"For Input As #1
   Line Input #1,s2$(0)
   Line Input #1,s2$(1)
   Line Input #1,s2$(2)
   Line Input #1,s$
   cou(s2$(2)+" - "+s$):cen()
   Close #1
  EndIf
 Next i
 ChDir old_dir$
 s$=ci$("Game number? ")
 i=Val(s$)
 If i<1 Or i>10 Then i=0
 If i>0 And res And Not exists(i)Then i=0
 If i>0 And Not res And exists(i)Then
  s$=ci$("Overwrite game "+Str$(i)+" [y|N]? ")
  If LCase$(s$)<>"y"Then i=0
 EndIf
 If i>0 And Not res Then
  s$=ci$("Save game name? ")
  If s$=""Then i=0
 EndIf
 If i=0 Then cou("Cancelled"):cen():Exit Function
 s2$(0)=ss$(2)+"\"+ss$(5)+"\game"+Str$(i)+".sav"
 If res Then
  Open s2$(0)For Input As #1
  Line Input #1,s2$(0)
  Line Input #1,s2$(1)
  Line Input #1,s2$(2)
  Line Input #1,s$
  cou("Restoring '"+s$+"' ..."):cen()
  Local ad,err,new_pc,new_fp,stack_sz,mem_sz
  s$=Input$(9,#1)
  new_pc=Peek(Var s$,1)*65536+Peek(Var s$,2)*256+Peek(Var s$,3)
  new_fp=Peek(Var s$,4)*256+Peek(Var s$,5)
  stack_sz=Peek(Var s$,6)*256+Peek(Var s$,7)
  mem_sz=Peek(Var s$,8)*256+Peek(Var s$,9)
  If new_pc<0 Or new_pc>=FSZ Then err=1
  If new_fp<0 Or new_fp>stack_sz Then err=2
  If stack_sz<0 Or stack_sz>511 Then err=3
  If mem_sz<>BST Then err=4
  If err<>0 Then
   cou("Save file is invalid (error "+Str$(err)+")")
   Close #1
  Exit Function
  EndIf
  pc=new_pc
  fp=new_fp
  sp=0
  For i=0 To stack_sz-1
   s$=Input$(2,#1)
   push(Peek(Var s$,1)*256+Peek(Var s$,2))
  Next i
  Do
   s$=Input$(255,#1)
   For i=1 To Len(s$)
    wb(ad,Peek(Var s$,i))
    ad=ad+1
   Next i
  Loop Until Len(s$)=0
  If ad<>BST Then Error"Unrecoverable restore error!"
 Else
  cou("Saving '"+s$+"' ..."):cen()
  Open s2$(0)For Output As #1
  Print #1,"ZMIM save file"
  Print #1,"1"
  Print #1,Date$+" "+Time$
  Print #1,s$
  Print #1,Chr$(pc\65536);Chr$(pc\256);Chr$(pc Mod 256);
  Print #1,Chr$(fp\256);Chr$(fp Mod 256);
  Print #1,Chr$(sp\256);Chr$(sp Mod 256);
  Print #1,Chr$(BST\256);Chr$(BST Mod 256);
  For i=0 To sp-1
   Print #1,Chr$(spe(i)\256);Chr$(spe(i)Mod 256);
  Next i
  For i=0 To BST-1
   Print #1,Chr$(rb(i));
  Next i
 EndIf
 Close #1
 zsv=1
End Function

Function fi_choose$(d$,fspec$)
 Local f$,i,j,nc,nr,old_dir$,sz,width,x
 old_dir$=Cwd$
 ChDir d$
 f$=Dir$(fspec$)
 Do While f$<>""
  If Left$(f$,1)<>"."Then
   sz=sz+1
   If Len(f$)>width Then width=Len(f$)
  EndIf
  f$=Dir$()
 Loop
 If sz=0 Then cou("No files found"):cen():ChDir old_dir$:Exit Function
 Local all$(sz)LENGTH width
 all$(sz)=Chr$(&h7F)
 f$=Dir$(fspec$)
 i=0
 Do
  If Left$(f$,1)<>"."Then all$(i)=f$:i=i+1
  f$=Dir$()
 Loop Until i=sz
 ChDir old_dir$
 If sz<8 Then nc=1 Else nc=2
 nr=CInt(sz/nc+0.4999)
 width=width+10
 For i=0 To nr-1
  For j=0 to nc-1
   cfl()
   x=(j*nr)+i
   If x<sz Then
    If j*width>Pos Then cou(Space$(j*width-Pos))
    cou("  ["+Format$(x+1,"%2g")+"] "+all$(x))
   EndIf
  Next j
  cen()
 Next i
 f$=ci$("File number? ")
 If Val(f$)>0 And Val(f$)<=sz Then fi_choose$=d$+"\"+all$(Val(f$)-1)
End Function

Dim ss$(5)Length 20

Sub main_init()
 Local i,x
 cen()
 mem_init(ss$(4)+"\"+ss$(5)+".z3")
 di_init()
 cen()
 GVA=rw(&h0C)
 x=rb(&h01)
 x=x Or &b00010000
 x=x And &b10011111
 wb(&h01,x)
 wb(&h20,36)
 wb(&h21,80)
 pc=rw(&h06)
 For i=0 To 511:stk(i)=0:Next i
 sp=0
 fp=&hFFFF
End Sub

Sub main()
 Local i,old_dir$,old_pc,state,s$
 ss$(0)="\zmim"
 ss$(1)=ss$(0)+"\resources"
 ss$(2)=ss$(0)+"\saves"
 ss$(3)=ss$(0)+"\scripts"
 ss$(4)=ss$(0)+"\stories"
 Cls
 cecho(ss$(1)+"\titl_cm1.txt")
 de_init()
 cou("Select a story file from '"+ss$(4)+"':"):cen()
 Do While s$=""
  s$=fi_choose$(ss$(4),"*.z3")
 Loop
 s$=Mid$(s$,Len(ss$(4))+2)
 ss$(5)=Left$(s$,Len(s$)-3)
 old_dir$=Cwd$
 ChDir(ss$(2))
 s$=Dir$(ss$(5),File):If s$<>""Then Error"Unexpected file: "+s$
 s$=Dir$(ss$(5),Dir):If s$=""Then MkDir(ss$(5))
 ChDir(ss$(3))
 s$=Dir$(ss$(5),File):If s$<>""Then Error"Unexpected file:"+s$
 s$=Dir$(ss$(5),Dir):If s$=""Then MkDir(ss$(5))
 ChDir(old_dir$)
 main_init()
 s$=ss$(5)+"-"+Date$+"-"+Time$+".scr"
 For i=1 To Len(s$)
  If Peek(Var s$,i)=Asc(":")Then Poke Var s$,i,Asc("-")
 Next i
 s$=ss$(3)+"\"+ss$(5)+"\"+s$
 If LCase$(ci$("Write script to '"+s$+"' [y|N] "))="y"Then
  Open s$ For Output As #2
  csc=&b01
 EndIf
 For i=0 To 10:cen():Next i
 Timer=0
 Do While state<>4
  old_pc=pc
  If state=0 Or state=6 Then
   state=exe(ztrace)
  Else
   state=debug()
  EndIf
 Loop
 cen()
 cou("Num instructions processed = "+Str$(nop)):cen()
 cou("Instructions / second      = ")
 cou(Format$(1000*nop/Timer,"%.1f"))
 cen()
 cou("Num page faults            = "+Str$(pf)):cen()
 If csc And &b01 Then Close #2
 If csc And &b10 Then Close #3
End Sub

main()
End