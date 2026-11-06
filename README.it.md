# Woo4Delphi

[English](README.md) | **Italiano** | [Español](README.es.md) | [Français](README.fr.md) | [Deutsch](README.de.md)

Di [KD Software Srls](https://www.kdsoftware.it) - sviluppatore Giordano Giaccaglia - <info@kdsoftware.it>

Client per la **WooCommerce REST API v3** in Delphi 13 Florence: due unit da aggiungere al progetto,
solo RTL (`System.Net.HttpClient`, `System.JSON`), nessun pacchetto da installare.

- Tutte le risorse della v3 (prodotti, variazioni, ordini, clienti, coupon, tasse, spedizioni,
  impostazioni, pagamenti, webhook, report, stato del sistema, dati) come **record Delphi tipizzati**.
- Un solo modo di lavorare su ogni risorsa: `List`, `Get`, `Add`, `Update`, `Delete`, `Batch`.
- Le modifiche mandano **solo i campi che elenchi**: un campo che non nomini non viene mai sovrascritto.
- Un livello JSON grezzo per tutto il resto.

| File | Contenuto |
|------|-----------|
| `Woo4Delphi.Types.pas` | I record di tutte le risorse, campo per campo dalla documentazione v3 |
| `Woo4Delphi.Client.pas` | `TWooClient`, `TWooEndpoint<T>`, `EWooError` |
| `Woo4Delphi.SelfCheck.dpr` | Verifica a riga di comando (offline, e dal vivo su un negozio) |
| `Samples\VCL\Woo4DelphiDemo.dpr` | Applicazione VCL con una pagina per area, per provare tutte le funzioni |

## Requisiti

- Delphi 13 Florence (usa l'espressione `if … then … else` e i record gestiti), Win32 o Win64.
- WooCommerce con REST API v3 (WooCommerce 3.5 o successivo) raggiungibile in **HTTPS**.
- Una coppia di chiavi REST: in WordPress, *WooCommerce → Impostazioni → Avanzate → REST API →
  Aggiungi chiave*. Permessi *Lettura* per leggere, *Lettura/Scrittura* per modificare.

## Avvio rapido

Aggiungi `Woo4Delphi.Types.pas` e `Woo4Delphi.Client.pas` al progetto (o la cartella al search path).

```delphi
uses
  System.Net.URLClient,   // TNameValuePair, per i filtri
  Woo4Delphi.Types,
  Woo4Delphi.Client;

var lWoo := TWooClient.Create('https://negozio.example.com', 'ck_...', 'cs_...');
try
  // un record: niente da liberare
  var lProduct := lWoo.Products.Get(7);
  lProduct.RegularPrice := '12.50';
  lProduct.StockQuantity := 0;
  lWoo.Products.Update(lProduct, ['regular_price', 'stock_quantity']);   // solo questi due campi

  // tutte le pagine, filtrate
  for var lOrder in lWoo.Orders.List([TNameValuePair.Create('status', 'processing')]) do
    Writeln(lOrder.Number, '  ', lOrder.Billing.City, '  ', lOrder.Total, ' ', lOrder.Currency);

  lWoo.UpdateOrderStatus(1234, 'completed');
finally
  lWoo.Free;
end;
```

## Concetti

### I record

Ogni risorsa è un record (`TWooProduct`, `TWooOrder`, `TWooCustomer`…). Stringhe e array sono gestiti
dal compilatore: nessun `Free`, nessuna perdita di memoria.

- **Nomi**: un campo Delphi corrisponde alla chiave JSON in snake_case (`RegularPrice` ↔ `regular_price`,
  `DateCreatedGmt` ↔ `date_created_gmt`). Dove la regola non basta, o la chiave è una parola riservata,
  c'è un `[JsonName]`: `ProductType` ↔ `type`, `IsVirtual` ↔ `virtual`, `RateClass` ↔ `class`,
  `Caption` ↔ `label`, `DefaultValue` ↔ `default`, `Address1` ↔ `address_1`.
- **Chiavi sconosciute**: ignorate in lettura, mai inviate in scrittura. Un `null` diventa 0, `''`,
  `False` o un record vuoto.
- **Inizializzazione automatica**: i record che si possono creare si azzerano da soli e prendono i
  default di WooCommerce dove non sono zero. Basta `var lCoupon: TWooCoupon;`, non serve `Default()`:

  | Record | Default diversi da zero |
  |--------|-------------------------|
  | `TWooProduct` | `ReviewsAllowed = True`, `DownloadLimit = -1`, `DownloadExpiry = -1` |
  | `TWooVariation` | `DownloadLimit = -1`, `DownloadExpiry = -1` |
  | `TWooTaxRate` | `Priority = 1`, `Shipping = True` |
  | `TWooShippingZoneMethod` | `Enabled = True` |
  | `TWooRefund` | `ApiRestock = True`; `ApiRefund = False` (vedi *Rimborsi*) |

- **Prezzi e totali** sono stringhe, come li manda WooCommerce (`'9.90'`). Per calcolare:
  `StrToFloat(lProduct.RegularPrice, TFormatSettings.Invariant)`.
- **Date** sono le stringhe ISO di WooCommerce. `DateCreated` è nell'ora del negozio, senza fuso;
  `DateCreatedGmt` è UTC: `ISO8601ToDate(lOrder.DateCreatedGmt, True)`.
- **Campi "JSON text"**: alcuni valori hanno tipo variabile o chiavi dinamiche e arrivano come testo
  JSON in una stringa: il `Value` dei `MetaData` quando non è una stringa, il `Value` delle impostazioni
  multiselect (`'["IT","FR"]'`), i `Settings` di gateway e metodi di spedizione, `Options` delle
  impostazioni, `Totals` del report vendite, il `Price` delle righe d'ordine (un numero in JSON).
  Per mandare un oggetto o un array assegna il suo testo JSON: `lGateway.Settings := '{"title":"Bonifico"}'`.
- **Variazioni**: quando lo stock lo gestisce il prodotto padre WooCommerce manda
  `"manage_stock": "parent"`; il record lo legge come `ManageStock = False`.

### Gli endpoint: `TWooEndpoint<T>`

`lWoo.Products`, `lWoo.Variations(IDProdotto)`, `lWoo.Settings('general')`… restituiscono un
`TWooEndpoint<T>`, sempre con gli stessi metodi:

| Metodo | HTTP | Cosa fa |
|--------|------|---------|
| `List(AParams)` | GET | **Tutte le pagine**, 100 elementi per richiesta; una sola richiesta sugli endpoint non paginati |
| `Get(ID)` | GET | Un elemento; `ID` numerico o stringa (`'woocommerce_currency'`, `'bacs'`, `'IT'`) |
| `Add(Item)` | POST | Crea. Non manda i campi in sola lettura (`id`, `price`, `permalink`, `date_created`…) né stringhe e array vuoti: WooCommerce applica i suoi default |
| `Update(Item, Campi)` | PUT | Manda **solo** le chiavi JSON elencate; l'ID lo prende da `Item`. Una chiave che non è un campo del record solleva `EArgumentException` |
| `Delete(ID, AForce)` | DELETE | Prodotti, ordini, coupon: senza `AForce` vanno nel cestino. Tutte le altre risorse non hanno cestino: eliminazione sempre definitiva |
| `Batch(Crea, Aggiorna, Campi, Elimina)` | POST …/batch | Fino a 100 elementi in totale per chiamata. `Errors` elenca gli elementi rifiutati |

`Update` richiede l'elenco dei campi perché un record non distingue "non impostato" da "vuoto":
mandarlo intero azzererebbe i campi che non hai letto o impostato. Il modo naturale è leggere,
modificare, salvare i campi toccati:

```delphi
var lCustomer := lWoo.Customers.Get(42);
lCustomer.Billing.Phone := '+39 02 1234567';
lWoo.Customers.Update(lCustomer, ['billing']);   // l'oggetto billing intero, come letto e modificato
```

### Filtri e paginazione

I filtri sono i parametri della documentazione WooCommerce, come coppie nome/valore:

```delphi
var lOrders := lWoo.Orders.List([
  TNameValuePair.Create('status', 'processing'),
  TNameValuePair.Create('modified_after', '2026-11-01T00:00:00')]);
```

`List` imposta da sé `per_page` e `page` e scarica tutto in memoria. Su cataloghi molto grandi
usa il livello grezzo pagina per pagina (`lWoo.Get('products', [per_page, page])`): dopo ogni
chiamata `LastTotal` e `LastTotalPages` riportano gli header `X-WP-Total` e `X-WP-TotalPages`.

### Errori

- `EWooError`: ogni risposta non 2xx. `StatusCode` è lo stato HTTP, `Code` il codice WooCommerce
  (`woocommerce_rest_product_invalid_id`, `rest_invalid_param`, `rest_no_route`…), `Message` il testo.
  Se un proxy risponde con una pagina HTML, `Code` vale `http_<stato>`.
- `EArgumentException`: URL non HTTPS, campo sconosciuto in `Update`, record senza ID in `Update`.
- Gli errori di rete di `THTTPClient` (`ENetHTTPClientException`) passano invariati.

### Livello grezzo

Per ciò che i record non coprono: `Get`, `Post`, `Put`, `Delete`, `GetAll` lavorano su `TJSONValue`,
con endpoint relativi a `/wp-json/wc/v3/`. **Il valore restituito lo liberi tu.**

```delphi
var lAnswer := lWoo.Get('orders/123', [TNameValuePair.Create('dp', '4')]);
try
  Writeln(lAnswer.Format(2));
finally
  lAnswer.Free;
end;
```

`lWoo.ToJSON<T>(Record)` e `lWoo.ParseJSON<T>(Testo)` convertono un record nel JSON di WooCommerce e viceversa,
con le stesse regole sui nomi: utile per log, salvataggi, chiamate grezze.

### Autenticazione e connessione

- Solo HTTPS: WooCommerce accetta le chiavi in Basic auth solo su HTTPS (su HTTP serve OAuth 1.0a,
  non implementato), e su HTTP la chiave segreta viaggerebbe in chiaro.
- `QueryStringAuth := True`: per gli host (PHP in CGI/FastCGI) che tolgono l'header `Authorization`
  e rispondono 401 con chiavi valide. Le chiavi vanno anche nella query string, e quindi **nei log del server**.
- `lWoo.HTTP` è il `THTTPClient` sottostante: timeout (`ConnectionTimeout`, `ResponseTimeout`), proxy,
  e per i soli negozi di sviluppo con certificato autofirmato `ValidateServerCertificateCallback`.
- Un `TWooClient` per thread: `LastTotal`/`LastTotalPages` descrivono l'ultima chiamata di quell'istanza.

## Riferimento degli endpoint

| Area | Metodo del client | Record | Operazioni | Note |
|------|-------------------|--------|------------|------|
| Prodotti | `Products` | `TWooProduct` | tutte + Batch | cestino |
| | `DuplicateProduct(ID)` | `TWooProduct` | POST …/duplicate | la copia nasce in bozza |
| Libreria media | `UploadImage(File, Alt)` | `TWooImage` | POST /wp/v2/media | WordPress, non WooCommerce: vedi *Immagini del prodotto* |
| Variazioni | `Variations(IDProdotto)` | `TWooVariation` | tutte + Batch | |
| Attributi globali | `Attributes` | `TWooProductAttribute` | tutte + Batch | non paginato |
| Termini di attributo | `AttributeTerms(IDAttributo)` | `TWooAttributeTerm` | tutte + Batch | |
| Categorie | `Categories` | `TWooProductCategory` | tutte + Batch | |
| Tag | `Tags` | `TWooProductTag` | tutte + Batch | |
| Classi di spedizione | `ShippingClasses` | `TWooShippingClass` | tutte + Batch | |
| Recensioni | `Reviews` | `TWooProductReview` | tutte + Batch | |
| Campi personalizzati | `ProductCustomFieldNames` | `TArray<string>` | elenco | versioni recenti di WooCommerce |
| Ordini | `Orders` | `TWooOrder` | tutte + Batch | cestino; `SetPaid` in creazione |
| | `UpdateOrderStatus(ID, Stato)` | `TWooOrder` | PUT | e-mail e magazzino come dal pannello |
| Note d'ordine | `OrderNotes(IDOrdine)` | `TWooOrderNote` | List, Get, Add, Delete | `CustomerNote = True` avvisa il cliente |
| Rimborsi d'ordine | `Refunds(IDOrdine)` | `TWooRefund` | List, Get, Add, Delete | vedi *Rimborsi* |
| Tutti i rimborsi | `AllRefunds` | `TWooRefund` | List | `ParentId` = ordine |
| E-mail d'ordine | `OrderEmailTemplates(ID)`, `SendOrderEmail(ID, Modello, Email, Forza)` | `TWooEmailTemplate` | GET, POST | modello vuoto = dettagli ordine (fattura) |
| Clienti | `Customers` | `TWooCustomer` | tutte + Batch | solo ruolo *customer* (filtro `role=all` per tutti) |
| | `CustomerDownloads(ID)` | `TWooDownload` | GET | |
| Coupon | `Coupons` | `TWooCoupon` | tutte + Batch | cestino |
| Aliquote | `TaxRates` | `TWooTaxRate` | tutte + Batch | |
| Classi d'imposta | `TaxClasses` | `TWooTaxClass` | List, Add, Delete(slug) | eliminarla cancella anche le sue aliquote |
| Webhook | `Webhooks` | `TWooWebhook` | tutte + Batch | `Secret` firma i payload |
| Gruppi di impostazioni | `SettingGroups` | `TWooSettingGroup` | List | indice: le opzioni sono in `Settings(gruppo)` |
| Impostazioni | `Settings(IDGruppo)` | `TWooSetting` | List, Get, Update, Batch | `Value` in testo JSON per i multiselect |
| Gateway di pagamento | `PaymentGateways` | `TWooPaymentGateway` | List, Get, Update | |
| Zone di spedizione | `ShippingZones` | `TWooShippingZone` | List, Get, Add, Update, Delete | la zona 0 non si elimina |
| Località di una zona | `ShippingZoneLocations(ID)`, `UpdateShippingZoneLocations(ID, Località)` | `TWooZoneLocation` | GET, PUT | il PUT sostituisce tutte le località |
| Metodi di una zona | `ShippingZoneMethods(IDZona)` | `TWooShippingZoneMethod` | List, Get, Add, Update, Delete | ID = `InstanceId`; `MethodId` obbligatorio in creazione |
| Metodi di spedizione | `ShippingMethods` | `TWooShippingMethod` | List, Get | |
| Report | `Reports` | `TWooIndexEntry` | List | indice dei report |
| | `SalesReport(Filtri)` | `TWooSalesReport` | GET | `period` o `date_min`/`date_max` |
| | `TopSellersReport(Filtri)` | `TWooTopSeller` | GET | |
| | `ReportTotals('orders')` | `TWooReportTotal` | GET | coupons, customers, orders, products, reviews |
| Stato del sistema | `SystemStatus` | `TWooSystemStatus` | GET | ambiente, database, plugin, tema, impostazioni, sicurezza, pagine |
| Strumenti di sistema | `SystemTools`, `RunSystemTool(ID)` | `TWooSystemTool` | List, Get, PUT | alcuni strumenti sono distruttivi |
| Dati | `Data` | `TWooIndexEntry` | List | indice |
| | `Continents`, `Countries` | `TWooContinent`, `TWooCountry` | List, Get(codice) | |
| | `Currencies` | `TWooCurrency` | List, Get(codice) | `Get('current')` = valuta del negozio |

*Tutte* = `List`, `Get`, `Add`, `Update`, `Delete`. Sugli endpoint che WooCommerce non prevede
(per esempio `Add` su `Countries`) il server risponde `EWooError` con codice `rest_no_route`.

## Ricette

**Immagini del prodotto: principale e galleria**

In `TWooProduct.Images` la prima immagine è la principale, le altre sono la galleria. WooCommerce
accetta solo immagini che stanno già nella libreria media (per `Id`) oppure un URL da scaricare
(`Id` 0 e `Src`). Non ha un endpoint per caricare file: un file dal disco va caricato prima nella
libreria media di WordPress con `UploadImage`. Quell'endpoint (`/wp/v2/media`) **non accetta le chiavi
WooCommerce**: serve un utente WordPress che possa caricare file e una sua *password per le
applicazioni* (Utenti → Profilo → Password per le applicazioni), non la password di accesso.

```delphi
lWoo.WordPressUser := 'editor';
lWoo.WordPressAppPassword := 'abcd efgh ijkl mnop qrst uvwx';
var lMain := lWoo.UploadImage('C:\Foto\tazza.jpg', 'Tazza rossa');   // Id e Src nella libreria media
var lFromWeb: TWooImage;
lFromWeb.Src := 'https://example.com/foto/tazza-retro.jpg';            // la scarica WooCommerce
var lProduct := lWoo.Products.Get(7);
lProduct.Images := [lMain, lFromWeb];                                    // principale, poi galleria
lWoo.Products.Update(lProduct, ['images']);
```

- `Images` sostituisce tutte le immagini: per aggiungerne una alla galleria parti da quelle del prodotto.
  `Images := nil` le toglie tutte. Togliere un'immagine non la cancella dalla libreria media.
- Quando rimandi le immagini lette, manda solo `Id`: il `Name` che WooCommerce restituisce ha già la
  tipografia di WordPress (apostrofi curvi), e un `Name` non vuoto rinomina il file nella libreria.
- Per l'URL il server del negozio deve poter raggiungere l'indirizzo: su un negozio di sviluppo
  `https://localhost` di solito non va (WooCommerce risponde `woocommerce_product_image_upload_error`).
- Il nome del file su disco perde le lettere non ASCII (`caffè.jpg` → `caff_.jpg`); il titolo
  dell'immagine nella libreria le conserva.

**Aggiornare lo stock di molti prodotti in una chiamata**

```delphi
var lUpdates: TArray<TWooProduct>;
SetLength(lUpdates, 2);
lUpdates[0].Id := 7;   lUpdates[0].ManageStock := True; lUpdates[0].StockQuantity := 12;
lUpdates[1].Id := 8;   lUpdates[1].ManageStock := True; lUpdates[1].StockQuantity := 0;
var lResult := lWoo.Products.Batch(nil, lUpdates, ['manage_stock', 'stock_quantity'], []);
for var lError in lResult.Errors do
  Writeln(lError);   // es. 'update[1] woocommerce_rest_product_invalid_id: Invalid ID.'
```

**Creare un prodotto variabile con una variazione**

```delphi
var lProduct: TWooProduct;
lProduct.Name := 'Tazza';
lProduct.ProductType := 'variable';
SetLength(lProduct.Attributes, 1);
lProduct.Attributes[0].Name := 'Colore';
lProduct.Attributes[0].Variation := True;
lProduct.Attributes[0].Visible := True;
lProduct.Attributes[0].Options := ['Rosso', 'Blu'];
lProduct := lWoo.Products.Add(lProduct);

var lVariation: TWooVariation;
lVariation.RegularPrice := '9.90';
SetLength(lVariation.Attributes, 1);
lVariation.Attributes[0].Name := 'Colore';
lVariation.Attributes[0].Option := 'Rosso';
lWoo.Variations(lProduct.Id).Add(lVariation);
```

**Creare un ordine pagato**

```delphi
var lOrder: TWooOrder;
lOrder.PaymentMethod := 'bacs';
lOrder.SetPaid := True;                    // processing, magazzino scalato
lOrder.Billing.Email := 'cliente@example.it';
SetLength(lOrder.LineItems, 1);
lOrder.LineItems[0].ProductId := 7;
lOrder.LineItems[0].Quantity := 2;
lOrder := lWoo.Orders.Add(lOrder);
```

**Rimborsi.** `TWooRefund.ApiRefund` parte da `False` (in WooCommerce il default è `True`): il rimborso
viene registrato senza muovere denaro. Impostalo a `True` per restituire i soldi tramite il gateway.

```delphi
var lRefund: TWooRefund;
lRefund.Amount := '10.00';
lRefund.Reason := 'Reso';
lRefund.ApiRefund := True;    // rimborso reale tramite il gateway
lWoo.Refunds(1234).Add(lRefund);
```

**Cambiare un'impostazione del negozio**

```delphi
var lSetting := lWoo.Settings('general').Get('woocommerce_specific_allowed_countries');
lSetting.Value := '["IT","FR","DE"]';     // multiselect: testo JSON
lWoo.Settings('general').Update(lSetting, ['value']);
```

## Il sample VCL

`Samples\VCL\Woo4DelphiDemo.dpr`: aprilo in RAD Studio, poi compila ed esegui.
In alto URL e chiavi; la seconda riga serve solo per caricare immagini (utente WordPress e password per
le applicazioni). In basso c'è il log di ogni chiamata con il tempo impiegato.

Le impostazioni si leggono all'avvio da `Woo4DelphiDemo.ini`, accanto all'eseguibile, e vi si salvano
alla chiusura. Puoi anche scriverlo a mano:

```ini
[Store]
URL=https://negozio.example.com
ConsumerKey=ck_...
ConsumerSecret=cs_...
QueryStringAuth=0
; 1 solo per negozi di sviluppo con certificato autofirmato
AcceptAnyCertificate=0

[WordPress]
User=editor
AppPassword=abcd efgh ijkl mnop qrst uvwx
```

> Il file contiene chiavi e password **in chiaro**: non metterlo sotto controllo di versione e non
> distribuirlo con l'eseguibile.

| Pagina | Cosa prova |
|--------|------------|
| **Prodotti** | elenco e ricerca, modifica tipizzata dei campi principali (anche EAN, stato del magazzino, categorie), immagini (carica file, da URL, scegli la principale, togli), crea, duplica, cestino, eliminazione definitiva; variazioni: elenco, prezzo e stock, aggiungi, elimina |
| **Categorie** | elenco, crea, rinomina, slug, sposta sotto un'altra categoria, descrizione, elimina |
| **Ordini** | elenco per stato, dettaglio, cambio di stato, note (anche visibili al cliente), rimborsi, invio e-mail, ordine di prova |
| **Risorse** | tutti gli endpoint tipizzati: elenco con filtri, leggi, crea e aggiorna da JSON (passando dal record), elimina, batch su più righe |
| **Report e sistema** | report vendite, più venduti, totali, stato del sistema, strumenti, valuta, campi personalizzati, località di una zona, download di un cliente |
| **JSON grezzo** | qualsiasi metodo su qualsiasi endpoint |

> **Attenzione**: il sample lavora sul negozio a cui si collega. Crea, modifica ed elimina dati
> reali, cambia stati d'ordine (con le e-mail di WooCommerce ai clienti), registra rimborsi, esegue
> strumenti di sistema. Ogni operazione distruttiva chiede conferma, ma usalo su un **negozio di prova**.

Le chiamate girano nel thread principale per tenere il codice leggibile: in un'applicazione vera
spostale in un thread (`TTask.Run`) con un `TWooClient` per thread.

## Verifica

```
dcc32 Woo4Delphi.SelfCheck.dpr  (oppure dcc64)
Woo4Delphi.SelfCheck.exe                                   controlli offline
Woo4Delphi.SelfCheck.exe Samples\VCL\Woo4DelphiDemo.ini    anche sul negozio
```

Senza parametri esegue i controlli offline: URL e codifica dei parametri, header di autenticazione,
nomi JSON e default dei record, convertitori, lettura degli errori. Con un file ini (la sezione
`[Store]`, la stessa del sample VCL) legge anche, **in sola lettura**, un elemento di ogni risorsa del
negozio: se WooCommerce manda un campo con un tipo inatteso, lo segnala. Un endpoint che manca nella
versione di WooCommerce del negozio viene riportato, non fatto fallire. `AcceptAnyCertificate=1`
serve per un negozio di prova con certificato autofirmato.

I permalink di WordPress (Impostazioni → Permalink) non devono essere "Semplice": con quell'impostazione
`/wp-json/` non esiste e WordPress risponde con la home page. Il client lo segnala con un errore
`invalid_json` che lo spiega.

## Limiti noti

- Niente OAuth 1.0a: solo negozi in HTTPS.
- Non mappati: l'endpoint dei brand (`products/brands`; i brand di un prodotto sì, in `Brands`),
  l'anteprima dei rimborsi (`refunds/preview`) e `compute_totals` (WooCommerce 11.1+), i campi non
  presenti nella documentazione v3 (per esempio `parent_name` delle righe d'ordine). Si raggiungono
  con il livello grezzo.
- `List` tiene tutto in memoria. Se un proxy togliesse l'header `X-WP-TotalPages`, un elenco
  paginato si fermerebbe ai primi 100 elementi.
- Chiamate sincrone: nessuna API asincrona.

## Crediti

Sviluppato da **KD Software Srls** - sviluppatore Giordano Giaccaglia.
Sito: <https://www.kdsoftware.it> - e-mail: <info@kdsoftware.it>
