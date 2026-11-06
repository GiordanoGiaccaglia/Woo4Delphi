object ResourcesFrame: TResourcesFrame
  Left = 0
  Top = 0
  Width = 1000
  Height = 620
  TabOrder = 0
  object PanelList: TPanel
    Left = 0
    Top = 0
    Width = 1000
    Height = 35
    Align = alTop
    BevelOuter = bvNone
    TabOrder = 0
    object ComboResource: TComboBox
      AlignWithMargins = True
      Left = 3
      Top = 3
      Width = 260
      Height = 23
      Align = alLeft
      Style = csDropDownList
      DropDownCount = 30
      TabOrder = 0
      OnChange = ComboResourceChange
    end
    object EditParent: TEdit
      AlignWithMargins = True
      Left = 269
      Top = 3
      Width = 160
      Height = 29
      Align = alLeft
      TabOrder = 1
    end
    object EditParams: TEdit
      AlignWithMargins = True
      Left = 435
      Top = 3
      Width = 300
      Height = 29
      Align = alLeft
      TabOrder = 2
      TextHint = 'Filtri: status=processing&search=caffe'
    end
    object ButtonList: TButton
      AlignWithMargins = True
      Left = 741
      Top = 3
      Width = 90
      Height = 29
      Align = alLeft
      Caption = 'Elenco'
      TabOrder = 3
      OnClick = ButtonListClick
    end
    object LabelCount: TLabel
      AlignWithMargins = True
      Left = 837
      Top = 3
      Width = 120
      Height = 29
      Align = alLeft
      AutoSize = False
      Layout = tlCenter
    end
  end
  object PanelItem: TPanel
    Left = 0
    Top = 35
    Width = 1000
    Height = 35
    Align = alTop
    BevelOuter = bvNone
    TabOrder = 1
    object EditID: TEdit
      AlignWithMargins = True
      Left = 3
      Top = 3
      Width = 160
      Height = 29
      Align = alLeft
      TabOrder = 0
      TextHint = 'ID'
    end
    object ButtonGet: TButton
      AlignWithMargins = True
      Left = 169
      Top = 3
      Width = 70
      Height = 29
      Align = alLeft
      Caption = 'Leggi'
      TabOrder = 1
      OnClick = ButtonGetClick
    end
    object ButtonAdd: TButton
      AlignWithMargins = True
      Left = 245
      Top = 3
      Width = 150
      Height = 29
      Align = alLeft
      Caption = 'Crea dal JSON a destra'
      TabOrder = 2
      OnClick = ButtonAddClick
    end
    object CheckForce: TCheckBox
      AlignWithMargins = True
      Left = 401
      Top = 3
      Width = 170
      Height = 29
      Align = alLeft
      Caption = 'Definitivo (senza cestino)'
      TabOrder = 3
    end
    object ButtonDelete: TButton
      AlignWithMargins = True
      Left = 577
      Top = 3
      Width = 80
      Height = 29
      Align = alLeft
      Caption = 'Elimina'
      TabOrder = 4
      OnClick = ButtonDeleteClick
    end
  end
  object PanelUpdate: TPanel
    Left = 0
    Top = 70
    Width = 1000
    Height = 35
    Align = alTop
    BevelOuter = bvNone
    TabOrder = 2
    object EditFields: TEdit
      AlignWithMargins = True
      Left = 3
      Top = 3
      Width = 300
      Height = 29
      Align = alLeft
      TabOrder = 0
      TextHint = 'Campi da aggiornare: name, regular_price'
    end
    object ButtonUpdate: TButton
      AlignWithMargins = True
      Left = 309
      Top = 3
      Width = 180
      Height = 29
      Align = alLeft
      Caption = 'Aggiorna con il JSON a destra'
      TabOrder = 1
      OnClick = ButtonUpdateClick
    end
    object ButtonBatchUpdate: TButton
      AlignWithMargins = True
      Left = 495
      Top = 3
      Width = 190
      Height = 29
      Align = alLeft
      Caption = 'Batch: aggiorna le righe scelte'
      TabOrder = 2
      OnClick = ButtonBatchUpdateClick
    end
    object ButtonBatchDelete: TButton
      AlignWithMargins = True
      Left = 691
      Top = 3
      Width = 180
      Height = 29
      Align = alLeft
      Caption = 'Batch: elimina le righe scelte'
      TabOrder = 3
      OnClick = ButtonBatchDeleteClick
    end
  end
  object MemoJSON: TMemo
    AlignWithMargins = True
    Left = 553
    Top = 108
    Width = 444
    Height = 509
    Align = alRight
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -12
    Font.Name = 'Consolas'
    Font.Style = []
    ParentFont = False
    ScrollBars = ssBoth
    TabOrder = 4
    WordWrap = False
  end
  object SplitterRight: TSplitter
    Left = 546
    Top = 105
    Width = 4
    Height = 515
    Align = alRight
  end
  object ListItems: TListView
    Left = 0
    Top = 105
    Width = 546
    Height = 515
    Align = alClient
    Columns = <
      item
        Caption = 'ID'
        Width = 140
      end
      item
        Caption = 'Descrizione'
        Width = 360
      end>
    HideSelection = False
    MultiSelect = True
    ReadOnly = True
    RowSelect = True
    TabOrder = 3
    ViewStyle = vsReport
    OnSelectItem = ListItemsSelectItem
  end
end
