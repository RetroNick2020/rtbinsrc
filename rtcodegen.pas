unit rtcodegen;

interface
uses
  Classes, SysUtils,StrUtils;

const
 NoLan    = 0;
 BasicLan = 1;
 BasicLNLan = 2;
 CLan     = 3;
 PascalLan= 4;
 FBBasicLan = 5;   //fix this in the future - just a hack right now to make things work with freebasic
 QB64BasicLan = 6; //fix this in the future - just a hack right now to make things work with Qb64
 AQBBasicLan = 7;  //fix this in the future - just a hack right now to make things work with Amiga QuickBasic AQB

 ValueFormatDecimal = 0;
 ValueFormatHex = 1;




 c_char_signed = 1;
 c_char_unsigned = 2;
 c_int_signed = 3;
 c_int_unsigned = 4;
 c_long_signed = 5;
 c_long_unsigned = 6;

 pascal_byte = 7;
 pascal_integer = 8;
 pascal_word = 9;
 pascal_longint = 10;
 pascal_longword = 11;

 basic_byte = 12;
 basic_integer = 13;
 basic_long    = 14;

 bitsize8   =1;
 bitsize16 = 2;
 bitsize32 = 3;

type
  CodeGenRec = Record
                      InDentSize      : integer; //how many characters to pad
                      IndentOnFirst   : Boolean; //indent on first line
                      ValuesPerLine   : integer; //# values seperated by comma
                      ValuesTotal     : longint; //#number of values we are going to write
                      ValueFormat     : integer;

                      VC              : integer;  //value counter - how many byte/integer written
                      VCL             : longint;  //value counter per line
                      LineCount       : integer;  //line counter
                      LanId           : integer;

                       LineBufStr : String;
                       NextLineNumber : integer;

  end;

  MemoProc = procedure(Msg : string);

procedure CGInit(var mc : CodeGenRec);
procedure CGSetLan(var mc : CodeGenRec;Lan : integer);
procedure CGSetValuesTotal(var mc : CodeGenRec;amount : longint);
procedure CGSetValueFormat(var mc : CodeGenRec;format : integer);
procedure CGWriteInteger(var mc : CodeGenRec;value : longword);
procedure CGWriteByte(var mc : CodeGenRec;value : byte);
procedure CGSetValuesPerLine(var mc : CodeGenRec;amount : integer);
procedure CGSetIndentOnFirstLine(var mc : CodeGenRec;indent : boolean);
procedure CGSetIndent(var mc : CodeGenRec;isize : integer);

procedure CGSetMemoProc(MP : MemoProc);
procedure CGWrite(var mc : CodeGenRec ; Msg : string);
procedure CGWriteLn(var mc : CodeGenRec);

function ImportBinFile(var mc : CodeGenRec;filename,aname : string;Lan,DataType,nformat : integer) : word;

implementation

var
 CGMemo : MemoProc;
 //LineBufStr : String ='';
procedure CGSetMemoProc(MP : MemoProc);
begin
 CGMemo:=MP;
end;

procedure CGWrite(var mc : CodeGenRec ; Msg : string);
begin
// CGMemo(Msg);
 mc.LineBufStr:=mc.LineBufStr+Msg;
end;


procedure CGWriteLn(var mc : CodeGenRec);
begin
 CGMemo(mc.LineBufStr);
 mc.LineBufStr:='';
end;


procedure CGSetIndent(var mc : CodeGenRec;isize : integer);
begin
  mc.InDentSize:=isize;
end;

procedure CGSetIndentOnFirstLine(var mc : CodeGenRec;indent : boolean);
begin
  mc.IndentOnFirst:=indent;
end;

procedure CGSetValuesPerLine(var mc : CodeGenRec;amount : integer);
begin
  mc.ValuesPerLine:=amount;
end;

procedure CGSetValuesTotal(var mc : CodeGenRec;amount : longint);
begin
  mc.ValuesTotal:=amount;
end;

procedure CGSetValueFormat(var mc : CodeGenRec;format : integer);
begin
  mc.ValueFormat:=format;
end;

procedure CGSetLan(var mc : CodeGenRec;Lan : integer);
begin
  mc.LanId:=Lan;
end;

procedure CGInit(var mc : CodeGenRec);
begin
// mc.FTextPtr:=@F;
 mc.VC:=0;
 mc.VCL:=0;
 mc.LineCount:=0;
 mc.LineBufStr:='';
 mc.NextLineNumber:=1000;
 CGSetIndent(mc,10);
 CGSetIndentOnFirstLine(mc,true);
 CGSetValuesPerLine(mc,10);
 CGSetValuesTotal(mc,0);
 CGSetValueFormat(mc,ValueFormatDecimal);
 CGSetLan(mc,PascalLan);
end;

function CGGetGWNextLineNumber(var mc :CodeGenRec) : integer;
begin
 CGGetGWNextLineNumber:=mc.NextLineNumber;
 inc(mc.NextLineNumber,10);
end;

procedure CGWriteLineNumber(var mc : CodeGenRec);
begin
 if (mc.LanId<>BasicLNLan) then exit;
 if mc.VCL = 0 then
 begin
//    Write(mc.FTextPtr^,GetGWNextLineNumber,' ');
   CGWrite(mc,IntToStr(CGGetGWNextLineNumber(mc))+' ');
 end;
end;

procedure CGWriteLineFeed(var mc : CodeGenRec);
begin
 if (mc.VC=mc.ValuesTotal) then exit;
 if mc.VCL = mc.ValuesPerLine then
 begin
//    WriteLn(mc.FTextPtr^);
    CGWriteLn(mc);
    mc.VCL:=0;
    inc(mc.LineCount);
 end;
end;

procedure CGWriteData(var mc : CodeGenRec);
begin
  if (mc.LanId=BasicLan) or (mc.LanId=BasicLNLan) then
  begin
    if mc.VCL = 0 then CGWrite(mc,'DATA ');
  end;
end;

procedure CGWriteIndent(var mc : CodeGenRec);
var
 indentstr : string;
begin
 if (mc.LanId=BasicLan) or (mc.LanId=BasicLNLan)  then exit;
 if (mc.VCL = 0) then
 begin
  if (mc.IndentOnFirst = false) and (mc.LineCount=0) then exit;
//  Write(mc.FTextPtr^,' ':mc.InDentSize);
   indentstr:=PadRight(' ',mc.InDentSize);
   CGWrite(mc,indentstr);
 end;
end;

procedure CGWriteComma(var mc : CodeGenRec);
begin
 if (mc.VC=mc.ValuesTotal) then
 begin
//   write(FTEXT,'END');
   exit;
 end;

 if mc.VCL > 0 then
 begin
   if (mc.VCL<mc.ValuesPerLine) then
   begin
    // Write(mc.FTextPtr^,',');
     CGWrite(mc,',');
   end
   else if (mc.VCL=mc.ValuesPerLine)  then  //end of line but not last value
   begin
     if (mc.LanId<>BasicLan) and (mc.LanId<>BasicLNLan) then
     begin
       //Write(mc.FTextPtr^,','); //if not basic write a comma
       CGWrite(mc,',');
     end;
   end;
 end;
end;

function ByteToHex(num : byte;LanId : integer) : string;
var
 HStr : String;
begin
 HStr:=hexstr(num,2);
 if LanId=BasicLan then HStr:='&H'+HStr;
 if LanId=PascalLan then HStr:='$'+HStr;
 if LanId=CLan then HStr:='0x'+HStr;
 ByteToHex:=HStr;
end;

procedure CGWriteByte(var mc : CodeGenRec;value : byte);
begin
 CGWriteLineNumber(mc); //line numbers - only if lan - basicLN
 CGWriteData(mc);       //basiclan data statements -  lanid should be basiclan
 CGWriteIndent(mc);    // method will decide if indent needed

 inc(mc.VC);
 inc(mc.VCL);

 if  mc.ValueFormat = ValueFormatDecimal then
 begin
   //Write(mc.FTextPtr^,value);
   CGWrite(mc,IntToStr(value));
 end
 else if mc.ValueFormat = ValueFormatHex then
 begin
   //Write(mc.FTextPtr^,ByteToHEx(value,mc.LanId));
   CGWrite(mc,ByteToHEx(value,mc.LanId));
 end;

 CGWriteComma(mc);     // method will decide if comma needed
 CGWriteLineFeed(mc);  // method will decide if line feed needed
end;

procedure CGWriteStr(var mc : CodeGenRec;value : string);
begin
 CGWriteLineNumber(mc); //line numbers - only if lan - basicLN
 CGWriteData(mc);       //basiclan data statements -  lanid should be basiclan
 CGWriteIndent(mc);    // method will decide if indent needed

 inc(mc.VC);
 inc(mc.VCL);

 CGWrite(mc,value);

 CGWriteComma(mc);     // method will decide if comma needed
 CGWriteLineFeed(mc);  // method will decide if line feed needed
end;

function IntegerToHex(num,LanId : integer) : string;
var
 HStr : String;
begin
 HStr:=hexstr(num,4);
 if LanId=BasicLan then HStr:='&H'+HStr;
 if LanId=PascalLan then HStr:='$'+HStr;
 if LanId=CLan then HStr:='0x'+HStr;
 IntegerToHex:=HStr;
end;

procedure CGWriteInteger(var mc : CodeGenRec;value : longword);
begin
 CGWriteLineNumber(mc); //line numbers - only if lan - basicLN
 CGWriteData(mc);       //basiclan data statements -  lanid should be basiclan
 CGWriteIndent(mc);    // method will decide if indent needed

 inc(mc.VC);
 inc(mc.VCL);

 if  mc.ValueFormat = ValueFormatDecimal then
 begin
   //Write(mc.FTextPtr^,value);
   //CGWrite(mc,IntToStr(smallint(value)));
   CGWrite(mc,IntToStr(value));

 end
 else if mc.ValueFormat = ValueFormatHex then
 begin
   //Write(mc.FTextPtr^,IntegerToHex(value,mc.LanId));
   CGWrite(mc,IntegerToHex(value,mc.LanId));
 end;

 CGWriteComma(mc);     // method will decide if comma needed
 CGWriteLineFeed(mc);  // method will decide if line feed needed
end;

function varypetostring(vtype : integer) : string;
begin
  case vtype of  c_char_signed:result:='char';
               c_char_unsigned:result:='unsigned char';
                  c_int_signed:result:='int';
                c_int_unsigned:result:='unsigned int';
                 c_long_signed:result:='long';
               c_long_unsigned:result:='unsigned long';
                   pascal_byte:result:='Byte';
                pascal_integer:result:='Integer';
                   pascal_word:result:='Word';
                pascal_longint:result:='Longint';
               pascal_longword:result:='Longword';
//                    basic_byte:
//                 basic_integer:
//                    basic_long:
  end;
end;

function VTypeToHexStr(num : longword;datatype : integer) : string;
begin
 case datatype of  c_char_signed:result:='0x'+LowerCase(IntToHex(UInt8(num),2));
               c_char_unsigned:result:='0x'+LowerCase(IntToHex(UInt8(num),2));
                  c_int_signed:result:='0x'+LowerCase(IntToHex(UInt16(num),4));
                c_int_unsigned:result:='0x'+LowerCase(IntToHex(UInt16(num),4));
                 c_long_signed:result:='0x'+LowerCase(IntToHex(UInt32(num),8));
               c_long_unsigned:result:='0x'+LowerCase(IntToHex(UInt32(num),8));
                   pascal_byte:result:='$'+IntToHex(UInt8(num),2);
                pascal_integer:result:='$'+IntToHex(UInt16(num),4);
                   pascal_word:result:='$'+IntToHex(UInt16(num),4);
                pascal_longint:result:='$'+IntToHex(UInt32(num),8);
               pascal_longword:result:='$'+IntToHex(UInt32(num),8);
                    basic_byte:result:='&H'+IntToHex(UInt8(num),2);
                 basic_integer:result:='&H'+IntToHex(UInt16(num),4);
                    basic_long:result:='&H'+IntToHex(UInt32(num),8);
  end;
 //if LanId=BasicLan then HStr:='&H'+HStr;
// if LanId=PascalLan then HStr:='$'+HStr;
// if LanId=CLan then HStr:='0x'+HStr;
end;

function VTypeToDecStr(num : longword;datatype : integer) : string;
begin
 case datatype of  c_char_signed:result:=IntToStr(Int8(num));
               c_char_unsigned:result:=IntToStr(UInt8(num));
                  c_int_signed:result:=IntToStr(Int16(num));
                c_int_unsigned:result:=IntToStr(UInt16(num));
                 c_long_signed:result:=IntToStr(Int32(num));
                 c_long_unsigned:result:=IntToStr(UInt32(num));
                   pascal_byte:result:=IntToStr(UInt8(num));
                pascal_integer:result:=IntToStr(Int16(num));
                   pascal_word:result:=IntToStr(UInt16(num));
                pascal_longint:result:=IntToStr(Int32(num));
               pascal_longword:result:=IntToStr(UInt32(num));
                    basic_byte:result:=IntToStr(UInt8(num));
                 basic_integer:result:=IntToStr(Int16(num));
                    basic_long:result:=IntToStr(Int32(num));
  end;
end;


procedure CGWriteNumber(var mc : CodeGenRec;value : longword;datatype : integer);
begin
 CGWriteLineNumber(mc); //line numbers - only if lan - basicLN
 CGWriteData(mc);       //basiclan data statements -  lanid should be basiclan
 CGWriteIndent(mc);    // method will decide if indent needed

 inc(mc.VC);
 inc(mc.VCL);

 if  mc.ValueFormat = ValueFormatDecimal then
 begin
   //Write(mc.FTextPtr^,value);

   CGWrite(mc,VTypeToDecStr(value,datatype));
 end
 else if mc.ValueFormat = ValueFormatHex then
 begin
   //Write(mc.FTextPtr^,ByteToHEx(value,mc.LanId));
   CGWrite(mc,VTypeToHexStr(value,datatype));
 end;

 CGWriteComma(mc);     // method will decide if comma needed
 CGWriteLineFeed(mc);  // method will decide if line feed needed
end;


procedure ConvertToCode(var mc : CodeGenRec;aname : string;var data; asize : longword; Lan,DataType,BitSize : integer);
var
 i     : longword;
 BData : PByte absolute data;
 WData : PWord absolute data;
 LData : PLongword absolute data;
begin
 Case Lan of PascalLan:CGWrite(mc,aname+' : array[0..'+IntToStr(asize-1)+'] of '+varypetostring(datatype)+' = (');
                  CLan:CGWrite(mc,varypetostring(datatype)+' '+aname+'['+IntToStr(asize)+'] = {');
              BasicLan:CGWrite(mc,#39+' '+aname+' Size='+IntToStr(asize));
 end;
 CGWriteLn(mc);

 for i:=0 to asize-1 do
 begin
   Case BitSize of BitSize8:begin
                             CGWriteNumber(mc,BData[i],DataType);
                           end;
                 BitSize16:begin
                             CGWriteNumber(mc,WData[i],DataType);
                           end;
                 BitSize32:begin
                             CGWriteNumber(mc,LData[i],DataType);
                           end;
  end;
 end;
 Case Lan of PascalLan:CGWrite(mc,');');
                    cLan:CGWrite(mc,'};');
 end;
 CGWriteLn(mc);
 CGWriteLn(mc);
end;

function GetBitSize(datatype : integer) : integer;
begin
 result:=0;
 case datatype of pascal_byte,c_char_signed,c_char_unsigned,basic_byte:result:=bitsize8;
               pascal_integer,pascal_word,c_int_signed,c_int_unsigned,basic_integer:result:=bitsize16;
               pascal_longword,pascal_longint,c_long_signed,c_long_unsigned,basic_long:result:=bitsize32;
 end;
end;

function ImportBinFile(var mc : CodeGenRec;filename,aname : string;Lan,DataType,nformat : integer) : word;
var
 asize   : longword;
 datalength : longword;
 padsize : longword;
 DataPtr : PByte;
 F       : File;
 bitsize    : integer;
begin
 CGSetLan(mc,Lan);
 CGSetValueFormat(mc,nFormat);
 {$I-}
 Assign(F,filename);
 Reset(F,1);
 DataLength:=FileSize(F);
 bitsize:=GetBitSize(datatype);
 Case bitsize of bitsize8:begin
                      asize:=DataLength;  //byte
                      padsize:=DataLength;
                    end;
                  bitsize16:begin
                      asize:=(Datalength+1) div 2;
                      padsize:=asize*2;
                    end;
                  bitsize32:begin
                      asize:=(DataLength+3) div 4;
                      padsize:=asize*4;
                    end;
 end;
 CGSetValuesTotal(mc,asize);

 GetMem(DataPtr,padsize);
 if bitsize = bitsize16 then
 begin
    (DataPtr+padsize-1)^:=0;
 end
 else if bitsize=bitsize32 then
 begin
     (DataPtr+padsize-1)^:=0;
     (DataPtr+padsize-2)^:=0;
     (DataPtr+padsize-3)^:=0;
 end;

 if DataPtr<>NIL then
 begin
   Blockread(F,DataPtr^,DataLength);
   ConvertToCode( mc,aname,DataPtr,asize,Lan,DataType,BitSize);

   FreeMem(DataPtr,padsize);
 end;
 close(F);
 {$I+}
  result:=IORESULT;
end;

end.

