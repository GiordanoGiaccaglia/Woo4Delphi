object CategoriesFrame: TCategoriesFrame
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
    object ButtonList: TButton
      AlignWithMargins = True
      Left = 3
      Top = 3
      Width = 100
      Height = 29
      Align = alLeft
      Caption = 'Elenco'
      TabOrder = 0
      OnClick = ButtonListClick
    end
    object LabelCount: TLabel
      AlignWithMargins = True
      Left = 109
      Top = 3
      Width = 150
      Height = 29
      Align = alLeft
      AutoSize = False
      Layout = tlCenter
    end
  end
  object PanelEdit: TPanel
    Left = 670
    Top = 35
    Width = 330
    Height = 585
    Align = alRight
    BevelOuter = bvNone
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
    object LabelSlug: TLabel
      AlignWithMargins = True
      Left = 3
      Top = 50
      Width = 324
      Height = 15
      Margins.Top = 0
      Margins.Bottom = 0
      Align = alTop
      Caption = 'Slug (vuoto = ricavato dal nome)'
    end
    object EditSlug: TEdit
      AlignWithMargins = True
      Left = 3
      Top = 70
      Width = 324
      Height = 23
      Align = alTop
      TabOrder = 1
    end
    object LabelParent: TLabel
      AlignWithMargins = True
      Left = 3
      Top = 100
      Width = 324
      Height = 15
      Margins.Top = 0
      Margins.Bottom = 0
      Align = alTop
      Caption = 'Categoria genitore'
    end
    object ComboParent: TComboBox
      AlignWithMargins = True
      Left = 3
      Top = 120
      Width = 324
      Height = 23
      Align = alTop
      Style = csDropDownList
      TabOrder = 2
    end
    object LabelDescription: TLabel
      AlignWithMargins = True
      Left = 3
      Top = 150
      Width = 324
      Height = 15
      Margins.Top = 0
      Margins.Bottom = 0
      Align = alTop
      Caption = 'Descrizione'
    end
    object MemoDescription: TMemo
      AlignWithMargins = True
      Left = 3
      Top = 170
      Width = 324
      Height = 100
      Align = alTop
      ScrollBars = ssVertical
      TabOrder = 3
    end
    object ButtonAdd: TButton
      AlignWithMargins = True
      Left = 3
      Top = 280
      Width = 324
      Height = 25
      Align = alTop
      Caption = 'Crea come nuova categoria'
      TabOrder = 4
      OnClick = ButtonAddClick
    end
    object ButtonSave: TButton
      AlignWithMargins = True
      Left = 3
      Top = 310
      Width = 324
      Height = 25
      Align = alTop
      Caption = 'Salva modifiche'
      TabOrder = 5
      OnClick = ButtonSaveClick
    end
    object ButtonDelete: TButton
      AlignWithMargins = True
      Left = 3
      Top = 340
      Width = 324
      Height = 25
      Align = alTop
      Caption = 'Elimina (definitivo)'
      TabOrder = 6
      OnClick = ButtonDeleteClick
    end
  end
  object SplitterRight: TSplitter
    Left = 666
    Top = 35
    Width = 4
    Height = 585
    Align = alRight
  end
  object ListCategories: TListView
    Left = 0
    Top = 35
    Width = 666
    Height = 585
    Align = alClient
    Columns = <
      item
        Caption = 'ID'
        Width = 60
      end
      item
        Caption = 'Nome'
        Width = 220
      end
      item
        Caption = 'Slug'
        Width = 160
      end
      item
        Caption = 'Genitore'
        Width = 140
      end
      item
        Caption = 'Prodotti'
        Width = 60
      end>
    HideSelection = False
    ReadOnly = True
    RowSelect = True
    TabOrder = 1
    ViewStyle = vsReport
    OnSelectItem = ListCategoriesSelectItem
  end
end
