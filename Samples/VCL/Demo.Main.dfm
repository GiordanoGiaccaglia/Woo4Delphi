object MainForm: TMainForm
  Left = 0
  Top = 0
  Caption = 'Woo4Delphi - demo del client WooCommerce REST v3'
  ClientHeight = 860
  ClientWidth = 1240
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  Position = poScreenCenter
  OnClose = FormClose
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  TextHeight = 15
  object PanelConnection: TPanel
    Left = 0
    Top = 0
    Width = 1240
    Height = 35
    Align = alTop
    BevelOuter = bvNone
    TabOrder = 0
    object EditURL: TEdit
      AlignWithMargins = True
      Left = 3
      Top = 3
      Width = 260
      Height = 29
      Align = alLeft
      TabOrder = 0
      TextHint = 'https://negozio.example.com'
    end
    object EditKey: TEdit
      AlignWithMargins = True
      Left = 269
      Top = 3
      Width = 200
      Height = 29
      Align = alLeft
      TabOrder = 1
      TextHint = 'Consumer key (ck_...)'
    end
    object EditSecret: TEdit
      AlignWithMargins = True
      Left = 475
      Top = 3
      Width = 200
      Height = 29
      Align = alLeft
      PasswordChar = '*'
      TabOrder = 2
      TextHint = 'Consumer secret (cs_...)'
    end
    object CheckQueryStringAuth: TCheckBox
      AlignWithMargins = True
      Left = 681
      Top = 3
      Width = 170
      Height = 29
      Hint =
        'Per gli host che tolgono l'#39'header Authorization (PHP in CGI/FastCGI). ' +
        'La chiave segreta finisce nei log del server.'
      Align = alLeft
      Caption = 'Chiavi nella query string'
      ParentShowHint = False
      ShowHint = True
      TabOrder = 3
    end
    object CheckAnyCertificate: TCheckBox
      AlignWithMargins = True
      Left = 857
      Top = 3
      Width = 230
      Height = 29
      Hint =
        'Solo per negozi di sviluppo con certificato autofirmato: disattiva ' +
        'la verifica del server.'
      Align = alLeft
      Caption = 'Accetta certificati non validi (test)'
      ParentShowHint = False
      ShowHint = True
      TabOrder = 4
    end
    object ButtonConnect: TButton
      AlignWithMargins = True
      Left = 1093
      Top = 3
      Width = 100
      Height = 29
      Align = alLeft
      Caption = 'Connetti'
      TabOrder = 5
      OnClick = ButtonConnectClick
    end
  end
  object PanelWordPress: TPanel
    Left = 0
    Top = 35
    Width = 1240
    Height = 35
    Align = alTop
    BevelOuter = bvNone
    TabOrder = 1
    object LabelWordPress: TLabel
      AlignWithMargins = True
      Left = 3
      Top = 3
      Width = 260
      Height = 29
      Align = alLeft
      AutoSize = False
      Caption = 'Solo per caricare immagini (WordPress):'
      Layout = tlCenter
    end
    object EditWordPressUser: TEdit
      AlignWithMargins = True
      Left = 269
      Top = 3
      Width = 200
      Height = 29
      Align = alLeft
      TabOrder = 0
      TextHint = 'Utente WordPress'
      OnChange = EditWordPressChange
    end
    object EditWordPressPassword: TEdit
      AlignWithMargins = True
      Left = 475
      Top = 3
      Width = 200
      Height = 29
      Hint =
        'Una "password per le applicazioni" (Utenti > Profilo), non la ' +
        'password di accesso'
      Align = alLeft
      ParentShowHint = False
      PasswordChar = '*'
      ShowHint = True
      TabOrder = 1
      TextHint = 'Password per le applicazioni'
      OnChange = EditWordPressChange
    end
  end
  object PageControl: TPageControl
    Left = 0
    Top = 70
    Width = 1240
    Height = 632
    ActivePage = TabProducts
    Align = alClient
    TabOrder = 1
    object TabProducts: TTabSheet
      Caption = 'Prodotti'
      inline ProductsFrame: TProductsFrame
        Left = 0
        Top = 0
        Width = 1232
        Height = 637
        Align = alClient
        TabOrder = 0
      end
    end
    object TabCategories: TTabSheet
      Caption = 'Categorie'
      inline CategoriesFrame: TCategoriesFrame
        Left = 0
        Top = 0
        Width = 1232
        Height = 637
        Align = alClient
        TabOrder = 0
      end
    end
    object TabOrders: TTabSheet
      Caption = 'Ordini'
      ImageIndex = 1
      inline OrdersFrame: TOrdersFrame
        Left = 0
        Top = 0
        Width = 1232
        Height = 637
        Align = alClient
        TabOrder = 0
      end
    end
    object TabResources: TTabSheet
      Caption = 'Risorse (tutti gli endpoint)'
      ImageIndex = 2
      inline ResourcesFrame: TResourcesFrame
        Left = 0
        Top = 0
        Width = 1232
        Height = 637
        Align = alClient
        TabOrder = 0
      end
    end
    object TabReports: TTabSheet
      Caption = 'Report e sistema'
      ImageIndex = 3
      inline ReportsFrame: TReportsFrame
        Left = 0
        Top = 0
        Width = 1232
        Height = 637
        Align = alClient
        TabOrder = 0
      end
    end
    object TabRaw: TTabSheet
      Caption = 'JSON grezzo'
      ImageIndex = 4
      inline RawFrame: TRawFrame
        Left = 0
        Top = 0
        Width = 1232
        Height = 637
        Align = alClient
        TabOrder = 0
      end
    end
  end
  object SplitterLog: TSplitter
    Left = 0
    Top = 702
    Width = 1240
    Height = 4
    Cursor = crVSplit
    Align = alBottom
  end
  object MemoLog: TMemo
    Left = 0
    Top = 706
    Width = 1240
    Height = 135
    Align = alBottom
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
  object StatusBar: TStatusBar
    Left = 0
    Top = 841
    Width = 1240
    Height = 19
    Panels = <>
    SimplePanel = True
    SimpleText = 'Non connesso'
  end
end
