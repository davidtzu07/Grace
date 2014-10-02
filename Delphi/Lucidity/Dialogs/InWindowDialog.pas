unit InWindowDialog;

interface

uses
  Vcl.Forms,
  InWindowDialog.MessageDialog, InWindowDialog.InputDialog;

type
  TInputDialogResult = InWindowDialog.InputDialog.TDialogResult;


procedure InWindow_ShowMessage(const TopLevelForm : TForm; const Msg : string);
procedure InWindow_InputDialog(const TopLevelForm : TForm; const Text, InputLabel, DefaultValue : string; ResultHandler : TInputDialogResult);


// TODO:HIGH need an InWindow about dialog to replace uAboutDialog.pas.


{
  Text, InputLabel, DefaultValue : string;
  ResultHandler : TInputDialogResult;

  Text         := 'Rename File';
  InputLabel   := '';
  DefaultValue := fn;
  ResultHandler := procedure(ResultText : string)
  var
  begin
  end;
  InWindow_InputDialog(Plugin.Globals.TopLevelForm, Text, InputLabel, DefaultValue, ResultHandler);
  }

implementation

procedure InWindow_ShowMessage(const TopLevelForm : TForm; const Msg : string);
var
  MsgDialog : TMessageDialog;
begin
  MsgDialog := TMessageDialog.Create;
  MsgDialog.Text := Msg;
  MsgDialog.ShowInWindow_WithAutoFree(TopLevelForm, true, true);
end;

procedure InWindow_InputDialog(const TopLevelForm : TForm; const Text, InputLabel, DefaultValue : string; ResultHandler : TInputDialogResult);
var
  InputDialog : TInputDialog;
begin
  InputDialog := TInputDialog.Create;
  InputDialog.InputText := Text;
  InputDialog.InputLabel := InputLabel;
  InputDialog.DefaultValue := DefaultValue;
  InputDialog.DialogResultHandler := ResultHandler;
  InputDialog.ShowInWindow_WithAutoFree(TopLevelForm, true, true);
end;

end.