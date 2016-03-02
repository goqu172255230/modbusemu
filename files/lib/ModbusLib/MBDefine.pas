unit MBDefine;

{$mode objfpc}{$H+}

interface

uses Classes, MBBitsClasses;

type

  TModbusTypeEnum = (mtRTU,mtTCP);
  TModbusTypeNames = array [TModbusTypeEnum] of String;

resourcestring

  rsModbusProtocolTypeRTU = 'Протокол Modbus RTU';
  rsModbusProtocolTypeTCP = 'Протокол Modbus TCP';
  rsModbusDeviceTypeRTU   = 'Устройство Modbus RTU';
  rsModbusDeviceTypeTCP   = 'Устройство Modbus TCP';

const

  ModbusTypeNames         : TModbusTypeNames = ('RTU','TCP');
  ModbusTypeProtocolNames : TModbusTypeNames = (rsModbusProtocolTypeRTU,rsModbusProtocolTypeTCP);
  ModbusTypeDeviceNames   : TModbusTypeNames = (rsModbusDeviceTypeRTU,rsModbusDeviceTypeTCP);

type

  TRegMBTypes = (rgDiscrete=0,rgCoils=1,rgInput=3,rgHolding=4,rgNone=5);
  TRegTypes = (rtSimpleWord,  // весь регистр рассматривается как единое целое
               rtWord,        // весь регистр рассматривается как единое целое + представление в виде бит
               rtWordByte,    // регистр содержит два независимых байта информации каждый из них представлен в виде набора бит
               rtBit          // битовый регистр
               );
  TRegViewTypes = (rvtBit,                // регистр битовый
                   rvtDWAnalog,           // регистр размером 16 бит, содержащий аналоговое значение
                   rvtDWBits,             // регистр размером 16 бит, содержащий набор из 16 флагов состояний
                   rvtBTLBBitHBAnalog,    // регистр размером 16 бит, каждый байт которого является самостоятельной еденицей, LB младший байт - набор 8 флагов, HB старший байт - аналоговое значение
                   rvtBTLBAnalogHBBit,    // регистр размером 16 бит, каждый байт которого является самостоятельной еденицей, LB младший байт - аналоговое значение, HB старший байт - набор из 8-ми флагов
                   rvtBTLBBitHBBit,       // регистр размером 16 бит, каждый байт которого является самостоятельной еденицей, LB младший байт - набор из 8-ми флагов, HB старший байт - набор из 8-ми флагов
                   rvtBTLBAnalogHBAnalog  // регистр размером 16 битв, каждый байт которого является самостоятельной еденицей, LB младший байт - аналоговое значение, HB старший байт - аналоговое значение
                   );

  TBuilderTypeEnum = (btUnknown,btMBRTU,btMBASCII,btMBTCP);
  TReaderTypeEnum = (rtUnknown,rtMBRTU,rtMBASCII,rtMBTCP);

  TDeviceRangeItem = record
   RegType  : TRegMBTypes;
   RangeID  : String;
   StartReg : Word;
   Quantity : Word;
  end;

  TDeviceRangeArray = array of TDeviceRangeItem;

  TRegBit = TWordBit;        // идентификаторы бит
  TRegBits = set of TRegBit; // коллекция идентификаторов бит

  TBitRegsValues   = array of Boolean;
  TWordRegsValues  = array of Word;
  TRegAddressArray = TWordRegsValues;

  TBitRegsValueRange  = array of TBitRegsValues;
  TWordRegsValueRange = array of TWordRegsValues;

  TMBFunctionsEnum = (fnNon,fn01,fn02,fn03,fn04,fn05,fn06,fn07,fn08,fn11 = 11,
                      fn12 = 12,fn15 = 15,fn16 = 16,fn17 = 17, fn20 = 20,
                      fn21 = 21,fn22 = 22,fn23 = 23,fn24 = 24, fn43_13 = 56,
                      fn43_14 = 57, fn72 = 72, fn110 = 110);

  TMBTCPFunctionEnum = (fnTNon, fnT01, fnT02, fnT03, fnT04, fnT05 , fnT06,
                        fnT15 = 15, fnT16 = 16, fnT20 = 20, fnT21 = 21,
                        fnT22 = 22, fnT23 = 23, fnT24 = 24, fnT43_13 = 56,
                        fnT43_14 = 57, fnT72 = 72, fnT110 = 110);

  TMBFunctionsEnumSimple = (sfnNon,sfn01,sfn02,sfn03,sfn04,sfn05,sfn06,sfn07,sfn08,sfn11,
                            sfn12,sfn15,sfn16,sfn17,sfn20,sfn21,sfn22,sfn23,sfn24,sfn43_13,
                            sfn43_14,sfn72,sfn110);

  TMBTCPFunctionEnumSimple = (sfnTNon,sfnT01,sfnT02,sfnT03,sfnT04,sfnT05,sfnT06,
                              sfnT15,sfnT16,sfnT20,sfnT21,sfnT22,sfnT23,sfnT24,sfnT43_13,
                              sfnT43_14,sfnT72,sfnT110);

  TMBFunctionsSet = set of TMBFunctionsEnum;
  TMBTCPFunctionsSet = set of TMBTCPFunctionEnum;

  TMBFunctionsSimpleSet = set of TMBFunctionsEnumSimple;
  TMBTCPFunctionsSimpleSet = set of TMBTCPFunctionEnumSimple;

const
  MAXWORD        = 65535;
  MBRTUMinDevNum = 1;
  MBRTUMaxDevNum = 247;
  MBTCPMinDevNum = 0;
  MBTCPMaxDevNum = 255;
  MBFunctionsNameRU : array [TMBFunctionsEnumSimple] of String = ('Функция ','Функция 1','Функция 2','Функция 3',
                                                            'Функция 4','Функция 5','Функция 6','Функция 7',
                                                            'Функция 8','Функция 11','Функция 12','Функция 15',
                                                            'Функция 16','Функция 17','Функция 20','Функция 21',
                                                            'Функция 22','Функция 23','Функция 24','Функция 43/13',
                                                            'Функция 43/14','Функция 72','Функция 110');

  MBRTUFunctionsSet : TMBFunctionsSet = [fnNon, fn01, fn02, fn03, fn04, fn05,
                                         fn06, fn07, fn08, fn11, fn12, fn15,
                                         fn16, fn17, fn20, fn21, fn22, fn23,
                                         fn24, fn43_13, fn43_14, fn72, fn110];

  MBTCPFunctionsSet : TMBTCPFunctionsSet = [fnTNon, fnT01, fnT02, fnT03, fnT04,
                                            fnT05, fnT06, fnT15, fnT16, fnT20,
                                            fnT21, fnT22, fnT23, fnT24, fnT43_13,
                                            fnT43_14, fnT72, fnT110];

type

  TReadPacketEventType = (rpError, rpEndRead, rpStartRead);

  TMBSubrangeStateOfRange = (ssrIsInRange, ssrNotIncluded, ssrRangesAreEqual, ssrOutsideLeftEdge, ssrOutsideRightEdge, ssrLargerRange);
  TMBSubrangeStateOfRangeSet = set of TMBSubrangeStateOfRange;
  TMBSubrangeStateOfRangeArray = array of TMBSubrangeStateOfRange;

  PMBRegistersRange = ^TMBRegistersRange;
  TMBRegistersRange = packed record
   StartAddres : Cardinal;
   Count       : Word;
  end;

  TMBRegistersRangeArray = array of TMBRegistersRange;

  PMBRegistersRangeClassic = ^TMBRegistersRangeClassic;
  TMBRegistersRangeClassic = packed record
   case Integer of
   0 : (StartAddres : Word;
        Count       : Word);
   1 : (AllInOne : Cardinal);      
  end;

  TMBRegistersRangeClassicArray = array of TMBRegistersRangeClassic;

  PMBDataField = ^TMBDataField;
  TMBDataField = array of Byte;

  PMBCRCField = ^TMBCRCField;
  TMBCRCField  = Word;

  TMBSliceOfDeviceStatus = packed record
   SliceTime     : TDateTime;
   DeviceNum     : Byte;
   Error         : Cardinal;
   ErrorTime     : TDateTime;
   DiscretRanges : TMBRegistersRangeClassicArray;
   CoilRanges    : TMBRegistersRangeClassicArray;
   InputRanges   : TMBRegistersRangeClassicArray;
   HoldingRanges : TMBRegistersRangeClassicArray;
   DiscretRegVal : TBitRegsValueRange;
   CoilRegVal    : TBitRegsValueRange;
   InputRegVal   : TWordRegsValueRange;
   HoldingRegVal : TWordRegsValueRange;
  end;

  PIP4AddrRecord = ^TIP4AddrRecord;
  TIP4AddrRecord = packed record
   case integer of
       0: (Byte1 : Byte;
           Byte2 : Byte;
           Byte3 : Byte;
           Byte4 : Byte);
       1: (Addr : Cardinal);
  end;

  TSignedType = (stNone,stSmall,stShort,stInt);

  PInteger32 = ^TInteger32;
  TInteger32 = packed record
   case integer of
       0: (Bytes : array [0..3] of Byte);
{           Byte1 : Byte;
           Byte2 : Byte;
           Byte3 : Byte;
           Byte4 : Byte);}
       1: (Words : array [0..1] of Word);
{           Word1 : Word;
           Word2 : Word);}
       2: (Value : Integer);
  end;

  PCardinal = ^TCardinal;
  TCardinal = packed record
   case integer of
       0: (Bytes : array [0..3] of Byte);
{           Byte1 : Byte;
           Byte2 : Byte;
           Byte3 : Byte;
           Byte4 : Byte);}
       1: (Words : array [0..1] of Word);
{           Word1 : Word;
           Word2 : Word);}
       2: (Value : Cardinal);
  end;

  PTCounter64 = ^TCounter64;
  TCounter64 = packed record
   case integer of
       0: (Bytes : array [0..7] of Byte);
{           Byte1 : Byte;
           Byte2 : Byte;
           Byte3 : Byte;
           Byte4 : Byte;
           Byte5 : Byte;
           Byte6 : Byte;
           Byte7 : Byte;
           Byte8 : Byte);}
       1: (Words : array [0..3] of Word);
{           Word1 : Word;
           Word2 : Word;
           Word3 : Word;
           Word4 : Word);}
       2: (Cardinals : array [0..1] of Cardinal);
{           Cardinal1 : Cardinal;
           Cardinal2 : Cardinal);}
       3: (Value : QWord);
  end;

  PTCP4AddrInfo = ^TTCP4AddrInfo;
  TTCP4AddrInfo = packed record
   IP   : TIP4AddrRecord;
   Port : Word;
  end;

  PPollingTimeParam = ^TPollingTimeParam;
  TPollingTimeParam = packed record
   Interval          : Cardinal;
   TimeOut           : Cardinal;
   ReconnectInterval : Cardinal;
  end;

  PMBTCPSlavePollingParam = ^TMBTCPSlavePollingParam;
  TMBTCPSlavePollingParam = packed record
   SlaveAddr        : TTCP4AddrInfo;
   PoolingTimeParam : TPollingTimeParam;
  end;

  PMBPollingItem = ^TMBPollingItem;
  TMBPollingItem = packed record
   DevNumber : Byte;
   FunctNum  : Byte;
   StartAddr : Word;
   Quantity  : Word;
  end;

  PMBTCPSlavePollingItem = ^TMBTCPSlavePollingItem;
  TMBTCPSlavePollingItem = packed record
   ObjectID    : String; // идентификатор объекта
   ID          : String; // идентификатор устройства
   RangeID     : String; // идентификатор интервала переменных устройства
   Caption     : String;
   LastError   : Cardinal;
   SlaveParams : TMBTCPSlavePollingParam;
   Item        : TMBPollingItem;
  end;

  TMBDispEventEnum = (mdeeConnect,mdeeDisconnect,mdeeSend,mdeeReceive,mdeeSocketError,mdeeMBError);

  TPollingError = procedure(AItemProp : TMBTCPSlavePollingItem) of Object;
  TPollingEvent = procedure(AItemProp : TMBTCPSlavePollingItem; EvType : TMBDispEventEnum) of Object;

  function GetMBRangeTypeAsString(AType : TRegMBTypes):String;
  function GetSignedTypeFromStr(AType : AnsiString): TSignedType;
  function GetStrFromSignedType(AType : TSignedType): AnsiString;

  function GetRangeTypeAsStrID(AType : TRegMBTypes):String;
  function GetRangeTypeFromStrID(AType : String):TRegMBTypes;

  function  CopyDataArray(ASource : TRegAddressArray; AOffset : Cardinal; ACount : Integer = -1) : TRegAddressArray;
  procedure AddArrayToArray(ADest,ASource : TRegAddressArray; ANotDuplicate : Boolean = True);
  function  GetAddressArrayAsString(AArray : TRegAddressArray;AIsHex : Boolean = True): String;
  function  IsValueInArray(AArray : TRegAddressArray; AValue : Word) : Boolean;
  procedure AddValueToAllItems(AArray : TRegAddressArray; AValue : Word);
  procedure AddArrayToArrayPlusStart(ADest : TRegAddressArray; const ASource : TRegAddressArray; AStartAddr : Word = 0; ANotDuplicate : Boolean = True);

  function GetFunctionSetAsString(ASet : TMBFunctionsSet) : String;
  function GetFunctionSetFromString(ASetStr : String) : TMBFunctionsSet;

  function  GetBuffAsStringHexMB(Buff : Pointer; aLen : Integer; Delimeter : String = ':') : String;

implementation

uses sysutils;

function  GetBuffAsStringHexMB(Buff : Pointer; aLen : Integer; Delimeter : String = ':') : String;
var i : Integer;
    TempByte : PByte;
begin
 Result := '';
 if not Assigned(Buff) then Exit;
 TempByte := Buff;
 for i := 0 to aLen-1 do
  begin
   if Result = '' then Result := Result + IntToHex(TempByte^,2)
    else Result :=Format('%s%s%s',[Result,Delimeter,IntToHex(TempByte^,2)]);
   Inc(TempByte);
  end;
end;

function GetFunctionSetFromString(ASetStr : String) : TMBFunctionsSet;
var TempStrList : TStringList;
    TempStr  : String;
    TemVal   : Integer;
    i,Count  : Integer;
    TempFnID : TMBFunctionsEnum;
begin
 Result := [];
 if ASetStr = '' then Exit;
 TempStr := StringReplace(ASetStr,',',#10,[rfIgnoreCase,rfReplaceAll]);
 TempStrList := TStringList.Create;
 try
  TempStrList.Text := TempStr;
  Count := TempStrList.Count-1;
  for i := 0 to Count do
   begin
    try
     TemVal := StrToInt(TempStrList.Strings[i]);
    except
     Continue;
    end;
    case TemVal of
     1,2,3,4,5,6,7,8,11,
     12,15,16,17,20,21,
     22,23,24,56,57,72,110 : begin
                              TempFnID := TMBFunctionsEnum(TemVal);
                              Result := Result + [TempFnID];
                             end;
    else
     Continue;
    end;
   end;
 finally
  FreeAndNil(TempStrList);
 end;
end;

function GetFunctionSetAsString(ASet : TMBFunctionsSet): String;
begin
  Result := '';
  if ASet = [] then Exit;

  if fn01 in ASet then Result := Format('%d,',[Integer(fn01)]);

  if fn02 in ASet then
   if Result = '' then Result := Format('%d,',[Integer(fn02)])
    else Result := Format('%s%d,',[Result,Integer(fn02)]);

  if fn03 in ASet then
   if Result = '' then Result := Format('%d,',[Integer(fn03)])
    else Result := Format('%s%d,',[Result,Integer(fn03)]);

  if fn04 in ASet then
   if Result = '' then Result := Format('%d,',[Integer(fn04)])
    else Result := Format('%s%d,',[Result,Integer(fn04)]);

  if fn05 in ASet then
   if Result = '' then Result := Format('%d,',[Integer(fn05)])
    else Result := Format('%s%d,',[Result,Integer(fn05)]);

  if fn06 in ASet then
   if Result = '' then Result := Format('%d,',[Integer(fn06)])
    else Result := Format('%s%d,',[Result,Integer(fn06)]);

  if fn07 in ASet then
   if Result = '' then Result := Format('%d,',[Integer(fn07)])
    else Result := Format('%s%d,',[Result,Integer(fn07)]);

  if fn08 in ASet then
   if Result = '' then Result := Format('%d,',[Integer(fn08)])
    else Result := Format('%s%d,',[Result,Integer(fn08)]);

  if fn11 in ASet then
   if Result = '' then Result := Format('%d,',[Integer(fn11)])
    else Result := Format('%s%d,',[Result,Integer(fn11)]);

  if fn12 in ASet then
   if Result = '' then Result := Format('%d,',[Integer(fn12)])
    else Result := Format('%s%d,',[Result,Integer(fn12)]);

  if fn15 in ASet then
   if Result = '' then Result := Format('%d,',[Integer(fn15)])
    else Result := Format('%s%d,',[Result,Integer(fn15)]);

  if fn16 in ASet then
   if Result = '' then Result := Format('%d,',[Integer(fn16)])
    else Result := Format('%s%d,',[Result,Integer(fn16)]);

  if fn17 in ASet then
   if Result = '' then Result := Format('%d,',[Integer(fn17)])
    else Result := Format('%s%d,',[Result,Integer(fn17)]);

  if fn20 in ASet then
   if Result = '' then Result := Format('%d,',[Integer(fn20)])
    else Result := Format('%s%d,',[Result,Integer(fn20)]);

  if fn21 in ASet then
   if Result = '' then Result := Format('%d,',[Integer(fn21)])
    else Result := Format('%s%d,',[Result,Integer(fn21)]);

  if fn22 in ASet then
   if Result = '' then Result := Format('%d,',[Integer(fn22)])
    else Result := Format('%s%d,',[Result,Integer(fn22)]);

  if fn23 in ASet then
   if Result = '' then Result := Format('%d,',[Integer(fn23)])
    else Result := Format('%s%d,',[Result,Integer(fn23)]);

  if fn24 in ASet then
   if Result = '' then Result := Format('%d,',[Integer(fn24)])
    else Result := Format('%s%d,',[Result,Integer(fn24)]);

  if fn43_13 in ASet then
   if Result = '' then Result := Format('%d,',[Integer(fn43_13)])
    else Result := Format('%s%d,',[Result,Integer(fn43_13)]);

  if fn43_14 in ASet then
   if Result = '' then Result := Format('%d,',[Integer(fn43_14)])
    else Result := Format('%s%d,',[Result,Integer(fn43_14)]);

  if fn72 in ASet then
   if Result = '' then Result := Format('%d,',[Integer(fn72)])
    else Result := Format('%s%d,',[Result,Integer(fn02)]);

  if fn110 in ASet then
   if Result = '' then Result := Format('%d',[Integer(fn72)])
    else Result := Format('%s%d',[Result,Integer(fn02)]);

  if Result[Length(Result)] = ',' then SetLength(Result,Length(Result)-1);
end;

procedure AddArrayToArrayPlusStart(ADest : TRegAddressArray; const ASource : TRegAddressArray; AStartAddr : Word = 0; ANotDuplicate : Boolean = True);
var NewLen, i : Integer;
begin
  NewLen := Length(ASource);
  for i := 0 to NewLen-1 do
   begin
    if ANotDuplicate then
     if IsValueInArray(ADest,ASource[i]+AStartAddr) then Continue;
    SetLength(ADest,Length(ADest)+1);
    ADest[Length(ADest)-1] := ASource[i]+AStartAddr;
   end;
end;

procedure AddValueToAllItems(AArray : TRegAddressArray; AValue : Word);
var i : Integer;
begin
  for i := Low(AArray) to High(AArray) do AArray[i] := AArray[i]+AValue;
end;

function  IsValueInArray(AArray : TRegAddressArray; AValue : Word) : Boolean;
var i : Integer;
begin
  Result := False;
  for i := Low(AArray) to High(AArray) do
   if AArray[i] = AValue then
    begin
     Result := True;
     Break;
    end;
end;

function  GetAddressArrayAsString(AArray : TRegAddressArray;AIsHex : Boolean = True): String;
var i, TempCount : Integer;
begin
  Result := '';
  if Length(AArray) = 0 then Exit;
  TempCount := Length(AArray);
  Result := Format('(%u):',[TempCount]);
  if AIsHex then
   begin
    for i := 0 to TempCount - 1 do Result := Format('%s%s:',[Result,IntToHex(AArray[i],4)])
   end
  else
   begin
    for i := 0 to TempCount - 1 do Result := Format('%s%d:',[Result,AArray[i]])
   end;
end;

procedure AddArrayToArray(ADest,ASource : TRegAddressArray; ANotDuplicate : Boolean = True);
var NewLen,{OldLen,}i : Integer;
begin
//  OldLen := Length(ADest);
  NewLen := {OldLen + }Length(ASource);
//  SetLength(ADest,NewLen);
  for i := 0{OldLen} to NewLen-1 do
   begin
    if ANotDuplicate then
     if IsValueInArray(ADest,ASource[i]) then Continue;
    SetLength(ADest,Length(ADest)+1);
    ADest[Length(ADest)-1] := ASource[i{-OldLen}];
   end;
end;

function  CopyDataArray(ASource : TRegAddressArray; AOffset : Cardinal; ACount : Integer = -1) : TRegAddressArray;
var TempLen : Cardinal;
    TempCount, i : Integer;
begin
  SetLength(Result,0);
  TempLen := Length(ASource);
  if  (TempLen = 0) or (AOffset > (TempLen -1)) or ((AOffset + ACount) > (TempLen -1)) or (ACount < -1) or (ACount = 0)  then Exit;
  if ACount > 0 then
   begin
    SetLength(Result,ACount);
    TempCount := ACount-1;
   end
  else
   begin
    SetLength(Result,(TempLen - AOffset));
    TempCount := TempLen - AOffset -1;
   end;
  for i := 0 to TempCount do Result[i] := ASource[AOffset+Cardinal(i)];
end;

function GetRangeTypeFromStrID(AType : String):TRegMBTypes;
begin
  if SameText(AType,'Dis') then Result := rgDiscrete
   else
     if SameText(AType,'Coi') then Result := rgCoils
      else
        if SameText(AType,'Inp') then Result := rgInput
          else
            if SameText(AType,'Hol') then Result := rgHolding
             else
               Result := rgNone;
end;

function GetRangeTypeAsStrID(AType : TRegMBTypes):String;
begin
  Result := '';
  case AType of
   rgDiscrete : Result := 'Dis';
   rgCoils    : Result := 'Coi';
   rgInput    : Result := 'Inp';
   rgHolding  : Result := 'Hol';
   rgNone     : Result := 'None';
  end;
end;

function GetStrFromSignedType(AType : TSignedType): AnsiString;
begin
  Result := '';
  case AType of
   stSmall : Result := 'sml';
   stShort : Result := 'sht';
   stInt   : Result := 'int';
   stNone  : Result := 'none';
  end;
end;

function GetSignedTypeFromStr(AType : AnsiString): TSignedType;
begin
  if SameText(AType,'sml') then Result := stSmall
   else
     if SameText(AType,'sht') then Result := stShort
      else
        if SameText(AType,'int') then Result := stInt
          else Result := stNone;
end;

function GetMBRangeTypeAsString(AType : TRegMBTypes):String;
begin
  Result := '';
  case AType of
   rgDiscrete : Result := 'Discrete';
   rgCoils    : Result := 'Coils';
   rgInput    : Result := 'Input';
   rgHolding  : Result := 'Holding';
   rgNone     : Result := 'None';
  end;
end;

end.
