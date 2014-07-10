{
  A unit to catch assorted GUI related methods that are shared between the Lucidity GUI units.
}

unit uGuiUtils;

interface

{$WARN SYMBOL_PLATFORM OFF}

uses
  eeTypes,
  eeEnumHelper,
  Math,
  Dialogs,
  VamKnob,
  eeGlobals,
  Lucidity.PluginParameters,
  uLucidityEnums,
  Lucidity.Interfaces,
  Lucidity.Types,
  Lucidity.SampleMap, eePlugin,
  VamLabel, VamTextBox, VamWinControl, RedFoxContainer, VamPanel,
  Controls;

type
  TZoomPos = record
    Zoom : single;    // range 0..1 (min zoom -> max zoom)
    Offset : single;  // range 0..1
    IndexA : single;  // range 0..1
    IndexB : single;  // range 0..1
  end;

procedure CalcZoomOffset(const IndexA, IndexB : single; const SampleFrames, DisplayPixelWidth : integer; out Zoom, Offset : single);
procedure CalcZoomBounds(const Zoom, Offset : single; const SampleFrames, DisplayPixelWidth : integer; out IndexA, IndexB:single);
function CalcZoomPos(const SampleFrames, DisplayPixelWidth, TargetSamplePos : integer):TZoomPos;

procedure ClearPadding(aControl : TVamWinControl); overload;
procedure ClearPadding(aControl : TRedFoxContainer); overload;


type
  TRegionDisplayResult = record
    Region : IRegion;
    Message : string;
  end;

function FindRegionToDisplay(const Plugin : TeePlugin):TRegionDisplayResult;

function ShowLoopMarkers(const aRegion : IRegion):boolean;

procedure SpreadControls_Horz(Controls:TArray<TControl>; const Parent : TWinControl);

procedure UpdateFilterControls(var Knobs : array of TControl; var Labels : array of TControl; const FilterType : TFilterType);



type
  TDialogTarget = (dtLucidityProgram, dtSfzProgram);

procedure SetupFileSaveDialog_Program(var SaveDialog : TFileSaveDialog);
procedure SetupFileOpenDialog_Program(var OpenDialog : TFileOpenDialog);

procedure SetupFileOpenDialog(var OpenDialog : TFileOpenDialog; const Target : TDialogTarget);

procedure GuiStandard_RegisterControl(const GuiStandard : TObject; const Control : TObject; const Par : TPluginParameter);
procedure GuiStandard_RegisterMenuButton(const GuiStandard : TObject; const Control : TObject; const Par : TPluginParameter);

function FindMenuHelperForParameter(const Par : TPluginParameter) : TCustomEnumHelperClass;


type
  //These commands are utilised by the GUI.
  Command = record
  public
    class procedure NormaliseSamples(Plugin : TeePlugin); static;
    class procedure MoveSampleMarker(const Plugin : TeePlugin; const Marker : TSampleMarker; const NewSamplePos : integer); static;

    class procedure ClearCurrentModulationForParameter(const Plugin : TeePlugin; const ParName :string); static;
    class procedure ClearAllModulationForParameter(const Plugin : TeePlugin; const ParName : string); static;
    class procedure ClearModulationForParameter(const Plugin : TeePlugin; const ParName : string; const ModSlot : integer); static;

    class function IsParameterModulated(const Plugin : TeePlugin; const ParName : string):boolean; overload; static;
    class function IsParameterModulated(const Plugin : TeePlugin; const ParName : string; const ModSlot : integer):boolean; overload; static;

    class function GetModSlotSource(const Plugin : TeePlugin; const ModSlot : integer):string; static;

    // TODO: delete these old parameters.
    class procedure ClearCurrentModulationForParameter_OLD(const Plugin : TeePlugin; const ModParIndex : integer); static;
    class procedure ClearAllModulationForParameter_OLD(const Plugin : TeePlugin; const ModParIndex : integer); static;

    class function GetParValue(const Plugin : TeePlugin; const Par : TPluginParameter):single; overload; static;
    class function GetParValue<TEnum>(const Plugin : TeePlugin; const Par : TPluginParameter):TEnum; overload; static;
    class function GetParDisplayInfo(const Plugin : TeePlugin; const ParID : TPluginParameterID):string; static;

    class procedure SetMidiCCForParameter(const Plugin : TeePlugin; const TargetParameterName : string); static;

    class procedure ToggleSampleZoom(const Plugin : TeePlugin); static;
    class procedure ToggleSampleMapVisibility(const Plugin : TeePlugin); static;
    class procedure ShowSampleZoom(const Plugin : TeePlugin); static;

    class function AreSampleZoomControlsVisible(const Plugin : TeePlugin):boolean; static;


    class procedure VstPar_BeginEdit(const Plugin : TeePlugin; const VstParameterIndex : integer); static;
    class procedure VstPar_EndEdit(const Plugin : TeePlugin; const VstParameterIndex : integer); static;
    class procedure VstPar_SetParameterAutomated(const Plugin : TeePlugin; const VstParameterIndex : integer; const ParValue : single); static;


  end;

  GuiSetup = record
    class procedure StyleButton_CommandButton(const Button : TVamTextBox); static;
    class procedure StyleButton_CommandButton_Bright(const Button : TVamTextBox); static;
    class procedure StyleButton_SelectorButton(const Button : TVamTextBox); static;
  end;



implementation

uses
  SysUtils,
  Effect.MidiAutomation,
  RedFoxColor,
  VamGuiControlInterfaces,
  eeDsp,
  eeSampleFloat,
  uConstants,
  LucidityModConnections,
  GuidEx,
  Lucidity.Globals,
  Lucidity.KeyGroup,
  eeGuiStandardv2,
  VamCompoundNumericKnob;



procedure CalcZoomOffset(const IndexA, IndexB : single; const SampleFrames, DisplayPixelWidth : integer; out Zoom, Offset : single);
var
  DivFactor : single;
begin
  //check entry conditions
  assert(IndexB >= IndexA);
  assert(IndexA >= 0);
  assert(IndexA <= 1);
  assert(IndexB >= 0);
  assert(IndexB <= 1);

  Zoom := 1 - (IndexB - IndexA);

  DivFactor := (1 - (IndexB - IndexA));

  if (DivFactor = 0)
    then Offset := 0
    else Offset := IndexA / DivFactor;

  //Check exit conditions
  assert(Zoom >= 0);
  assert(Zoom <= 1);
  assert(Offset >= 0);
  assert(Offset <= 1);
end;

procedure CalcZoomBounds(const Zoom, Offset : single; const SampleFrames, DisplayPixelWidth : integer; out IndexA, IndexB:single);
var
  DivFactor : single;
  Dist : single;
begin
  //check entry conditions
  assert(Zoom >= 0);
  assert(Zoom <= 1);
  assert(Offset >= 0);
  assert(Offset <= 1);

  Dist := 1 - Zoom;
  // (IndexB - IndexA) := Dist;

  DivFactor := (1 - Dist);

  IndexA := Offset * DivFactor;
  IndexB := IndexA + Dist;

  //Check exit conditions
  assert(IndexA >= 0);
  assert(IndexA <= 1);
  assert(IndexB >= 0);
  assert(IndexB <= 1);
end;

function CalcZoomPos(const SampleFrames, DisplayPixelWidth, TargetSamplePos : integer):TZoomPos;
var
  SampleIndexA, SampleIndexB : integer;
begin
  if TargetSamplePos >= SampleFrames then raise Exception.Create('TargetSamplePos is larger than SampleFrames.');

  if DisplayPixelWidth >= SampleFrames then
  begin
    //SampleIndexA := 0;
    //SampleIndexB := SampleFrames-1;
    result.Zoom := 0;
    result.Offset := 0;
    result.IndexA := 0;
    result.IndexB := 1;
    exit; //=============================>>
  end;


  if DisplayPixelWidth < SampleFrames then
  begin
    SampleIndexA := TargetSamplePos - (DisplayPixelWidth div 2);
    SampleIndexB := TargetSamplePos + (DisplayPixelWidth div 2);

    if SampleIndexA < 0 then
    begin
      SampleIndexA := 0;
      SampleIndexB := SampleIndexA + DisplayPixelWidth;
    end;

    if SampleIndexB >= SampleFrames then
    begin
      SampleIndexA := SampleFrames - 1 - DisplayPixelWidth;
      SampleIndexB := SampleFrames - 1;
    end;

    // double check everything has been computed correctly.
    assert(SampleIndexA >= 0);
    assert(SampleIndexB < SampleFrames);


    result.IndexA := SampleIndexA / (SampleFrames-1);
    result.IndexB := SampleIndexB / (SampleFrames-1);

    //finally, calc the zoom and offset values...
    CalcZoomOffset(result.IndexA, result.IndexB, SampleFrames, DisplayPixelWidth, result.Zoom, result.Offset);
  end;
end;


procedure ClearPadding(aControl : TVamWinControl); overload;
begin
  aControl.Padding.SetBounds(0,0,0,0);
  aControl.Margins.SetBounds(0,0,0,0);
  aControl.AlignWithMargins := true;

  if (aControl is TVamPanel) then
  begin
    (aControl as TVamPanel).CornerRadius1 := 3;
    (aControl as TVamPanel).CornerRadius2 := 3;
    (aControl as TVamPanel).CornerRadius3 := 3;
    (aControl as TVamPanel).CornerRadius4 := 3;
  end;

end;

procedure ClearPadding(aControl : TRedFoxContainer); overload;
begin
  aControl.Padding.SetBounds(0,0,0,0);
  aControl.Margins.SetBounds(0,0,0,0);
  aControl.AlignWithMargins := true;
end;


procedure SetupFileSaveDialog_Program(var SaveDialog : TFileSaveDialog);
var
  ft : TFileTypeItem;
begin
  if (Lucidity.Globals.LastProgramLoadDir <> '') and (DirectoryExists(Lucidity.Globals.LastProgramSaveDir)) then
  begin
    SaveDialog.DefaultFolder := Lucidity.Globals.LastProgramSaveDir;
  end;

  ft := SaveDialog.FileTypes.Add;
  ft.DisplayName := 'Lucidity Program';
  ft.FileMask    := '*.lpg';

  SaveDialog.DefaultExtension := 'lpg';
end;

procedure SetupFileOpenDialog_Program(var OpenDialog : TFileOpenDialog);
var
  ft : TFileTypeItem;
begin
  if (Lucidity.Globals.LastProgramLoadDir <> '') and (DirectoryExists(Lucidity.Globals.LastProgramSaveDir)) then
  begin
    OpenDialog.DefaultFolder := Lucidity.Globals.LastProgramLoadDir;
  end;

  ft := OpenDialog.FileTypes.Add;
  ft.DisplayName := 'Lucidity Program';
  ft.FileMask    := '*.lpg';

  ft := OpenDialog.FileTypes.Add;
  ft.DisplayName := 'All Files';
  ft.FileMask    := '*.*';

  OpenDialog.DefaultExtension := 'lpg';
end;


function FindRegionToDisplay(const Plugin : TeePlugin):TRegionDisplayResult; overload;
var
  rx : IRegion;
  rs : string;
  kg : IKeyGroup;
  SelectedRegionCount : integer;

  IsSampleMapVisible : boolean;
begin
  rx := nil;
  rs := '';

  kg := Plugin.FocusedKeyGroup;
  if not assigned(kg) then
  begin
    rx := nil;
    rs := '(No Key Group Selected)';
    result.Region  := rx;
    result.Message := rs;
    exit; //================exit>>==================>>
  end;

  if Plugin.Globals.GuiState.MainGuiLayout = TMainGuiLayout.MapEdit
    then IsSampleMapVisible := true
    else IsSampleMapVisible := false;

  if (IsSampleMapVisible = false) then
  begin
    rx := Plugin.FocusedRegion;
    rs := '';

    if (assigned(rx)) and (rx.GetKeyGroup.GetName <> kg.GetName) then
    begin
      rx := Plugin.SampleMap.FindRegionByKeyGroup(kg.GetName);
      rs := '';
    end;

    if (not assigned(rx)) then
    begin
      rx := Plugin.SampleMap.FindRegionByKeyGroup(kg.GetName);
      rs := '';
    end;

    if (not assigned(rx)) and (Plugin.SampleMap.RegionCount = 0) then
    begin
      rs := '(No Samples Loaded)';
    end;

    if (not assigned(rx)) and (Plugin.SampleMap.RegionCount > 0) then
    begin
      rs := '(No Regions Selected)';
    end;
  end else
  begin
    if (Plugin.Globals.GuiState.MouseOverRegionID <> TGuidEx.EmptyGuid) then
    begin
      rx := Plugin.SampleMap.FindRegionByUniqueID(Plugin.Globals.GuiState.MouseOverRegionID);
      if not assigned(rx) then rs := 'ERROR';
    end else
    begin
      SelectedRegionCount := Plugin.SampleMap.SelectedRegionCount;

      if Plugin.SampleMap.RegionCount = 0 then
      begin
        rx := nil;
        rs := '(No Samples Loaded)';
      end else
      if SelectedRegionCount = 0 then
      begin
        rx := nil;
        rs := '(No Regions Selected)';
      end else
      if SelectedRegionCount > 1 then
      begin
        rx := nil;
        rs := '(' + IntToStr(SelectedRegionCount) + ' Regions Selected)';
      end else
      begin
        rx := Plugin.FocusedRegion;
        rs := '';
      end;
    end;
  end;

  result.Region  := rx;
  result.Message := rs;
end;

function ShowLoopMarkers(const aRegion : IRegion):boolean;
var
  kg : TKeyGroup;
begin
  kg := (aRegion.GetKeyGroup.GetObject as TKeyGroup);
  case kg.VoiceParameters.SamplePlaybackType of
    TSamplePlaybackType.NoteSampler,
    TSamplePlaybackType.LoopSampler,
    TSamplePlaybackType.OneShotSampler:
    begin
      case kg.VoiceParameters.SamplerLoopBounds of
        //TSamplerLoopBounds.LoopOff:    result := false;
        TSamplerLoopBounds.LoopSample: result := false;
        TSamplerLoopBounds.LoopPoints: result := true;
      else
        raise Exception.Create('Unexpected type.');
      end;
    end;

    TSamplePlaybackType.GrainStretch: result := true;
    TSamplePlaybackType.WaveOsc:      result := true;
  else
    raise Exception.Create('Unexpected Sample playback type.');
  end;

end;

procedure SpreadControls_Horz(Controls:TArray<TControl>; const Parent : TWinControl);
var
  ControlCount : integer;
  c1: Integer;
  TotalControlWidth : integer;
  TotalSpace : integer;
  OffsetA, OffsetB : single;
begin
  ControlCount := Length(Controls);

  TotalControlWidth := 0;
  for c1 := 0 to ControlCount-1 do
  begin
    inc(TotalControlWidth, Controls[c1].Width);
  end;

  TotalSpace := Parent.Width - TotalControlWidth;

  for c1 := 0 to ControlCount-1 do
  begin
    offsetA := (TotalControlWidth / ControlCount * c1);
    offsetB := TotalSpace / (ControlCount-1) * c1;
    Controls[c1].Left := round(OffsetA + OffsetB);
  end;
end;





procedure UpdateFilterControls(var Knobs : array of TControl; var Labels : array of TControl; const FilterType : TFilterType);
  procedure FastUpdateControl(aControl, aLabel : Tcontrol; const Caption : string = '');
  begin
    if Caption <> '' then
    begin
      aControl.Visible := true;
      (aControl as TVamKnob).IsKnobEnabled := true;
      (aLabel as TVamLabel).Text := Caption;
      aLabel.Visible := true;
    end else
    begin
      aControl.Visible := true;
      (aControl as TVamKnob).IsKnobEnabled := false;
      (aLabel as TVamLabel).Text := '';
      aLabel.Visible := false;
    end;
  end;
begin
  case FilterType of
    ftNone:
    begin
      FastUpdateControl(Knobs[0], Labels[0], '');
      FastUpdateControl(Knobs[1], Labels[1], '');
      FastUpdateControl(Knobs[2], Labels[2], '');
      FastUpdateControl(Knobs[3], Labels[3], '');
    end;

    ftLofiA:
    begin
      FastUpdateControl(Knobs[0], Labels[0], 'SR');
      FastUpdateControl(Knobs[1], Labels[1], 'BITS');
      FastUpdateControl(Knobs[2], Labels[2], '');
      FastUpdateControl(Knobs[3], Labels[3], '');
    end;

    ftRingModA:
    begin
      FastUpdateControl(Knobs[0], Labels[0], 'FREQ');
      FastUpdateControl(Knobs[1], Labels[1], 'AMT');
      FastUpdateControl(Knobs[2], Labels[2], '');
      FastUpdateControl(Knobs[3], Labels[3], '');
    end;

    //ftDistA:
    //begin
    //end;

    ftCombA:
    begin
      FastUpdateControl(Knobs[0], Labels[0], 'FREQ');
      FastUpdateControl(Knobs[1], Labels[1], 'AMT');
      FastUpdateControl(Knobs[2], Labels[2], 'MIX');
      FastUpdateControl(Knobs[3], Labels[3], '');
    end;

    ft2PoleLowPass,
    ft2PoleBandPass,
    ft2PoleHighPass,
    ft4PoleLowPass,
    ft4PoleBandPass,
    ft4PoleHighPass:
    begin
      FastUpdateControl(Knobs[0], Labels[0], 'FREQ');
      FastUpdateControl(Knobs[1], Labels[1], 'RES');
      FastUpdateControl(Knobs[2], Labels[2], 'GAIN');
      FastUpdateControl(Knobs[3], Labels[3], '');
    end;
  else
    raise Exception.Create('Type not handled.');
  end;

end;


procedure SetupFileOpenDialog(var OpenDialog : TFileOpenDialog; const Target : TDialogTarget);
var
  ft : TFileTypeItem;
begin
  case Target of
    dtLucidityProgram:
    begin
      if (Lucidity.Globals.LastProgramLoadDir <> '') and (DirectoryExists(Lucidity.Globals.LastProgramSaveDir)) then
      begin
        OpenDialog.DefaultFolder := Lucidity.Globals.LastProgramLoadDir;
      end;

      ft := OpenDialog.FileTypes.Add;
      ft.DisplayName := 'Lucidity Program';
      ft.FileMask    := '*.lpg';

      ft := OpenDialog.FileTypes.Add;
      ft.DisplayName := 'All Files';
      ft.FileMask    := '*.*';

      OpenDialog.DefaultExtension := 'lpg';
    end;


    dtSfzProgram:
    begin
      // TODO: set default folder location.

      ft := OpenDialog.FileTypes.Add;
      ft.DisplayName := 'SFZ Program';
      ft.FileMask    := '*.sfz';

      ft := OpenDialog.FileTypes.Add;
      ft.DisplayName := 'All Files';
      ft.FileMask    := '*.*';

      OpenDialog.DefaultExtension := 'sfz';
    end;
  else
    raise Exception.Create('Target type not handled.');
  end;
end;


{ Command }

class procedure Command.NormaliseSamples(Plugin: TeePlugin);
var
  Region:IRegion;
  sample : PSampleFloat;

  c1 : integer;
  MaxSampleValue : single;
  MaxDB : single;
  ch1 : PSingle;
  ch2 : PSingle;
begin
  Region := Plugin.SampleMap.FindFocusedRegion;
  if not assigned(Region) then exit;

  Sample := Region.GetSample;
  if not assigned(Sample) then exit;
  if not Sample^.Properties.IsValid then exit;


  if Sample.Properties.ChannelCount = 1 then
  begin
    ch1 := Sample.Properties.Ch1;
    ch2 := Sample.Properties.Ch1;
  end else
  if Sample.Properties.ChannelCount = 2 then
  begin
    ch1 := Sample.Properties.Ch1;
    ch2 := Sample.Properties.Ch2;
  end else
  begin
    exit; // channel count not supported.
  end;


  MaxSampleValue := 0;

  for c1 := 0 to Sample.Properties.SampleFrames-1 do
  begin
    if abs(ch1^) > MaxSampleValue
      then MaxSampleValue := abs(ch1^);

    if abs(ch2^) > MaxSampleValue
      then MaxSampleValue := abs(ch2^);

    inc(ch1);
    inc(ch2);
  end;



  MaxDB := LinearToDecibels(MaxSampleValue);

  Region.GetProperties^.SampleVolume := -MaxDB;

  Plugin.Globals.MotherShip.SendMessageUsingGuiThread(TLucidMsgID.Command_UpdateSampleDisplay);
end;


class procedure Command.SetMidiCCForParameter(const Plugin: TeePlugin; const TargetParameterName: string);
var
  Value : string;
  MidiCC : integer;
  Error : boolean;
  ErrorMessage : string;
  MidiBinding : IMidiBinding;
begin
  Error := false;

  Value := InputBox('Set MIDI CC', 'Choose a MIDI CC# (0-127)', '');

  if Value <> '' then
  begin
    // 2: Check for valid MIDI CC index,
    try
      MidiCC := StrToInt(Value);
    except
      //Catch all exceptions. Assume an invalid integer value was entered.
      Error := true;
      ErrorMessage := '"' + Value + '" isn''t a valid integer.';
      MidiCC := -1;
    end;

    if (Error = false) and (MidiCC < 0) then
    begin
      Error := true;
      ErrorMessage := 'The MIDI CC index you entered is too small.';
    end;

    if (Error = false) and (MidiCC > 127) then
    begin
      Error := true;
      ErrorMessage := 'The MIDI CC index you entered is too big.';
    end;

    if (Error = false) and (MidiCC >= 0) and (MidiCC <= 127) then
    begin
      // Set the midi binding for the current parameter.
      Plugin.MidiAutomation.ClearBinding(TargetParameterName);

      MidiBinding := TMidiBinding.Create;
      MidiBinding.SetParName(TargetParameterName);
      MidiBinding.SetMidiCC(MidiCC);

      Plugin.MidiAutomation.AddBinding(MidiBinding);
    end;
  end;

  if (Error = true) then
  begin
    ShowMessage('Error: ' + ErrorMessage);
  end;
end;

class procedure Command.ShowSampleZoom(const Plugin: TeePlugin);
begin
  if Plugin.Globals.GuiState.MainGuiLayout <> TMainGuiLayout.SampleZoom then
  begin
    Plugin.Globals.GuiState.MainGuiLayout := TMainGuiLayout.SampleZoom;
    Plugin.Globals.MotherShip.MsgVcl(TLucidMsgID.GUILayoutChanged);
  end;
end;

class procedure Command.ToggleSampleMapVisibility(const Plugin: TeePlugin);
begin
  if Plugin.Globals.GuiState.MainGuiLayout <> TMainGuiLayout.MapEdit then
  begin
    Plugin.Globals.GuiState.MainGuiLayout := TMainGuiLayout.MapEdit;
    Plugin.Globals.MotherShip.MsgVcl(TLucidMsgID.GUILayoutChanged);
  end else
  begin
    Plugin.Globals.GuiState.MainGuiLayout := TMainGuiLayout.Default;
    Plugin.Globals.MotherShip.MsgVcl(TLucidMsgID.GUILayoutChanged);
  end;
end;

class procedure Command.ToggleSampleZoom(const Plugin: TeePlugin);
begin
  if Plugin.Globals.GuiState.MainGuiLayout <> TMainGuiLayout.SampleZoom then
  begin
    Plugin.Globals.GuiState.MainGuiLayout := TMainGuiLayout.SampleZoom;
    Plugin.Globals.MotherShip.MsgVcl(TLucidMsgID.GUILayoutChanged);
  end else
  begin
    Plugin.Globals.GuiState.MainGuiLayout := TMainGuiLayout.Default;
    Plugin.Globals.MotherShip.MsgVcl(TLucidMsgID.GUILayoutChanged);
  end;
end;

class procedure Command.VstPar_BeginEdit(const Plugin: TeePlugin; const VstParameterIndex: integer);
begin
  Plugin.Globals.VstMethods.BeginParameterEdit(VstParameterIndex);
end;

class procedure Command.VstPar_EndEdit(const Plugin: TeePlugin;  const VstParameterIndex: integer);
begin
  Plugin.Globals.VstMethods.EndParameterEdit(VstParameterIndex);
end;

class procedure Command.VstPar_SetParameterAutomated(const Plugin: TeePlugin; const VstParameterIndex: integer; const ParValue: single);
begin
  Plugin.Globals.VstMethods.SetParameterAutomated(VstParameterIndex, ParValue);
end;

class procedure Command.ClearAllModulationForParameter_OLD(const Plugin: TeePlugin; const ModParIndex: integer);
var
  kg : IKeyGroup;
  c1: Integer;
begin
  kg := Plugin.ActiveKeyGroup;
  if not assigned(kg) then exit;

  for c1 := 0 to kModSlotCount-1 do
  begin
    kg.SetModParModAmount(ModParIndex, c1, 0);
  end;

  Plugin.Globals.MotherShip.MsgVCL(TLucidMsgID.ModAmountChanged);
end;

class function Command.IsParameterModulated(const Plugin: TeePlugin; const ParName: string): boolean;
var
  kg : IKeyGroup;
  c1: Integer;
  ModParIndex : integer;
  Par : TPluginParameter;
  ModAmount : single;
begin
  kg := Plugin.ActiveKeyGroup;
  if not assigned(kg) then exit(false);

  Par := PluginParFromName(ParName);
  ModParIndex := GetModParIndex(Par);
  if ModParIndex = -1 then exit(false);

  for c1 := 0 to kModSlotCount-1 do
  begin
    ModAmount := kg.GetModParModAmount(ModParIndex, c1);
    if ModAmount <> 0
      then exit(true);
  end;

  // === no modulation if we've made it this far..

  result := false;
end;

class function Command.IsParameterModulated(const Plugin: TeePlugin; const ParName: string; const ModSlot: integer): boolean;
var
  kg : IKeyGroup;
  ModParIndex : integer;
  Par : TPluginParameter;
  ModAmount : single;
begin
  kg := Plugin.ActiveKeyGroup;
  if not assigned(kg) then exit(false);

  Par := PluginParFromName(ParName);
  ModParIndex := GetModParIndex(Par);
  if ModParIndex = -1 then exit(false);

  ModAmount := kg.GetModParModAmount(ModParIndex, ModSlot);
    if ModAmount <> 0
      then result := true
      else result := false;
end;

class function Command.AreSampleZoomControlsVisible(const Plugin: TeePlugin): boolean;
begin
  if Plugin.Globals.GuiState.MainGuiLayout = TMainGuiLayout.SampleZoom
    then result := true
    else result := false;
end;

class procedure Command.ClearAllModulationForParameter(const Plugin: TeePlugin; const ParName: string);
var
  kg : IKeyGroup;
  c1: Integer;
  ModParIndex : integer;
  Par : TPluginParameter;
begin
  kg := Plugin.ActiveKeyGroup;
  if not assigned(kg) then exit;

  Par := PluginParFromName(ParName);
  ModParIndex := GetModParIndex(Par);
  if ModParIndex = -1 then exit;

  for c1 := 0 to kModSlotCount-1 do
  begin
    kg.SetModParModAmount(ModParIndex, c1, 0);
  end;

  Plugin.Globals.MotherShip.MsgVCL(TLucidMsgID.ModAmountChanged);
end;

class procedure Command.ClearCurrentModulationForParameter(const Plugin: TeePlugin; const ParName: string);
var
  kg : IKeyGroup;
  CurrentModSlot: Integer;
  ModParIndex : integer;
  Par : TPluginParameter;
begin
  kg := Plugin.ActiveKeyGroup;
  if not assigned(kg) then exit;

  Par := PluginParFromName(ParName);
  ModParIndex := GetModParIndex(Par);
  if ModParIndex = -1 then exit;

  CurrentModSlot := Plugin.Globals.SelectedModSlot;
  if CurrentModSlot = -1 then exit;

  kg.SetModParModAmount(ModParIndex, CurrentModSlot, 0);

  Plugin.Globals.MotherShip.MsgVCL(TLucidMsgID.ModAmountChanged);
end;


class procedure Command.ClearCurrentModulationForParameter_OLD(const Plugin: TeePlugin; const ModParIndex: integer);
var
  ModSlot : integer;
  kg : IKeyGroup;
begin
  ModSlot := Plugin.Globals.SelectedModSlot;

  if ModSlot <> -1 then
  begin
    kg := Plugin.ActiveKeyGroup;
    kg.SetModParModAmount(ModParIndex, ModSlot, 0);
  end;

  Plugin.Globals.MotherShip.MsgVCL(TLucidMsgID.ModAmountChanged);
end;

class procedure Command.ClearModulationForParameter(const Plugin: TeePlugin; const ParName: string; const ModSlot: integer);
var
  kg : IKeyGroup;
  ModParIndex : integer;
  Par : TPluginParameter;
begin
  kg := Plugin.ActiveKeyGroup;
  if not assigned(kg) then exit;

  Par := PluginParFromName(ParName);
  ModParIndex := GetModParIndex(Par);
  if ModParIndex = -1 then exit;

  kg.SetModParModAmount(ModParIndex, ModSlot, 0);

  Plugin.Globals.MotherShip.MsgVCL(TLucidMsgID.ModAmountChanged);
end;


class function Command.GetModSlotSource(const Plugin: TeePlugin; const ModSlot: integer): string;
var
  kg : IKeyGroup;
  ModConnections : TModConnections;
  ModSource : TModSource;
  ModSourceText : string;
begin
  kg := Plugin.ActiveKeyGroup;
  if not assigned(kg) then exit('');

  ModConnections := kg.GetModConnections;

  ModSource := ModConnections.GetModSource(ModSlot);
  ModSourceText := TModSourceHelper.ToFullGuiString(ModSource);

  result := ModSourceText;
end;



class function Command.GetParValue(const Plugin: TeePlugin; const Par: TPluginParameter): single;
var
  ParID : TPluginParameterID;
begin
  ParID := PluginParToID(Par);
  result := Plugin.GetPluginParameter(ParID);
end;

class function Command.GetParValue<TEnum>(const Plugin: TeePlugin; const Par: TPluginParameter): TEnum;
var
  ParID : TPluginParameterID;
  ParValue : single;
begin
  ParID := PluginParToID(Par);
  ParValue := Plugin.GetPluginParameter(ParID);
  result := TEnumHelper<TEnum>.ToEnum(ParValue);
end;

class function Command.GetParDisplayInfo(const Plugin: TeePlugin; const ParID: TPluginParameterID): string;
var
  text : string;
  Par : TPluginParameter;
begin
  Par := PluginParFromID(ParID);
  Text := PluginParToDisplayName(Par);

  result := Text;
end;

class procedure Command.MoveSampleMarker(const Plugin: TeePlugin; const Marker: TSampleMarker; const NewSamplePos: integer);
var
  Region : IRegion;
begin
  Region := Plugin.FocusedRegion;

  case Marker of
    smSampleStartMarker: Region.GetProperties^.SampleStart := NewSamplePos;
    smSampleEndMarker:   Region.GetProperties^.SampleEnd   := NewSamplePos;
    smLoopStartMarker:   Region.GetProperties^.LoopStart   := NewSamplePos;
    smLoopEndMarker:     Region.GetProperties^.LoopEnd     := NewSamplePos;
  end;

  Plugin.Globals.MotherShip.MsgVCL(TLucidMsgID.SampleMarkersChanged);
end;


procedure GuiStandard_RegisterControl(const GuiStandard : TObject; const Control : TObject; const Par : TPluginParameter);
var
  gs : TGuiStandard;
begin
  assert(GuiStandard is eeGuiStandardv2.TGuiStandard);
  gs := GuiStandard as eeGuiStandardv2.TGuiStandard;

  if (Control is TVamKnob) then
  begin
    (Control as TVamKnob).ParameterName := PluginParToName(Par);
    gs.RegisterControl('KnobHandler', Control);
  end else
  if (Control is TVamCompoundNumericKnob) then
  begin
    (Control as TVamCompoundNumericKnob).ParameterName := PluginParToName(Par);
    gs.RegisterControl('KnobHandler', Control);
  end else
  begin
    raise Exception.Create('type not handled.');
  end;

end;

procedure GuiStandard_RegisterMenuButton(const GuiStandard : TObject; const Control : TObject; const Par : TPluginParameter);
var
  gs : TGuiStandard;
  mc : IMenuControl;
begin
  assert(GuiStandard is eeGuiStandardv2.TGuiStandard);
  gs := GuiStandard as eeGuiStandardv2.TGuiStandard;


  if Supports(Control, IMenuControl, mc)  then
  begin
    mc.SetParameterName(PluginParToName(Par));
    gs.RegisterControl('MenuButtonHandler', Control);
  end else
  begin
    raise Exception.Create('type not handled.');
  end;
end;


function FindMenuHelperForParameter(const Par : TPluginParameter) : TCustomEnumHelperClass;
begin
  case Par of
    TPluginParameter.VoiceMode:              result := TVoiceModeHelper;
    TPluginParameter.PitchTracking:          result := TPitchTrackingHelper;
    TPluginParameter.SamplePlaybackType:     result := TSamplePlaybackTypeHelper;
    TPluginParameter.SampleResetClockSource: result := TClockSourceHelper;
    TPluginParameter.SamplerLoopBounds:      result := TSamplerLoopBoundsHelper;
    TPluginParameter.SamplerLoopMode:        result := TKeyGroupTriggerModeHelper;
    TPluginParameter.AmpVelocity:            result := TEnvVelocityDepthHelper;
    TPluginParameter.ModVelocity:            result := TEnvVelocityDepthHelper;
    TPluginParameter.FilterRouting:          result := TFilterRoutingHelper;
    TPluginParameter.Filter1Type:            result := TFilterTypeHelper;
    TPluginParameter.Filter2Type:            result := TFilterTypeHelper;
    TPluginParameter.Lfo1Shape:              result := TLfoShapeHelper;
    TPluginParameter.Lfo2Shape:              result := TLfoShapeHelper;
    TPluginParameter.Lfo1FreqMode:           result := TLfoFreqModeHelper;
    TPluginParameter.Lfo2FreqMode:           result := TLfoFreqModeHelper;
    TPluginParameter.Lfo1Range:              result := TLfoRangeHelper;
    TPluginParameter.Lfo2Range:              result := TLfoRangeHelper;
    TPluginParameter.Seq1Clock:              result := TSequencerClockHelper;
    TPluginParameter.Seq1Direction:          result := TStepSequencerDirectionHelper;
    TPluginParameter.Seq1Length:             result := TStepSequencerLengthHelper;
    TPluginParameter.Seq2Clock:              result := TSequencerClockHelper;
    TPluginParameter.Seq2Direction:          result := TStepSequencerDirectionHelper;
    TPluginParameter.Seq2Length:             result := TStepSequencerLengthHelper;
  else
    raise Exception.Create('Type not handled.');
  end;
end;


{ GuiSetup }

class procedure GuiSetup.StyleButton_CommandButton(const Button: TVamTextBox);
// http://www.colorhexa.com/ccccca-to-d3e0f7
begin
  Button.Color           :=  '$ffD0D6E1';
  //Button.ColorMouseOver  :=  '$ffD3E0F7';
  Button.ColorMouseOver  :=  '$ffE3EEFF';

  Button.ColorBorder     :=  '$ff000000';
  Button.Font.Color      := GetRedFoxColor('$ff242B39');

  Button.ShowBorder := true;
end;

class procedure GuiSetup.StyleButton_CommandButton_Bright(const Button: TVamTextBox);
// http://www.colorhexa.com/ccccca-to-d3e0f7
begin
  Button.Color           :=  '$ffD0D6E1';
  //Button.ColorMouseOver  :=  '$ffD3E0F7';
  Button.ColorMouseOver  :=  '$ffE3EEFF';

  Button.ColorBorder     :=  '$ff000000';
  Button.Font.Color      := GetRedFoxColor('$ff242B39');

  Button.ShowBorder := true;
end;

class procedure GuiSetup.StyleButton_SelectorButton(const Button: TVamTextBox);
begin
  Button.Color          := kColor_LcdDark1;
  Button.ColorMouseOver := kColor_ButtonMouseOver;
  Button.Font.Color     := GetRedFoxColor(kColor_LcdDark5);
end;

end.

