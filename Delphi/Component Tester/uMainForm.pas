unit uMainForm;

interface



uses
  SynCommons,
  eeFileBrowserAddon,
  wmfintf,
  ACS_MemFloat,
  ACS_Wave,
  ACS_smpeg,
  SfzParser,
  NativeXML,
  Lucidity.Sfz,
  VamLib.Utils,
  VamLib.Debouncer,
  VamLib.GuiUtils,
  eeOscPhaseCounter,
  RedFoxImageBuffer,
  VamLib.HighSpeedTimer,
  VamLib.UniqueID,
  VamLib.ZeroObject,
  VamLib.Collections.Lists,
  VamLib.MultiEvent,
  VamLib.Animation,
  AudioIO,
  eeSampleFloat, {VamSampleDisplayBackBuffer,} {VamSamplePeakBuffer,}
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, RedFoxWinControl, VamWinControl,
  VamSampleDisplay, RedFoxContainer, Vcl.StdCtrls, VamLabel, VamKnob,
  VamModSelector, VamCompoundNumericKnob, VamNumericKnob,
  LucidityGui.DropBoxSelector, VamShortMessageOverlay, Vcl.ExtCtrls,
  VamSliderSwitch, VamMiniLevelMeter, VamCustomTreeView, VamTreeView,
  VamTextBox, VamTabPanel, VamTabs, VamScrollBox, VamScrollBar, VamPanel,
  VamMultiLineTextBox, VamMemo, VamImage, VamDiv, VamButton,
  RedFoxGraphicControl, VamGraphicControl, VamArrows, VamXYPad, VamSlider,
  VamStatusLed, VamSamplerKeys, VamSampleMap,
  VamModularJack, LucidityGui.VectorSequence,
  VamCompoundLabel;

type
  TMyTestObject = class(TRefCountedZeroObject)
  public
    destructor Destroy; override;
  end;


  TForm1 = class(TForm)
    Button1: TButton;
    Button2: TButton;
    Button3: TButton;
    Panel1: TPanel;
    Panel2: TPanel;
    Edit1: TEdit;
    Edit2: TEdit;
    Edit3: TEdit;
    procedure VamKnob1KnobPosChanged(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure Button3Click(Sender: TObject);
  private
    FileBrowserAddon : TFileBrowserAddon;

    MotherShip : TMotherShip;
    OscPhase : TOscPhaseCounter;
    StepSize : TOscPhaseCounter;

    ThrottleID_VSTParChange : TUniqueID;

    BackBuffer: TRedFoxImageBuffer;

    ID : TUniqueID;
    KnobValue : single;
    TimeReference : TDateTime;
    Timer : THighSpeedTimer;
    Token : TDebounceToken;
    KnobTT : TThrottleToken;
    procedure UpdateLabel;

    procedure HandleTimerEvent(Sender : TObject);
  public
    procedure UpdateMemo;
  end;

var
  Form1: TForm1;

implementation

{$R *.dfm}

uses
  _DirectSound,
  VamGuiControlInterfaces,
  RedFoxColor,
  VamLib.Throttler,
  //eeEnumHelper,
  Generics.Collections,
  VamLib.Threads,
  DateUtils,
  ACS_MAD,
  InWindowDialog.MessageDialog,
  InWindowDialog.InputDialog;

type
  TProcDictionary = TDictionary<integer, TDateTime>;

var
  GlobalDict : TProcDictionary;

type
  TKnobHack = class(TVamKnob)
  private
  public
  end;

procedure DrawKnob_ModEditOverlay(Sender: TObject);
  procedure CalcStartSweep(const Angle1, Angle2 : single; out Start, Sweep : single);
  begin
    Start := (Angle2+90) / 360 * 2 * pi;
    Sweep := (Angle1+90) / 360 * 2 * pi;
  end;
const
  kMinAngle = 30;
  kMaxAngle = 300;
  kArcSpan  = 300;
var
  Knob : TKnobHack;
  MidX, MidY : single;
  Angle1, Angle2 : single;
  s1, s2 : single;
begin
  Knob := TKnobHack(Sender as TVamKnob);

  MidX := Knob.Width  * 0.5;
  MidY := Knob.Height * 0.5;

  Knob.BackBuffer.BufferInterface.LineWidth := Knob.ModLineWidth;
  Knob.BackBuffer.BufferInterface.LineColor := GetAggColor(clAqua, 128);

  Angle1 := kMinAngle;
  Angle2 := kMinAngle + kArcSpan;

  CalcStartSweep(Angle1, Angle2, s1, s2);
  Knob.BackBuffer.BufferInterface.Arc(MidX, MidY, Knob.ModLineDist, Knob.ModLineDist, s1, s2);
end;


//==============================================================================

procedure TForm1.FormCreate(Sender: TObject);
const
  kDebugStr = '$11223344';
  kRed = '$FFFF0000';
var
  x : integer;
  rc : TRedFoxColor;
  xs : string;
begin
  ThrottleID_VSTParChange.Init;

  Timer := THighSpeedTimer.Create;
  Timer.Interval := 300;
  Timer.OnTimer := self.HandleTimerEvent;
  Timer.Enabled := false;

  xs := 'James Brown';

  Delete(xs, Length(xs), 1);


end;

procedure TForm1.FormDestroy(Sender: TObject);
begin
  Timer.Free;
  BackBuffer.Free;
  FileBrowserAddon.Free;
end;

procedure TForm1.Button2Click(Sender: TObject);
var
  MessageDialog : TMessageDialog;
begin
  MessageDialog := TMessageDialog.Create;
  MessageDialog.Text := 'James brown is dead. Frozen sald is the best.' + EndOfLine + 'Jacob was first.' + EndOfLine + 'A fanzine (portmanteau of fan and magazine or -zine) is a nonprofessional and nonofficial publication produced by fans of a particular cultural phenomenon (such as a literary or musical genre) for the pleasure of others who share their interest.';
  MessageDialog.ShowInWindow_WithAutoFree(self, false, true);
end;

procedure TForm1.Button3Click(Sender: TObject);
var
  InputDialog : TInputDialog;
begin
  Inputdialog := TInputDialog.Create;
  InputDialog.InputText := 'Text';
  InputDialog.InputLabel := 'Label';
  InputDialog.DefaultValue := 'Default Value';

  InputDialog.DialogResultHandler := procedure(InputText : string)
  begin
    ShowMessage(InputText);
  end;

  InputDialog.ShowInWindow_WithAutoFree(self, false, true);


end;

procedure TForm1.UpdateLabel;
begin

end;

procedure TForm1.UpdateMemo;
begin

end;




procedure TForm1.VamKnob1KnobPosChanged(Sender: TObject);
var
  ReferenceTime : TDateTime;
begin

end;

procedure TForm1.HandleTimerEvent(Sender: TObject);
begin

end;





{ TMyTestObject }

destructor TMyTestObject.Destroy;
begin

  inherited;
end;

initialization
  ReportMemoryLeaksOnShutDown := True;


finalization


end.
