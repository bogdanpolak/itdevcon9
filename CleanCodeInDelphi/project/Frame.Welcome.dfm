object FrameWelcome: TFrameWelcome
  Left = 0
  Top = 0
  Width = 320
  Height = 330
  TabOrder = 0
  object Bevel1: TBevel
    AlignWithMargins = True
    Left = 3
    Top = 3
    Width = 314
    Height = 50
    Align = alTop
    Shape = bsSpacer
    ExplicitLeft = 136
    ExplicitTop = 96
    ExplicitWidth = 50
  end
  object Panel1: TPanel
    AlignWithMargins = True
    Left = 3
    Top = 59
    Width = 314
    Height = 102
    Align = alTop
    Caption = ' '
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -13
    Font.Name = 'Tahoma'
    Font.Style = []
    ParentFont = False
    TabOrder = 0
    object lbAppName: TLabel
      AlignWithMargins = True
      Left = 4
      Top = 21
      Width = 306
      Height = 40
      Margins.Top = 20
      Align = alTop
      Alignment = taCenter
      Caption = 'lbAppName'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -33
      Font.Name = 'Tahoma'
      Font.Style = []
      ParentFont = False
      ExplicitTop = 4
      ExplicitWidth = 166
    end
    object lbAppVersion: TLabel
      AlignWithMargins = True
      Left = 4
      Top = 67
      Width = 306
      Height = 16
      Align = alTop
      Alignment = taCenter
      Caption = 'lbAppVersion'
      ExplicitWidth = 75
    end
  end
  object lbxMessages: TListBox
    AlignWithMargins = True
    Left = 3
    Top = 167
    Width = 314
    Height = 146
    Align = alTop
    BevelKind = bkFlat
    BorderStyle = bsNone
    Color = clBtnFace
    ItemHeight = 13
    TabOrder = 1
  end
end
