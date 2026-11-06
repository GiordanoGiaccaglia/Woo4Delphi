object RawFrame: TRawFrame
  Left = 0
  Top = 0
  Width = 1000
  Height = 620
  TabOrder = 0
  object PanelTop: TPanel
    Left = 0
    Top = 0
    Width = 1000
    Height = 35
    Align = alTop
    BevelOuter = bvNone
    TabOrder = 0
    object ComboMethod: TComboBox
      AlignWithMargins = True
      Left = 3
      Top = 3
      Width = 90
      Height = 23
      Align = alLeft
      Style = csDropDownList
      ItemIndex = 0
      TabOrder = 0
      Text = 'GET'
      Items.Strings = (
        'GET'
        'POST'
        'PUT'
        'DELETE')
    end
    object EditEndpoint: TEdit
      AlignWithMargins = True
      Left = 99
      Top = 3
      Width = 420
      Height = 29
      Align = alLeft
      TabOrder = 1
      Text = 'products?per_page=5'
      TextHint = 'Endpoint dopo /wp-json/wc/v3/, es. orders/123?dp=4'
    end
    object ButtonSend: TButton
      AlignWithMargins = True
      Left = 525
      Top = 3
      Width = 90
      Height = 29
      Align = alLeft
      Caption = 'Invia'
      TabOrder = 2
      OnClick = ButtonSendClick
    end
    object LabelInfo: TLabel
      AlignWithMargins = True
      Left = 621
      Top = 3
      Width = 370
      Height = 29
      Align = alLeft
      AutoSize = False
      Layout = tlCenter
    end
  end
  object LabelBody: TLabel
    AlignWithMargins = True
    Left = 3
    Top = 38
    Width = 994
    Height = 15
    Align = alTop
    Caption = 'Body JSON (per POST e PUT)'
  end
  object MemoBody: TMemo
    AlignWithMargins = True
    Left = 3
    Top = 59
    Width = 994
    Height = 140
    Align = alTop
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -12
    Font.Name = 'Consolas'
    Font.Style = []
    Lines.Strings = (
      '{}')
    ParentFont = False
    ScrollBars = ssBoth
    TabOrder = 1
    WordWrap = False
  end
  object SplitterBody: TSplitter
    Left = 0
    Top = 202
    Width = 1000
    Height = 4
    Cursor = crVSplit
    Align = alTop
  end
  object MemoResponse: TMemo
    AlignWithMargins = True
    Left = 3
    Top = 209
    Width = 994
    Height = 408
    Align = alClient
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -12
    Font.Name = 'Consolas'
    Font.Style = []
    ParentFont = False
    ReadOnly = True
    ScrollBars = ssBoth
    TabOrder = 2
    WordWrap = False
  end
end
