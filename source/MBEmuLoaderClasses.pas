unit MBEmuLoaderClasses;

{$mode objfpc}{$H+}

interface

uses Classes, SysUtils, syncobjs,
     MBDeviceClasses,
     DeviceView,
     LoggerItf,
     ChennelRSClasses, ChennelTCPClasses,
     NativeXml;

type

  { TMBEmuLoader }

  TMBEmuLoader = class(TObjectLogged)
   private
    FDevList         : TStrings;
    FDevArray        : PDeviceArray;
    FDevFormArray    : PDevFormArray;
    FChannelList     : TStrings;
    FCSection        : TCriticalSection;
    FOnDevChangeProc : TNotifyEvent;
    procedure SaveChannels(AChannelsNode : TXmlNode);
    procedure SaveChannelRS(AChannelsNode : TXmlNode;AChannel : TChennelRS; ADescr : String);
    procedure SaveChannelTCP(AChannelsNode : TXmlNode;AChannel : TChennelTCP; ADescr : String);

    procedure SaveDevices(ADevicesNode : TXmlNode);
    procedure SaveDevice(ADevicesNode : TXmlNode; ADevice : TMBDevice);

    procedure LoadDevices(ADevicesNode : TXmlNode);
    procedure LoadChannels(AChannelsNode : TXmlNode);
   public
    constructor Create(ADevList         : TStrings;
                       ADevArray        : PDeviceArray;
                       ADevFormArray    : PDevFormArray;
                       AChannelList     : TStrings;
                       ACSection        : TCriticalSection;
                       AOnDevChangeProc : TNotifyEvent); virtual;
    destructor  Destroy; override;

    procedure SaveConfig(AFileName : String);
    procedure LoadConfig(AFileName : String);
  end;

implementation

uses MBDefine,
     ExceptionsTypes,
     {$IFDEF WINDOWS}
     LazFileUtils,
     LazUTF8,
     {$ENDIF}
     ModbusEmuResStr,
     MBEmuXMLConst,
     COMPortParamTypes;

{ TMBEmuLoader }

constructor TMBEmuLoader.Create(ADevList         : TStrings;
                                ADevArray        : PDeviceArray;
                                ADevFormArray    : PDevFormArray;
                                AChannelList     : TStrings;
                                ACSection        : TCriticalSection;
                                AOnDevChangeProc : TNotifyEvent);
begin
  FDevList         := ADevList;
  FDevArray        := ADevArray;
  FDevFormArray    := ADevFormArray;
  FChannelList     := AChannelList;
  FCSection        := ACSection;
  FOnDevChangeProc := AOnDevChangeProc;
end;

destructor TMBEmuLoader.Destroy;
begin
  inherited Destroy;
end;

procedure TMBEmuLoader.LoadConfig(AFileName : String);
var TempDoc  : TNativeXml;
    TempNode : TXmlNode;
begin
  if AFileName = '' then raise Exception.Create(rsLoader3);
  if not {$IFDEF UNIX}FileExists{$ELSE}FileExistsUTF8{$ENDIF}(AFileName) then raise Exception.CreateFmt(rsLoader4, [AFileName]);

  TempDoc := TNativeXml.Create(nil);
  TempDoc.ExternalEncoding := seUTF8;
  try
   TempDoc.LoadFromFile({$IFDEF UNIX}AFileName{$ELSE}UTF8ToSys(AFileName){$ENDIF});
   if not SameText(csNodeRoot,TempDoc.Root.Name) then  raise Exception.CreateFmt(rsLoader5,[TempDoc.Root.Name,csNodeRoot]);

   TempNode := TempDoc.Root.NodeByName(csNodeChannels);
   if Assigned(TempNode) then LoadChannels(TempNode)
    else SendLogMessage(llInfo,rsLoader6,Format(rsLoader7,[csNodeChannels,AFileName]));

   TempNode := TempDoc.Root.NodeByName(csNodeDevices);
   if Assigned(TempNode) then LoadDevices(TempNode)
    else SendLogMessage(llInfo,rsLoader6,Format(rsLoader7,[csNodeDevices,AFileName]));;

   SendLogMessage(llInfo,rsLoader6,Format(rsLoader8,[AFileName]));
  finally
   FreeAndNil(TempDoc);
  end;
end;

procedure TMBEmuLoader.LoadDevices(ADevicesNode : TXmlNode);
var i, Count, i1, Count1 : Integer;
    TempNode, TempNodeRegs, TempNodeReg: TXmlNode;
    TempAttr : TsdAttribute;
    TempDevAddr : Byte;
    TempDev  : TMBDevice;
    TempDefCoil,TempDefDiscret : Boolean;
    TempDefHolding,TempDefInput : Word;
    TempFuncStr : String;
    TempAddr, TempWordVal : Word;
    TempBoolVal : Boolean;
    TempDescr : String;
begin
  Count := ADevicesNode.NodeCount-1;
  for i := 0 to Count do
   begin
    TempNode := ADevicesNode.Nodes[i];
    if TempNode.ElementType <> xeElement then Continue;
    if not SameText(TempNode.Name,csNodeDevice) then Continue;

    TempDefCoil    := False;
    TempDefDiscret := False;
    TempDefHolding := 0;
    TempDefInput   := 0;
    TempFuncStr    := '';

    TempAttr := TempNode.AttributeByName[csAttrAddres];
    if not Assigned(TempAttr) then raise EXmlAttribute.Create(ClassName,TempNode.Name,csAttrAddres);
    TempDevAddr := Byte(TempAttr.ValueAsInteger);
    // если устройство уже существует, то не подгружаем из конфигурации
    if Assigned(FDevArray^[TempDevAddr]) then Continue;

    TempAttr := TempNode.AttributeByName[csAttrDefCoil];
    if Assigned(TempAttr) then TempDefCoil := TempAttr.ValueAsBool;

    TempAttr := TempNode.AttributeByName[csAttrDefDiscr];
    if Assigned(TempAttr) then TempDefDiscret := TempAttr.ValueAsBool;

    TempAttr := TempNode.AttributeByName[csAttrDefHold];
    if Assigned(TempAttr) then TempDefHolding := TempAttr.ValueAsInteger;

    TempAttr := TempNode.AttributeByName[csAttrDefInput];
    if Assigned(TempAttr) then TempDefInput := TempAttr.ValueAsInteger;

    TempAttr := TempNode.AttributeByName[csAttrFunction];
    if Assigned(TempAttr) then TempFuncStr := TempAttr.Value;

    SendLogMessage(llDebug,'TMBEmuLoader.LoadDevices','Получили атрибуты');


    TempDev := TMBDevice.Create(nil);

    TempDev.DeviceNum := TempDevAddr;

    TempDev.DefCoil    := TempDefCoil;
    TempDev.DefDiscret := TempDefDiscret;
    TempDev.DefHolding := TempDefHolding;
    TempDev.DefInput   := TempDefInput;

    TempDev.DeviceFunctions := TempDev.DeviceFunctions + GetFunctionSetFromString(TempFuncStr);

    SendLogMessage(llDebug,'TMBEmuLoader.LoadDevices',GetFunctionSetAsString(TempDev.DeviceFunctions));

    if fn01 in TempDev.DeviceFunctions then TempDev.AddRegisters(rgCoils,0,65535);
    if fn02 in TempDev.DeviceFunctions then TempDev.AddRegisters(rgDiscrete,0,65535);
    if fn03 in TempDev.DeviceFunctions then TempDev.AddRegisters(rgHolding,0,65535);
    if fn04 in TempDev.DeviceFunctions then TempDev.AddRegisters(rgInput,0,65535);
    if fn05 in TempDev.DeviceFunctions then
     if not (fn01 in TempDev.DeviceFunctions) then
      begin
       TempDev.DeviceFunctions := TempDev.DeviceFunctions+[fn01];
       TempDev.AddRegisters(rgCoils,0,65535);
      end;
    if fn06 in TempDev.DeviceFunctions then
     if not (fn03 in TempDev.DeviceFunctions) then
      begin
       TempDev.DeviceFunctions := TempDev.DeviceFunctions+[fn03];
       TempDev.AddRegisters(rgHolding,0,65535);
      end;
    if fn15 in TempDev.DeviceFunctions then
     if not (fn01 in TempDev.DeviceFunctions) then
      begin
       TempDev.DeviceFunctions := TempDev.DeviceFunctions+[fn01];
       TempDev.AddRegisters(rgCoils,0,65535);
      end;
    if fn16 in TempDev.DeviceFunctions then
     if not (fn03 in TempDev.DeviceFunctions) then
      begin
       TempDev.DeviceFunctions := TempDev.DeviceFunctions+[fn03];
       TempDev.AddRegisters(rgHolding,0,65535);
      end;

    SendLogMessage(llDebug,'TMBEmuLoader.LoadDevices','Создали устройство');

    TempDev.InitializeDevice;

    SendLogMessage(llDebug,'TMBEmuLoader.LoadDevices','Инициализировали устройство');

    FDevArray^[TempDevAddr] := TempDev;

    FDevFormArray^[TempDevAddr] := TfrmDeviceView.Create(nil);
    FDevFormArray^[TempDevAddr].Logger      := Logger;
    FDevFormArray^[TempDevAddr].CSection    := FCSection;
    FDevFormArray^[TempDevAddr].Device      := TempDev;
    FDevFormArray^[TempDevAddr].OnDevChange := FOnDevChangeProc;

    SendLogMessage(llDebug,'TMBEmuLoader.LoadDevices','Создали форму');

    FDevList.AddObject(Format(rsDevAdd2,[TempDevAddr]),TempDev);

    SendLogMessage(llDebug,'TMBEmuLoader.LoadDevices','Добавили форму в список');

    TempDev.BeginPacketUpdate;
    try

     SendLogMessage(llDebug,'TMBEmuLoader.LoadDevices','1');

     TempNodeRegs := TempNode.NodeByName(csNodeCoils);
     if Assigned(TempNodeRegs) then
      begin
       Count1 := TempNodeRegs.NodeCount-1;
       for i1 := 0 to Count1 do
        begin
         TempNodeReg := TempNodeRegs.Nodes[i1];
         if TempNodeReg.ElementType <> xeElement then Continue;
         if not SameText(TempNodeReg.Name,csNodeReg) then Continue;

         TempAddr    := 0;
         TempBoolVal := False;
         TempDescr   := '';

         TempAttr := TempNodeReg.AttributeByName[csAttrAddres];
         if not Assigned(TempAttr) then raise EXmlAttribute.Create(ClassName,TempNodeReg.Name,csAttrAddres);
         TempAddr := Word(TempAttr.ValueAsInteger);

         TempAttr := TempNodeReg.AttributeByName[csAttrValue];
         if Assigned(TempAttr) then TempBoolVal := TempAttr.ValueAsBool;

         TempAttr := TempNodeReg.AttributeByName[csAttrDescript];
         if Assigned(TempAttr) then TempDescr := TempAttr.Value;

         SendLogMessage(llDebug,'TMBEmuLoader.LoadDevices',Format('Coil. Установили регистр %d',[TempAddr]));

         TempDev.Coils[TempAddr].Value       := TempBoolVal;
         TempDev.Coils[TempAddr].Description := TempDescr;
        end;
      end
     else SendLogMessage(llDebug,'TMBEmuLoader.LoadDevices',Format('Coil. не нашли %s',[csNodeCoils]));

     SendLogMessage(llDebug,'TMBEmuLoader.LoadDevices','2');

     TempNodeRegs := TempNode.NodeByName(csNodeDiscr);
     if Assigned(TempNodeRegs) then
      begin
       Count1 := TempNodeRegs.NodeCount-1;
       for i1 := 0 to Count1 do
        begin
         TempNodeReg := TempNodeRegs.Nodes[i1];
         if TempNodeReg.ElementType <> xeElement then Continue;
         if not SameText(TempNodeReg.Name,csNodeReg) then Continue;

         TempAddr    := 0;
         TempBoolVal := False;
         TempDescr   := '';

         TempAttr := TempNodeReg.AttributeByName[csAttrAddres];
         if not Assigned(TempAttr) then raise EXmlAttribute.Create(ClassName,TempNodeReg.Name,csAttrAddres);
         TempAddr := Word(TempAttr.ValueAsInteger);

         TempAttr := TempNodeReg.AttributeByName[csAttrValue];
         if Assigned(TempAttr) then TempBoolVal := TempAttr.ValueAsBool;

         TempAttr := TempNodeReg.AttributeByName[csAttrDescript];
         if Assigned(TempAttr) then TempDescr := TempAttr.Value;

         SendLogMessage(llDebug,'TMBEmuLoader.LoadDevices',Format('Discrets. Установили регистр %d',[TempAddr]));

         TempDev.Discrets[TempAddr].ServerSideSetValue(TempBoolVal);
         TempDev.Discrets[TempAddr].Description := TempDescr;
        end;
      end
     else SendLogMessage(llDebug,'TMBEmuLoader.LoadDevices',Format('Discrets. не нашли %s',[csNodeDiscr]));

     SendLogMessage(llDebug,'TMBEmuLoader.LoadDevices','3');

     TempNodeRegs := TempNode.NodeByName(csNodeHold);
     if Assigned(TempNodeRegs) then
      begin
       Count1 := TempNodeRegs.NodeCount-1;
       for i1 := 0 to Count1 do
        begin
         TempNodeReg := TempNodeRegs.Nodes[i1];
         if TempNodeReg.ElementType <> xeElement then Continue;
         if not SameText(TempNodeReg.Name,csNodeReg) then Continue;

         TempAddr    := 0;
         TempWordVal := 0;
         TempDescr   := '';

         TempAttr := TempNodeReg.AttributeByName[csAttrAddres];
         if not Assigned(TempAttr) then raise EXmlAttribute.Create(ClassName,TempNodeReg.Name,csAttrAddres);
         TempAddr := Word(TempAttr.ValueAsInteger);

         TempAttr := TempNodeReg.AttributeByName[csAttrValue];
         if Assigned(TempAttr) then TempWordVal := Word(TempAttr.ValueAsInteger);

         TempAttr := TempNodeReg.AttributeByName[csAttrDescript];
         if Assigned(TempAttr) then TempDescr := TempAttr.Value;

         SendLogMessage(llDebug,'TMBEmuLoader.LoadDevices',Format('Holding. Установили регистр %d',[TempAddr]));

         TempDev.Holdings[TempAddr].Value       := TempWordVal;
         TempDev.Holdings[TempAddr].Description := TempDescr;
        end;
      end
     else SendLogMessage(llDebug,'TMBEmuLoader.LoadDevices',Format('Holding. не нашли %s',[csNodeHold]));

     SendLogMessage(llDebug,'TMBEmuLoader.LoadDevices','4');

     TempNodeRegs := TempNode.NodeByName(csNodeInp);
     if Assigned(TempNodeRegs) then
      begin
       Count1 := TempNodeRegs.NodeCount-1;
       for i1 := 0 to Count1 do
        begin
         TempNodeReg := TempNodeRegs.Nodes[i1];
         if TempNodeReg.ElementType <> xeElement then Continue;
         if not SameText(TempNodeReg.Name,csNodeReg) then Continue;

         TempAddr    := 0;
         TempWordVal := 0;
         TempDescr   := '';

         TempAttr := TempNodeReg.AttributeByName[csAttrAddres];
         if not Assigned(TempAttr) then raise EXmlAttribute.Create(ClassName,TempNodeReg.Name,csAttrAddres);
         TempAddr := Word(TempAttr.ValueAsInteger);

         TempAttr := TempNodeReg.AttributeByName[csAttrValue];
         if Assigned(TempAttr) then TempWordVal := Word(TempAttr.ValueAsInteger);

         TempAttr := TempNodeReg.AttributeByName[csAttrDescript];
         if Assigned(TempAttr) then TempDescr := TempAttr.Value;

         SendLogMessage(llDebug,'TMBEmuLoader.LoadDevices',Format('Input. Установили регистр %d',[TempAddr]));

         TempDev.Inputs[TempAddr].ServerSideSetValue(TempWordVal);
         TempDev.Inputs[TempAddr].Description := TempDescr;
        end;
      end
     else SendLogMessage(llDebug,'TMBEmuLoader.LoadDevices',Format('Input. не нашли %s',[csNodeInp]));

     SendLogMessage(llDebug,'TMBEmuLoader.LoadDevices','5');
    finally
     TempDev.EndPacketUpdate;
    end;
    SendLogMessage(llDebug,'TMBEmuLoader.LoadDevices','6');
   end;
end;

procedure TMBEmuLoader.LoadChannels(AChannelsNode : TXmlNode);
begin

end;

procedure TMBEmuLoader.SaveConfig(AFileName : String);
var TempDoc  : TNativeXml;
    TempNode : TXmlNode;
begin
  if AFileName = '' then raise Exception.Create(rsLoader1);
  TempDoc := TNativeXml.Create(nil);
  try
   TempDoc.ExternalEncoding := seUTF8;
   TempDoc.XmlFormat := xfReadable;
   TempDoc.Root.Name := csNodeRoot;

   TempNode := TempDoc.Root.NodeNew(csNodeChannels);
   SaveChannels(TempNode);

   TempNode := TempDoc.Root.NodeNew(csNodeDevices);
   SaveDevices(TempNode);

   TempDoc.SaveToFile({$IFDEF UNIX}AFileName{$ELSE}UTF8ToSys(AFileName){$ENDIF});
  finally
   FreeAndNil(TempDoc);
  end;
end;

procedure TMBEmuLoader.SaveChannels(AChannelsNode : TXmlNode);
var TempChannel : TObject;
    i, Count    : Integer;
begin
  Count := FChannelList.Count-1;
  for i := 0 to Count do
   begin
    TempChannel := FChannelList.Objects[i];
    if TempChannel.ClassType = TChennelRS then SaveChannelRS(AChannelsNode,TChennelRS(TempChannel),FChannelList.Strings[i]);
    if TempChannel.ClassType = TChennelTCP then SaveChannelTCP(AChannelsNode,TChennelTCP(TempChannel),FChannelList.Strings[i]);
   end;
end;

procedure TMBEmuLoader.SaveChannelRS(AChannelsNode : TXmlNode; AChannel : TChennelRS; ADescr : String);
var TempNode    : TXmlNode;
begin
  TempNode := AChannelsNode.NodeNew(csNodeChannel);
  TempNode.AttributeAdd(csAttrName,AChannel.Name);
  TempNode.AttributeAdd(csAttrType,csTypeRS);
  TempNode.AttributeAdd(csAttrDescr,ADescr);
  {$IFDEF UNIX}
  if AChannel.PortPrefix = pptLinux then TempNode.AttributeAdd(csAttrPref,cCOMPrefixPathLinux);
  if AChannel.PortPrefix = pptOther then
   begin
    TempNode.AttributeAdd(csAttrPref,cCOMPrefixPathLinuxOther);
    TempNode.AttributeAdd(csAttrPrefOther,AChannel.PortPrefixOther);
   end;
  {$ELSE}
   if AChannel.PortPrefix = pptWindows then TempNode.AttributeAdd(csAttrPref,cCOMPrefixPathWindows);
  {$ENDIF}
  TempNode.AttributeAdd(csAttrPort, IntToStr(AChannel.PortNum));
  TempNode.AttributeAdd(csAttrBauRate, GetBaudRateStrFromID(AChannel.BaudRate));
  TempNode.AttributeAdd(csAttrByteSize, ComPortDataBitsSymbol[AChannel.ByteSize]);
  TempNode.AttributeAdd(csAttrParity, GetParityIDStrFromValue(AChannel.Parity));
  TempNode.AttributeAdd(csAttrStopBit, GetStopBitsIDStrFromValue1(AChannel.StopBits));
end;

procedure TMBEmuLoader.SaveChannelTCP(AChannelsNode : TXmlNode; AChannel : TChennelTCP; ADescr : String);
var TempNode    : TXmlNode;
begin
  TempNode := AChannelsNode.NodeNew(csNodeChannel);
  TempNode.AttributeAdd(csAttrName,AChannel.Name);
  TempNode.AttributeAdd(csAttrType,csTypeTCP);
  TempNode.AttributeAdd(csAttrDescr,ADescr);
  TempNode.AttributeAdd(csAttrAddres,AChannel.BindAddress);
  TempNode.AttributeAdd(csAttrPort,IntToStr(AChannel.Port));
end;

procedure TMBEmuLoader.SaveDevices(ADevicesNode : TXmlNode);
var TempDevice : TMBDevice;
    i, Count   : Integer;
begin
  Count := 255;
  for i := 1 to Count do
   begin
    if not Assigned(FDevArray^[i]) then Continue;
    TempDevice := FDevArray^[i];
    SaveDevice(ADevicesNode,TempDevice);
   end;
end;

procedure TMBEmuLoader.SaveDevice(ADevicesNode : TXmlNode; ADevice : TMBDevice);
var NodeDev,NodeRegs, NodeReg : TXmlNode;
    TempDefCoil,TempDefDiscret : Boolean;
    TempDefHolding,TempDefInput : Word;
    TempFunc : String;
    i,Count : Integer;
begin
  NodeDev := ADevicesNode.NodeNew(csNodeDevice);

  NodeDev.AttributeAdd(csAttrAddres, IntToStr(ADevice.DeviceNum));

  TempDefCoil    := ADevice.DefCoil;
  TempDefDiscret := ADevice.DefDiscret;
  TempDefHolding := ADevice.DefHolding;
  TempDefInput   := ADevice.DefInput;

  NodeDev.AttributeAdd(csAttrDefCoil,  BoolToStr(TempDefCoil,True));
  NodeDev.AttributeAdd(csAttrDefDiscr, BoolToStr(TempDefDiscret,True));
  NodeDev.AttributeAdd(csAttrDefHold,  IntToHex(TempDefHolding,4));
  NodeDev.AttributeAdd(csAttrDefInput, IntToHex(TempDefInput,4));

  TempFunc := GetFunctionSetAsString(ADevice.DeviceFunctions);
  if TempFunc = '' then raise Exception.CreateFmt(rsLoader2, [ADevice.DeviceNum]);
  NodeDev.AttributeAdd(csAttrFunction, TempFunc);

  Count := ADevice.CoilCount-1;
  if Count > -1 then
   begin
    NodeRegs := NodeDev.NodeNew(csNodeCoils);
    for i := 0 to Count do
     begin
      if ADevice.Coils[i].Value = TempDefCoil then Continue;
      NodeReg := NodeRegs.NodeNew(csNodeReg);
      NodeReg.AttributeAdd(csAttrAddres, IntToStr(ADevice.Coils[i].RegNumber));
      NodeReg.AttributeAdd(csAttrValue, BoolToStr(ADevice.Coils[i].Value,True));
      NodeReg.AttributeAdd(csAttrDescript, ADevice.Coils[i].Description);
     end;
   end;

  Count := ADevice.DiscretCount-1;
  if Count > -1 then
   begin
    NodeRegs := NodeDev.NodeNew(csNodeDiscr);
    for i := 0 to Count do
     begin
      if ADevice.Discrets[i].Value = TempDefDiscret then Continue;
      NodeReg := NodeRegs.NodeNew(csNodeReg);
      NodeReg.AttributeAdd(csAttrAddres, IntToStr(ADevice.Discrets[i].RegNumber));
      NodeReg.AttributeAdd(csAttrValue, BoolToStr(ADevice.Discrets[i].Value,True));
      NodeReg.AttributeAdd(csAttrDescript, ADevice.Discrets[i].Description);
     end;
   end;

  Count := ADevice.HoldingCount-1;
  if Count > -1 then
   begin
    NodeRegs := NodeDev.NodeNew(csNodeHold);
    for i := 0 to Count do
     begin
      if ADevice.Holdings[i].Value = TempDefHolding then Continue;
      NodeReg := NodeRegs.NodeNew(csNodeReg);
      NodeReg.AttributeAdd(csAttrAddres, IntToStr(ADevice.Holdings[i].RegNumber));
      NodeReg.AttributeAdd(csAttrValue, IntToStr(ADevice.Holdings[i].Value));
      NodeReg.AttributeAdd(csAttrDescript, ADevice.Holdings[i].Description);
     end;
   end;

  Count := ADevice.InputCount-1;
  if Count > -1 then
   begin
    NodeRegs := NodeDev.NodeNew(csNodeInp);
    for i := 0 to Count do
     begin
      if ADevice.Inputs[i].Value = TempDefInput then Continue;
      NodeReg := NodeRegs.NodeNew(csNodeReg);
      NodeReg.AttributeAdd(csAttrAddres, IntToStr(ADevice.Inputs[i].RegNumber));
      NodeReg.AttributeAdd(csAttrValue, IntToStr(ADevice.Inputs[i].Value));
      NodeReg.AttributeAdd(csAttrDescript, ADevice.Inputs[i].Description);
     end;
   end;
end;

end.
