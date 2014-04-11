unit Menu.SampleDisplayMenu;

interface

uses
  Lucidity.Interfaces,
  eePlugin, Vcl.Menus;


type
  TSampleDisplayMenu = class
  private
  protected
    Plugin : TeePlugin;
    Menu : TPopUpMenu;

    procedure EventHandle_NormaliseSample(Sender : TObject);
    procedure EventHandle_EditSamplePoints(Sender : TObject);
    procedure EventHandle_EditSampleMap(Sender : TObject);
    procedure EventHandle_ShowInWindowsExplorer(Sender : TObject);
    procedure EventHandle_ModulationCommand(Sender : TObject);
  public
    constructor Create;
    destructor Destroy; override;

    procedure Initialize(aPlugin : TeePlugin);

    procedure Popup(const x, y : integer);

  end;

implementation

uses
  uGuiUtils,
  SysUtils,
  eeWinEx,
  Lucidity.SampleMap,
  uConstants;

const
  SampleStartTag = 1;
  SampleEndTag   = 2;
  LoopStartTag   = 3;
  LoopEndTag     = 4;

{ TSampleDisplayMenu }

constructor TSampleDisplayMenu.Create;
begin
  Menu := TPopupMenu.Create(nil);
end;

destructor TSampleDisplayMenu.Destroy;
begin
  Menu.Free;
  inherited;
end;

procedure TSampleDisplayMenu.Initialize(aPlugin: TeePlugin);
begin
  Plugin := aPlugin;
end;

procedure TSampleDisplayMenu.Popup(const x, y: integer);
var
  mi : TMenuItem;
  Childmi : TMenuItem;
  Tag : integer;
begin
  Menu.Items.Clear;


  mi := TMenuItem.Create(Menu);
  mi.Caption := 'Normalise Sample';
  mi.OnClick := EventHandle_NormaliseSample;
  Menu.Items.Add(mi);

  mi := TMenuItem.Create(Menu);
  mi.Caption := 'Edit Sample Points...';
  mi.OnClick := EventHandle_EditSamplePoints;
  Menu.Items.Add(mi);

  mi := TMenuItem.Create(Menu);
  mi.Caption := 'Edit Sample Map...';
  mi.OnClick := EventHandle_EditSampleMap;
  Menu.Items.Add(mi);


  mi := TMenuItem.Create(Menu);
  mi.Caption := 'Show in Windows Exporer...';
  mi.OnClick := EventHandle_ShowInWindowsExplorer;
  Menu.Items.Add(mi);

  mi := TMenuItem.Create(Menu);
  mi.Caption := '-';
  Menu.Items.Add(mi);



  Tag := SampleStartTag;
  mi := TMenuItem.Create(Menu);
  mi.Caption := 'Sample Start';
  Menu.Items.Add(mi);

    Childmi := TMenuItem.Create(Menu);
    ChildMi.Caption := 'Clear Current Modulation';
    ChildMi.OnClick := EventHandle_ModulationCommand;
    ChildMi.Tag := Tag;
    mi.Add(ChildMi);

    Childmi := TMenuItem.Create(Menu);
    ChildMi.Caption := 'Clear All Modulation';
    ChildMi.OnClick := EventHandle_ModulationCommand;
    ChildMi.Tag := Tag;
    mi.Add(ChildMi);


  Tag := SampleEndTag;
  mi := TMenuItem.Create(Menu);
  mi.Caption := 'Sample End';
  Menu.Items.Add(mi);

    Childmi := TMenuItem.Create(Menu);
    ChildMi.Caption := 'Clear Current Modulation';
    ChildMi.OnClick := EventHandle_ModulationCommand;
    ChildMi.Tag := Tag;
    mi.Add(ChildMi);

    Childmi := TMenuItem.Create(Menu);
    ChildMi.Caption := 'Clear All Modulation';
    ChildMi.OnClick := EventHandle_ModulationCommand;
    ChildMi.Tag := Tag;
    mi.Add(ChildMi);


  Tag := LoopStartTag;
  mi := TMenuItem.Create(Menu);
  mi.Caption := 'Loop Start';
  Menu.Items.Add(mi);

    Childmi := TMenuItem.Create(Menu);
    ChildMi.Caption := 'Clear Current Modulation';
    ChildMi.OnClick := EventHandle_ModulationCommand;
    ChildMi.Tag := Tag;
    mi.Add(ChildMi);

    Childmi := TMenuItem.Create(Menu);
    ChildMi.Caption := 'Clear All Modulation';
    ChildMi.OnClick := EventHandle_ModulationCommand;
    ChildMi.Tag := Tag;
    mi.Add(ChildMi);


  Tag := LoopEndTag;
  mi := TMenuItem.Create(Menu);
  mi.Caption := 'Loop End';
  Menu.Items.Add(mi);

    Childmi := TMenuItem.Create(Menu);
    ChildMi.Caption := 'Clear Current Modulation';
    ChildMi.OnClick := EventHandle_ModulationCommand;
    ChildMi.Tag := Tag;
    mi.Add(ChildMi);

    Childmi := TMenuItem.Create(Menu);
    ChildMi.Caption := 'Clear All Modulation';
    ChildMi.OnClick := EventHandle_ModulationCommand;
    ChildMi.Tag := Tag;
    mi.Add(ChildMi);





  Menu.Popup(x, y);
end;

procedure TSampleDisplayMenu.EventHandle_EditSampleMap(Sender: TObject);
begin
  if not assigned(Plugin) then exit;

  if Plugin.GuiState.IsSampleMapVisible
    then Plugin.Globals.MotherShip.SendMessageUsingGuiThread(TLucidMsgID.Command_HideSampleMapEdit)
    else Plugin.Globals.MotherShip.SendMessageUsingGuiThread(TLucidMsgID.Command_ShowSampleMapEdit);

end;

procedure TSampleDisplayMenu.EventHandle_EditSamplePoints(Sender: TObject);
begin
  if not assigned(Plugin) then exit;
  Plugin.Globals.MotherShip.SendMessageUsingGuiThread(TLucidMsgID.Command_ShowLoopEditFrame);
end;

procedure TSampleDisplayMenu.EventHandle_NormaliseSample(Sender: TObject);
begin
  if not assigned(Plugin) then exit;
  Command.NormaliseSamples(Plugin);
end;

procedure TSampleDisplayMenu.EventHandle_ShowInWindowsExplorer(Sender: TObject);
var
  Region : IRegion;
  fn : string;
begin
  if not assigned(Plugin) then exit;

  Region := Plugin.FocusedRegion;

  if assigned(Region) then
  begin
    fn := Region.GetProperties^.SampleFileName;
    if FileExists(Fn) then
    begin
      OpenFolderAndSelectFile(Fn);
    end;

  end;
end;

procedure TSampleDisplayMenu.EventHandle_ModulationCommand(Sender: TObject);
begin

end;



end.
