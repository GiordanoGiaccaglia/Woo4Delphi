// Woo4Delphi by KD Software Srls - https://www.kdsoftware.it - info@kdsoftware.it
// Developer: Giordano Giaccaglia

unit Demo.Reports;

// The calls that are not plain collections: reports, system status and tools, zone locations,
// customer downloads, product custom-field names, the shop currency.

interface

uses
  System.SysUtils,
  System.Classes,
  Vcl.Controls,
  Vcl.Forms,
  Vcl.StdCtrls,
  Vcl.ExtCtrls,
  Demo.Common;

type
  TReportsFrame = class(TFrame)
    PanelReports: TPanel;
    ComboPeriod: TComboBox;
    ButtonSales: TButton;
    ButtonTopSellers: TButton;
    ComboTotals: TComboBox;
    ButtonTotals: TButton;
    PanelSystem: TPanel;
    ButtonSystemStatus: TButton;
    ButtonTools: TButton;
    ComboTools: TComboBox;
    ButtonRunTool: TButton;
    ButtonCurrency: TButton;
    ButtonCustomFields: TButton;
    PanelOther: TPanel;
    EditZone: TEdit;
    ButtonLocations: TButton;
    ButtonSaveLocations: TButton;
    EditCustomer: TEdit;
    ButtonDownloads: TButton;
    MemoResult: TMemo;
    procedure ButtonSalesClick(Sender: TObject);
    procedure ButtonTopSellersClick(Sender: TObject);
    procedure ButtonTotalsClick(Sender: TObject);
    procedure ButtonSystemStatusClick(Sender: TObject);
    procedure ButtonToolsClick(Sender: TObject);
    procedure ButtonRunToolClick(Sender: TObject);
    procedure ButtonCurrencyClick(Sender: TObject);
    procedure ButtonCustomFieldsClick(Sender: TObject);
    procedure ButtonLocationsClick(Sender: TObject);
    procedure ButtonSaveLocationsClick(Sender: TObject);
    procedure ButtonDownloadsClick(Sender: TObject);
  private
    fContext: TDemoContext;
    fToolIDs: TArray<string>;
    procedure Show(const ALines: array of string);
  public
    procedure Setup(const AContext: TDemoContext);
  end;

implementation

uses
  System.Net.URLClient,
  Woo4Delphi.Types;

{$R *.dfm}

procedure TReportsFrame.Setup(const AContext: TDemoContext);
begin
  fContext := AContext;
end;

procedure TReportsFrame.Show(const ALines: array of string);
begin
  MemoResult.Lines.BeginUpdate;
  try
    MemoResult.Lines.Clear;
    for var lLine in ALines do
      MemoResult.Lines.Add(lLine);
  finally
    MemoResult.Lines.EndUpdate;
  end;
end;

procedure TReportsFrame.ButtonSalesClick(Sender: TObject);
begin
  fContext.Run('Report vendite', procedure
    begin
      var lSales := fContext.Woo.SalesReport([TNameValuePair.Create('period', ComboPeriod.Text)]);
      Show([Format('Periodo: %s (raggruppato per %s)', [ComboPeriod.Text, lSales.TotalsGroupedBy]),
        'Vendite lorde: ' + lSales.TotalSales, 'Vendite nette: ' + lSales.NetSales,
        'Media: ' + lSales.AverageSales, Format('Ordini: %d  Articoli: %d  Clienti: %d', [lSales.TotalOrders,
        lSales.TotalItems, lSales.TotalCustomers]), 'Imposte: ' + lSales.TotalTax, 'Spedizioni: ' + lSales.TotalShipping,
        'Rimborsi: ' + lSales.TotalRefunds, 'Sconti: ' + lSales.TotalDiscount, '', 'Per data:', PrettyJSON(lSales.Totals)]);
    end);
end;

procedure TReportsFrame.ButtonTopSellersClick(Sender: TObject);
begin
  fContext.Run('Prodotti pi'#$F9' venduti', procedure
    begin
      MemoResult.Clear;
      for var lSeller in fContext.Woo.TopSellersReport([TNameValuePair.Create('period', ComboPeriod.Text)]) do
        MemoResult.Lines.Add(Format('%5d  %s (prodotto %d)', [lSeller.Quantity, lSeller.Title, lSeller.ProductId]));
    end);
end;

procedure TReportsFrame.ButtonTotalsClick(Sender: TObject);
begin
  fContext.Run('Totali ' + ComboTotals.Text, procedure
    begin
      MemoResult.Clear;
      for var lTotal in fContext.Woo.ReportTotals(ComboTotals.Text) do
        MemoResult.Lines.Add(Format('%8s  %s (%s)', [lTotal.Total, lTotal.Name, lTotal.Slug]));
    end);
end;

procedure TReportsFrame.ButtonSystemStatusClick(Sender: TObject);
begin
  fContext.Run('Stato del sistema', procedure
    begin
      var lStatus := fContext.Woo.SystemStatus;
      var lEnv := lStatus.Environment;
      Show([Format('Sito: %s', [lEnv.SiteUrl]),
        Format('WooCommerce %s, database %s', [lEnv.Version, lStatus.Database.WcDatabaseVersion]),
        Format('WordPress %s, PHP %s, MySQL %s, %s', [lEnv.WpVersion, lEnv.PhpVersion, lEnv.MysqlVersion, lEnv.ServerInfo]),
        Format('Memoria WP %d MB, upload massimo %d MB, debug %s', [lEnv.WpMemoryLimit div 1048576,
          lEnv.MaxUploadSize div 1048576, BoolToStr(lEnv.WpDebugMode, True)]),
        Format('Tema: %s %s', [lStatus.Theme.Name, lStatus.Theme.Version]),
        Format('Valuta: %s (%d decimali)', [lStatus.Settings.Currency, lStatus.Settings.NumberOfDecimals]),
        Format('HTTPS: %s', [BoolToStr(lStatus.Security.SecureConnection, True)]), '', 'Plugin attivi:']);
      for var lPlugin in lStatus.ActivePlugins do
        MemoResult.Lines.Add(Format('  %s %s (%s)', [lPlugin.Name, lPlugin.Version, lPlugin.AuthorName]));
    end);
end;

procedure TReportsFrame.ButtonToolsClick(Sender: TObject);
begin
  fContext.Run('Strumenti di sistema', procedure
    begin
      fToolIDs := nil;
      ComboTools.Items.Clear;
      MemoResult.Clear;
      for var lTool in fContext.Woo.SystemTools.List do
      begin
        fToolIDs := fToolIDs + [lTool.Id];
        ComboTools.Items.Add(lTool.Name);
        MemoResult.Lines.Add(Format('%s: %s', [lTool.Name, lTool.Description]));
      end;
      ComboTools.ItemIndex := 0;
    end);
end;

procedure TReportsFrame.ButtonRunToolClick(Sender: TObject);
begin
  fContext.Run('Esegui strumento', procedure
    begin
      if ComboTools.ItemIndex < 0 then
        raise Exception.Create('Carica gli strumenti e scegline uno');
      // some tools are destructive (delete_taxes, reset_roles...): ask first
      if not fContext.Confirm(Format('Eseguire "%s" sul negozio?', [ComboTools.Text])) then
        Exit;
      var lTool := fContext.Woo.RunSystemTool(fToolIDs[ComboTools.ItemIndex]);
      fContext.Log(Format('%s: %s (%s)', [lTool.Name, lTool.Message, BoolToStr(lTool.Success, True)]));
    end);
end;

procedure TReportsFrame.ButtonCurrencyClick(Sender: TObject);
begin
  fContext.Run('Valuta del negozio', procedure
    begin
      var lCurrency := fContext.Woo.Currencies.Get('current');
      Show([Format('%s - %s (%s)', [lCurrency.Code, lCurrency.Name, lCurrency.Symbol])]);
    end);
end;

procedure TReportsFrame.ButtonCustomFieldsClick(Sender: TObject);
begin
  fContext.Run('Nomi dei campi personalizzati', procedure
    begin
      Show(fContext.Woo.ProductCustomFieldNames);
    end);
end;

procedure TReportsFrame.ButtonLocationsClick(Sender: TObject);
begin
  fContext.Run('Localit'#$E0' della zona', procedure
    begin
      var lLocations := fContext.Woo.ShippingZoneLocations(StrToInt64(EditZone.Text));
      MemoResult.Text := PrettyJSON(fContext.Woo.ToJSON<TArray<TWooZoneLocation>>(lLocations));
    end);
end;

procedure TReportsFrame.ButtonSaveLocationsClick(Sender: TObject);
begin
  fContext.Run('Salva localit'#$E0' della zona', procedure
    begin
      // the memo holds the JSON array read with "Leggi localita", edited by hand
      var lLocations := fContext.Woo.ParseJSON<TArray<TWooZoneLocation>>(MemoResult.Text);
      if not fContext.Confirm(Format('Sostituire le localit'#$E0' della zona %s con %d voci?',
        [EditZone.Text, Length(lLocations)])) then
        Exit;
      lLocations := fContext.Woo.UpdateShippingZoneLocations(StrToInt64(EditZone.Text), lLocations);
      MemoResult.Text := PrettyJSON(fContext.Woo.ToJSON<TArray<TWooZoneLocation>>(lLocations));
    end);
end;

procedure TReportsFrame.ButtonDownloadsClick(Sender: TObject);
begin
  fContext.Run('Download del cliente', procedure
    begin
      MemoResult.Clear;
      for var lDownload in fContext.Woo.CustomerDownloads(StrToInt64(EditCustomer.Text)) do
        MemoResult.Lines.Add(Format('%s - %s: rimasti %s, scade %s (%s)', [lDownload.ProductName,
          lDownload.DownloadName, lDownload.DownloadsRemaining, lDownload.AccessExpires, lDownload.FileInfo.Url]));
    end);
end;

end.
