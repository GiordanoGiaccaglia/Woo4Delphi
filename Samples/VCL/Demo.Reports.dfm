object ReportsFrame: TReportsFrame
  Left = 0
  Top = 0
  Width = 1000
  Height = 620
  TabOrder = 0
  object PanelReports: TPanel
    Left = 0
    Top = 0
    Width = 1000
    Height = 35
    Align = alTop
    BevelOuter = bvNone
    TabOrder = 0
    object ComboPeriod: TComboBox
      AlignWithMargins = True
      Left = 3
      Top = 3
      Width = 110
      Height = 23
      Align = alLeft
      Style = csDropDownList
      ItemIndex = 1
      TabOrder = 0
      Text = 'month'
      Items.Strings = (
        'week'
        'month'
        'last_month'
        'year')
    end
    object ButtonSales: TButton
      AlignWithMargins = True
      Left = 119
      Top = 3
      Width = 110
      Height = 29
      Align = alLeft
      Caption = 'Report vendite'
      TabOrder = 1
      OnClick = ButtonSalesClick
    end
    object ButtonTopSellers: TButton
      AlignWithMargins = True
      Left = 235
      Top = 3
      Width = 110
      Height = 29
      Align = alLeft
      Caption = 'Pi'#249' venduti'
      TabOrder = 2
      OnClick = ButtonTopSellersClick
    end
    object ComboTotals: TComboBox
      AlignWithMargins = True
      Left = 351
      Top = 3
      Width = 110
      Height = 23
      Align = alLeft
      Style = csDropDownList
      ItemIndex = 2
      TabOrder = 3
      Text = 'orders'
      Items.Strings = (
        'coupons'
        'customers'
        'orders'
        'products'
        'reviews')
    end
    object ButtonTotals: TButton
      AlignWithMargins = True
      Left = 467
      Top = 3
      Width = 90
      Height = 29
      Align = alLeft
      Caption = 'Totali'
      TabOrder = 4
      OnClick = ButtonTotalsClick
    end
  end
  object PanelSystem: TPanel
    Left = 0
    Top = 35
    Width = 1000
    Height = 35
    Align = alTop
    BevelOuter = bvNone
    TabOrder = 1
    object ButtonSystemStatus: TButton
      AlignWithMargins = True
      Left = 3
      Top = 3
      Width = 120
      Height = 29
      Align = alLeft
      Caption = 'Stato del sistema'
      TabOrder = 0
      OnClick = ButtonSystemStatusClick
    end
    object ButtonTools: TButton
      AlignWithMargins = True
      Left = 129
      Top = 3
      Width = 120
      Height = 29
      Align = alLeft
      Caption = 'Strumenti'
      TabOrder = 1
      OnClick = ButtonToolsClick
    end
    object ComboTools: TComboBox
      AlignWithMargins = True
      Left = 255
      Top = 3
      Width = 220
      Height = 23
      Align = alLeft
      Style = csDropDownList
      TabOrder = 2
    end
    object ButtonRunTool: TButton
      AlignWithMargins = True
      Left = 481
      Top = 3
      Width = 120
      Height = 29
      Align = alLeft
      Caption = 'Esegui strumento'
      TabOrder = 3
      OnClick = ButtonRunToolClick
    end
    object ButtonCurrency: TButton
      AlignWithMargins = True
      Left = 607
      Top = 3
      Width = 120
      Height = 29
      Align = alLeft
      Caption = 'Valuta del negozio'
      TabOrder = 4
      OnClick = ButtonCurrencyClick
    end
    object ButtonCustomFields: TButton
      AlignWithMargins = True
      Left = 733
      Top = 3
      Width = 170
      Height = 29
      Align = alLeft
      Caption = 'Campi personalizzati'
      TabOrder = 5
      OnClick = ButtonCustomFieldsClick
    end
  end
  object PanelOther: TPanel
    Left = 0
    Top = 70
    Width = 1000
    Height = 35
    Align = alTop
    BevelOuter = bvNone
    TabOrder = 2
    object EditZone: TEdit
      AlignWithMargins = True
      Left = 3
      Top = 3
      Width = 80
      Height = 29
      Align = alLeft
      NumbersOnly = True
      TabOrder = 0
      TextHint = 'ID zona'
    end
    object ButtonLocations: TButton
      AlignWithMargins = True
      Left = 89
      Top = 3
      Width = 120
      Height = 29
      Align = alLeft
      Caption = 'Leggi localit'#224
      TabOrder = 1
      OnClick = ButtonLocationsClick
    end
    object ButtonSaveLocations: TButton
      AlignWithMargins = True
      Left = 215
      Top = 3
      Width = 170
      Height = 29
      Align = alLeft
      Caption = 'Salva localit'#224' (dal JSON)'
      TabOrder = 2
      OnClick = ButtonSaveLocationsClick
    end
    object EditCustomer: TEdit
      AlignWithMargins = True
      Left = 391
      Top = 3
      Width = 80
      Height = 29
      Align = alLeft
      NumbersOnly = True
      TabOrder = 3
      TextHint = 'ID cliente'
    end
    object ButtonDownloads: TButton
      AlignWithMargins = True
      Left = 477
      Top = 3
      Width = 140
      Height = 29
      Align = alLeft
      Caption = 'Download del cliente'
      TabOrder = 4
      OnClick = ButtonDownloadsClick
    end
  end
  object MemoResult: TMemo
    AlignWithMargins = True
    Left = 3
    Top = 108
    Width = 994
    Height = 509
    Align = alClient
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -12
    Font.Name = 'Consolas'
    Font.Style = []
    ParentFont = False
    ScrollBars = ssBoth
    TabOrder = 3
    WordWrap = False
  end
end
