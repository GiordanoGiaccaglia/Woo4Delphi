object OrdersFrame: TOrdersFrame
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
    object ComboFilter: TComboBox
      AlignWithMargins = True
      Left = 3
      Top = 3
      Width = 150
      Height = 23
      Align = alLeft
      Style = csDropDownList
      ItemIndex = 0
      TabOrder = 0
      Text = '(tutti gli stati)'
      Items.Strings = (
        '(tutti gli stati)'
        'pending'
        'processing'
        'on-hold'
        'completed'
        'cancelled'
        'refunded'
        'failed')
    end
    object ButtonList: TButton
      AlignWithMargins = True
      Left = 159
      Top = 3
      Width = 100
      Height = 29
      Align = alLeft
      Caption = 'Elenco'
      TabOrder = 1
      OnClick = ButtonListClick
    end
    object LabelCount: TLabel
      AlignWithMargins = True
      Left = 265
      Top = 3
      Width = 150
      Height = 29
      Align = alLeft
      AutoSize = False
      Layout = tlCenter
    end
  end
  object PanelDetail: TPanel
    Left = 520
    Top = 35
    Width = 480
    Height = 585
    Align = alRight
    BevelOuter = bvNone
    TabOrder = 2
    object MemoOrder: TMemo
      AlignWithMargins = True
      Left = 3
      Top = 3
      Width = 474
      Height = 200
      Align = alTop
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -12
      Font.Name = 'Consolas'
      Font.Style = []
      ParentFont = False
      ReadOnly = True
      ScrollBars = ssBoth
      TabOrder = 0
      WordWrap = False
    end
    object PanelStatus: TPanel
      Left = 0
      Top = 206
      Width = 480
      Height = 33
      Align = alTop
      BevelOuter = bvNone
      TabOrder = 1
      object ComboStatus: TComboBox
        AlignWithMargins = True
        Left = 3
        Top = 3
        Width = 150
        Height = 23
        Align = alLeft
        Style = csDropDownList
        TabOrder = 0
        Items.Strings = (
          'pending'
          'processing'
          'on-hold'
          'completed'
          'cancelled'
          'refunded'
          'failed')
      end
      object ButtonStatus: TButton
        AlignWithMargins = True
        Left = 159
        Top = 3
        Width = 120
        Height = 27
        Align = alLeft
        Caption = 'Cambia stato'
        TabOrder = 1
        OnClick = ButtonStatusClick
      end
    end
    object LabelNotes: TLabel
      AlignWithMargins = True
      Left = 3
      Top = 242
      Width = 474
      Height = 15
      Align = alTop
      Caption = 'Note dell'#39'ordine'
    end
    object ListNotes: TListBox
      AlignWithMargins = True
      Left = 3
      Top = 263
      Width = 474
      Height = 70
      Align = alTop
      TabOrder = 2
    end
    object PanelNote: TPanel
      Left = 0
      Top = 336
      Width = 480
      Height = 33
      Align = alTop
      BevelOuter = bvNone
      TabOrder = 3
      object EditNote: TEdit
        AlignWithMargins = True
        Left = 3
        Top = 3
        Width = 200
        Height = 27
        Align = alLeft
        TabOrder = 0
        TextHint = 'Testo della nota'
      end
      object CheckCustomerNote: TCheckBox
        AlignWithMargins = True
        Left = 209
        Top = 3
        Width = 115
        Height = 27
        Align = alLeft
        Caption = 'Visibile al cliente'
        TabOrder = 1
      end
      object ButtonAddNote: TButton
        AlignWithMargins = True
        Left = 330
        Top = 3
        Width = 70
        Height = 27
        Align = alLeft
        Caption = 'Aggiungi'
        TabOrder = 2
        OnClick = ButtonAddNoteClick
      end
      object ButtonDeleteNote: TButton
        AlignWithMargins = True
        Left = 406
        Top = 3
        Width = 70
        Height = 27
        Align = alLeft
        Caption = 'Elimina'
        TabOrder = 3
        OnClick = ButtonDeleteNoteClick
      end
    end
    object LabelRefunds: TLabel
      AlignWithMargins = True
      Left = 3
      Top = 372
      Width = 474
      Height = 15
      Align = alTop
      Caption = 'Rimborsi'
    end
    object ListRefunds: TListBox
      AlignWithMargins = True
      Left = 3
      Top = 393
      Width = 474
      Height = 50
      Align = alTop
      TabOrder = 4
    end
    object PanelRefund: TPanel
      Left = 0
      Top = 446
      Width = 480
      Height = 33
      Align = alTop
      BevelOuter = bvNone
      TabOrder = 5
      object EditRefundAmount: TEdit
        AlignWithMargins = True
        Left = 3
        Top = 3
        Width = 80
        Height = 27
        Align = alLeft
        TabOrder = 0
        TextHint = 'Importo'
      end
      object EditRefundReason: TEdit
        AlignWithMargins = True
        Left = 89
        Top = 3
        Width = 150
        Height = 27
        Align = alLeft
        TabOrder = 1
        TextHint = 'Motivo'
      end
      object CheckApiRefund: TCheckBox
        AlignWithMargins = True
        Left = 245
        Top = 3
        Width = 130
        Height = 27
        Align = alLeft
        Caption = 'Rimborsa via gateway'
        TabOrder = 2
      end
      object ButtonRefund: TButton
        AlignWithMargins = True
        Left = 381
        Top = 3
        Width = 90
        Height = 27
        Align = alLeft
        Caption = 'Rimborsa'
        TabOrder = 3
        OnClick = ButtonRefundClick
      end
    end
    object PanelEmail: TPanel
      Left = 0
      Top = 479
      Width = 480
      Height = 33
      Align = alTop
      BevelOuter = bvNone
      TabOrder = 6
      object ComboTemplates: TComboBox
        AlignWithMargins = True
        Left = 3
        Top = 3
        Width = 280
        Height = 23
        Align = alLeft
        Style = csDropDownList
        TabOrder = 0
      end
      object ButtonSendEmail: TButton
        AlignWithMargins = True
        Left = 289
        Top = 3
        Width = 120
        Height = 27
        Align = alLeft
        Caption = 'Invia e-mail'
        TabOrder = 1
        OnClick = ButtonSendEmailClick
      end
    end
    object PanelNewOrder: TPanel
      Left = 0
      Top = 512
      Width = 480
      Height = 33
      Align = alTop
      BevelOuter = bvNone
      TabOrder = 7
      object EditNewProduct: TEdit
        AlignWithMargins = True
        Left = 3
        Top = 3
        Width = 80
        Height = 27
        Align = alLeft
        NumbersOnly = True
        TabOrder = 0
        TextHint = 'ID prodotto'
      end
      object EditNewQuantity: TEdit
        AlignWithMargins = True
        Left = 89
        Top = 3
        Width = 60
        Height = 27
        Align = alLeft
        NumbersOnly = True
        TabOrder = 1
        TextHint = 'Quantit'#224
      end
      object EditNewEmail: TEdit
        AlignWithMargins = True
        Left = 155
        Top = 3
        Width = 150
        Height = 27
        Align = alLeft
        TabOrder = 2
        TextHint = 'E-mail cliente'
      end
      object CheckSetPaid: TCheckBox
        AlignWithMargins = True
        Left = 311
        Top = 3
        Width = 60
        Height = 27
        Align = alLeft
        Caption = 'Pagato'
        TabOrder = 3
      end
      object ButtonCreateOrder: TButton
        AlignWithMargins = True
        Left = 377
        Top = 3
        Width = 100
        Height = 27
        Align = alLeft
        Caption = 'Crea ordine'
        TabOrder = 4
        OnClick = ButtonCreateOrderClick
      end
    end
  end
  object SplitterRight: TSplitter
    Left = 516
    Top = 35
    Width = 4
    Height = 585
    Align = alRight
  end
  object ListOrders: TListView
    Left = 0
    Top = 35
    Width = 516
    Height = 585
    Align = alClient
    Columns = <
      item
        Caption = 'ID'
        Width = 55
      end
      item
        Caption = 'Numero'
        Width = 65
      end
      item
        Caption = 'Data'
        Width = 130
      end
      item
        Caption = 'Stato'
        Width = 85
      end
      item
        Caption = 'Cliente'
        Width = 140
      end
      item
        Caption = 'Totale'
        Width = 90
      end>
    HideSelection = False
    ReadOnly = True
    RowSelect = True
    TabOrder = 1
    ViewStyle = vsReport
    OnSelectItem = ListOrdersSelectItem
  end
end
