# Woo4Delphi

**English** | [Italiano](README.it.md) | [Español](README.es.md) | [Français](README.fr.md) | [Deutsch](README.de.md)

By [KD Software Srls](https://www.kdsoftware.it) - developer Giordano Giaccaglia - <info@kdsoftware.it>

A **WooCommerce REST API v3** client for Delphi 13 Florence: two units to add to your project,
RTL only (`System.Net.HttpClient`, `System.JSON`), no package to install.

- Every v3 resource (products, variations, orders, customers, coupons, taxes, shipping,
  settings, payments, webhooks, reports, system status, data) as **typed Delphi records**.
- One way to work with every resource: `List`, `Get`, `Add`, `Update`, `Delete`, `Batch`.
- Updates send **only the fields you list**: a field you do not name is never overwritten.
- A raw JSON layer for everything else.

| File | Contents |
|------|----------|
| `Woo4Delphi.Types.pas` | The records of every resource, field by field from the v3 documentation |
| `Woo4Delphi.Client.pas` | `TWooClient`, `TWooEndpoint<T>`, `EWooError` |
| `Woo4Delphi.SelfCheck.dpr` | Command-line check (offline, and live against a store) |
| `Samples\VCL\Woo4DelphiDemo.dpr` | VCL application with one page per area, to try every feature |

## Requirements

- Delphi 13 Florence (it uses the `if … then … else` expression and managed records), Win32 or Win64.
- WooCommerce with REST API v3 (WooCommerce 3.5 or later) reachable over **HTTPS**.
- A REST key pair: in WordPress, *WooCommerce → Settings → Advanced → REST API → Add key*.
  *Read* permission to read, *Read/Write* to make changes.

## Quick start

Add `Woo4Delphi.Types.pas` and `Woo4Delphi.Client.pas` to the project (or their folder to the search path).

```delphi
uses
  System.Net.URLClient,   // TNameValuePair, for filters
  Woo4Delphi.Types,
  Woo4Delphi.Client;

var lWoo := TWooClient.Create('https://shop.example.com', 'ck_...', 'cs_...');
try
  // a record: nothing to free
  var lProduct := lWoo.Products.Get(7);
  lProduct.RegularPrice := '12.50';
  lProduct.StockQuantity := 0;
  lWoo.Products.Update(lProduct, ['regular_price', 'stock_quantity']);   // these two fields only

  // every page, filtered
  for var lOrder in lWoo.Orders.List([TNameValuePair.Create('status', 'processing')]) do
    Writeln(lOrder.Number, '  ', lOrder.Billing.City, '  ', lOrder.Total, ' ', lOrder.Currency);

  lWoo.UpdateOrderStatus(1234, 'completed');
finally
  lWoo.Free;
end;
```

## Concepts

### Records

Every resource is a record (`TWooProduct`, `TWooOrder`, `TWooCustomer`…). Strings and arrays are
managed by the compiler: no `Free`, no memory leaks.

- **Names**: a Delphi field maps to the snake_case JSON key (`RegularPrice` ↔ `regular_price`,
  `DateCreatedGmt` ↔ `date_created_gmt`). Where the rule does not fit, or the key is a reserved word,
  there is a `[JsonName]`: `ProductType` ↔ `type`, `IsVirtual` ↔ `virtual`, `RateClass` ↔ `class`,
  `Caption` ↔ `label`, `DefaultValue` ↔ `default`, `Address1` ↔ `address_1`.
- **Unknown keys**: ignored when reading, never sent when writing. A `null` becomes 0, `''`,
  `False` or an empty record.
- **Automatic initialization**: the records you can create clear themselves and take the WooCommerce
  defaults where those are not zero. `var lCoupon: TWooCoupon;` is enough, no `Default()` needed:

  | Record | Non-zero defaults |
  |--------|-------------------|
  | `TWooProduct` | `ReviewsAllowed = True`, `DownloadLimit = -1`, `DownloadExpiry = -1` |
  | `TWooVariation` | `DownloadLimit = -1`, `DownloadExpiry = -1` |
  | `TWooTaxRate` | `Priority = 1`, `Shipping = True` |
  | `TWooShippingZoneMethod` | `Enabled = True` |
  | `TWooRefund` | `ApiRestock = True`; `ApiRefund = False` (see *Refunds*) |

- **Prices and totals** are strings, as WooCommerce sends them (`'9.90'`). To compute with them:
  `StrToFloat(lProduct.RegularPrice, TFormatSettings.Invariant)`.
- **Dates** are the WooCommerce ISO strings. `DateCreated` is in the store's time, without a time zone;
  `DateCreatedGmt` is UTC: `ISO8601ToDate(lOrder.DateCreatedGmt, True)`.
- **"JSON text" fields**: some values have a variable type or dynamic keys and arrive as JSON text
  in a string: the `Value` of `MetaData` when it is not a string, the `Value` of multiselect settings
  (`'["IT","FR"]'`), the `Settings` of gateways and shipping methods, the `Options` of settings,
  the `Totals` of the sales report, the `Price` of order line items (a number in JSON).
  To send an object or an array, assign its JSON text: `lGateway.Settings := '{"title":"Bank transfer"}'`.
- **Variations**: when the parent product manages the stock, WooCommerce sends
  `"manage_stock": "parent"`; the record reads it as `ManageStock = False`.

### Endpoints: `TWooEndpoint<T>`

`lWoo.Products`, `lWoo.Variations(ProductID)`, `lWoo.Settings('general')`… return a
`TWooEndpoint<T>`, always with the same methods:

| Method | HTTP | What it does |
|--------|------|--------------|
| `List(AParams)` | GET | **Every page**, 100 items per request; a single request on non-paginated endpoints |
| `Get(ID)` | GET | One item; `ID` numeric or a string (`'woocommerce_currency'`, `'bacs'`, `'IT'`) |
| `Add(Item)` | POST | Creates. It sends neither read-only fields (`id`, `price`, `permalink`, `date_created`…) nor empty strings and arrays: WooCommerce applies its defaults |
| `Update(Item, Fields)` | PUT | Sends **only** the listed JSON keys; takes the ID from `Item`. A key that is not a field of the record raises `EArgumentException` |
| `Delete(ID, AForce)` | DELETE | Products, orders, coupons: without `AForce` they go to the trash. No other resource has a trash: deletion is always permanent |
| `Batch(Create, Update, Fields, Delete)` | POST …/batch | Up to 100 items in total per call. `Errors` lists the rejected items |

`Update` needs the list of fields because a record cannot tell "not set" from "empty": sending it
whole would clear the fields you did not read or set. The natural way is read, change, save the
fields you touched:

```delphi
var lCustomer := lWoo.Customers.Get(42);
lCustomer.Billing.Phone := '+1 555 0100';
lWoo.Customers.Update(lCustomer, ['billing']);   // the whole billing object, as read and changed
```

### Filters and paging

Filters are the parameters of the WooCommerce documentation, as name/value pairs:

```delphi
var lOrders := lWoo.Orders.List([
  TNameValuePair.Create('status', 'processing'),
  TNameValuePair.Create('modified_after', '2026-11-01T00:00:00')]);
```

`List` sets `per_page` and `page` itself and loads everything into memory. On very large catalogs
use the raw layer page by page (`lWoo.Get('products', [per_page, page])`): after each call
`LastTotal` and `LastTotalPages` report the `X-WP-Total` and `X-WP-TotalPages` headers.

### Errors

- `EWooError`: every non-2xx response. `StatusCode` is the HTTP status, `Code` the WooCommerce code
  (`woocommerce_rest_product_invalid_id`, `rest_invalid_param`, `rest_no_route`…), `Message` the text.
  If a proxy answers with an HTML page, `Code` is `http_<status>`.
- `EArgumentException`: a URL that is not HTTPS, an unknown field in `Update`, a record without an ID in `Update`.
- `THTTPClient` network errors (`ENetHTTPClientException`) pass through unchanged.

### Raw layer

For what the records do not cover: `Get`, `Post`, `Put`, `Delete`, `GetAll` work on `TJSONValue`,
with endpoints relative to `/wp-json/wc/v3/`. **You free the returned value.**

```delphi
var lAnswer := lWoo.Get('orders/123', [TNameValuePair.Create('dp', '4')]);
try
  Writeln(lAnswer.Format(2));
finally
  lAnswer.Free;
end;
```

`lWoo.ToJSON<T>(Record)` and `lWoo.ParseJSON<T>(Text)` turn a record into WooCommerce JSON and back,
with the same naming rules: useful for logs, saved copies, raw calls.

### Authentication and connection

- HTTPS only: WooCommerce accepts the keys in Basic auth only over HTTPS (HTTP needs OAuth 1.0a,
  not implemented), and over HTTP the secret key would travel in clear text.
- `QueryStringAuth := True`: for hosts (PHP as CGI/FastCGI) that strip the `Authorization` header
  and answer 401 to valid keys. The keys then also go in the query string, and so **into the server logs**.
- `lWoo.HTTP` is the underlying `THTTPClient`: timeouts (`ConnectionTimeout`, `ResponseTimeout`), proxy,
  and, for development stores with a self-signed certificate only, `ValidateServerCertificateCallback`.
- One `TWooClient` per thread: `LastTotal`/`LastTotalPages` describe the last call of that instance.

## Endpoint reference

| Area | Client method | Record | Operations | Notes |
|------|---------------|--------|------------|-------|
| Products | `Products` | `TWooProduct` | all + Batch | trash |
| | `DuplicateProduct(ID)` | `TWooProduct` | POST …/duplicate | the copy starts as a draft |
| Media library | `UploadImage(File, Alt)` | `TWooImage` | POST /wp/v2/media | WordPress, not WooCommerce: see *Product images* |
| Variations | `Variations(ProductID)` | `TWooVariation` | all + Batch | |
| Global attributes | `Attributes` | `TWooProductAttribute` | all + Batch | not paginated |
| Attribute terms | `AttributeTerms(AttributeID)` | `TWooAttributeTerm` | all + Batch | |
| Categories | `Categories` | `TWooProductCategory` | all + Batch | |
| Tags | `Tags` | `TWooProductTag` | all + Batch | |
| Shipping classes | `ShippingClasses` | `TWooShippingClass` | all + Batch | |
| Reviews | `Reviews` | `TWooProductReview` | all + Batch | |
| Custom fields | `ProductCustomFieldNames` | `TArray<string>` | list | recent WooCommerce versions |
| Orders | `Orders` | `TWooOrder` | all + Batch | trash; `SetPaid` on creation |
| | `UpdateOrderStatus(ID, Status)` | `TWooOrder` | PUT | e-mails and stock as from the admin panel |
| Order notes | `OrderNotes(OrderID)` | `TWooOrderNote` | List, Get, Add, Delete | `CustomerNote = True` notifies the customer |
| Order refunds | `Refunds(OrderID)` | `TWooRefund` | List, Get, Add, Delete | see *Refunds* |
| All refunds | `AllRefunds` | `TWooRefund` | List | `ParentId` = order |
| Order e-mails | `OrderEmailTemplates(ID)`, `SendOrderEmail(ID, Template, Email, Force)` | `TWooEmailTemplate` | GET, POST | empty template = order details (invoice) |
| Customers | `Customers` | `TWooCustomer` | all + Batch | *customer* role only (filter `role=all` for everyone) |
| | `CustomerDownloads(ID)` | `TWooDownload` | GET | |
| Coupons | `Coupons` | `TWooCoupon` | all + Batch | trash |
| Tax rates | `TaxRates` | `TWooTaxRate` | all + Batch | |
| Tax classes | `TaxClasses` | `TWooTaxClass` | List, Add, Delete(slug) | deleting one also deletes its rates |
| Webhooks | `Webhooks` | `TWooWebhook` | all + Batch | `Secret` signs the payloads |
| Setting groups | `SettingGroups` | `TWooSettingGroup` | List | an index: the options are in `Settings(group)` |
| Settings | `Settings(GroupID)` | `TWooSetting` | List, Get, Update, Batch | `Value` as JSON text for multiselects |
| Payment gateways | `PaymentGateways` | `TWooPaymentGateway` | List, Get, Update | |
| Shipping zones | `ShippingZones` | `TWooShippingZone` | List, Get, Add, Update, Delete | zone 0 cannot be deleted |
| Zone locations | `ShippingZoneLocations(ID)`, `UpdateShippingZoneLocations(ID, Locations)` | `TWooZoneLocation` | GET, PUT | the PUT replaces every location |
| Zone methods | `ShippingZoneMethods(ZoneID)` | `TWooShippingZoneMethod` | List, Get, Add, Update, Delete | ID = `InstanceId`; `MethodId` required on creation |
| Shipping methods | `ShippingMethods` | `TWooShippingMethod` | List, Get | |
| Reports | `Reports` | `TWooIndexEntry` | List | index of the reports |
| | `SalesReport(Filters)` | `TWooSalesReport` | GET | `period` or `date_min`/`date_max` |
| | `TopSellersReport(Filters)` | `TWooTopSeller` | GET | |
| | `ReportTotals('orders')` | `TWooReportTotal` | GET | coupons, customers, orders, products, reviews |
| System status | `SystemStatus` | `TWooSystemStatus` | GET | environment, database, plugins, theme, settings, security, pages |
| System tools | `SystemTools`, `RunSystemTool(ID)` | `TWooSystemTool` | List, Get, PUT | some tools are destructive |
| Data | `Data` | `TWooIndexEntry` | List | index |
| | `Continents`, `Countries` | `TWooContinent`, `TWooCountry` | List, Get(code) | |
| | `Currencies` | `TWooCurrency` | List, Get(code) | `Get('current')` = the store currency |

*All* = `List`, `Get`, `Add`, `Update`, `Delete`. On the endpoints WooCommerce does not provide
(for example `Add` on `Countries`) the server answers with an `EWooError` with code `rest_no_route`.

## Recipes

**Product images: main image and gallery**

In `TWooProduct.Images` the first image is the main one, the others are the gallery. WooCommerce
accepts only images already in the media library (by `Id`) or a URL to download (`Id` 0 and `Src`).
It has no endpoint to upload files: a file on disk must first be uploaded to the WordPress media
library with `UploadImage`. That endpoint (`/wp/v2/media`) **does not accept WooCommerce keys**: it
needs a WordPress user who can upload files and an *application password* of that user
(Users → Profile → Application Passwords), not the login password.

```delphi
lWoo.WordPressUser := 'editor';
lWoo.WordPressAppPassword := 'abcd efgh ijkl mnop qrst uvwx';
var lMain := lWoo.UploadImage('C:\Photos\mug.jpg', 'Red mug');        // Id and Src in the media library
var lFromWeb: TWooImage;
lFromWeb.Src := 'https://example.com/photos/mug-back.jpg';            // WooCommerce downloads it
var lProduct := lWoo.Products.Get(7);
lProduct.Images := [lMain, lFromWeb];                                 // main image, then gallery
lWoo.Products.Update(lProduct, ['images']);
```

- `Images` replaces every image: to add one to the gallery, start from the product's images.
  `Images := nil` removes them all. Removing an image does not delete it from the media library.
- When you send back the images you read, send only `Id`: the `Name` WooCommerce returns already has
  WordPress typography applied (curly quotes), and a non-empty `Name` renames the file in the library.
- For a URL, the store's server must be able to reach the address: on a development store
  `https://localhost` usually fails (WooCommerce answers `woocommerce_product_image_upload_error`).
- The file name on disk loses its non-ASCII letters (`café.jpg` → `caf_.jpg`); the image title in
  the library keeps them.

**Update the stock of many products in one call**

```delphi
var lUpdates: TArray<TWooProduct>;
SetLength(lUpdates, 2);
lUpdates[0].Id := 7;   lUpdates[0].ManageStock := True; lUpdates[0].StockQuantity := 12;
lUpdates[1].Id := 8;   lUpdates[1].ManageStock := True; lUpdates[1].StockQuantity := 0;
var lResult := lWoo.Products.Batch(nil, lUpdates, ['manage_stock', 'stock_quantity'], []);
for var lError in lResult.Errors do
  Writeln(lError);   // e.g. 'update[1] woocommerce_rest_product_invalid_id: Invalid ID.'
```

**Create a variable product with one variation**

```delphi
var lProduct: TWooProduct;
lProduct.Name := 'Mug';
lProduct.ProductType := 'variable';
SetLength(lProduct.Attributes, 1);
lProduct.Attributes[0].Name := 'Color';
lProduct.Attributes[0].Variation := True;
lProduct.Attributes[0].Visible := True;
lProduct.Attributes[0].Options := ['Red', 'Blue'];
lProduct := lWoo.Products.Add(lProduct);

var lVariation: TWooVariation;
lVariation.RegularPrice := '9.90';
SetLength(lVariation.Attributes, 1);
lVariation.Attributes[0].Name := 'Color';
lVariation.Attributes[0].Option := 'Red';
lWoo.Variations(lProduct.Id).Add(lVariation);
```

**Create a paid order**

```delphi
var lOrder: TWooOrder;
lOrder.PaymentMethod := 'bacs';
lOrder.SetPaid := True;                    // processing, stock reduced
lOrder.Billing.Email := 'customer@example.com';
SetLength(lOrder.LineItems, 1);
lOrder.LineItems[0].ProductId := 7;
lOrder.LineItems[0].Quantity := 2;
lOrder := lWoo.Orders.Add(lOrder);
```

**Refunds.** `TWooRefund.ApiRefund` starts as `False` (the WooCommerce default is `True`): the refund
is recorded without moving any money. Set it to `True` to give the money back through the gateway.

```delphi
var lRefund: TWooRefund;
lRefund.Amount := '10.00';
lRefund.Reason := 'Returned';
lRefund.ApiRefund := True;    // a real refund through the gateway
lWoo.Refunds(1234).Add(lRefund);
```

**Change a store setting**

```delphi
var lSetting := lWoo.Settings('general').Get('woocommerce_specific_allowed_countries');
lSetting.Value := '["IT","FR","DE"]';     // multiselect: JSON text
lWoo.Settings('general').Update(lSetting, ['value']);
```

## The VCL sample

`Samples\VCL\Woo4DelphiDemo.dpr`: open it in RAD Studio, then build and run. Its interface is in
Italian. At the top go the URL and the keys; the second row is needed only to upload images
(WordPress user and application password). At the bottom is the log of every call, with the time
it took.

The settings are read at startup from `Woo4DelphiDemo.ini`, next to the executable, and saved there
on close. You can also write it by hand:

```ini
[Store]
URL=https://shop.example.com
ConsumerKey=ck_...
ConsumerSecret=cs_...
QueryStringAuth=0
; 1 only for development stores with a self-signed certificate
AcceptAnyCertificate=0

[WordPress]
User=editor
AppPassword=abcd efgh ijkl mnop qrst uvwx
```

> The file holds keys and passwords **in clear text**: keep it out of version control and do not
> ship it with the executable.

| Page | What it tries |
|------|---------------|
| **Prodotti** (products) | list and search, typed editing of the main fields (EAN, stock status and categories too), images (upload a file, from a URL, pick the main one, remove), create, duplicate, trash, permanent delete; variations: list, price and stock, add, delete |
| **Categorie** (categories) | list, create, rename, slug, move under another category, description, delete |
| **Ordini** (orders) | list by status, detail, status change, notes (customer-visible ones too), refunds, sending e-mails, a test order |
| **Risorse** (resources) | every typed endpoint: list with filters, read, create and update from JSON (through the record), delete, batch on several rows |
| **Report e sistema** (reports and system) | sales report, top sellers, totals, system status, tools, currency, custom fields, the locations of a zone, a customer's downloads |
| **JSON grezzo** (raw JSON) | any method on any endpoint |

> **Warning**: the sample works on the store it connects to. It creates, changes and deletes real
> data, changes order statuses (with the WooCommerce e-mails to customers), records refunds, runs
> system tools. Every destructive operation asks for confirmation, but use it on a **test store**.

Calls run on the main thread to keep the code readable: in a real application move them to a
thread (`TTask.Run`) with one `TWooClient` per thread.

## Verification

```
dcc32 Woo4Delphi.SelfCheck.dpr  (or dcc64)
Woo4Delphi.SelfCheck.exe                                   offline checks
Woo4Delphi.SelfCheck.exe Samples\VCL\Woo4DelphiDemo.ini    against the store too
```

Without parameters it runs the offline checks: URL and parameter encoding, authentication headers,
JSON names and record defaults, converters, error parsing. With an ini file (the `[Store]` section,
the same as the VCL sample) it also reads, **read-only**, one item of every resource of the store:
if WooCommerce sends a field with an unexpected type, it reports it. An endpoint missing from the
store's WooCommerce version is reported, not failed. `AcceptAnyCertificate=1` is for a test store
with a self-signed certificate.

The WordPress permalinks (Settings → Permalinks) must not be "Plain": with that setting
`/wp-json/` does not exist and WordPress answers with the home page. The client reports it with an
`invalid_json` error that explains it.

## Known limits

- No OAuth 1.0a: HTTPS stores only.
- Not mapped: the brands endpoint (`products/brands`; a product's brands are, in `Brands`),
  the refund preview (`refunds/preview`) and `compute_totals` (WooCommerce 11.1+), the fields missing
  from the v3 documentation (for example `parent_name` of order line items). The raw layer reaches them.
- `List` keeps everything in memory. If a proxy stripped the `X-WP-TotalPages` header, a paginated
  list would stop at the first 100 items.
- Synchronous calls: no asynchronous API.

## Credits

Developed by **KD Software Srls** - developer Giordano Giaccaglia.
Website: <https://www.kdsoftware.it> - e-mail: <info@kdsoftware.it>
