# Woo4Delphi

[English](README.md) | [Italiano](README.it.md) | [Español](README.es.md) | [Français](README.fr.md) | **Deutsch**

Von [KD Software Srls](https://www.kdsoftware.it) - Entwickler Giordano Giaccaglia - <info@kdsoftware.it>

Client für die **WooCommerce REST API v3** für Delphi 13 Florence: zwei Units, die man dem Projekt
hinzufügt, nur RTL (`System.Net.HttpClient`, `System.JSON`), kein Package zu installieren.

- Alle Ressourcen der v3 (Produkte, Varianten, Bestellungen, Kunden, Gutscheine, Steuern, Versand,
  Einstellungen, Zahlungen, Webhooks, Berichte, Systemstatus, Daten) als **typisierte Delphi-Records**.
- Eine einzige Arbeitsweise für jede Ressource: `List`, `Get`, `Add`, `Update`, `Delete`, `Batch`.
- Änderungen senden **nur die Felder, die Sie angeben**: ein Feld, das Sie nicht nennen, wird nie
  überschrieben.
- Eine rohe JSON-Schicht für alles andere.

| Datei | Inhalt |
|-------|--------|
| `Woo4Delphi.Types.pas` | Die Records aller Ressourcen, Feld für Feld nach der v3-Dokumentation |
| `Woo4Delphi.Client.pas` | `TWooClient`, `TWooEndpoint<T>`, `EWooError` |
| `Woo4Delphi.SelfCheck.dpr` | Prüfung auf der Kommandozeile (offline und live gegen einen Shop) |
| `Samples\VCL\Woo4DelphiDemo.dpr` | VCL-Anwendung mit einer Seite pro Bereich, um alle Funktionen auszuprobieren |

## Voraussetzungen

- Delphi 13 Florence (verwendet den `if … then … else`-Ausdruck und Managed Records), Win32 oder Win64.
- WooCommerce mit REST API v3 (WooCommerce 3.5 oder neuer), erreichbar über **HTTPS**.
- Ein REST-Schlüsselpaar: in WordPress unter *WooCommerce → Einstellungen → Erweitert → REST-API →
  Schlüssel hinzufügen*. Berechtigung *Lesen* zum Lesen, *Lesen/Schreiben* zum Ändern.

## Schnellstart

Fügen Sie `Woo4Delphi.Types.pas` und `Woo4Delphi.Client.pas` dem Projekt hinzu (oder ihren Ordner dem Suchpfad).

```delphi
uses
  System.Net.URLClient,   // TNameValuePair, für die Filter
  Woo4Delphi.Types,
  Woo4Delphi.Client;

var lWoo := TWooClient.Create('https://shop.example.com', 'ck_...', 'cs_...');
try
  // ein Record: nichts freizugeben
  var lProduct := lWoo.Products.Get(7);
  lProduct.RegularPrice := '12.50';
  lProduct.StockQuantity := 0;
  lWoo.Products.Update(lProduct, ['regular_price', 'stock_quantity']);   // nur diese zwei Felder

  // alle Seiten, gefiltert
  for var lOrder in lWoo.Orders.List([TNameValuePair.Create('status', 'processing')]) do
    Writeln(lOrder.Number, '  ', lOrder.Billing.City, '  ', lOrder.Total, ' ', lOrder.Currency);

  lWoo.UpdateOrderStatus(1234, 'completed');
finally
  lWoo.Free;
end;
```

## Konzepte

### Die Records

Jede Ressource ist ein Record (`TWooProduct`, `TWooOrder`, `TWooCustomer`…). Strings und Arrays
verwaltet der Compiler: kein `Free`, keine Speicherlecks.

- **Namen**: ein Delphi-Feld entspricht dem JSON-Schlüssel in snake_case (`RegularPrice` ↔ `regular_price`,
  `DateCreatedGmt` ↔ `date_created_gmt`). Wo die Regel nicht passt oder der Schlüssel ein reserviertes
  Wort ist, gibt es ein `[JsonName]`: `ProductType` ↔ `type`, `IsVirtual` ↔ `virtual`, `RateClass` ↔ `class`,
  `Caption` ↔ `label`, `DefaultValue` ↔ `default`, `Address1` ↔ `address_1`.
- **Unbekannte Schlüssel**: werden beim Lesen ignoriert und beim Schreiben nie gesendet. Ein `null`
  wird zu 0, `''`, `False` oder einem leeren Record.
- **Automatische Initialisierung**: die Records, die man anlegen kann, setzen sich selbst auf null und
  übernehmen die WooCommerce-Standardwerte, wo diese nicht null sind. `var lCoupon: TWooCoupon;` genügt,
  `Default()` ist nicht nötig:

  | Record | Standardwerte ungleich null |
  |--------|-----------------------------|
  | `TWooProduct` | `ReviewsAllowed = True`, `DownloadLimit = -1`, `DownloadExpiry = -1` |
  | `TWooVariation` | `DownloadLimit = -1`, `DownloadExpiry = -1` |
  | `TWooTaxRate` | `Priority = 1`, `Shipping = True` |
  | `TWooShippingZoneMethod` | `Enabled = True` |
  | `TWooRefund` | `ApiRestock = True`; `ApiRefund = False` (siehe *Rückerstattungen*) |

- **Preise und Summen** sind Strings, so wie WooCommerce sie sendet (`'9.90'`). Zum Rechnen:
  `StrToFloat(lProduct.RegularPrice, TFormatSettings.Invariant)`.
- **Datumswerte** sind die ISO-Strings von WooCommerce. `DateCreated` ist in der Zeit des Shops, ohne
  Zeitzone; `DateCreatedGmt` ist UTC: `ISO8601ToDate(lOrder.DateCreatedGmt, True)`.
- **„JSON text“-Felder**: manche Werte haben einen variablen Typ oder dynamische Schlüssel und kommen
  als JSON-Text in einem String an: der `Value` der `MetaData`, wenn er kein String ist, der `Value` von
  Multiselect-Einstellungen (`'["IT","FR"]'`), die `Settings` von Zahlungs-Gateways und Versandarten,
  die `Options` der Einstellungen, die `Totals` des Verkaufsberichts, der `Price` der Bestellpositionen
  (eine Zahl in JSON). Um ein Objekt oder ein Array zu senden, weisen Sie seinen JSON-Text zu:
  `lGateway.Settings := '{"title":"Überweisung"}'`.
- **Varianten**: wenn das übergeordnete Produkt den Bestand verwaltet, sendet WooCommerce
  `"manage_stock": "parent"`; der Record liest das als `ManageStock = False`.

### Die Endpoints: `TWooEndpoint<T>`

`lWoo.Products`, `lWoo.Variations(ProduktID)`, `lWoo.Settings('general')`… liefern einen
`TWooEndpoint<T>`, immer mit denselben Methoden:

| Methode | HTTP | Was sie tut |
|---------|------|-------------|
| `List(AParams)` | GET | **Alle Seiten**, 100 Elemente pro Anfrage; eine einzige Anfrage bei nicht paginierten Endpoints |
| `Get(ID)` | GET | Ein Element; `ID` numerisch oder als String (`'woocommerce_currency'`, `'bacs'`, `'IT'`) |
| `Add(Item)` | POST | Legt an. Sendet weder schreibgeschützte Felder (`id`, `price`, `permalink`, `date_created`…) noch leere Strings und Arrays: WooCommerce wendet seine Standardwerte an |
| `Update(Item, Felder)` | PUT | Sendet **nur** die angegebenen JSON-Schlüssel; die ID kommt aus `Item`. Ein Schlüssel, der kein Feld des Records ist, löst `EArgumentException` aus |
| `Delete(ID, AForce)` | DELETE | Produkte, Bestellungen, Gutscheine: ohne `AForce` landen sie im Papierkorb. Alle anderen Ressourcen haben keinen Papierkorb: Löschen ist immer endgültig |
| `Batch(Anlegen, Ändern, Felder, Löschen)` | POST …/batch | Bis zu 100 Elemente insgesamt pro Aufruf. `Errors` listet die abgelehnten Elemente |

`Update` braucht die Liste der Felder, weil ein Record „nicht gesetzt“ nicht von „leer“ unterscheiden
kann: ihn vollständig zu senden, würde die Felder leeren, die Sie weder gelesen noch gesetzt haben.
Der natürliche Weg ist lesen, ändern und die geänderten Felder speichern:

```delphi
var lCustomer := lWoo.Customers.Get(42);
lCustomer.Billing.Phone := '+49 30 1234567';
lWoo.Customers.Update(lCustomer, ['billing']);   // das ganze billing-Objekt, wie gelesen und geändert
```

### Filter und Paginierung

Die Filter sind die Parameter der WooCommerce-Dokumentation, als Name/Wert-Paare:

```delphi
var lOrders := lWoo.Orders.List([
  TNameValuePair.Create('status', 'processing'),
  TNameValuePair.Create('modified_after', '2026-11-01T00:00:00')]);
```

`List` setzt `per_page` und `page` selbst und lädt alles in den Speicher. Bei sehr großen Katalogen
verwenden Sie die rohe Schicht Seite für Seite (`lWoo.Get('products', [per_page, page])`): nach jedem
Aufruf geben `LastTotal` und `LastTotalPages` die Header `X-WP-Total` und `X-WP-TotalPages` wieder.

### Fehler

- `EWooError`: jede Antwort außer 2xx. `StatusCode` ist der HTTP-Status, `Code` der WooCommerce-Code
  (`woocommerce_rest_product_invalid_id`, `rest_invalid_param`, `rest_no_route`…), `Message` der Text.
  Antwortet ein Proxy mit einer HTML-Seite, ist `Code` gleich `http_<Status>`.
- `EArgumentException`: eine URL ohne HTTPS, ein unbekanntes Feld in `Update`, ein Record ohne ID in `Update`.
- Netzwerkfehler von `THTTPClient` (`ENetHTTPClientException`) werden unverändert weitergegeben.

### Rohe Schicht

Für das, was die Records nicht abdecken: `Get`, `Post`, `Put`, `Delete`, `GetAll` arbeiten mit `TJSONValue`,
mit Endpoints relativ zu `/wp-json/wc/v3/`. **Den zurückgegebenen Wert geben Sie selbst frei.**

```delphi
var lAnswer := lWoo.Get('orders/123', [TNameValuePair.Create('dp', '4')]);
try
  Writeln(lAnswer.Format(2));
finally
  lAnswer.Free;
end;
```

`lWoo.ToJSON<T>(Record)` und `lWoo.ParseJSON<T>(Text)` wandeln einen Record in WooCommerce-JSON um und
zurück, mit denselben Namensregeln: nützlich für Logs, gespeicherte Kopien und rohe Aufrufe.

### Authentifizierung und Verbindung

- Nur HTTPS: WooCommerce akzeptiert die Schlüssel per Basic Auth nur über HTTPS (über HTTP braucht es
  OAuth 1.0a, nicht implementiert), und über HTTP würde der geheime Schlüssel im Klartext übertragen.
- `QueryStringAuth := True`: für Hoster (PHP als CGI/FastCGI), die den `Authorization`-Header entfernen
  und auf gültige Schlüssel mit 401 antworten. Die Schlüssel stehen dann auch im Query-String und damit
  **in den Server-Logs**.
- `lWoo.HTTP` ist der zugrunde liegende `THTTPClient`: Timeouts (`ConnectionTimeout`, `ResponseTimeout`),
  Proxy und, nur für Entwicklungs-Shops mit selbstsigniertem Zertifikat, `ValidateServerCertificateCallback`.
- Ein `TWooClient` pro Thread: `LastTotal`/`LastTotalPages` beschreiben den letzten Aufruf dieser Instanz.

## Referenz der Endpoints

| Bereich | Methode des Clients | Record | Operationen | Hinweise |
|---------|---------------------|--------|-------------|----------|
| Produkte | `Products` | `TWooProduct` | alle + Batch | Papierkorb |
| | `DuplicateProduct(ID)` | `TWooProduct` | POST …/duplicate | die Kopie entsteht als Entwurf |
| Mediathek | `UploadImage(File, Alt)` | `TWooImage` | POST /wp/v2/media | WordPress, nicht WooCommerce: siehe *Produktbilder* |
| Varianten | `Variations(ProduktID)` | `TWooVariation` | alle + Batch | |
| Globale Eigenschaften | `Attributes` | `TWooProductAttribute` | alle + Batch | nicht paginiert |
| Eigenschaftswerte | `AttributeTerms(EigenschaftID)` | `TWooAttributeTerm` | alle + Batch | |
| Kategorien | `Categories` | `TWooProductCategory` | alle + Batch | |
| Schlagwörter | `Tags` | `TWooProductTag` | alle + Batch | |
| Versandklassen | `ShippingClasses` | `TWooShippingClass` | alle + Batch | |
| Bewertungen | `Reviews` | `TWooProductReview` | alle + Batch | |
| Benutzerdefinierte Felder | `ProductCustomFieldNames` | `TArray<string>` | Liste | neuere WooCommerce-Versionen |
| Bestellungen | `Orders` | `TWooOrder` | alle + Batch | Papierkorb; `SetPaid` beim Anlegen |
| | `UpdateOrderStatus(ID, Status)` | `TWooOrder` | PUT | E-Mails und Bestand wie im Backend |
| Bestellnotizen | `OrderNotes(BestellID)` | `TWooOrderNote` | List, Get, Add, Delete | `CustomerNote = True` benachrichtigt den Kunden |
| Rückerstattungen einer Bestellung | `Refunds(BestellID)` | `TWooRefund` | List, Get, Add, Delete | siehe *Rückerstattungen* |
| Alle Rückerstattungen | `AllRefunds` | `TWooRefund` | List | `ParentId` = Bestellung |
| Bestell-E-Mails | `OrderEmailTemplates(ID)`, `SendOrderEmail(ID, Vorlage, Email, Erzwingen)` | `TWooEmailTemplate` | GET, POST | leere Vorlage = Bestelldetails (Rechnung) |
| Kunden | `Customers` | `TWooCustomer` | alle + Batch | nur Rolle *customer* (Filter `role=all` für alle) |
| | `CustomerDownloads(ID)` | `TWooDownload` | GET | |
| Gutscheine | `Coupons` | `TWooCoupon` | alle + Batch | Papierkorb |
| Steuersätze | `TaxRates` | `TWooTaxRate` | alle + Batch | |
| Steuerklassen | `TaxClasses` | `TWooTaxClass` | List, Add, Delete(slug) | Löschen entfernt auch ihre Steuersätze |
| Webhooks | `Webhooks` | `TWooWebhook` | alle + Batch | `Secret` signiert die Payloads |
| Einstellungsgruppen | `SettingGroups` | `TWooSettingGroup` | List | Index: die Optionen stehen in `Settings(Gruppe)` |
| Einstellungen | `Settings(GruppenID)` | `TWooSetting` | List, Get, Update, Batch | `Value` als JSON-Text bei Multiselect |
| Zahlungs-Gateways | `PaymentGateways` | `TWooPaymentGateway` | List, Get, Update | |
| Versandzonen | `ShippingZones` | `TWooShippingZone` | List, Get, Add, Update, Delete | Zone 0 lässt sich nicht löschen |
| Regionen einer Zone | `ShippingZoneLocations(ID)`, `UpdateShippingZoneLocations(ID, Regionen)` | `TWooZoneLocation` | GET, PUT | der PUT ersetzt alle Regionen |
| Versandarten einer Zone | `ShippingZoneMethods(ZonenID)` | `TWooShippingZoneMethod` | List, Get, Add, Update, Delete | ID = `InstanceId`; `MethodId` beim Anlegen Pflicht |
| Versandarten | `ShippingMethods` | `TWooShippingMethod` | List, Get | |
| Berichte | `Reports` | `TWooIndexEntry` | List | Index der Berichte |
| | `SalesReport(Filter)` | `TWooSalesReport` | GET | `period` oder `date_min`/`date_max` |
| | `TopSellersReport(Filter)` | `TWooTopSeller` | GET | |
| | `ReportTotals('orders')` | `TWooReportTotal` | GET | coupons, customers, orders, products, reviews |
| Systemstatus | `SystemStatus` | `TWooSystemStatus` | GET | Umgebung, Datenbank, Plugins, Theme, Einstellungen, Sicherheit, Seiten |
| Systemwerkzeuge | `SystemTools`, `RunSystemTool(ID)` | `TWooSystemTool` | List, Get, PUT | manche Werkzeuge sind destruktiv |
| Daten | `Data` | `TWooIndexEntry` | List | Index |
| | `Continents`, `Countries` | `TWooContinent`, `TWooCountry` | List, Get(Code) | |
| | `Currencies` | `TWooCurrency` | List, Get(Code) | `Get('current')` = Währung des Shops |

*Alle* = `List`, `Get`, `Add`, `Update`, `Delete`. Bei Endpoints, die WooCommerce nicht vorsieht
(zum Beispiel `Add` auf `Countries`), antwortet der Server mit einem `EWooError` mit dem Code `rest_no_route`.

## Rezepte

**Produktbilder: Hauptbild und Galerie**

In `TWooProduct.Images` ist das erste Bild das Hauptbild, die anderen bilden die Galerie. WooCommerce
akzeptiert nur Bilder, die schon in der Mediathek liegen (per `Id`), oder eine URL zum Herunterladen
(`Id` 0 und `Src`). Es hat keinen Endpoint zum Hochladen von Dateien: eine Datei von der Festplatte
muss zuerst mit `UploadImage` in die WordPress-Mediathek hochgeladen werden. Dieser Endpoint
(`/wp/v2/media`) **akzeptiert keine WooCommerce-Schlüssel**: er braucht einen WordPress-Benutzer, der
Dateien hochladen darf, und eines seiner *Anwendungspasswörter* (Benutzer → Profil →
Anwendungspasswörter), nicht das Anmeldepasswort.

```delphi
lWoo.WordPressUser := 'editor';
lWoo.WordPressAppPassword := 'abcd efgh ijkl mnop qrst uvwx';
var lMain := lWoo.UploadImage('C:\Fotos\tasse.jpg', 'Rote Tasse');    // Id und Src in der Mediathek
var lFromWeb: TWooImage;
lFromWeb.Src := 'https://example.com/fotos/tasse-hinten.jpg';         // WooCommerce lädt es herunter
var lProduct := lWoo.Products.Get(7);
lProduct.Images := [lMain, lFromWeb];                                 // Hauptbild, dann Galerie
lWoo.Products.Update(lProduct, ['images']);
```

- `Images` ersetzt alle Bilder: um eines zur Galerie hinzuzufügen, gehen Sie von den Bildern des
  Produkts aus. `Images := nil` entfernt alle. Ein entferntes Bild bleibt in der Mediathek.
- Wenn Sie gelesene Bilder zurücksenden, senden Sie nur `Id`: der `Name`, den WooCommerce liefert, hat
  bereits die WordPress-Typografie (typografische Anführungszeichen), und ein nicht leerer `Name`
  benennt die Datei in der Mediathek um.
- Bei einer URL muss der Server des Shops die Adresse erreichen können: in einem Entwicklungs-Shop
  funktioniert `https://localhost` meist nicht (WooCommerce antwortet `woocommerce_product_image_upload_error`).
- Der Dateiname auf der Festplatte verliert seine Nicht-ASCII-Buchstaben (`müsli.jpg` → `m_sli.jpg`);
  der Titel des Bildes in der Mediathek behält sie.

**Den Bestand vieler Produkte mit einem Aufruf ändern**

```delphi
var lUpdates: TArray<TWooProduct>;
SetLength(lUpdates, 2);
lUpdates[0].Id := 7;   lUpdates[0].ManageStock := True; lUpdates[0].StockQuantity := 12;
lUpdates[1].Id := 8;   lUpdates[1].ManageStock := True; lUpdates[1].StockQuantity := 0;
var lResult := lWoo.Products.Batch(nil, lUpdates, ['manage_stock', 'stock_quantity'], []);
for var lError in lResult.Errors do
  Writeln(lError);   // z. B. 'update[1] woocommerce_rest_product_invalid_id: Invalid ID.'
```

**Ein variables Produkt mit einer Variante anlegen**

```delphi
var lProduct: TWooProduct;
lProduct.Name := 'Tasse';
lProduct.ProductType := 'variable';
SetLength(lProduct.Attributes, 1);
lProduct.Attributes[0].Name := 'Farbe';
lProduct.Attributes[0].Variation := True;
lProduct.Attributes[0].Visible := True;
lProduct.Attributes[0].Options := ['Rot', 'Blau'];
lProduct := lWoo.Products.Add(lProduct);

var lVariation: TWooVariation;
lVariation.RegularPrice := '9.90';
SetLength(lVariation.Attributes, 1);
lVariation.Attributes[0].Name := 'Farbe';
lVariation.Attributes[0].Option := 'Rot';
lWoo.Variations(lProduct.Id).Add(lVariation);
```

**Eine bezahlte Bestellung anlegen**

```delphi
var lOrder: TWooOrder;
lOrder.PaymentMethod := 'bacs';
lOrder.SetPaid := True;                    // processing, Bestand reduziert
lOrder.Billing.Email := 'kunde@example.de';
SetLength(lOrder.LineItems, 1);
lOrder.LineItems[0].ProductId := 7;
lOrder.LineItems[0].Quantity := 2;
lOrder := lWoo.Orders.Add(lOrder);
```

**Rückerstattungen.** `TWooRefund.ApiRefund` steht anfangs auf `False` (in WooCommerce ist der
Standardwert `True`): die Rückerstattung wird erfasst, ohne Geld zu bewegen. Setzen Sie es auf `True`,
um das Geld über das Zahlungs-Gateway zurückzuzahlen.

```delphi
var lRefund: TWooRefund;
lRefund.Amount := '10.00';
lRefund.Reason := 'Rücksendung';
lRefund.ApiRefund := True;    // echte Rückerstattung über das Gateway
lWoo.Refunds(1234).Add(lRefund);
```

**Eine Shop-Einstellung ändern**

```delphi
var lSetting := lWoo.Settings('general').Get('woocommerce_specific_allowed_countries');
lSetting.Value := '["IT","FR","DE"]';     // Multiselect: JSON-Text
lWoo.Settings('general').Update(lSetting, ['value']);
```

## Das VCL-Sample

`Samples\VCL\Woo4DelphiDemo.dpr`: in RAD Studio öffnen, kompilieren und ausführen. Die Oberfläche ist
italienisch. Oben stehen URL und Schlüssel; die zweite Zeile wird nur zum Hochladen von Bildern
gebraucht (WordPress-Benutzer und Anwendungspasswort). Unten steht das Protokoll jedes Aufrufs mit
seiner Dauer.

Die Einstellungen werden beim Start aus `Woo4DelphiDemo.ini` neben der ausführbaren Datei gelesen und
beim Schließen dort gespeichert. Sie können die Datei auch von Hand schreiben:

```ini
[Store]
URL=https://shop.example.com
ConsumerKey=ck_...
ConsumerSecret=cs_...
QueryStringAuth=0
; 1 nur für Entwicklungs-Shops mit selbstsigniertem Zertifikat
AcceptAnyCertificate=0

[WordPress]
User=editor
AppPassword=abcd efgh ijkl mnop qrst uvwx
```

> Die Datei enthält Schlüssel und Passwörter **im Klartext**: nehmen Sie sie nicht in die
> Versionskontrolle auf und liefern Sie sie nicht mit der ausführbaren Datei aus.

| Seite | Was sie ausprobiert |
|-------|---------------------|
| **Prodotti** (Produkte) | Liste und Suche, typisierte Bearbeitung der wichtigsten Felder (auch EAN, Lagerstatus, Kategorien), Bilder (Datei hochladen, von URL, Hauptbild wählen, entfernen), anlegen, duplizieren, Papierkorb, endgültig löschen; Varianten: Liste, Preis und Bestand, hinzufügen, löschen |
| **Categorie** (Kategorien) | Liste, anlegen, umbenennen, Slug, unter eine andere Kategorie verschieben, Beschreibung, löschen |
| **Ordini** (Bestellungen) | Liste nach Status, Detail, Statuswechsel, Notizen (auch für den Kunden sichtbare), Rückerstattungen, E-Mail-Versand, Testbestellung |
| **Risorse** (Ressourcen) | alle typisierten Endpoints: Liste mit Filtern, lesen, aus JSON anlegen und ändern (über den Record), löschen, Batch über mehrere Zeilen |
| **Report e sistema** (Berichte und System) | Verkaufsbericht, Bestseller, Summen, Systemstatus, Werkzeuge, Währung, benutzerdefinierte Felder, Regionen einer Zone, Downloads eines Kunden |
| **JSON grezzo** (rohes JSON) | jede Methode auf jedem Endpoint |

> **Achtung**: das Sample arbeitet auf dem Shop, mit dem es verbunden ist. Es legt echte Daten an,
> ändert und löscht sie, ändert Bestellstatus (mit den WooCommerce-E-Mails an die Kunden), erfasst
> Rückerstattungen und führt Systemwerkzeuge aus. Jede destruktive Operation fragt nach einer
> Bestätigung, aber verwenden Sie es mit einem **Test-Shop**.

Die Aufrufe laufen im Hauptthread, damit der Code lesbar bleibt: in einer echten Anwendung verlagern
Sie sie in einen Thread (`TTask.Run`), mit einem `TWooClient` pro Thread.

## Prüfung

```
dcc32 Woo4Delphi.SelfCheck.dpr  (oder dcc64)
Woo4Delphi.SelfCheck.exe                                   Offline-Prüfungen
Woo4Delphi.SelfCheck.exe Samples\VCL\Woo4DelphiDemo.ini    auch gegen den Shop
```

Ohne Parameter führt es die Offline-Prüfungen aus: URL und Kodierung der Parameter,
Authentifizierungs-Header, JSON-Namen und Standardwerte der Records, Konverter, Auswertung der
Fehler. Mit einer ini-Datei (der Abschnitt `[Store]`, derselbe wie im VCL-Sample) liest es außerdem,
**nur lesend**, ein Element jeder Ressource des Shops: sendet WooCommerce ein Feld mit einem
unerwarteten Typ, meldet es das. Ein Endpoint, der in der WooCommerce-Version des Shops fehlt, wird
gemeldet, ohne die Prüfung scheitern zu lassen. `AcceptAnyCertificate=1` ist für einen Test-Shop mit
selbstsigniertem Zertifikat gedacht.

Die WordPress-Permalinks (Einstellungen → Permalinks) dürfen nicht auf „Einfach“ stehen: mit dieser
Einstellung gibt es `/wp-json/` nicht, und WordPress antwortet mit der Startseite. Der Client meldet
das mit einem `invalid_json`-Fehler, der es erklärt.

## Bekannte Einschränkungen

- Kein OAuth 1.0a: nur Shops mit HTTPS.
- Nicht abgebildet: der Marken-Endpoint (`products/brands`; die Marken eines Produkts schon, in
  `Brands`), die Vorschau der Rückerstattungen (`refunds/preview`) und `compute_totals`
  (WooCommerce 11.1+), Felder, die in der v3-Dokumentation fehlen (zum Beispiel `parent_name` der
  Bestellpositionen). Sie sind über die rohe Schicht erreichbar.
- `List` hält alles im Speicher. Entfernt ein Proxy den Header `X-WP-TotalPages`, endet eine
  paginierte Liste nach den ersten 100 Elementen.
- Synchrone Aufrufe: keine asynchrone API.

## Credits

Entwickelt von **KD Software Srls** - Entwickler Giordano Giaccaglia.
Website: <https://www.kdsoftware.it> - E-Mail: <info@kdsoftware.it>
