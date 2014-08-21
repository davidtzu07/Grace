unit uGuiState;

interface

{$INCLUDE Defines.inc}

uses
  uConstants, uLucidityEnums, Classes, Controls,
  eeTypes;

type
  TGuiState = class
  private
    fLowerTabState: TLowerTabOptions;
    fMouseOverRegionID: TGUID;
    fCurrentModDestTarget: TModDest;
    fFocusedControl: TControl;
    fIsModDestAutoSelectEnabled: boolean;
    fMainGuiLayout: TMainGuiLayout;
    fActiveVstPluginParameterID: TPluginParameterId;
    fSampleMapGroupVisibility: TGroupVisibility;
    procedure SetActiveVstPluginParameterID(const Value: TPluginParameterId);
  public
    constructor Create;
    destructor Destroy; override;

    property MouseOverRegionID : TGUID read fMouseOverRegionID write fMouseOverRegionID;

    property ModDestTarget : TModDest read fCurrentModDestTarget write fCurrentModDestTarget;
    property IsModDestAutoSelectEnabled : boolean read fIsModDestAutoSelectEnabled write fIsModDestAutoSelectEnabled;

    property FocusedControl : TControl read fFocusedControl write fFocusedControl;

    property MainGuiLayout : TMainGuiLayout read fMainGuiLayout   write fMainGuiLayout;
    property LowerTabState : TLowerTabOptions read fLowerTabState write fLowerTabState;

    //property SampleDisplayZoom : single read fSampleDisplayZ


    // NOTE:
    // Normally calling SetParameterAutomated() when GUI controls are automated is the prefered way to update parameters that
    // are visible to the host application (as a VST Plugin Parameter). The host will echo the parameter change back to the
    // plugin so it can than update it's internal state. This works well with most plugins. However in the case of
    // multi-timbral plugins where a GUI control is "focused" on a particalar layer, GUI control changes are normally intended
    // to changed the "focused" element, where as, VST Plugin Parameter changes normally change all elements. (In truth this
    // depends on how the plugin developer decides to respond to plugin parameter changes. Making Vst Plugin Parameter changes
    // "Global" seems to be appropiate in my experience.)
    // Because of the above we need some way to apply parameter changes whilst filtering out the echo parameter change that is
    // received back from the host. ActiveVstPluginParameterID stores the currently active parameter on the GUI.
    // The plugin can then use this to filter out the echoed parameter changes.
    property ActiveVstPluginParameterID : TPluginParameterId read fActiveVstPluginParameterID write SetActiveVstPluginParameterID;

    property SampleMapGroupVisibility : TGroupVisibility read fSampleMapGroupVisibility write fSampleMapGroupVisibility;
  end;

implementation

uses
  SysUtils,
 {$IFDEF Logging}
 SmartInspectLogging,
 VamLib.LoggingProxy,
 {$ENDIF}
  GuidEx;

{ TGuiState }

constructor TGuiState.Create;
begin
  fLowerTabState := TLowerTabOptions.TabMain; // shows the main tab by default.

  MouseOverRegionID := TGuidEx.EmptyGuid;

  fIsModDestAutoSelectEnabled := true;
  fMainGuiLayout := TMainGuiLayout.Default;
end;

destructor TGuiState.Destroy;
begin

  inherited;
end;

procedure TGuiState.SetActiveVstPluginParameterID(const Value: TPluginParameterId);
begin
  fActiveVstPluginParameterID := Value;
end;

end.
