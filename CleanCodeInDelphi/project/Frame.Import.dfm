object FrameImport: TFrameImport
  Left = 0
  Top = 0
  Width = 320
  Height = 240
  TabOrder = 0
  object Panel1: TPanel
    AlignWithMargins = True
    Left = 20
    Top = 100
    Width = 280
    Height = 81
    Margins.Left = 20
    Margins.Top = 100
    Margins.Right = 20
    Align = alTop
    Caption = 'Panel1'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -27
    Font.Name = 'Tahoma'
    Font.Style = []
    ParentFont = False
    TabOrder = 0
    ExplicitLeft = 72
    ExplicitTop = 104
    ExplicitWidth = 185
  end
  object tmrFrameReady: TTimer
    Interval = 1
    OnTimer = tmrFrameReadyTimer
    Left = 32
    Top = 8
  end
end
