object ProductsFrame: TProductsFrame
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
    object EditSearch: TEdit
      AlignWithMargins = True
      Left = 3
      Top = 3
      Width = 220
      Height = 29
      Align = alLeft
      TabOrder = 0
      TextHint = 'Cerca nome o SKU'
    end
    object ButtonList: TButton
      AlignWithMargins = True
      Left = 229
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
      Left = 335
      Top = 3
      Width = 150
      Height = 29
      Align = alLeft
      AutoSize = False
      Layout = tlCenter
    end
  end
  object PanelVariations: TPanel
    Left = 0
    Top = 450
    Width = 1000
    Height = 170
    Align = alBottom
    BevelOuter = bvNone
    TabOrder = 3
    object PanelVariationsTop: TPanel
      Left = 0
      Top = 0
      Width = 1000
      Height = 35
      Align = alTop
      BevelOuter = bvNone
      TabOrder = 0
      object ButtonVariations: TButton
        AlignWithMargins = True
        Left = 3
        Top = 3
        Width = 150
        Height = 29
        Align = alLeft
        Caption = 'Variazioni del prodotto'
        TabOrder = 0
        OnClick = ButtonVariationsClick
      end
      object EditVarPrice: TEdit
        AlignWithMargins = True
        Left = 159
        Top = 3
        Width = 90
        Height = 29
        Align = alLeft
        TabOrder = 1
        TextHint = 'Prezzo listino'
      end
      object EditVarStock: TEdit
        AlignWithMargins = True
        Left = 255
        Top = 3
        Width = 70
        Height = 29
        Align = alLeft
        TabOrder = 2
        TextHint = 'Stock'
      end
      object ButtonVarSave: TButton
        AlignWithMargins = True
        Left = 331
        Top = 3
        Width = 120
        Height = 29
        Align = alLeft
        Caption = 'Salva variazione'
        TabOrder = 3
        OnClick = ButtonVarSaveClick
      end
      object EditVarAttribute: TEdit
        AlignWithMargins = True
        Left = 457
        Top = 3
        Width = 100
        Height = 29
        Align = alLeft
        TabOrder = 4
        TextHint = 'Attributo'
      end
      object EditVarOption: TEdit
        AlignWithMargins = True
        Left = 563
        Top = 3
        Width = 100
        Height = 29
        Align = alLeft
        TabOrder = 5
        TextHint = 'Valore'
      end
      object ButtonVarAdd: TButton
        AlignWithMargins = True
        Left = 669
        Top = 3
        Width = 140
        Height = 29
        Align = alLeft
        Caption = 'Aggiungi variazione'
        TabOrder = 6
        OnClick = ButtonVarAddClick
      end
      object ButtonVarDelete: TButton
        AlignWithMargins = True
        Left = 815
        Top = 3
        Width = 90
        Height = 29
        Align = alLeft
        Caption = 'Elimina'
        TabOrder = 7
        OnClick = ButtonVarDeleteClick
      end
    end
    object MemoJSON: TMemo
      AlignWithMargins = True
      Left = 667
      Top = 38
      Width = 330
      Height = 129
      Align = alRight
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
    object ListVariations: TListView
      Left = 0
      Top = 35
      Width = 1000
      Height = 155
      Align = alClient
      Columns = <
        item
          Caption = 'ID'
          Width = 70
        end
        item
          Caption = 'SKU'
          Width = 120
        end
        item
          Caption = 'Attributi'
          Width = 300
        end
        item
          Caption = 'Prezzo'
          Width = 90
        end
        item
          Caption = 'Stock'
          Width = 90
        end>
      HideSelection = False
      ReadOnly = True
      RowSelect = True
      TabOrder = 1
      ViewStyle = vsReport
      OnSelectItem = ListVariationsSelectItem
    end
  end
  object SplitterBottom: TSplitter
    Left = 0
    Top = 446
    Width = 1000
    Height = 4
    Cursor = crVSplit
    Align = alBottom
  end
  object PanelEdit: TScrollBox
    Left = 650
    Top = 35
    Width = 350
    Height = 411
    VertScrollBar.Tracking = True
    Align = alRight
    BorderStyle = bsNone
    TabOrder = 2
    object LabelName: TLabel
      AlignWithMargins = True
      Left = 3
      Top = 0
      Width = 324
      Height = 15
      Margins.Top = 0
      Margins.Bottom = 0
      Align = alTop
      Caption = 'Nome'
    end
    object EditName: TEdit
      AlignWithMargins = True
      Left = 3
      Top = 20
      Width = 324
      Height = 23
      Align = alTop
      TabOrder = 0
    end
    object LabelSku: TLabel
      AlignWithMargins = True
      Left = 3
      Top = 50
      Width = 324
      Height = 15
      Margins.Top = 0
      Margins.Bottom = 0
      Align = alTop
      Caption = 'SKU'
    end
    object EditSku: TEdit
      AlignWithMargins = True
      Left = 3
      Top = 70
      Width = 324
      Height = 23
      Align = alTop
      TabOrder = 1
    end
    object LabelEan: TLabel
      AlignWithMargins = True
      Left = 3
      Top = 100
      Width = 324
      Height = 15
      Margins.Top = 0
      Margins.Bottom = 0
      Align = alTop
      Caption = 'EAN / GTIN / UPC / ISBN (global_unique_id)'
    end
    object EditEan: TEdit
      AlignWithMargins = True
      Left = 3
      Top = 120
      Width = 324
      Height = 23
      Align = alTop
      TabOrder = 2
    end
    object LabelRegularPrice: TLabel
      AlignWithMargins = True
      Left = 3
      Top = 150
      Width = 324
      Height = 15
      Margins.Top = 0
      Margins.Bottom = 0
      Align = alTop
      Caption = 'Prezzo di listino (regular_price)'
    end
    object EditRegularPrice: TEdit
      AlignWithMargins = True
      Left = 3
      Top = 170
      Width = 324
      Height = 23
      Align = alTop
      TabOrder = 3
    end
    object LabelSalePrice: TLabel
      AlignWithMargins = True
      Left = 3
      Top = 200
      Width = 324
      Height = 15
      Margins.Top = 0
      Margins.Bottom = 0
      Align = alTop
      Caption = 'Prezzo in saldo (sale_price, vuoto = nessun saldo)'
    end
    object EditSalePrice: TEdit
      AlignWithMargins = True
      Left = 3
      Top = 220
      Width = 324
      Height = 23
      Align = alTop
      TabOrder = 4
    end
    object LabelStatus: TLabel
      AlignWithMargins = True
      Left = 3
      Top = 250
      Width = 324
      Height = 15
      Margins.Top = 0
      Margins.Bottom = 0
      Align = alTop
      Caption = 'Stato'
    end
    object ComboStatus: TComboBox
      AlignWithMargins = True
      Left = 3
      Top = 270
      Width = 324
      Height = 23
      Align = alTop
      Style = csDropDownList
      TabOrder = 5
      Items.Strings = (
        'draft'
        'pending'
        'private'
        'publish')
    end
    object CheckManageStock: TCheckBox
      AlignWithMargins = True
      Left = 3
      Top = 300
      Width = 324
      Height = 17
      Align = alTop
      Caption = 'Gestisci magazzino (manage_stock)'
      TabOrder = 6
    end
    object LabelStock: TLabel
      AlignWithMargins = True
      Left = 3
      Top = 325
      Width = 324
      Height = 15
      Margins.Top = 0
      Margins.Bottom = 0
      Align = alTop
      Caption = 'Quantit'#224' in magazzino'
    end
    object EditStock: TEdit
      AlignWithMargins = True
      Left = 3
      Top = 345
      Width = 324
      Height = 23
      Align = alTop
      NumbersOnly = True
      TabOrder = 7
    end
    object LabelStockStatus: TLabel
      AlignWithMargins = True
      Left = 3
      Top = 375
      Width = 324
      Height = 15
      Margins.Top = 0
      Margins.Bottom = 0
      Align = alTop
      Caption = 'Stato magazzino (se gestisci il magazzino lo calcola WooCommerce)'
    end
    object ComboStockStatus: TComboBox
      AlignWithMargins = True
      Left = 3
      Top = 395
      Width = 324
      Height = 23
      Align = alTop
      Style = csDropDownList
      TabOrder = 8
      Items.Strings = (
        'instock'
        'outofstock'
        'onbackorder')
    end
    object LabelCategories: TLabel
      AlignWithMargins = True
      Left = 3
      Top = 425
      Width = 324
      Height = 15
      Margins.Top = 0
      Margins.Bottom = 0
      Align = alTop
      Caption = 'Categorie (nessuna = categoria predefinita)'
    end
    object ListCategories: TCheckListBox
      AlignWithMargins = True
      Left = 3
      Top = 445
      Width = 324
      Height = 110
      Align = alTop
      ItemHeight = 17
      TabOrder = 9
    end
    object LabelImages: TLabel
      AlignWithMargins = True
      Left = 3
      Top = 565
      Width = 324
      Height = 15
      Margins.Top = 0
      Margins.Bottom = 0
      Align = alTop
      Caption = 'Immagini (la prima '#232' la principale, le altre la galleria)'
    end
    object ListImages: TListBox
      AlignWithMargins = True
      Left = 3
      Top = 585
      Width = 324
      Height = 90
      Align = alTop
      ItemHeight = 15
      TabOrder = 10
    end
    object PanelImageButtons: TPanel
      Left = 0
      Top = 680
      Width = 330
      Height = 31
      Align = alTop
      BevelOuter = bvNone
      TabOrder = 11
      object ButtonImageFile: TButton
        AlignWithMargins = True
        Left = 3
        Top = 3
        Width = 104
        Height = 25
        Align = alLeft
        Caption = 'Carica file...'
        TabOrder = 0
        OnClick = ButtonImageFileClick
      end
      object ButtonImageMain: TButton
        AlignWithMargins = True
        Left = 113
        Top = 3
        Width = 104
        Height = 25
        Align = alLeft
        Caption = 'Rendi principale'
        TabOrder = 1
        OnClick = ButtonImageMainClick
      end
      object ButtonImageRemove: TButton
        AlignWithMargins = True
        Left = 223
        Top = 3
        Width = 104
        Height = 25
        Align = alLeft
        Caption = 'Togli'
        TabOrder = 2
        OnClick = ButtonImageRemoveClick
      end
    end
    object PanelImageUrl: TPanel
      Left = 0
      Top = 715
      Width = 330
      Height = 31
      Align = alTop
      BevelOuter = bvNone
      TabOrder = 12
      object EditImageUrl: TEdit
        AlignWithMargins = True
        Left = 3
        Top = 3
        Width = 238
        Height = 25
        Align = alClient
        TabOrder = 0
        TextHint = 'https://... (la scarica WooCommerce)'
      end
      object ButtonImageUrl: TButton
        AlignWithMargins = True
        Left = 247
        Top = 3
        Width = 80
        Height = 25
        Align = alRight
        Caption = 'Da URL'
        TabOrder = 1
        OnClick = ButtonImageUrlClick
      end
    end
    object ButtonAdd: TButton
      AlignWithMargins = True
      Left = 3
      Top = 750
      Width = 324
      Height = 25
      Align = alTop
      Caption = 'Crea come nuovo prodotto'
      TabOrder = 13
      OnClick = ButtonAddClick
    end
    object ButtonSave: TButton
      AlignWithMargins = True
      Left = 3
      Top = 780
      Width = 324
      Height = 25
      Align = alTop
      Caption = 'Salva modifiche (solo i campi qui sopra)'
      TabOrder = 14
      OnClick = ButtonSaveClick
    end
    object ButtonDuplicate: TButton
      AlignWithMargins = True
      Left = 3
      Top = 810
      Width = 324
      Height = 25
      Align = alTop
      Caption = 'Duplica'
      TabOrder = 15
      OnClick = ButtonDuplicateClick
    end
    object ButtonTrash: TButton
      AlignWithMargins = True
      Left = 3
      Top = 840
      Width = 324
      Height = 25
      Align = alTop
      Caption = 'Sposta nel cestino'
      TabOrder = 16
      OnClick = ButtonTrashClick
    end
    object ButtonDelete: TButton
      AlignWithMargins = True
      Left = 3
      Top = 870
      Width = 324
      Height = 25
      Align = alTop
      Caption = 'Elimina definitivamente'
      TabOrder = 17
      OnClick = ButtonDeleteClick
    end
  end
  object SplitterRight: TSplitter
    Left = 646
    Top = 35
    Width = 4
    Height = 391
    Align = alRight
  end
  object ListProducts: TListView
    Left = 0
    Top = 35
    Width = 646
    Height = 411
    Align = alClient
    Columns = <
      item
        Caption = 'ID'
        Width = 60
      end
      item
        Caption = 'Nome'
        Width = 240
      end
      item
        Caption = 'SKU'
        Width = 110
      end
      item
        Caption = 'Tipo'
        Width = 75
      end
      item
        Caption = 'Prezzo'
        Width = 70
      end
      item
        Caption = 'Stock'
        Width = 80
      end>
    HideSelection = False
    ReadOnly = True
    RowSelect = True
    TabOrder = 1
    ViewStyle = vsReport
    OnSelectItem = ListProductsSelectItem
  end
  object OpenDialogImage: TOpenDialog
    Filter = 'Immagini (*.jpg;*.jpeg;*.png;*.gif;*.webp)|*.jpg;*.jpeg;*.png;*.gif;*.webp'
    Options = [ofHideReadOnly, ofAllowMultiSelect, ofFileMustExist, ofEnableSizing]
    Title = 'Immagini da caricare nella libreria media'
    Left = 40
    Top = 120
  end
end
