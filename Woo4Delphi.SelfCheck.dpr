// Woo4Delphi by KD Software Srls - https://www.kdsoftware.it - info@kdsoftware.it
// Developer: Giordano Giaccaglia

program Woo4Delphi.SelfCheck;

// Offline checks always run. Live checks run when an ini file is passed, the one the VCL demo writes
// (Woo4Delphi.SelfCheck Samples\VCL\Woo4DelphiDemo.ini): read-only GETs (one item of every large
// collection, the small lists, reports, system status).

{$APPTYPE CONSOLE}
{$ASSERTIONS ON}

uses
  System.SysUtils,
  System.IniFiles,
  System.Generics.Collections,
  System.JSON,
  System.Net.URLClient,
  Woo4Delphi.Types in 'Woo4Delphi.Types.pas',
  Woo4Delphi.Client in 'Woo4Delphi.Client.pas';

procedure OfflineChecks;
begin
  var lWoo := TWooClient.Create('https://shop.example.com/', 'ck_' + StringOfChar('a', 40), 'cs_' + StringOfChar('b', 40));
  try
    Assert(lWoo.URLFor('/products/12') = 'https://shop.example.com/wp-json/wc/v3/products/12', lWoo.URLFor('/products/12'));
    var lURL := lWoo.URLFor('products', [TNameValuePair.Create('per_page', '10'), TNameValuePair.Create('search', 'caff'#$E8' & latte')]);
    Assert(lURL = 'https://shop.example.com/wp-json/wc/v3/products?per_page=10&search=caff%C3%A8%20%26%20latte', lURL);
    var lAuth := lWoo.HTTP.CustomHeaders['Authorization'];
    Assert(lAuth.StartsWith('Basic ') and not lAuth.Contains(#10) and not lAuth.Contains(#13), 'auth header wrapped: ' + lAuth);
    lWoo.QueryStringAuth := True;
    lURL := lWoo.URLFor('products', [TNameValuePair.Create('per_page', '10')]);
    Assert(lURL = 'https://shop.example.com/wp-json/wc/v3/products?per_page=10&consumer_key=ck_' + StringOfChar('a', 40) +
      '&consumer_secret=cs_' + StringOfChar('b', 40), lURL);

    // records <-> JSON: names, self-initialization, converters
    var lProduct: TWooProduct;  // no Default(): the record zeroes itself and takes WooCommerce's defaults
    Assert((lProduct.Id = 0) and not lProduct.Featured and lProduct.ReviewsAllowed and (lProduct.DownloadLimit = -1));
    lProduct.ProductType := 'simple';
    lProduct.Dimensions.Length := '10';
    var lJSON := lWoo.ToJSON<TWooProduct>(lProduct);
    Assert(lJSON.Contains('"type":"simple"') and lJSON.Contains('"virtual":false') and
      lJSON.Contains('"reviews_allowed":true') and lJSON.Contains('"dimensions":{"length":"10"'), lJSON);
    var lLine := lWoo.ParseJSON<TWooOrderLine>(
      '{"id":1,"price":9.95,"sku":null,"meta_data":[{"id":2,"key":"k","value":{"a":[1,2]}}],"unknown":{"x":1}}');
    Assert((lLine.Price = '9.95') and (lLine.Sku = '') and (lLine.MetaData[0].Value = '{"a":[1,2]}'),
      lLine.Price + ' ' + lLine.MetaData[0].Value);
    Assert(lWoo.ToJSON<TWooMeta>(lLine.MetaData[0]).Contains('"value":{"a":[1,2]}'), 'object meta not written back as JSON');
    Assert(not lWoo.ParseJSON<TWooVariation>('{"manage_stock":"parent","image":null}').ManageStock);
    Assert(lWoo.ParseJSON<TWooAddress>('{"address_1":"Via Roma 1"}').Address1 = 'Via Roma 1');
    var lRate: TWooTaxRate;
    Assert((lRate.Priority = 1) and lRate.Shipping and lWoo.ToJSON<TWooTaxRate>(lRate).Contains('"class":""'));
  finally
    lWoo.Free;
  end;

  var lRaised := False;
  try
    TWooClient.Create('http://shop.example.com', 'k', 's').Free;
  except
    on EArgumentException do
      lRaised := True;
  end;
  Assert(lRaised, 'plain http accepted');

  var lError := EWooError.FromResponse(404, '{"code":"woocommerce_rest_product_invalid_id","message":"Invalid ID.","data":{"status":404}}');
  try
    Assert((lError.StatusCode = 404) and (lError.Code = 'woocommerce_rest_product_invalid_id'), lError.Message);
    Assert(lError.Message.Contains('Invalid ID.'), lError.Message);
  finally
    lError.Free;
  end;

  lError := EWooError.FromResponse(502, '<html>Bad Gateway</html>');
  try
    Assert((lError.Code = 'http_502') and lError.Message.Contains('Bad Gateway'), lError.Message);
  finally
    lError.Free;
  end;
  Writeln('offline checks: OK');
end;

// ID of the first item of a list endpoint, '' when the list is empty
function FirstID(const AWoo: TWooClient; const AEndpoint: string; const AParams: TNameValueArray = nil;
  const AIDKey: string = 'id'): string;
begin
  Result := '';
  var lList := AWoo.Get(AEndpoint, AParams + [TNameValuePair.Create('per_page', '1')]);
  try
    if (lList is TJSONArray) and (TJSONArray(lList).Count > 0) then
      Result := TJSONArray(lList).Items[0].GetValue<string>(AIDKey);
  finally
    lList.Free;
  end;
end;

// Runs one live read; an endpoint this WooCommerce version does not have is reported, not failed
procedure Probe(const AName: string; const ARead: TFunc<string>);
begin
  try
    Writeln('live: ', AName, ': ', ARead());
  except
    on E: EWooError do
      if E.Code = 'rest_no_route' then
        Writeln('live: ', AName, ': not on this WooCommerce version')
      else
        raise;
  end;
end;

procedure AcceptAnyCertificate(const Sender: TObject; const ARequest: TURLRequest; const Certificate: TCertificate;
  var Accepted: Boolean);
begin
  Accepted := True;
end;

procedure LiveChecks;
begin
  if ParamCount = 0 then
  begin
    Writeln('live checks: skipped (pass an ini file with a [Store] section, e.g. Samples\VCL\Woo4DelphiDemo.ini)');
    Exit;
  end;
  if not FileExists(ParamStr(1)) then
    raise EFileNotFoundException.Create('ini file not found: ' + ParamStr(1));
  var lStoreURL, lKey, lSecret: string;
  var lAnyCertificate: Boolean;
  var lIni := TMemIniFile.Create(ParamStr(1), TEncoding.UTF8);
  try
    lStoreURL := lIni.ReadString('Store', 'URL', '');
    lKey := lIni.ReadString('Store', 'ConsumerKey', '');
    lSecret := lIni.ReadString('Store', 'ConsumerSecret', '');
    lAnyCertificate := lIni.ReadBool('Store', 'AcceptAnyCertificate', False);
  finally
    lIni.Free;
  end;
  var lWoo := TWooClient.Create(lStoreURL, lKey, lSecret);
  try
    if lAnyCertificate then  // test stores with a self-signed certificate only
      lWoo.HTTP.ValidateServerCertificateCallback := AcceptAnyCertificate;
    // typed reads of real data: a field WooCommerce sends with an unexpected type fails here
    Probe('products', function: string
      begin
        var lID := FirstID(lWoo, 'products');
        Assert(lWoo.LastTotalPages >= 0, 'X-WP-TotalPages missing');
        Result := Format('%d in the shop', [lWoo.LastTotal]);
        if lID <> '' then
          Result := Result + ', first: ' + lWoo.Products.Get(lID).Name;
      end);
    Probe('variations', function: string
      begin
        Result := 'no variable product';
        var lID := FirstID(lWoo, 'products', [TNameValuePair.Create('type', 'variable')]);
        if lID <> '' then
          Result := Format('product %s has %d', [lID, Length(lWoo.Variations(lID.ToInt64).List)]);
      end);
    Probe('orders', function: string
      begin
        var lID := FirstID(lWoo, 'orders');
        Result := 'none';
        if lID <> '' then
        begin
          var lOrder := lWoo.Orders.Get(lID);
          Result := Format('%s, %s %s, %d lines, %d notes, %d refunds, %d e-mail templates', [lOrder.Number, lOrder.Total,
            lOrder.Currency, Length(lOrder.LineItems), Length(lWoo.OrderNotes(lOrder.Id).List),
            Length(lWoo.Refunds(lOrder.Id).List), Length(lWoo.OrderEmailTemplates(lOrder.Id))]);
        end;
      end);
    Probe('all refunds', function: string begin Result := FirstID(lWoo, 'refunds'); end);
    Probe('customers', function: string
      begin
        Result := 'none';
        var lID := FirstID(lWoo, 'customers');
        if lID <> '' then
        begin
          var lCustomer := lWoo.Customers.Get(lID);
          Result := Format('%d downloads for the first', [Length(lWoo.CustomerDownloads(lCustomer.Id))]);
        end;
      end);
    Probe('coupons', function: string
      begin
        Result := 'none';
        var lID := FirstID(lWoo, 'coupons');
        if lID <> '' then
          Result := lWoo.Coupons.Get(lID).Code;
      end);
    Probe('categories', function: string
      begin
        Result := 'none';
        var lID := FirstID(lWoo, 'products/categories');
        if lID <> '' then
          Result := lWoo.Categories.Get(lID).Name;
      end);
    Probe('tags', function: string
      begin
        Result := 'none';
        var lID := FirstID(lWoo, 'products/tags');
        if lID <> '' then
          Result := lWoo.Tags.Get(lID).Name;
      end);
    Probe('attributes', function: string
      begin
        var lAttributes := lWoo.Attributes.List;
        Result := Length(lAttributes).ToString;
        if lAttributes <> nil then
          Result := Result + Format(', %d terms in the first', [Length(lWoo.AttributeTerms(lAttributes[0].Id).List)]);
      end);
    Probe('shipping classes', function: string begin Result := FirstID(lWoo, 'products/shipping_classes'); end);
    Probe('reviews', function: string
      begin
        Result := 'none';
        var lID := FirstID(lWoo, 'products/reviews');
        if lID <> '' then
          Result := lWoo.Reviews.Get(lID).Reviewer;
      end);
    Probe('custom field names', function: string begin Result := Length(lWoo.ProductCustomFieldNames).ToString; end);
    Probe('tax rates', function: string
      begin
        Result := 'none';
        var lID := FirstID(lWoo, 'taxes');
        if lID <> '' then
          Result := lWoo.TaxRates.Get(lID).Rate;
      end);
    Probe('tax classes', function: string begin Result := Length(lWoo.TaxClasses.List).ToString; end);
    Probe('webhooks', function: string begin Result := Length(lWoo.Webhooks.List).ToString; end);
    Probe('settings', function: string
      begin
        Result := Format('%d groups, currency %s', [Length(lWoo.SettingGroups.List),
          lWoo.Settings('general').Get('woocommerce_currency').Value]);
      end);
    Probe('payment gateways', function: string begin Result := Length(lWoo.PaymentGateways.List).ToString; end);
    Probe('shipping zones', function: string
      begin
        var lZones := lWoo.ShippingZones.List;
        Result := Length(lZones).ToString;
        if lZones <> nil then
          Result := Result + Format(', first: %d locations, %d methods', [Length(lWoo.ShippingZoneLocations(lZones[0].Id)),
            Length(lWoo.ShippingZoneMethods(lZones[0].Id).List)]);
      end);
    Probe('shipping methods', function: string begin Result := Length(lWoo.ShippingMethods.List).ToString; end);
    Probe('reports', function: string
      begin
        Result := Format('%d, sales %s, %d top sellers, %d order totals', [Length(lWoo.Reports.List),
          lWoo.SalesReport.TotalSales, Length(lWoo.TopSellersReport), Length(lWoo.ReportTotals('orders'))]);
      end);
    Probe('system status', function: string
      begin
        var lStatus := lWoo.SystemStatus;
        Result := Format('WooCommerce %s, WordPress %s, PHP %s, %d plugins, %d tools', [lStatus.Environment.Version,
          lStatus.Environment.WpVersion, lStatus.Environment.PhpVersion, Length(lStatus.ActivePlugins),
          Length(lWoo.SystemTools.List)]);
      end);
    Probe('data', function: string
      begin
        Result := Format('%d countries, %d continents, currency %s', [Length(lWoo.Countries.List),
          Length(lWoo.Continents.List), lWoo.Currencies.Get('current').Code]);
      end);

    var lGot404 := False;
    try
      lWoo.Products.Get(0);
    except
      on E: EWooError do
        lGot404 := E.StatusCode = 404;
    end;
    Assert(lGot404, 'products/0 did not raise EWooError 404');

    lWoo.QueryStringAuth := True;  // the store must still accept the request with the extra parameters
    lWoo.Get('products', [TNameValuePair.Create('per_page', '1')]).Free;
    Writeln('live checks: OK');
  finally
    lWoo.Free;
  end;
end;

begin
  try
    OfflineChecks;
    LiveChecks;
  except
    on E: Exception do
    begin
      Writeln(E.ClassName, ': ', E.Message);
      ExitCode := 1;
    end;
  end;
end.
