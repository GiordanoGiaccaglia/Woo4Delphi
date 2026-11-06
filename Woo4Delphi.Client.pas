// Woo4Delphi by KD Software Srls - https://www.kdsoftware.it - info@kdsoftware.it
// Developer: Giordano Giaccaglia

unit Woo4Delphi.Client;

// WooCommerce REST API v3 client: HTTPS + consumer key/secret (HTTP Basic auth).
// Endpoints and fields: https://woocommerce.github.io/woocommerce-rest-api-docs/
//
//   var lWoo := TWooClient.Create('https://shop.example.com', 'ck_...', 'cs_...');
//   try
//     var lProduct := lWoo.Products.Get(7);               // a record: nothing to free
//     lProduct.RegularPrice := '12.50';
//     lWoo.Products.Update(lProduct, ['regular_price']);  // sends only the listed fields
//     for var lOrder in lWoo.Orders.List([TNameValuePair.Create('status', 'processing')]) do
//       Writeln(lOrder.Number, ' ', lOrder.Total);
//   finally
//     lWoo.Free;
//   end;
//
// Every resource is a TWooEndpoint<T> (List, Get, Add, Update, Delete, Batch) over the records
// of Woo4Delphi.Types. The raw layer (Get/Post/Put/Delete/GetAll) reaches anything else and
// returns a TJSONValue that the CALLER must free.
// One instance per thread: LastTotal/LastTotalPages describe this instance's last call.

interface

uses
  System.SysUtils,
  System.JSON,
  System.JSON.Serializers,
  System.Net.URLClient,
  System.Net.HttpClient,
  Woo4Delphi.Types;

type
  // Raised on any non-2xx answer. WooCommerce errors look like
  // {"code":"woocommerce_rest_product_invalid_id","message":"Invalid ID.","data":{"status":404}}
  EWooError = class(Exception)
  private
    fStatusCode: Integer;
    fCode: string;
  public
    constructor Create(const AStatusCode: Integer; const ACode, AMessage: string);
    class function FromResponse(const AStatusCode: Integer; const ABody: string): EWooError;
    property StatusCode: Integer read fStatusCode;
    property Code: string read fCode;
  end;

  TWooClient = class;

  // Answer of a /batch call. Errors has one line per item WooCommerce refused, e.g.
  // 'update[3] woocommerce_rest_product_invalid_id: Invalid ID.'; that item stays in its array with Id 0.
  TWooBatch<T> = record
    Created: TArray<T>;
    Updated: TArray<T>;
    Deleted: TArray<T>;
    Errors: TArray<string>;
  end;

  // One REST collection, e.g. lWoo.Coupons or lWoo.Variations(42). Values are records.
  TWooEndpoint<T> = record
  private
    fClient: TWooClient;
    fPath: string;
    fTrash: Boolean;
    fIDKey: string;
    function BatchItems(const AResponse: TJSONValue; const AKey: string; var AErrors: TArray<string>): TArray<T>;
  public
    // ATrash: Delete without AForce moves to the trash (products, orders, coupons); elsewhere
    // WooCommerce has no trash and Delete is always permanent. AIDKey: the key that holds the ID.
    constructor Create(const AClient: TWooClient; const APath: string; const ATrash: Boolean = False;
      const AIDKey: string = 'id');
    // Every page (100 items per request); a single request on endpoints that are not paginated
    function List(const AParams: TNameValueArray = nil): TArray<T>;
    function Get(const AID: Int64): T; overload;
    function Get(const AID: string): T; overload;
    // POST: read-only keys and empty strings/arrays are not sent, so WooCommerce applies its defaults
    function Add(const AItem: T): T;
    // PUT of the JSON keys listed in AFields only, e.g. ['regular_price', 'stock_quantity'];
    // the ID is taken from AItem. A key that is not a field of T raises EArgumentException.
    function Update(const AItem: T; const AFields: array of string): T;
    function Delete(const AID: Int64; const AForce: Boolean = False): T; overload;
    function Delete(const AID: string; const AForce: Boolean = False): T; overload;
    // Up to 100 items in total per call (WooCommerce limit). AUpdate items need their ID.
    function Batch(const AAdd, AUpdate: TArray<T>; const AUpdateFields: array of string;
      const ADelete: array of Int64): TWooBatch<T>;
    property Path: string read fPath;
  end;

  TWooClient = class
  private
    fHTTP: THTTPClient;
    fJSON: TJsonSerializer;
    fStoreURL: string;
    fBaseURL: string;
    fConsumerKey: string;
    fConsumerSecret: string;
    fQueryStringAuth: Boolean;
    fWordPressUser: string;
    fWordPressAppPassword: string;
    fLastTotal: Integer;
    fLastTotalPages: Integer;
    function Check(const AResponse: IHTTPResponse): TJSONValue;
    class function Expect<T: TJSONValue>(const AValue: TJSONValue): T; static;
    function FromJSON<T>(const AValue: TJSONValue): T;
    function CreateBody(const AJSON: string): TJSONObject;
    function UpdateBody(const AJSON: string; const AFields: array of string): TJSONObject;
    function ItemID(const AJSON, AIDKey: string): string;
  public
    constructor Create(const AStoreURL, AConsumerKey, AConsumerSecret: string);
    destructor Destroy; override;

    { Raw layer }

    // AEndpoint is relative to /wp-json/wc/v3/, e.g. 'products', 'orders/123', 'products/batch'
    function URLFor(const AEndpoint: string; const AParams: TNameValueArray = nil): string;
    function Get(const AEndpoint: string; const AParams: TNameValueArray = nil): TJSONValue;
    function Post(const AEndpoint: string; const ABody: TJSONValue): TJSONValue;
    function Put(const AEndpoint: string; const ABody: TJSONValue): TJSONValue;
    // Pass [TNameValuePair.Create('force', 'true')] to delete permanently instead of trashing
    function Delete(const AEndpoint: string; const AParams: TNameValueArray = nil): TJSONValue;
    // Every page of a list endpoint, 100 items per request (it sets per_page/page itself).
    // Holds the whole result in memory: on very large catalogs page with Get instead.
    function GetAll(const AEndpoint: string; const AParams: TNameValueArray = nil): TJSONArray;
    // A record as the JSON WooCommerce uses, and back (for logging, storing, building raw calls)
    function ToJSON<T>(const AValue: T): string;
    function ParseJSON<T>(const AJSON: string): T;

    { Products }

    function Products: TWooEndpoint<TWooProduct>;
    function DuplicateProduct(const AID: Int64): TWooProduct;
    function Variations(const AProductID: Int64): TWooEndpoint<TWooVariation>;
    function Attributes: TWooEndpoint<TWooProductAttribute>;
    function AttributeTerms(const AAttributeID: Int64): TWooEndpoint<TWooAttributeTerm>;
    function Categories: TWooEndpoint<TWooProductCategory>;
    function Tags: TWooEndpoint<TWooProductTag>;
    function ShippingClasses: TWooEndpoint<TWooShippingClass>;
    function Reviews: TWooEndpoint<TWooProductReview>;
    // Meta keys recorded on products, e.g. for a custom-field picker
    function ProductCustomFieldNames(const AParams: TNameValueArray = nil): TArray<string>;
    // Uploads an image file to the WordPress media library and returns it as a product image (Id, Src):
    // put it in TWooProduct.Images (the first is the main image, the others the gallery) and save with
    // Products.Update(lProduct, ['images']). An image already on the web needs no upload: an image with
    // Id 0 and Src set is downloaded by WooCommerce itself. WooCommerce has no upload endpoint and
    // /wp/v2/media does not accept its keys: set WordPressUser and WordPressAppPassword first.
    function UploadImage(const AFileName: string; const AAlt: string = ''): TWooImage;

    { Orders }

    // Filter with e.g. [TNameValuePair.Create('status', 'processing'), TNameValuePair.Create('after', '2026-01-01T00:00:00')]
    function Orders: TWooEndpoint<TWooOrder>;
    // pending, processing, on-hold, completed, cancelled, refunded, failed, or a plugin's custom status.
    // WooCommerce reacts as from the admin: e-mails to the customer, stock restored on cancelled.
    function UpdateOrderStatus(const AID: Int64; const AStatus: string): TWooOrder;
    function OrderNotes(const AOrderID: Int64): TWooEndpoint<TWooOrderNote>;
    // Add creates the refund; with ApiRefund = True the gateway gives the money back
    function Refunds(const AOrderID: Int64): TWooEndpoint<TWooRefund>;
    // Refunds of every order (List only)
    function AllRefunds: TWooEndpoint<TWooRefund>;
    function OrderEmailTemplates(const AOrderID: Int64): TArray<TWooEmailTemplate>;
    // ATemplateID '' sends the order details (invoice). AEmail '' uses the billing e-mail;
    // AForceEmailUpdate replaces an existing billing e-mail with AEmail. Returns WooCommerce's message.
    function SendOrderEmail(const AOrderID: Int64; const ATemplateID: string = ''; const AEmail: string = '';
      const AForceEmailUpdate: Boolean = False): string;

    { Customers and coupons }

    // Registered users with role "customer" only (pass role=all for every user).
    // Guest buyers have no customer record: their data is in the orders' Billing/Shipping.
    function Customers: TWooEndpoint<TWooCustomer>;
    function CustomerDownloads(const ACustomerID: Int64): TArray<TWooDownload>;
    function Coupons: TWooEndpoint<TWooCoupon>;

    { Taxes, webhooks, settings, payments }

    function TaxRates: TWooEndpoint<TWooTaxRate>;
    // Delete by slug; it removes the tax rates of that class too
    function TaxClasses: TWooEndpoint<TWooTaxClass>;
    function Webhooks: TWooEndpoint<TWooWebhook>;
    function SettingGroups: TWooEndpoint<TWooSettingGroup>;
    // Options of a group, e.g. Settings('general').Get('woocommerce_currency')
    function Settings(const AGroupID: string): TWooEndpoint<TWooSetting>;
    function PaymentGateways: TWooEndpoint<TWooPaymentGateway>;

    { Shipping }

    function ShippingZones: TWooEndpoint<TWooShippingZone>;
    function ShippingZoneLocations(const AZoneID: Int64): TArray<TWooZoneLocation>;
    // Replaces every location of the zone; an empty array clears them
    function UpdateShippingZoneLocations(const AZoneID: Int64; const ALocations: TArray<TWooZoneLocation>): TArray<TWooZoneLocation>;
    function ShippingZoneMethods(const AZoneID: Int64): TWooEndpoint<TWooShippingZoneMethod>;
    function ShippingMethods: TWooEndpoint<TWooShippingMethod>;

    { Reports }

    function Reports: TWooEndpoint<TWooIndexEntry>;
    // Params: period (week, month, last_month, year) or date_min/date_max (YYYY-MM-DD)
    function SalesReport(const AParams: TNameValueArray = nil): TWooSalesReport;
    function TopSellersReport(const AParams: TNameValueArray = nil): TArray<TWooTopSeller>;
    // AReport: coupons, customers, orders, products, reviews
    function ReportTotals(const AReport: string): TArray<TWooReportTotal>;

    { System and data }

    function SystemStatus: TWooSystemStatus;
    function SystemTools: TWooEndpoint<TWooSystemTool>;
    function RunSystemTool(const AID: string): TWooSystemTool;
    function Data: TWooEndpoint<TWooIndexEntry>;
    function Continents: TWooEndpoint<TWooContinent>;
    function Countries: TWooEndpoint<TWooCountry>;
    // Currencies.Get('current') is the shop currency
    function Currencies: TWooEndpoint<TWooCurrency>;

    // Underlying client, for timeouts and proxy settings
    property HTTP: THTTPClient read fHTTP;
    // Also send consumer_key/consumer_secret in the query string, for hosts (PHP as CGI/FastCGI)
    // that strip the Authorization header and answer 401. The header is still sent and wins when
    // it arrives. Off by default: the secret then lands in server access logs and in URLFor's result.
    property QueryStringAuth: Boolean read fQueryStringAuth write fQueryStringAuth;
    // For UploadImage only: a WordPress user who can upload files, and one of its Application
    // Passwords (Users > Profile > Application Passwords), not the login password. Sent as Basic auth.
    property WordPressUser: string read fWordPressUser write fWordPressUser;
    property WordPressAppPassword: string read fWordPressAppPassword write fWordPressAppPassword;
    // X-WP-Total / X-WP-TotalPages of the last list call; -1 when the endpoint does not send them
    property LastTotal: Integer read fLastTotal;
    property LastTotalPages: Integer read fLastTotalPages;
  end;

implementation

uses
  System.Classes,
  System.Generics.Collections,  // lets TJSONObject.GetPair inline (H2443)
  System.NetConsts,  // lets THTTPClient.SetAccept/SetContentType inline (H2443)
  System.Net.Mime,
  System.NetEncoding;

type
  // Record field -> JSON key: RegularPrice -> regular_price. [JsonName] on a field wins over it.
  TWooNames = class(TJsonDefaultContractResolver)
  protected
    function ResolvePropertyName(const AName: string): string; override;
  end;

function TWooNames.ResolvePropertyName(const AName: string): string;
begin
  Result := '';
  for var lChar in AName do
  begin
    if CharInSet(lChar, ['A'..'Z']) and (Result <> '') then
      Result := Result + '_';
    Result := Result + LowerCase(lChar);
  end;
end;

const
  // Top-level keys WooCommerce computes itself, in every resource that has them. Not sent on a
  // create: an 'id' even makes it answer "resource already exists". Nested keys are kept.
  cReadOnlyKeys: TArray<string> = [
    'id', 'instance_id', 'permalink', 'date_created', 'date_created_gmt', 'date_modified', 'date_modified_gmt',
    'price', 'price_html', 'on_sale', 'purchasable', 'total_sales', 'backorders_allowed', 'backordered',
    'shipping_required', 'shipping_taxable', 'shipping_class_id', 'average_rating', 'rating_count',
    'related_ids', 'variations', 'number', 'order_key', 'version', 'discount_total', 'discount_tax',
    'shipping_total', 'shipping_tax', 'cart_tax', 'total', 'total_tax', 'prices_include_tax',
    'customer_ip_address', 'customer_user_agent', 'date_paid', 'date_paid_gmt', 'date_completed',
    'date_completed_gmt', 'cart_hash', 'tax_lines', 'refunds', 'role', 'is_paying_customer', 'avatar_url',
    'usage_count', 'used_by', 'count', 'author', 'refunded_payment', 'resource', 'event', 'hooks',
    'method_title', 'method_description'];

// Removes empty strings, empty arrays and nulls at any depth: on a create they mean "not set"
procedure DropEmpty(const AValue: TJSONValue);
begin
  if AValue is TJSONObject then
  begin
    var lObject := TJSONObject(AValue);
    for var i := lObject.Count - 1 downto 0 do
    begin
      var lValue := lObject.Pairs[i].JsonValue;
      DropEmpty(lValue);
      if (lValue is TJSONNull) or ((lValue is TJSONString) and (lValue.Value = '')) or
        ((lValue is TJSONArray) and (TJSONArray(lValue).Count = 0)) then
        lObject.RemovePair(lObject.Pairs[i].JsonString.Value).Free;
    end;
  end
  else if AValue is TJSONArray then
    for var lItem in TJSONArray(AValue) do
      DropEmpty(lItem);
end;

{ EWooError }

constructor EWooError.Create(const AStatusCode: Integer; const ACode, AMessage: string);
begin
  inherited CreateFmt('WooCommerce HTTP %d %s: %s', [AStatusCode, ACode, AMessage]);
  fStatusCode := AStatusCode;
  fCode := ACode;
end;

class function EWooError.FromResponse(const AStatusCode: Integer; const ABody: string): EWooError;
begin
  var lCode := 'http_' + AStatusCode.ToString;
  var lMessage := Copy(ABody, 1, 500);  // a proxy or PHP fatal can answer with a whole HTML page
  var lJSON := TJSONValue.ParseJSONValue(ABody);
  try
    if lJSON is TJSONObject then
    begin
      lCode := lJSON.GetValue<string>('code', lCode);
      lMessage := lJSON.GetValue<string>('message', lMessage);
    end;
  finally
    lJSON.Free;
  end;
  Result := EWooError.Create(AStatusCode, lCode, lMessage);
end;

{ TWooEndpoint<T> }

constructor TWooEndpoint<T>.Create(const AClient: TWooClient; const APath: string; const ATrash: Boolean;
  const AIDKey: string);
begin
  fClient := AClient;
  fPath := APath;
  fTrash := ATrash;
  fIDKey := AIDKey;
end;

function TWooEndpoint<T>.List(const AParams: TNameValueArray): TArray<T>;
begin
  Result := fClient.FromJSON<TArray<T>>(fClient.GetAll(fPath, AParams));
end;

function TWooEndpoint<T>.Get(const AID: string): T;
begin
  Result := fClient.FromJSON<T>(fClient.Get(fPath + '/' + AID));
end;

function TWooEndpoint<T>.Get(const AID: Int64): T;
begin
  Result := Get(AID.ToString);
end;

function TWooEndpoint<T>.Add(const AItem: T): T;
begin
  var lBody := fClient.CreateBody(fClient.ToJSON<T>(AItem));
  try
    Result := fClient.FromJSON<T>(fClient.Post(fPath, lBody));
  finally
    lBody.Free;
  end;
end;

function TWooEndpoint<T>.Update(const AItem: T; const AFields: array of string): T;
begin
  var lJSON := fClient.ToJSON<T>(AItem);
  var lID := fClient.ItemID(lJSON, fIDKey);
  var lBody := fClient.UpdateBody(lJSON, AFields);
  try
    Result := fClient.FromJSON<T>(fClient.Put(fPath + '/' + lID, lBody));
  finally
    lBody.Free;
  end;
end;

function TWooEndpoint<T>.Delete(const AID: string; const AForce: Boolean): T;
begin
  Result := fClient.FromJSON<T>(fClient.Delete(fPath + '/' + AID,
    [TNameValuePair.Create('force', if AForce or not fTrash then 'true' else 'false')]));
end;

function TWooEndpoint<T>.Delete(const AID: Int64; const AForce: Boolean): T;
begin
  Result := Delete(AID.ToString, AForce);
end;

function TWooEndpoint<T>.BatchItems(const AResponse: TJSONValue; const AKey: string;
  var AErrors: TArray<string>): TArray<T>;
begin
  Result := nil;
  var lItems := AResponse.FindValue(AKey);
  if not (lItems is TJSONArray) then
    Exit;
  for var i := 0 to TJSONArray(lItems).Count - 1 do
  begin
    var lError := TJSONArray(lItems).Items[i].FindValue('error');
    if lError <> nil then
      AErrors := AErrors + [Format('%s[%d] %s: %s',
        [AKey, i, lError.GetValue<string>('code', ''), lError.GetValue<string>('message', '')])];
  end;
  Result := fClient.ParseJSON<TArray<T>>(lItems.ToJSON);
end;

function TWooEndpoint<T>.Batch(const AAdd, AUpdate: TArray<T>; const AUpdateFields: array of string;
  const ADelete: array of Int64): TWooBatch<T>;
begin
  var lFields: TArray<string> := [fIDKey];  // a batch update carries the ID in the item
  for var lField in AUpdateFields do
    lFields := lFields + [lField];
  var lBody := TJSONObject.Create;
  try
    if AAdd <> nil then
    begin
      var lList := TJSONArray.Create;
      lBody.AddPair('create', lList);
      for var lItem in AAdd do
        lList.AddElement(fClient.CreateBody(fClient.ToJSON<T>(lItem)));
    end;
    if AUpdate <> nil then
    begin
      var lList := TJSONArray.Create;
      lBody.AddPair('update', lList);
      for var lItem in AUpdate do
        lList.AddElement(fClient.UpdateBody(fClient.ToJSON<T>(lItem), lFields));
    end;
    if Length(ADelete) > 0 then
    begin
      var lList := TJSONArray.Create;
      lBody.AddPair('delete', lList);
      for var lID in ADelete do
        lList.Add(lID);
    end;
    var lResponse := fClient.Post(fPath + '/batch', lBody);
    try
      Result.Errors := nil;
      Result.Created := BatchItems(lResponse, 'create', Result.Errors);
      Result.Updated := BatchItems(lResponse, 'update', Result.Errors);
      Result.Deleted := BatchItems(lResponse, 'delete', Result.Errors);
    finally
      lResponse.Free;
    end;
  finally
    lBody.Free;
  end;
end;

{ TWooClient }

constructor TWooClient.Create(const AStoreURL, AConsumerKey, AConsumerSecret: string);
begin
  inherited Create;
  // WooCommerce accepts Basic auth only over HTTPS; plain HTTP needs OAuth 1.0a, and would leak the secret.
  if not AStoreURL.StartsWith('https://', True) then
    raise EArgumentException.Create('WooCommerce store URL must start with https://');
  fStoreURL := AStoreURL.TrimRight(['/']);
  fBaseURL := fStoreURL + '/wp-json/wc/v3/';
  fConsumerKey := AConsumerKey;
  fConsumerSecret := AConsumerSecret;
  fLastTotal := -1;
  fLastTotalPages := -1;
  fJSON := TJsonSerializer.Create;
  fJSON.ContractResolver := TWooNames.Create;
  fHTTP := THTTPClient.Create;
  fHTTP.Accept := 'application/json';
  fHTTP.ContentType := 'application/json; charset=utf-8';
  // Base64String, not Base64: Base64 wraps lines at 76 chars and ck_+cs_ keys encode to ~116.
  fHTTP.CustomHeaders['Authorization'] :=
    'Basic ' + TNetEncoding.Base64String.Encode(AConsumerKey + ':' + AConsumerSecret);
end;

destructor TWooClient.Destroy;
begin
  fHTTP.Free;
  fJSON.Free;
  inherited Destroy;
end;

function TWooClient.URLFor(const AEndpoint: string; const AParams: TNameValueArray): string;
begin
  var lURI := TURI.Create(fBaseURL + AEndpoint.TrimLeft(['/']));
  for var lParam in AParams do
    lURI.AddParameter(lParam.Name, lParam.Value);  // AddParameter percent-encodes name and value
  if fQueryStringAuth then
  begin
    lURI.AddParameter('consumer_key', fConsumerKey);
    lURI.AddParameter('consumer_secret', fConsumerSecret);
  end;
  Result := lURI.ToString;
end;

function TWooClient.Check(const AResponse: IHTTPResponse): TJSONValue;
begin
  var lBody := AResponse.ContentAsString;
  if (AResponse.StatusCode < 200) or (AResponse.StatusCode > 299) then
    raise EWooError.FromResponse(AResponse.StatusCode, lBody);
  fLastTotal := StrToIntDef(AResponse.HeaderValue['X-WP-Total'], -1);
  fLastTotalPages := StrToIntDef(AResponse.HeaderValue['X-WP-TotalPages'], -1);
  Result := TJSONValue.ParseJSONValue(lBody);
  if Result = nil then
  begin
    var lHint := '';
    if lBody.TrimLeft.StartsWith('<') then  // WordPress served a page: with Plain permalinks /wp-json/ is not routed
      lHint := 'HTML page instead of JSON: /wp-json/ is not reachable, set WordPress Settings > Permalinks to ' +
        'anything but Plain. ';
    raise EWooError.Create(AResponse.StatusCode, 'invalid_json', lHint + Copy(lBody, 1, 500));
  end;
end;

function TWooClient.Get(const AEndpoint: string; const AParams: TNameValueArray): TJSONValue;
begin
  Result := Check(fHTTP.Get(URLFor(AEndpoint, AParams)));
end;

function TWooClient.Post(const AEndpoint: string; const ABody: TJSONValue): TJSONValue;
begin
  var lSource := TStringStream.Create(ABody.ToJSON, TEncoding.UTF8);
  try
    Result := Check(fHTTP.Post(URLFor(AEndpoint), lSource));
  finally
    lSource.Free;
  end;
end;

function TWooClient.Put(const AEndpoint: string; const ABody: TJSONValue): TJSONValue;
begin
  var lSource := TStringStream.Create(ABody.ToJSON, TEncoding.UTF8);
  try
    Result := Check(fHTTP.Put(URLFor(AEndpoint), lSource));
  finally
    lSource.Free;
  end;
end;

function TWooClient.Delete(const AEndpoint: string; const AParams: TNameValueArray): TJSONValue;
begin
  Result := Check(fHTTP.Delete(URLFor(AEndpoint, AParams)));
end;

class function TWooClient.Expect<T>(const AValue: TJSONValue): T;
begin
  if not (AValue is T) then
  begin
    var lJSON := AValue.ToJSON;
    AValue.Free;  // the caller never receives it, so it is still ours
    raise EWooError.Create(0, 'unexpected_json', Copy(lJSON, 1, 500));
  end;
  Result := AValue as T;
end;

function TWooClient.ToJSON<T>(const AValue: T): string;
begin
  Result := fJSON.Serialize<T>(AValue);
end;

function TWooClient.ParseJSON<T>(const AJSON: string): T;
begin
  Result := fJSON.Deserialize<T>(AJSON);
end;

function TWooClient.FromJSON<T>(const AValue: TJSONValue): T;
begin
  try
    Result := fJSON.Deserialize<T>(AValue.ToJSON);
  finally
    AValue.Free;
  end;
end;

function TWooClient.CreateBody(const AJSON: string): TJSONObject;
begin
  Result := TJSONValue.ParseJSONValue(AJSON) as TJSONObject;
  for var lKey in cReadOnlyKeys do
    Result.RemovePair(lKey).Free;
  DropEmpty(Result);
end;

function TWooClient.UpdateBody(const AJSON: string; const AFields: array of string): TJSONObject;
begin
  var lAll := TJSONValue.ParseJSONValue(AJSON) as TJSONObject;
  try
    Result := TJSONObject.Create;
    try
      for var lField in AFields do
      begin
        var lPair := lAll.RemovePair(lField);
        if lPair = nil then
          raise EArgumentException.CreateFmt('"%s" is not a field of this record (use the JSON key, e.g. regular_price)', [lField]);
        Result.AddPair(lPair);
      end;
    except
      Result.Free;
      raise;
    end;
  finally
    lAll.Free;
  end;
end;

function TWooClient.ItemID(const AJSON, AIDKey: string): string;
begin
  Result := '';
  var lItem := TJSONValue.ParseJSONValue(AJSON);
  try
    var lID := lItem.FindValue(AIDKey);
    if lID <> nil then
      Result := lID.Value;
  finally
    lItem.Free;
  end;
  if (Result = '') or (Result = '0') then
    raise EArgumentException.CreateFmt('The record has no "%s": read it first, or set it', [AIDKey]);
end;

function TWooClient.GetAll(const AEndpoint: string; const AParams: TNameValueArray): TJSONArray;
const
  cPerPage = 100;  // WooCommerce maximum
begin
  Result := TJSONArray.Create;
  try
    var lPage := 1;
    repeat
      // per_page/page go last: PHP keeps the last value of a repeated parameter
      var lItems := Expect<TJSONArray>(Get(AEndpoint, AParams +
        [TNameValuePair.Create('per_page', IntToStr(cPerPage)), TNameValuePair.Create('page', IntToStr(lPage))]));
      try
        while lItems.Count > 0 do
          Result.AddElement(lItems.Remove(0));  // Remove extracts without freeing
      finally
        lItems.Free;
      end;
      Inc(lPage);
    // shortcut: no X-WP-TotalPages means "not paginated" (data, settings, reports...) and stops after
    // one request; a proxy that strips the header would cut a paginated list to 100 items.
    until (fLastTotalPages < 0) or (lPage > fLastTotalPages);
  except
    Result.Free;
    raise;
  end;
end;

{ Products }

function TWooClient.Products: TWooEndpoint<TWooProduct>;
begin
  Result := TWooEndpoint<TWooProduct>.Create(Self, 'products', True);
end;

function TWooClient.DuplicateProduct(const AID: Int64): TWooProduct;
begin
  var lBody := TJSONObject.Create;
  try
    Result := FromJSON<TWooProduct>(Post('products/' + AID.ToString + '/duplicate', lBody));
  finally
    lBody.Free;
  end;
end;

function TWooClient.UploadImage(const AFileName, AAlt: string): TWooImage;
begin
  if (fWordPressUser = '') or (fWordPressAppPassword = '') then
    raise EArgumentException.Create('UploadImage needs WordPressUser and WordPressAppPassword (a WordPress ' +
      'Application Password): /wp/v2/media does not accept WooCommerce keys');
  var lType: string;
  var lKind: TMimeTypes.TKind;
  if not TMimeTypes.Default.GetFileInfo(AFileName, lType, lKind) or not lType.StartsWith('image/') then
    raise EArgumentException.CreateFmt('%s is not an image file (jpg, png, gif, webp)', [AFileName]);
  // shortcut: non-ASCII letters of the file name become '_' on disk (header values are not UTF-8 safe);
  // the attachment title, sent in the query string, keeps them
  var lDiskName := ExtractFileName(AFileName);
  for var i := 1 to Length(lDiskName) do
    if (lDiskName[i] > #126) or (lDiskName[i] = '"') then
      lDiskName[i] := '_';
  var lURI := TURI.Create(fStoreURL + '/wp-json/wp/v2/media');
  lURI.AddParameter('title', ChangeFileExt(ExtractFileName(AFileName), ''));
  if AAlt <> '' then
    lURI.AddParameter('alt_text', AAlt);
  var lFile := TFileStream.Create(AFileName, fmOpenRead or fmShareDenyWrite);
  try
    // per-request headers replace the client's WooCommerce Authorization and JSON Content-Type
    var lMedia := Expect<TJSONObject>(Check(fHTTP.Post(lURI.ToString, lFile, nil, [
      TNetHeader.Create('Authorization', 'Basic ' + TNetEncoding.Base64String.Encode(fWordPressUser + ':' +
        fWordPressAppPassword)),
      TNetHeader.Create('Content-Type', lType),
      TNetHeader.Create('Content-Disposition', 'attachment; filename="' + lDiskName + '"')])));
    try
      Result.Id := lMedia.GetValue<Int64>('id');
      Result.Src := lMedia.GetValue<string>('source_url');
      Result.Alt := lMedia.GetValue<string>('alt_text', '');
    finally
      lMedia.Free;
    end;
  finally
    lFile.Free;
  end;
end;

function TWooClient.Variations(const AProductID: Int64): TWooEndpoint<TWooVariation>;
begin
  Result := TWooEndpoint<TWooVariation>.Create(Self, 'products/' + AProductID.ToString + '/variations');
end;

function TWooClient.Attributes: TWooEndpoint<TWooProductAttribute>;
begin
  Result := TWooEndpoint<TWooProductAttribute>.Create(Self, 'products/attributes');
end;

function TWooClient.AttributeTerms(const AAttributeID: Int64): TWooEndpoint<TWooAttributeTerm>;
begin
  Result := TWooEndpoint<TWooAttributeTerm>.Create(Self, 'products/attributes/' + AAttributeID.ToString + '/terms');
end;

function TWooClient.Categories: TWooEndpoint<TWooProductCategory>;
begin
  Result := TWooEndpoint<TWooProductCategory>.Create(Self, 'products/categories');
end;

function TWooClient.Tags: TWooEndpoint<TWooProductTag>;
begin
  Result := TWooEndpoint<TWooProductTag>.Create(Self, 'products/tags');
end;

function TWooClient.ShippingClasses: TWooEndpoint<TWooShippingClass>;
begin
  Result := TWooEndpoint<TWooShippingClass>.Create(Self, 'products/shipping_classes');
end;

function TWooClient.Reviews: TWooEndpoint<TWooProductReview>;
begin
  Result := TWooEndpoint<TWooProductReview>.Create(Self, 'products/reviews');
end;

function TWooClient.ProductCustomFieldNames(const AParams: TNameValueArray): TArray<string>;
begin
  Result := FromJSON<TArray<string>>(GetAll('products/custom-fields/names', AParams));
end;

{ Orders }

function TWooClient.Orders: TWooEndpoint<TWooOrder>;
begin
  Result := TWooEndpoint<TWooOrder>.Create(Self, 'orders', True);
end;

function TWooClient.UpdateOrderStatus(const AID: Int64; const AStatus: string): TWooOrder;
begin
  var lChanges := TJSONObject.Create;
  try
    lChanges.AddPair('status', AStatus);
    Result := FromJSON<TWooOrder>(Put('orders/' + AID.ToString, lChanges));
  finally
    lChanges.Free;
  end;
end;

function TWooClient.OrderNotes(const AOrderID: Int64): TWooEndpoint<TWooOrderNote>;
begin
  Result := TWooEndpoint<TWooOrderNote>.Create(Self, 'orders/' + AOrderID.ToString + '/notes');
end;

function TWooClient.Refunds(const AOrderID: Int64): TWooEndpoint<TWooRefund>;
begin
  Result := TWooEndpoint<TWooRefund>.Create(Self, 'orders/' + AOrderID.ToString + '/refunds');
end;

function TWooClient.AllRefunds: TWooEndpoint<TWooRefund>;
begin
  Result := TWooEndpoint<TWooRefund>.Create(Self, 'refunds');
end;

function TWooClient.OrderEmailTemplates(const AOrderID: Int64): TArray<TWooEmailTemplate>;
begin
  Result := FromJSON<TArray<TWooEmailTemplate>>(Get('orders/' + AOrderID.ToString + '/actions/email_templates'));
end;

function TWooClient.SendOrderEmail(const AOrderID: Int64; const ATemplateID, AEmail: string;
  const AForceEmailUpdate: Boolean): string;
begin
  var lBody := TJSONObject.Create;
  try
    if ATemplateID <> '' then
      lBody.AddPair('template_id', ATemplateID);
    if AEmail <> '' then
      lBody.AddPair('email', AEmail);
    if AForceEmailUpdate then
      lBody.AddPair('force_email_update', TJSONTrue.Create);
    var lAction := if ATemplateID = '' then 'send_order_details' else 'send_email';
    var lAnswer := Post('orders/' + AOrderID.ToString + '/actions/' + lAction, lBody);
    try
      Result := lAnswer.GetValue<string>('message', '');
    finally
      lAnswer.Free;
    end;
  finally
    lBody.Free;
  end;
end;

{ Customers and coupons }

function TWooClient.Customers: TWooEndpoint<TWooCustomer>;
begin
  Result := TWooEndpoint<TWooCustomer>.Create(Self, 'customers');
end;

function TWooClient.CustomerDownloads(const ACustomerID: Int64): TArray<TWooDownload>;
begin
  Result := FromJSON<TArray<TWooDownload>>(Get('customers/' + ACustomerID.ToString + '/downloads'));
end;

function TWooClient.Coupons: TWooEndpoint<TWooCoupon>;
begin
  Result := TWooEndpoint<TWooCoupon>.Create(Self, 'coupons', True);
end;

{ Taxes, webhooks, settings, payments }

function TWooClient.TaxRates: TWooEndpoint<TWooTaxRate>;
begin
  Result := TWooEndpoint<TWooTaxRate>.Create(Self, 'taxes');
end;

function TWooClient.TaxClasses: TWooEndpoint<TWooTaxClass>;
begin
  Result := TWooEndpoint<TWooTaxClass>.Create(Self, 'taxes/classes', False, 'slug');
end;

function TWooClient.Webhooks: TWooEndpoint<TWooWebhook>;
begin
  Result := TWooEndpoint<TWooWebhook>.Create(Self, 'webhooks');
end;

function TWooClient.SettingGroups: TWooEndpoint<TWooSettingGroup>;
begin
  Result := TWooEndpoint<TWooSettingGroup>.Create(Self, 'settings');
end;

function TWooClient.Settings(const AGroupID: string): TWooEndpoint<TWooSetting>;
begin
  Result := TWooEndpoint<TWooSetting>.Create(Self, 'settings/' + AGroupID);
end;

function TWooClient.PaymentGateways: TWooEndpoint<TWooPaymentGateway>;
begin
  Result := TWooEndpoint<TWooPaymentGateway>.Create(Self, 'payment_gateways');
end;

{ Shipping }

function TWooClient.ShippingZones: TWooEndpoint<TWooShippingZone>;
begin
  Result := TWooEndpoint<TWooShippingZone>.Create(Self, 'shipping/zones');
end;

function TWooClient.ShippingZoneLocations(const AZoneID: Int64): TArray<TWooZoneLocation>;
begin
  Result := FromJSON<TArray<TWooZoneLocation>>(Get('shipping/zones/' + AZoneID.ToString + '/locations'));
end;

function TWooClient.UpdateShippingZoneLocations(const AZoneID: Int64;
  const ALocations: TArray<TWooZoneLocation>): TArray<TWooZoneLocation>;
begin
  var lBody := TJSONValue.ParseJSONValue(ToJSON<TArray<TWooZoneLocation>>(ALocations));
  try
    Result := FromJSON<TArray<TWooZoneLocation>>(Put('shipping/zones/' + AZoneID.ToString + '/locations', lBody));
  finally
    lBody.Free;
  end;
end;

function TWooClient.ShippingZoneMethods(const AZoneID: Int64): TWooEndpoint<TWooShippingZoneMethod>;
begin
  Result := TWooEndpoint<TWooShippingZoneMethod>.Create(Self, 'shipping/zones/' + AZoneID.ToString + '/methods',
    False, 'instance_id');
end;

function TWooClient.ShippingMethods: TWooEndpoint<TWooShippingMethod>;
begin
  Result := TWooEndpoint<TWooShippingMethod>.Create(Self, 'shipping_methods');
end;

{ Reports }

function TWooClient.Reports: TWooEndpoint<TWooIndexEntry>;
begin
  Result := TWooEndpoint<TWooIndexEntry>.Create(Self, 'reports');
end;

function TWooClient.SalesReport(const AParams: TNameValueArray): TWooSalesReport;
begin
  var lReports := FromJSON<TArray<TWooSalesReport>>(Get('reports/sales', AParams));
  if lReports = nil then
    Result := Default(TWooSalesReport)
  else
    Result := lReports[0];
end;

function TWooClient.TopSellersReport(const AParams: TNameValueArray): TArray<TWooTopSeller>;
begin
  Result := FromJSON<TArray<TWooTopSeller>>(Get('reports/top_sellers', AParams));
end;

function TWooClient.ReportTotals(const AReport: string): TArray<TWooReportTotal>;
begin
  Result := FromJSON<TArray<TWooReportTotal>>(Get('reports/' + AReport + '/totals'));
end;

{ System and data }

function TWooClient.SystemStatus: TWooSystemStatus;
begin
  Result := FromJSON<TWooSystemStatus>(Get('system_status'));
end;

function TWooClient.SystemTools: TWooEndpoint<TWooSystemTool>;
begin
  Result := TWooEndpoint<TWooSystemTool>.Create(Self, 'system_status/tools');
end;

function TWooClient.RunSystemTool(const AID: string): TWooSystemTool;
begin
  var lBody := TJSONObject.Create;
  try
    lBody.AddPair('confirm', TJSONTrue.Create);
    Result := FromJSON<TWooSystemTool>(Put('system_status/tools/' + AID, lBody));
  finally
    lBody.Free;
  end;
end;

function TWooClient.Data: TWooEndpoint<TWooIndexEntry>;
begin
  Result := TWooEndpoint<TWooIndexEntry>.Create(Self, 'data');
end;

function TWooClient.Continents: TWooEndpoint<TWooContinent>;
begin
  Result := TWooEndpoint<TWooContinent>.Create(Self, 'data/continents');
end;

function TWooClient.Countries: TWooEndpoint<TWooCountry>;
begin
  Result := TWooEndpoint<TWooCountry>.Create(Self, 'data/countries');
end;

function TWooClient.Currencies: TWooEndpoint<TWooCurrency>;
begin
  Result := TWooEndpoint<TWooCurrency>.Create(Self, 'data/currencies');
end;

end.
