object InputDialogForm: TInputDialogForm
  Left = 0
  Top = 0
  Caption = 'InputBoxDialogForm'
  ClientHeight = 300
  ClientWidth = 635
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  KeyPreview = True
  OldCreateOrder = False
  OnDeactivate = FormDeactivate
  OnKeyDown = FormKeyDown
  OnKeyPress = FormKeyPress
  PixelsPerInch = 96
  TextHeight = 13
  object RedFoxContainer1: TRedFoxContainer
    Left = 0
    Top = 0
    Width = 635
    Height = 300
    Color = '$FFEEEEEE'
    Align = alClient
    object BackPanel1: TVamPanel
      Left = 0
      Top = 0
      Width = 635
      Height = 300
      Opacity = 255
      Text = 'BackPanel1'
      HitTest = True
      Color = '$FF000000'
      Transparent = False
      Align = alClient
      Visible = True
      object BackPanel2: TVamPanel
        AlignWithMargins = True
        Left = 3
        Top = 3
        Width = 629
        Height = 294
        Opacity = 255
        Text = 'BackPanel2'
        HitTest = True
        Color = '$FFCCCCCC'
        CornerRadius1 = 3.000000000000000000
        CornerRadius2 = 3.000000000000000000
        CornerRadius3 = 3.000000000000000000
        CornerRadius4 = 3.000000000000000000
        Transparent = False
        Align = alClient
        Visible = True
        object ButtonDiv: TVamDiv
          AlignWithMargins = True
          Left = 8
          Top = 258
          Width = 613
          Height = 28
          Margins.Left = 8
          Margins.Top = 8
          Margins.Right = 8
          Margins.Bottom = 8
          Opacity = 255
          Text = 'ButtonDiv'
          HitTest = True
          Align = alBottom
          Visible = True
          OnResize = ButtonDivResize
          object OkButton: TButton
            Left = 152
            Top = 3
            Width = 97
            Height = 22
            Caption = 'OK'
            TabOrder = 0
            OnClick = OkButtonClick
          end
          object CancelButton: TButton
            Left = 272
            Top = 3
            Width = 97
            Height = 22
            Caption = 'Cancel'
            TabOrder = 1
            OnClick = CancelButtonClick
          end
        end
        object MainDialogArea: TVamDiv
          AlignWithMargins = True
          Left = 8
          Top = 8
          Width = 613
          Height = 198
          Margins.Left = 8
          Margins.Top = 8
          Margins.Right = 8
          Margins.Bottom = 8
          Opacity = 255
          Text = 'ButtonDiv'
          HitTest = True
          Align = alClient
          Visible = True
          object DialogTextControl: TLabel
            Left = 48
            Top = 24
            Width = 86
            Height = 13
            Caption = 'DialogTextControl'
          end
        end
        object InputAreaDiv: TVamDiv
          AlignWithMargins = True
          Left = 8
          Top = 214
          Width = 613
          Height = 28
          Margins.Left = 8
          Margins.Top = 0
          Margins.Right = 8
          Margins.Bottom = 8
          Opacity = 255
          Text = 'InputAreaDiv'
          HitTest = True
          Align = alBottom
          Visible = True
          object InputLabelControl: TLabel
            AlignWithMargins = True
            Left = 0
            Top = 3
            Width = 86
            Height = 25
            Margins.Left = 0
            Margins.Right = 4
            Align = alLeft
            Caption = 'InputLabelControl'
            ExplicitHeight = 13
          end
          object InputEditControl: TEdit
            AlignWithMargins = True
            Left = 120
            Top = 0
            Width = 161
            Height = 21
            Margins.Left = 0
            Margins.Top = 0
            Margins.Right = 0
            Margins.Bottom = 0
            TabOrder = 0
            Text = 'InputEditControl'
          end
        end
      end
    end
  end
end
