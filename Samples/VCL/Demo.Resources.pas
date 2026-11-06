// Woo4Delphi by KD Software Srls - https://www.kdsoftware.it - info@kdsoftware.it
// Developer: Giordano Giaccaglia

unit Demo.Resources;

// Every typed endpoint on one page: pick a resource, list it, read, create and update it from
// JSON (parsed into the record and sent through TWooEndpoint<T>), delete it, batch update/delete.

interface

uses
  System.SysUtils,
  System.Classes,
  System.Generics.Collections,
  System.Net.URLClient,
  Vcl.Controls,
  Vcl.Forms,
  Vcl.StdCtrls,
  Vcl.ExtCtrls,
  Vcl.ComCtrls,
  Demo.Common;

type
  // One TWooEndpoint<T> seen through JSON text, so the page can drive any of them
  IDemoResource = interface
    ['{6B0D7C0E-3F35-4F57-9E5B-2B5C8D7F1A41}']
    function Caption: string;
    function ParentLabel: string;   // '' when the endpoint has no parent ID
    function IDKey: string;
    function List(const AParent: string; const AParams: TNameValueArray): TArray<string>;
    function Get(const AParent, AID: string): string;
    function Add(const AParent, AJSON: string): string;
    function Update(const AParent, AJSON: string; const AFields: TArray<string>): string;
    function Delete(const AParent, AID: string; const AForce: Boolean): string;
    function Batch(const AParent: string; const AUpdates, AFields: TArray<string>; const ADeletes: TArray<Int64>): TArray<string>;
  end;

  TResourcesFrame = class(TFrame)
    PanelList: TPanel;
    ComboResource: TComboBox;
    EditParent: TEdit;
    EditParams: TEdit;
    ButtonList: TButton;
    LabelCount: TLabel;
    PanelItem: TPanel;
    EditID: TEdit;
    ButtonGet: TButton;
    ButtonAdd: TButton;
    CheckForce: TCheckBox;
    ButtonDelete: TButton;
    PanelUpdate: TPanel;
    EditFields: TEdit;
    ButtonUpdate: TButton;
    ButtonBatchUpdate: TButton;
    ButtonBatchDelete: TButton;
    MemoJSON: TMemo;
    SplitterRight: TSplitter;
    ListItems: TListView;
    procedure ComboResourceChange(Sender: TObject);
    procedure ButtonListClick(Sender: TObject);
    procedure ListItemsSelectItem(Sender: TObject; Item: TListItem; Selected: Boolean);
    procedure ButtonGetClick(Sender: TObject);
    procedure ButtonAddClick(Sender: TObject);
    procedure ButtonUpdateClick(Sender: TObject);
    procedure ButtonDeleteClick(Sender: TObject);
    procedure ButtonBatchUpdateClick(Sender: TObject);
    procedure ButtonBatchDeleteClick(Sender: TObject);
  private
    fContext: TDemoContext;
    fResources: TList<IDemoResource>;
    fItems: TArray<string>;
    procedure Register(const AResource: IDemoResource);
    function Resource: IDemoResource;
    function SelectedIndexes: TArray<Integer>;
    procedure ShowItems;
  public
    destructor Destroy; override;
    procedure Setup(const AContext: TDemoContext);
  end;

implementation

uses
  System.JSON,
  Woo4Delphi.Types,
  Woo4Delphi.Client;

{$R *.dfm}

type
  TDemoResource<T> = class(TInterfacedObject, IDemoResource)
  private
    fContext: TDemoContext;
    fCaption: string;
    fParentLabel: string;
    fIDKey: string;
    fEndpoint: TFunc<string, TWooEndpoint<T>>;
  public
    constructor Create(const AContext: TDemoContext; const ACaption, AParentLabel, AIDKey: string;
      const AEndpoint: TFunc<string, TWooEndpoint<T>>);
    function Caption: string;
    function ParentLabel: string;
    function IDKey: string;
    function List(const AParent: string; const AParams: TNameValueArray): TArray<string>;
    function Get(const AParent, AID: string): string;
    function Add(const AParent, AJSON: string): string;
    function Update(const AParent, AJSON: string; const AFields: TArray<string>): string;
    function Delete(const AParent, AID: string; const AForce: Boolean): string;
    function Batch(const AParent: string; const AUpdates, AFields: TArray<string>; const ADeletes: TArray<Int64>): TArray<string>;
  end;

{ TDemoResource<T> }

constructor TDemoResource<T>.Create(const AContext: TDemoContext; const ACaption, AParentLabel, AIDKey: string;
  const AEndpoint: TFunc<string, TWooEndpoint<T>>);
begin
  inherited Create;
  fContext := AContext;
  fCaption := ACaption;
  fParentLabel := AParentLabel;
  fIDKey := AIDKey;
  fEndpoint := AEndpoint;
end;

function TDemoResource<T>.Caption: string;
begin
  Result := fCaption;
end;

function TDemoResource<T>.ParentLabel: string;
begin
  Result := fParentLabel;
end;

function TDemoResource<T>.IDKey: string;
begin
  Result := fIDKey;
end;

function TDemoResource<T>.List(const AParent: string; const AParams: TNameValueArray): TArray<string>;
begin
  Result := nil;
  for var lItem in fEndpoint(AParent).List(AParams) do
    Result := Result + [fContext.Woo.ToJSON<T>(lItem)];
end;

function TDemoResource<T>.Get(const AParent, AID: string): string;
begin
  Result := fContext.Woo.ToJSON<T>(fEndpoint(AParent).Get(AID));
end;

function TDemoResource<T>.Add(const AParent, AJSON: string): string;
begin
  Result := fContext.Woo.ToJSON<T>(fEndpoint(AParent).Add(fContext.Woo.ParseJSON<T>(AJSON)));
end;

function TDemoResource<T>.Update(const AParent, AJSON: string; const AFields: TArray<string>): string;
begin
  Result := fContext.Woo.ToJSON<T>(fEndpoint(AParent).Update(fContext.Woo.ParseJSON<T>(AJSON), AFields));
end;

function TDemoResource<T>.Delete(const AParent, AID: string; const AForce: Boolean): string;
begin
  Result := fContext.Woo.ToJSON<T>(fEndpoint(AParent).Delete(AID, AForce));
end;

function TDemoResource<T>.Batch(const AParent: string; const AUpdates, AFields: TArray<string>;
  const ADeletes: TArray<Int64>): TArray<string>;
begin
  var lUpdates: TArray<T> := nil;
  for var lJSON in AUpdates do
    lUpdates := lUpdates + [fContext.Woo.ParseJSON<T>(lJSON)];
  Result := fEndpoint(AParent).Batch(nil, lUpdates, AFields, ADeletes).Errors;
end;

{ TResourcesFrame }

destructor TResourcesFrame.Destroy;
begin
  fResources.Free;
  inherited Destroy;
end;

procedure TResourcesFrame.Register(const AResource: IDemoResource);
begin
  fResources.Add(AResource);
  ComboResource.Items.Add(AResource.Caption);
end;

procedure TResourcesFrame.Setup(const AContext: TDemoContext);
begin
  fContext := AContext;
  fResources := TList<IDemoResource>.Create;
  // the endpoint is resolved at call time: the connection can change after Setup
  Register(TDemoResource<TWooProduct>.Create(AContext, 'Prodotti', '', 'id',
    function(P: string): TWooEndpoint<TWooProduct> begin Result := AContext.Woo.Products; end));
  Register(TDemoResource<TWooVariation>.Create(AContext, 'Variazioni', 'ID prodotto', 'id',
    function(P: string): TWooEndpoint<TWooVariation> begin Result := AContext.Woo.Variations(P.ToInt64); end));
  Register(TDemoResource<TWooProductAttribute>.Create(AContext, 'Attributi globali', '', 'id',
    function(P: string): TWooEndpoint<TWooProductAttribute> begin Result := AContext.Woo.Attributes; end));
  Register(TDemoResource<TWooAttributeTerm>.Create(AContext, 'Termini di un attributo', 'ID attributo', 'id',
    function(P: string): TWooEndpoint<TWooAttributeTerm> begin Result := AContext.Woo.AttributeTerms(P.ToInt64); end));
  Register(TDemoResource<TWooProductCategory>.Create(AContext, 'Categorie', '', 'id',
    function(P: string): TWooEndpoint<TWooProductCategory> begin Result := AContext.Woo.Categories; end));
  Register(TDemoResource<TWooProductTag>.Create(AContext, 'Tag', '', 'id',
    function(P: string): TWooEndpoint<TWooProductTag> begin Result := AContext.Woo.Tags; end));
  Register(TDemoResource<TWooShippingClass>.Create(AContext, 'Classi di spedizione', '', 'id',
    function(P: string): TWooEndpoint<TWooShippingClass> begin Result := AContext.Woo.ShippingClasses; end));
  Register(TDemoResource<TWooProductReview>.Create(AContext, 'Recensioni', '', 'id',
    function(P: string): TWooEndpoint<TWooProductReview> begin Result := AContext.Woo.Reviews; end));
  Register(TDemoResource<TWooOrder>.Create(AContext, 'Ordini', '', 'id',
    function(P: string): TWooEndpoint<TWooOrder> begin Result := AContext.Woo.Orders; end));
  Register(TDemoResource<TWooOrderNote>.Create(AContext, 'Note di un ordine', 'ID ordine', 'id',
    function(P: string): TWooEndpoint<TWooOrderNote> begin Result := AContext.Woo.OrderNotes(P.ToInt64); end));
  Register(TDemoResource<TWooRefund>.Create(AContext, 'Rimborsi di un ordine', 'ID ordine', 'id',
    function(P: string): TWooEndpoint<TWooRefund> begin Result := AContext.Woo.Refunds(P.ToInt64); end));
  Register(TDemoResource<TWooRefund>.Create(AContext, 'Tutti i rimborsi (solo elenco)', '', 'id',
    function(P: string): TWooEndpoint<TWooRefund> begin Result := AContext.Woo.AllRefunds; end));
  Register(TDemoResource<TWooCustomer>.Create(AContext, 'Clienti', '', 'id',
    function(P: string): TWooEndpoint<TWooCustomer> begin Result := AContext.Woo.Customers; end));
  Register(TDemoResource<TWooCoupon>.Create(AContext, 'Coupon', '', 'id',
    function(P: string): TWooEndpoint<TWooCoupon> begin Result := AContext.Woo.Coupons; end));
  Register(TDemoResource<TWooTaxRate>.Create(AContext, 'Aliquote d''imposta', '', 'id',
    function(P: string): TWooEndpoint<TWooTaxRate> begin Result := AContext.Woo.TaxRates; end));
  Register(TDemoResource<TWooTaxClass>.Create(AContext, 'Classi d''imposta', '', 'slug',
    function(P: string): TWooEndpoint<TWooTaxClass> begin Result := AContext.Woo.TaxClasses; end));
  Register(TDemoResource<TWooWebhook>.Create(AContext, 'Webhook', '', 'id',
    function(P: string): TWooEndpoint<TWooWebhook> begin Result := AContext.Woo.Webhooks; end));
  Register(TDemoResource<TWooSettingGroup>.Create(AContext, 'Gruppi di impostazioni (solo elenco)', '', 'id',
    function(P: string): TWooEndpoint<TWooSettingGroup> begin Result := AContext.Woo.SettingGroups; end));
  Register(TDemoResource<TWooSetting>.Create(AContext, 'Impostazioni di un gruppo', 'ID gruppo (es. general)', 'id',
    function(P: string): TWooEndpoint<TWooSetting> begin Result := AContext.Woo.Settings(P); end));
  Register(TDemoResource<TWooPaymentGateway>.Create(AContext, 'Gateway di pagamento', '', 'id',
    function(P: string): TWooEndpoint<TWooPaymentGateway> begin Result := AContext.Woo.PaymentGateways; end));
  Register(TDemoResource<TWooShippingZone>.Create(AContext, 'Zone di spedizione', '', 'id',
    function(P: string): TWooEndpoint<TWooShippingZone> begin Result := AContext.Woo.ShippingZones; end));
  Register(TDemoResource<TWooShippingZoneMethod>.Create(AContext, 'Metodi di una zona', 'ID zona', 'instance_id',
    function(P: string): TWooEndpoint<TWooShippingZoneMethod> begin Result := AContext.Woo.ShippingZoneMethods(P.ToInt64); end));
  Register(TDemoResource<TWooShippingMethod>.Create(AContext, 'Metodi di spedizione', '', 'id',
    function(P: string): TWooEndpoint<TWooShippingMethod> begin Result := AContext.Woo.ShippingMethods; end));
  Register(TDemoResource<TWooSystemTool>.Create(AContext, 'Strumenti di sistema', '', 'id',
    function(P: string): TWooEndpoint<TWooSystemTool> begin Result := AContext.Woo.SystemTools; end));
  Register(TDemoResource<TWooIndexEntry>.Create(AContext, 'Report disponibili (solo elenco)', '', 'slug',
    function(P: string): TWooEndpoint<TWooIndexEntry> begin Result := AContext.Woo.Reports; end));
  Register(TDemoResource<TWooIndexEntry>.Create(AContext, 'Dati disponibili (solo elenco)', '', 'slug',
    function(P: string): TWooEndpoint<TWooIndexEntry> begin Result := AContext.Woo.Data; end));
  Register(TDemoResource<TWooContinent>.Create(AContext, 'Continenti', '', 'code',
    function(P: string): TWooEndpoint<TWooContinent> begin Result := AContext.Woo.Continents; end));
  Register(TDemoResource<TWooCountry>.Create(AContext, 'Paesi', '', 'code',
    function(P: string): TWooEndpoint<TWooCountry> begin Result := AContext.Woo.Countries; end));
  Register(TDemoResource<TWooCurrency>.Create(AContext, 'Valute (ID current = valuta del negozio)', '', 'code',
    function(P: string): TWooEndpoint<TWooCurrency> begin Result := AContext.Woo.Currencies; end));
  ComboResource.ItemIndex := 0;
  ComboResourceChange(nil);
end;

function TResourcesFrame.Resource: IDemoResource;
begin
  Result := fResources[ComboResource.ItemIndex];
end;

function TResourcesFrame.SelectedIndexes: TArray<Integer>;
begin
  Result := nil;
  for var lItem in ListItems.Items do
    if lItem.Selected then
      Result := Result + [lItem.Index];
  if Result = nil then
    raise Exception.Create('Seleziona una o pi'#$F9' righe');
end;

procedure TResourcesFrame.ShowItems;
begin
  ListItems.Items.BeginUpdate;
  try
    ListItems.Items.Clear;
    for var lItem in fItems do
      AddRow(ListItems, [JSONField(lItem, Resource.IDKey), Describe(lItem)]);
  finally
    ListItems.Items.EndUpdate;
  end;
  LabelCount.Caption := Format('%d elementi', [Length(fItems)]);
end;

procedure TResourcesFrame.ComboResourceChange(Sender: TObject);
begin
  EditParent.Enabled := Resource.ParentLabel <> '';
  EditParent.TextHint := if EditParent.Enabled then Resource.ParentLabel else '(nessun padre)';
  fItems := nil;
  ShowItems;
  MemoJSON.Clear;
end;

procedure TResourcesFrame.ButtonListClick(Sender: TObject);
begin
  fContext.Run('Elenco ' + Resource.Caption, procedure
    begin
      fItems := Resource.List(EditParent.Text, ParseParams(EditParams.Text));
      ShowItems;
    end);
end;

procedure TResourcesFrame.ListItemsSelectItem(Sender: TObject; Item: TListItem; Selected: Boolean);
begin
  if Selected and (Item <> nil) then
  begin
    MemoJSON.Text := PrettyJSON(fItems[Item.Index]);
    EditID.Text := Item.Caption;
  end;
end;

procedure TResourcesFrame.ButtonGetClick(Sender: TObject);
begin
  fContext.Run('Leggi ' + Resource.Caption, procedure
    begin
      MemoJSON.Text := PrettyJSON(Resource.Get(EditParent.Text, EditID.Text));
    end);
end;

procedure TResourcesFrame.ButtonAddClick(Sender: TObject);
begin
  fContext.Run('Crea ' + Resource.Caption, procedure
    begin
      var lCreated := Resource.Add(EditParent.Text, MemoJSON.Text);
      fItems := fItems + [lCreated];
      ShowItems;
      MemoJSON.Text := PrettyJSON(lCreated);
      fContext.Log('Creato, ' + Resource.IDKey + ' = ' + JSONField(lCreated, Resource.IDKey));
    end);
end;

procedure TResourcesFrame.ButtonUpdateClick(Sender: TObject);
begin
  fContext.Run('Aggiorna ' + Resource.Caption, procedure
    begin
      var lFields := ParseFields(EditFields.Text);
      if lFields = nil then
        raise Exception.Create('Scrivi i campi da aggiornare, es. name, status');
      MemoJSON.Text := PrettyJSON(Resource.Update(EditParent.Text, MemoJSON.Text, lFields));
    end);
end;

procedure TResourcesFrame.ButtonDeleteClick(Sender: TObject);
begin
  fContext.Run('Elimina ' + Resource.Caption, procedure
    begin
      if fContext.Confirm(Format('Eliminare %s %s%s?', [Resource.Caption, EditID.Text,
        if CheckForce.Checked then ' DEFINITIVAMENTE' else ''])) then
        MemoJSON.Text := PrettyJSON(Resource.Delete(EditParent.Text, EditID.Text, CheckForce.Checked));
    end);
end;

procedure TResourcesFrame.ButtonBatchUpdateClick(Sender: TObject);
begin
  fContext.Run('Batch aggiorna ' + Resource.Caption, procedure
    begin
      // the listed fields take the values in the memo, on every selected row
      var lFields := ParseFields(EditFields.Text);
      var lValues := TJSONValue.ParseJSONValue(MemoJSON.Text) as TJSONObject;
      if (lFields = nil) or (lValues = nil) then
        raise Exception.Create('Scrivi i campi da aggiornare e, nel JSON, i loro nuovi valori');
      try
        var lUpdates: TArray<string> := nil;
        for var lIndex in SelectedIndexes do
        begin
          var lItem := TJSONValue.ParseJSONValue(fItems[lIndex]) as TJSONObject;
          try
            for var lField in lFields do
            begin
              lItem.RemovePair(lField).Free;
              var lValue := lValues.Values[lField];
              if lValue <> nil then
                lItem.AddPair(lField, lValue.Clone as TJSONValue);
            end;
            lUpdates := lUpdates + [lItem.ToJSON];
          finally
            lItem.Free;
          end;
        end;
        var lErrors := Resource.Batch(EditParent.Text, lUpdates, lFields, nil);
        fContext.Log(Format('Batch: %d inviati, %d rifiutati %s', [Length(lUpdates), Length(lErrors),
          string.Join('; ', lErrors)]));
      finally
        lValues.Free;
      end;
    end);
end;

procedure TResourcesFrame.ButtonBatchDeleteClick(Sender: TObject);
begin
  fContext.Run('Batch elimina ' + Resource.Caption, procedure
    begin
      var lIDs: TArray<Int64> := nil;
      for var lIndex in SelectedIndexes do
        lIDs := lIDs + [StrToInt64(ListItems.Items[lIndex].Caption)];
      if not fContext.Confirm(Format('Eliminare DEFINITIVAMENTE %d elementi?', [Length(lIDs)])) then
        Exit;
      var lErrors := Resource.Batch(EditParent.Text, nil, nil, lIDs);
      fContext.Log(Format('Batch: %d da eliminare, %d rifiutati %s', [Length(lIDs), Length(lErrors),
        string.Join('; ', lErrors)]));
    end);
end;

end.
