unit uConstants;

interface

{$INCLUDE Defines.inc}

uses
  SysUtils,
  eeEnumHelper,
  uLucidityEnums,
  Messages, eePluginSettings;

const
  kCompany = 'One Small Clue';
  kProduct = 'Lucidity';
  kProductVersion = '1.0';

const
  kKeyFileName = 'LucidityKey.dat';

var
  AppDataDir   : string; //As specified by windows.
  VstPluginDir : string; //Location of the VST plugin dll.
  PresetsDir   : string; //Location of preset files...

const
  UM_SAMPLE_FOCUS_CHANGED             = WM_APP + 1; //sent when the region or sample group focus changes..
  UM_SAMPLE_REGION_CHANGED            = WM_APP + 2; //sent when something about a region has changed. ie. the region has moved.
  UM_MOUSE_OVER_SAMPLE_REGION_CHANGED = WM_APP + 3;
  UM_MIDI_KEY_CHANGED                 = WM_APP + 4;
  UM_PREVIEW_INFO_CHANGED             = WM_APP + 5;

  UM_SHOW_SAMPLE_MAP_EDIT             = WM_APP + 6;
  UM_HIDE_SAMPLE_MAP_EDIT             = WM_APP + 7;

  UM_SHOW_ABOUT_DIALOG                = WM_APP + 8;
  UM_SHOW_LOOP_EDIT_FRAME             = WM_APP + 9;
  UM_CLOSE_CURRENT_DIALOG             = WM_APP + 10;

  UM_SAMPLE_MARKERS_CHANGED           = WM_APP + 11;
  UM_SAMPLE_OSC_TYPE_CHANGED          = WM_APP + 12;
  UM_LOOP_TYPE_CHANGED                = WM_APP + 13;

  UM_SAMPLE_DIRECTORIES_CHANGED       = WM_APP + 14;
  UM_FILTER_CHANGED                   = WM_APP + 15;

  UM_Update_Control_Visibility        = WM_APP + 16; //something has changed, check to see if any controls need to be visible/invisible.
  UM_Update_Mod_Matrix                = WM_APP + 17;
  UM_Focused_Control_Changed          = WM_APP + 18;
  UM_PROGRAM_SAVED_TO_DISK            = WM_APP + 19;

const
  kMaxStepSequencerLength = 32;
  kMaxVoiceCount = 64; //max number of voices per group.
  //kMaxVoiceCount = 8; //max number of voices per group.


type
  //==============================================================================
  // TSampleBounds is used by the oscillator type classes to store
  // a temporary copy of the sample start/end and loop start/end data.
  // I think it will be better to use a temporary copy of the start/end
  // markers. That way the oscillators can update the marker positions
  // independently of the region properties which may update at any time.
  PSampleOsc_SampleBounds = ^TSampleOsc_SampleBounds;
  TSampleOsc_SampleBounds = record
    AbsoluteSampleStart : integer; //Should be 0.
    AbsoluteSampleEnd   : integer; //should be equal to SampleFrames-1
    SampleStart         : integer;
    SampleEnd           : integer;
    LoopStart           : integer;
    LoopEnd             : integer;
  end;

  PGlobalModulationPoints = ^TGlobalModulationPoints;
  TGlobalModulationPoints = record
    Source_MonophonicMidiNote : single;
    Source_MidiPitchBendST    : single; //Range is in semitones. Should it be CV?
    Source_MidiPitchbend      : single; //range 0..1
    Source_MidiModWheel       : single; //range 0..1
    Source_PadX1              : single;
    Source_PadY1              : single;
    Source_PadX2              : single;
    Source_PadY2              : single;
    Source_PadX3              : single;
    Source_PadY3              : single;
    Source_PadX4              : single;
    Source_PadY4              : single;
  end;

  // Per voice modulation points. All modulation values are in audio range.
  PVoiceModulationPoints = ^TVoiceModulationPoints;
  TVoiceModulationPoints = record
    // Modulation Input Points
    MidiNote         : single; //MIDI note. 0 = c2.
    SampleStart      : single;
    SampleEnd        : single;
    LoopStart        : single;
    LoopEnd          : single;

    // Modulation Output Points
    OutputAmplitudeLevel : single;
  end;




type
  PFilePreviewInfo = ^TFilePreviewInfo;
  TFilePreviewInfo = record
    FileName     : string;
    IsSupported  : boolean;
    IsValid      : boolean;
    SampleTime   : string; //Time in textual form.
    SampleRate   : string;
    BitDepth     : string;
    ChannelCount : string;
    procedure Clear;
  end;

//==============================================================================
//   GUI Skin Constants
//==============================================================================

const
  kColor_LcdDark1 = '$ff242B39';
  kColor_LcdDark2 = '$ff313B4F';
  kColor_LcdDark3 = '$ff5D7095';
  kColor_LcdDark4 = '$ff64718D';
  kColor_LcdDark5 = '$ffA1BDED';

  kColor_ButtonMouseOver = '$ff404A5E';

  kColor_ToggleButtonOn           = '$FFC1D3F3';
  kColor_ToggleButtonOnMouseOver  = '$FFD3E0F7';
  kColor_ToggleButtonOff          = '$FFF1CBB9';
  kColor_ToggleButtonOffMouseOver = '$FFFAECE6';
  kColor_ToggleButtonBorder       = '$FF242B39';


  //=== grays for normal ===
  kPanelVeryDark = '$ff3B3B3B';
  kPanelDark  = '$ff939393';
  kPanelMid   = '$ffAEAEAE';
  kPanelLight = '$ffCCCCCA';

  //=== Greens for testing ====
  //kPanelVeryDark = '$ff3B3B3B';
  //kPanelDark     = '$ff92B420';
  //kPanelMid      = '$ffBCDF49';
  //kPanelLight   = '$ffBCDF49';

const
  kColor_SampleDisplayLine = kColor_LcdDark4;
  kSampleImageWidth  = 592; //used for the pre-rendering of sample images.
  kSampleImageHeight = 77;  //used for the pre-rendering of sample images.


const
  dcVstMenuButton = '1'; //Menu buttons linked to VST parameters use this display class.
  dcGUIMenuButton = '2'; //Menu buttons with all their functionality handed by the GUI use this display class.


const
  kLucidityProgramFileExtension = '.lpg';

//==============================================================================



type
  TLucidityException = Exception;

//==============================================================================

function PluginInfo:TeePluginSettings;

//==============================================================================


implementation

uses
  RTTI, TypInfo, Math, uDataFolderUtils, eeVstExtra;

var
  Global_Info:TeePluginSettings;

function PluginInfo:TeePluginSettings;
begin
  if not assigned(Global_Info) then
  begin
    Global_Info := TeePluginSettings.Create;

    //Set plugin information here.
    Global_Info.PluginVendor       := kCompany;
    Global_Info.PluginName         := kProduct;
    Global_Info.PluginVersion      := kProductVersion;
    Global_Info.VstUniqueId        := '52Tw';

    Global_Info.NumberOfPrograms   := 1;
    Global_Info.UseHostGui         := false;

    Global_Info.InitialGuiWidth    := 980;
    Global_Info.InitialGuiHeight   := 832;

    Global_Info.IsSynth            := true;
    Global_Info.PresetsAreChunks   := true;
    Global_Info.SoftBypass         := false;

    Global_Info.InitialInputCount  := 0;
    Global_Info.InitialOutputCount := 10;

    Global_Info.IsOverSamplingEnabled   := true;
    Global_Info.OverSampleFactor        := 2;
    Global_Info.FastControlRateDivision := 8;
    Global_Info.SlowControlRateDivision := 64;
  end;

  result := Global_Info;
end;







{ TFilePreviewInfo }

procedure TFilePreviewInfo.Clear;
begin
  self.FileName     := '';
  self.IsSupported  := false;
  self.IsValid      := false;
  self.SampleTime   := '';
  self.SampleRate   := '';
  self.BitDepth     := '';
  self.ChannelCount := '';
end;




initialization

finalization
  if assigned(Global_Info) then Global_Info.Free;
end.
