// Woo4Delphi by KD Software Srls - https://www.kdsoftware.it - info@kdsoftware.it
// Developer: Giordano Giaccaglia

unit Demo.Main;

// Woo4Delphi demo: connection on top, one page per area, the log of every call at the bottom.
// Calls run on the main thread for clarity: in a real application move them to a worker
// thread (TTask.Run) and give each thread its own TWooClient.

interface

uses
  System.SysUtils,
  System.Classes,
  Vcl.Controls,
  Vcl.Forms,
  Vcl.StdCtrls,
  Vcl.ExtCtrls,
  Vcl.ComCtrls,
  Demo.Common,
  Demo.Products,
  Demo.Categories,
  Demo.Orders,
  Demo.Resources,
  Demo.Reports,
  Demo.Raw;

type
  TMainForm = class(TForm)
    PanelConnection: TPanel;
    EditURL: TEdit;
    EditKey: TEdit;
    EditSecret: TEdit;
    CheckQueryStringAuth: TCheckBox;
    CheckAnyCertificate: TCheckBox;
    ButtonConnect: TButton;
    PanelWordPress: TPanel;
    LabelWordPress: TLabel;
    EditWordPressUser: TEdit;
    EditWordPressPassword: TEdit;
    PageControl: TPageControl;
    TabProducts: TTabSheet;
    ProductsFrame: TProductsFrame;
    TabCategories: TTabSheet;
    CategoriesFrame: TCategoriesFrame;
    TabOrders: TTabSheet;
    OrdersFrame: TOrdersFrame;
    TabResources: TTabSheet;
    ResourcesFrame: TResourcesFrame;
    TabReports: TTabSheet;
    ReportsFrame: TReportsFrame;
    TabRaw: TTabSheet;
    RawFrame: TRawFrame;
    SplitterLog: TSplitter;
    MemoLog: TMemo;
    StatusBar: TStatusBar;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure ButtonConnectClick(Sender: TObject);
    procedure EditWordPressChange(Sender: TObject);
  private
    fContext: TDemoContext;
    function SettingsFile: string;
    procedure LoadSettings;
    procedure SaveSettings;
  public
    property Context: TDemoContext read fContext;
  end;

var
  MainForm: TMainForm;

implementation

uses
  System.UITypes,
  System.IniFiles,
  Vcl.Dialogs;

{$R *.dfm}

// Woo4DelphiDemo.ini beside the exe: keys and passwords in plain text, keep it out of version control
function TMainForm.SettingsFile: string;
begin
  Result := ChangeFileExt(Application.ExeName, '.ini');
end;

procedure TMainForm.LoadSettings;
begin
  var lIni := TMemIniFile.Create(SettingsFile, TEncoding.UTF8);
  try
    EditURL.Text := lIni.ReadString('Store', 'URL', '');
    EditKey.Text := lIni.ReadString('Store', 'ConsumerKey', '');
    EditSecret.Text := lIni.ReadString('Store', 'ConsumerSecret', '');
    CheckQueryStringAuth.Checked := lIni.ReadBool('Store', 'QueryStringAuth', False);
    CheckAnyCertificate.Checked := lIni.ReadBool('Store', 'AcceptAnyCertificate', False);
    EditWordPressUser.Text := lIni.ReadString('WordPress', 'User', '');
    EditWordPressPassword.Text := lIni.ReadString('WordPress', 'AppPassword', '');
  finally
    lIni.Free;
  end;
end;

procedure TMainForm.SaveSettings;
begin
  var lIni := TMemIniFile.Create(SettingsFile, TEncoding.UTF8);
  try
    lIni.WriteString('Store', 'URL', Trim(EditURL.Text));
    lIni.WriteString('Store', 'ConsumerKey', Trim(EditKey.Text));
    lIni.WriteString('Store', 'ConsumerSecret', Trim(EditSecret.Text));
    lIni.WriteBool('Store', 'QueryStringAuth', CheckQueryStringAuth.Checked);
    lIni.WriteBool('Store', 'AcceptAnyCertificate', CheckAnyCertificate.Checked);
    lIni.WriteString('WordPress', 'User', Trim(EditWordPressUser.Text));
    lIni.WriteString('WordPress', 'AppPassword', Trim(EditWordPressPassword.Text));
    lIni.UpdateFile;
  finally
    lIni.Free;
  end;
end;

procedure TMainForm.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  try
    SaveSettings;
  except
    on E: Exception do  // an exception here would stop the form from closing
      MessageDlg('Impostazioni non salvate in ' + SettingsFile + ': ' + E.Message, mtWarning, [mbOK], 0);
  end;
end;

procedure TMainForm.FormCreate(Sender: TObject);
begin
  fContext := TDemoContext.Create(procedure(AText: string)
    begin
      MemoLog.Lines.Add(AText);
    end);
  ProductsFrame.Setup(fContext);
  CategoriesFrame.Setup(fContext);
  OrdersFrame.Setup(fContext);
  ResourcesFrame.Setup(fContext);
  ReportsFrame.Setup(fContext);
  RawFrame.Setup(fContext);
  LoadSettings;  // saved back on close
  EditWordPressChange(nil);
end;

procedure TMainForm.EditWordPressChange(Sender: TObject);
begin
  // live, not at Connect: the WordPress login is often typed after connecting
  fContext.SetWordPressLogin(Trim(EditWordPressUser.Text), Trim(EditWordPressPassword.Text));
end;

procedure TMainForm.FormDestroy(Sender: TObject);
begin
  fContext.Free;  // the frames belong to the form
end;

procedure TMainForm.ButtonConnectClick(Sender: TObject);
begin
  fContext.Run('Connessione', procedure
    begin
      fContext.Connect(Trim(EditURL.Text), Trim(EditKey.Text), Trim(EditSecret.Text), CheckQueryStringAuth.Checked,
        CheckAnyCertificate.Checked);
      var lCurrency := fContext.Woo.Currencies.Get('current');  // a cheap call that needs valid keys
      StatusBar.SimpleText := Format('Connesso a %s - valuta %s (%s)', [EditURL.Text, lCurrency.Code, lCurrency.Name]);
    end);
end;

end.
