object ScrollPanelFrame: TScrollPanelFrame
  Left = 0
  Top = 0
  Width = 811
  Height = 717
  TabOrder = 0
  object Panel: TRedFoxContainer
    AlignWithMargins = True
    Left = 2
    Top = 2
    Width = 807
    Height = 713
    Margins.Left = 2
    Margins.Top = 2
    Margins.Right = 2
    Margins.Bottom = 2
    Color = '$FFEEEEEE'
    Align = alClient
    object ScrollPanel: TVamPanel
      AlignWithMargins = True
      Left = 2
      Top = 2
      Width = 803
      Height = 709
      Margins.Left = 2
      Margins.Top = 2
      Margins.Right = 2
      Margins.Bottom = 2
      HitTest = True
      Color = '$FFCCCCCC'
      CornerRadius1 = 4.000000000000000000
      CornerRadius2 = 4.000000000000000000
      CornerRadius3 = 4.000000000000000000
      CornerRadius4 = 4.000000000000000000
      Transparent = False
      Align = alClient
      Visible = True
      Padding.Left = 4
      Padding.Top = 4
      Padding.Right = 4
      Padding.Bottom = 4
      object MainPanelScrollBox: TVamScrollBox
        Left = 4
        Top = 4
        Width = 795
        Height = 701
        HitTest = True
        Color_Border = '$FF000000'
        Color_Background = '$FF888888'
        Color_Foreground = '$FFCCCCCC'
        ScrollBars = ssVertical
        ScrollBarWidth = 16
        ScrollYPos = 1.000000000000000000
        ScrollXIndexSize = 0.250000000000000000
        ScrollYIndexSize = 0.250000000000000000
        Align = alClient
        Visible = True
        object MainPanelOuterDiv: TVamDiv
          AlignWithMargins = True
          Left = 2
          Top = 2
          Width = 775
          Height = 697
          Margins.Left = 2
          Margins.Top = 2
          Margins.Right = 2
          Margins.Bottom = 2
          HitTest = True
          Align = alClient
          Visible = True
          object MainPanelInnerDiv: TVamDiv
            Left = 72
            Top = 136
            Width = 313
            Height = 249
            Margins.Left = 2
            Margins.Top = 2
            Margins.Right = 2
            Margins.Bottom = 2
            HitTest = True
            Visible = True
          end
        end
      end
    end
  end
end
