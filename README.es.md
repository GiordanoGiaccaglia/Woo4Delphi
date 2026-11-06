# Woo4Delphi

[English](README.md) | [Italiano](README.it.md) | **Español** | [Français](README.fr.md) | [Deutsch](README.de.md)

De [KD Software Srls](https://www.kdsoftware.it) - desarrollador Giordano Giaccaglia - <info@kdsoftware.it>

Cliente de la **WooCommerce REST API v3** para Delphi 13 Florence: dos units que se añaden al proyecto,
solo RTL (`System.Net.HttpClient`, `System.JSON`), ningún paquete que instalar.

- Todos los recursos de la v3 (productos, variaciones, pedidos, clientes, cupones, impuestos, envíos,
  ajustes, pagos, webhooks, informes, estado del sistema, datos) como **records Delphi tipados**.
- Una sola forma de trabajar con cada recurso: `List`, `Get`, `Add`, `Update`, `Delete`, `Batch`.
- Las modificaciones envían **solo los campos que indicas**: un campo que no nombras nunca se sobrescribe.
- Una capa JSON en bruto para todo lo demás.

| Archivo | Contenido |
|---------|-----------|
| `Woo4Delphi.Types.pas` | Los records de todos los recursos, campo por campo según la documentación v3 |
| `Woo4Delphi.Client.pas` | `TWooClient`, `TWooEndpoint<T>`, `EWooError` |
| `Woo4Delphi.SelfCheck.dpr` | Verificación por línea de comandos (offline, y en vivo contra una tienda) |
| `Samples\VCL\Woo4DelphiDemo.dpr` | Aplicación VCL con una página por área, para probar todas las funciones |

## Requisitos

- Delphi 13 Florence (usa la expresión `if … then … else` y los records gestionados), Win32 o Win64.
- WooCommerce con REST API v3 (WooCommerce 3.5 o posterior) accesible por **HTTPS**.
- Un par de claves REST: en WordPress, *WooCommerce → Ajustes → Avanzado → API REST → Añadir clave*.
  Permiso *Lectura* para leer, *Lectura/Escritura* para modificar.

## Inicio rápido

Añade `Woo4Delphi.Types.pas` y `Woo4Delphi.Client.pas` al proyecto (o su carpeta al search path).

```delphi
uses
  System.Net.URLClient,   // TNameValuePair, para los filtros
  Woo4Delphi.Types,
  Woo4Delphi.Client;

var lWoo := TWooClient.Create('https://tienda.example.com', 'ck_...', 'cs_...');
try
  // un record: nada que liberar
  var lProduct := lWoo.Products.Get(7);
  lProduct.RegularPrice := '12.50';
  lProduct.StockQuantity := 0;
  lWoo.Products.Update(lProduct, ['regular_price', 'stock_quantity']);   // solo estos dos campos

  // todas las páginas, filtradas
  for var lOrder in lWoo.Orders.List([TNameValuePair.Create('status', 'processing')]) do
    Writeln(lOrder.Number, '  ', lOrder.Billing.City, '  ', lOrder.Total, ' ', lOrder.Currency);

  lWoo.UpdateOrderStatus(1234, 'completed');
finally
  lWoo.Free;
end;
```

## Conceptos

### Los records

Cada recurso es un record (`TWooProduct`, `TWooOrder`, `TWooCustomer`…). El compilador gestiona las
cadenas y los arrays: ningún `Free`, ninguna fuga de memoria.

- **Nombres**: un campo Delphi corresponde a la clave JSON en snake_case (`RegularPrice` ↔ `regular_price`,
  `DateCreatedGmt` ↔ `date_created_gmt`). Donde la regla no basta, o la clave es una palabra reservada,
  hay un `[JsonName]`: `ProductType` ↔ `type`, `IsVirtual` ↔ `virtual`, `RateClass` ↔ `class`,
  `Caption` ↔ `label`, `DefaultValue` ↔ `default`, `Address1` ↔ `address_1`.
- **Claves desconocidas**: se ignoran al leer y nunca se envían al escribir. Un `null` se convierte en 0,
  `''`, `False` o un record vacío.
- **Inicialización automática**: los records que se pueden crear se ponen a cero solos y toman los
  valores por defecto de WooCommerce cuando no son cero. Basta con `var lCoupon: TWooCoupon;`, no hace
  falta `Default()`:

  | Record | Valores por defecto distintos de cero |
  |--------|---------------------------------------|
  | `TWooProduct` | `ReviewsAllowed = True`, `DownloadLimit = -1`, `DownloadExpiry = -1` |
  | `TWooVariation` | `DownloadLimit = -1`, `DownloadExpiry = -1` |
  | `TWooTaxRate` | `Priority = 1`, `Shipping = True` |
  | `TWooShippingZoneMethod` | `Enabled = True` |
  | `TWooRefund` | `ApiRestock = True`; `ApiRefund = False` (ver *Reembolsos*) |

- **Precios y totales** son cadenas, tal como los envía WooCommerce (`'9.90'`). Para calcular:
  `StrToFloat(lProduct.RegularPrice, TFormatSettings.Invariant)`.
- **Fechas**: son las cadenas ISO de WooCommerce. `DateCreated` está en la hora de la tienda, sin zona
  horaria; `DateCreatedGmt` es UTC: `ISO8601ToDate(lOrder.DateCreatedGmt, True)`.
- **Campos "JSON text"**: algunos valores tienen tipo variable o claves dinámicas y llegan como texto
  JSON dentro de una cadena: el `Value` de los `MetaData` cuando no es una cadena, el `Value` de los ajustes
  multiselect (`'["IT","FR"]'`), los `Settings` de pasarelas y métodos de envío, las `Options` de los
  ajustes, los `Totals` del informe de ventas, el `Price` de las líneas de pedido (un número en JSON).
  Para enviar un objeto o un array asigna su texto JSON: `lGateway.Settings := '{"title":"Transferencia"}'`.
- **Variaciones**: cuando el stock lo gestiona el producto padre, WooCommerce envía
  `"manage_stock": "parent"`; el record lo lee como `ManageStock = False`.

### Los endpoints: `TWooEndpoint<T>`

`lWoo.Products`, `lWoo.Variations(IDProducto)`, `lWoo.Settings('general')`… devuelven un
`TWooEndpoint<T>`, siempre con los mismos métodos:

| Método | HTTP | Qué hace |
|--------|------|----------|
| `List(AParams)` | GET | **Todas las páginas**, 100 elementos por petición; una sola petición en los endpoints no paginados |
| `Get(ID)` | GET | Un elemento; `ID` numérico o cadena (`'woocommerce_currency'`, `'bacs'`, `'IT'`) |
| `Add(Item)` | POST | Crea. No envía los campos de solo lectura (`id`, `price`, `permalink`, `date_created`…) ni cadenas y arrays vacíos: WooCommerce aplica sus valores por defecto |
| `Update(Item, Campos)` | PUT | Envía **solo** las claves JSON indicadas; el ID lo toma de `Item`. Una clave que no es un campo del record lanza `EArgumentException` |
| `Delete(ID, AForce)` | DELETE | Productos, pedidos, cupones: sin `AForce` van a la papelera. Los demás recursos no tienen papelera: la eliminación es siempre definitiva |
| `Batch(Crear, Actualizar, Campos, Eliminar)` | POST …/batch | Hasta 100 elementos en total por llamada. `Errors` lista los elementos rechazados |

`Update` pide la lista de campos porque un record no distingue "no asignado" de "vacío": enviarlo
entero pondría a cero los campos que no has leído ni asignado. Lo natural es leer, modificar y
guardar los campos que has tocado:

```delphi
var lCustomer := lWoo.Customers.Get(42);
lCustomer.Billing.Phone := '+34 91 123 4567';
lWoo.Customers.Update(lCustomer, ['billing']);   // el objeto billing entero, tal como se leyó y modificó
```

### Filtros y paginación

Los filtros son los parámetros de la documentación de WooCommerce, como pares nombre/valor:

```delphi
var lOrders := lWoo.Orders.List([
  TNameValuePair.Create('status', 'processing'),
  TNameValuePair.Create('modified_after', '2026-11-01T00:00:00')]);
```

`List` fija por sí mismo `per_page` y `page` y descarga todo en memoria. En catálogos muy grandes
usa la capa en bruto página a página (`lWoo.Get('products', [per_page, page])`): después de cada
llamada `LastTotal` y `LastTotalPages` indican las cabeceras `X-WP-Total` y `X-WP-TotalPages`.

### Errores

- `EWooError`: toda respuesta que no sea 2xx. `StatusCode` es el estado HTTP, `Code` el código de WooCommerce
  (`woocommerce_rest_product_invalid_id`, `rest_invalid_param`, `rest_no_route`…), `Message` el texto.
  Si un proxy responde con una página HTML, `Code` vale `http_<estado>`.
- `EArgumentException`: URL que no es HTTPS, campo desconocido en `Update`, record sin ID en `Update`.
- Los errores de red de `THTTPClient` (`ENetHTTPClientException`) pasan sin cambios.

### Capa en bruto

Para lo que los records no cubren: `Get`, `Post`, `Put`, `Delete`, `GetAll` trabajan con `TJSONValue`,
con endpoints relativos a `/wp-json/wc/v3/`. **El valor devuelto lo liberas tú.**

```delphi
var lAnswer := lWoo.Get('orders/123', [TNameValuePair.Create('dp', '4')]);
try
  Writeln(lAnswer.Format(2));
finally
  lAnswer.Free;
end;
```

`lWoo.ToJSON<T>(Record)` y `lWoo.ParseJSON<T>(Texto)` convierten un record en el JSON de WooCommerce y
viceversa, con las mismas reglas de nombres: útil para logs, copias guardadas, llamadas en bruto.

### Autenticación y conexión

- Solo HTTPS: WooCommerce acepta las claves en Basic auth solo sobre HTTPS (sobre HTTP necesita
  OAuth 1.0a, no implementado), y sobre HTTP la clave secreta viajaría en claro.
- `QueryStringAuth := True`: para los hosts (PHP como CGI/FastCGI) que eliminan la cabecera `Authorization`
  y responden 401 con claves válidas. Las claves van también en la query string, y por tanto **en los logs del servidor**.
- `lWoo.HTTP` es el `THTTPClient` subyacente: timeouts (`ConnectionTimeout`, `ResponseTimeout`), proxy
  y, solo para tiendas de desarrollo con certificado autofirmado, `ValidateServerCertificateCallback`.
- Un `TWooClient` por hilo: `LastTotal`/`LastTotalPages` describen la última llamada de esa instancia.

## Referencia de los endpoints

| Área | Método del cliente | Record | Operaciones | Notas |
|------|--------------------|--------|-------------|-------|
| Productos | `Products` | `TWooProduct` | todas + Batch | papelera |
| | `DuplicateProduct(ID)` | `TWooProduct` | POST …/duplicate | la copia nace como borrador |
| Biblioteca de medios | `UploadImage(File, Alt)` | `TWooImage` | POST /wp/v2/media | WordPress, no WooCommerce: ver *Imágenes del producto* |
| Variaciones | `Variations(IDProducto)` | `TWooVariation` | todas + Batch | |
| Atributos globales | `Attributes` | `TWooProductAttribute` | todas + Batch | no paginado |
| Términos de atributo | `AttributeTerms(IDAtributo)` | `TWooAttributeTerm` | todas + Batch | |
| Categorías | `Categories` | `TWooProductCategory` | todas + Batch | |
| Etiquetas | `Tags` | `TWooProductTag` | todas + Batch | |
| Clases de envío | `ShippingClasses` | `TWooShippingClass` | todas + Batch | |
| Valoraciones | `Reviews` | `TWooProductReview` | todas + Batch | |
| Campos personalizados | `ProductCustomFieldNames` | `TArray<string>` | lista | versiones recientes de WooCommerce |
| Pedidos | `Orders` | `TWooOrder` | todas + Batch | papelera; `SetPaid` al crear |
| | `UpdateOrderStatus(ID, Estado)` | `TWooOrder` | PUT | correos y stock como desde el panel |
| Notas de pedido | `OrderNotes(IDPedido)` | `TWooOrderNote` | List, Get, Add, Delete | `CustomerNote = True` avisa al cliente |
| Reembolsos de pedido | `Refunds(IDPedido)` | `TWooRefund` | List, Get, Add, Delete | ver *Reembolsos* |
| Todos los reembolsos | `AllRefunds` | `TWooRefund` | List | `ParentId` = pedido |
| Correos de pedido | `OrderEmailTemplates(ID)`, `SendOrderEmail(ID, Plantilla, Email, Forzar)` | `TWooEmailTemplate` | GET, POST | plantilla vacía = detalles del pedido (factura) |
| Clientes | `Customers` | `TWooCustomer` | todas + Batch | solo rol *customer* (filtro `role=all` para todos) |
| | `CustomerDownloads(ID)` | `TWooDownload` | GET | |
| Cupones | `Coupons` | `TWooCoupon` | todas + Batch | papelera |
| Tasas de impuesto | `TaxRates` | `TWooTaxRate` | todas + Batch | |
| Clases de impuesto | `TaxClasses` | `TWooTaxClass` | List, Add, Delete(slug) | eliminarla borra también sus tasas |
| Webhooks | `Webhooks` | `TWooWebhook` | todas + Batch | `Secret` firma los payloads |
| Grupos de ajustes | `SettingGroups` | `TWooSettingGroup` | List | índice: las opciones están en `Settings(grupo)` |
| Ajustes | `Settings(IDGrupo)` | `TWooSetting` | List, Get, Update, Batch | `Value` en texto JSON para los multiselect |
| Pasarelas de pago | `PaymentGateways` | `TWooPaymentGateway` | List, Get, Update | |
| Zonas de envío | `ShippingZones` | `TWooShippingZone` | List, Get, Add, Update, Delete | la zona 0 no se puede eliminar |
| Regiones de una zona | `ShippingZoneLocations(ID)`, `UpdateShippingZoneLocations(ID, Regiones)` | `TWooZoneLocation` | GET, PUT | el PUT sustituye todas las regiones |
| Métodos de una zona | `ShippingZoneMethods(IDZona)` | `TWooShippingZoneMethod` | List, Get, Add, Update, Delete | ID = `InstanceId`; `MethodId` obligatorio al crear |
| Métodos de envío | `ShippingMethods` | `TWooShippingMethod` | List, Get | |
| Informes | `Reports` | `TWooIndexEntry` | List | índice de los informes |
| | `SalesReport(Filtros)` | `TWooSalesReport` | GET | `period` o `date_min`/`date_max` |
| | `TopSellersReport(Filtros)` | `TWooTopSeller` | GET | |
| | `ReportTotals('orders')` | `TWooReportTotal` | GET | coupons, customers, orders, products, reviews |
| Estado del sistema | `SystemStatus` | `TWooSystemStatus` | GET | entorno, base de datos, plugins, tema, ajustes, seguridad, páginas |
| Herramientas del sistema | `SystemTools`, `RunSystemTool(ID)` | `TWooSystemTool` | List, Get, PUT | algunas herramientas son destructivas |
| Datos | `Data` | `TWooIndexEntry` | List | índice |
| | `Continents`, `Countries` | `TWooContinent`, `TWooCountry` | List, Get(código) | |
| | `Currencies` | `TWooCurrency` | List, Get(código) | `Get('current')` = moneda de la tienda |

*Todas* = `List`, `Get`, `Add`, `Update`, `Delete`. En los endpoints que WooCommerce no prevé
(por ejemplo `Add` en `Countries`) el servidor responde con un `EWooError` de código `rest_no_route`.

## Recetas

**Imágenes del producto: principal y galería**

En `TWooProduct.Images` la primera imagen es la principal, las demás son la galería. WooCommerce
solo acepta imágenes que ya están en la biblioteca de medios (por `Id`) o una URL que descargar
(`Id` 0 y `Src`). No tiene un endpoint para subir archivos: un archivo del disco se sube primero a la
biblioteca de medios de WordPress con `UploadImage`. Ese endpoint (`/wp/v2/media`) **no acepta las claves
de WooCommerce**: necesita un usuario de WordPress que pueda subir archivos y una *contraseña de
aplicación* suya (Usuarios → Perfil → Contraseñas de aplicación), no la contraseña de acceso.

```delphi
lWoo.WordPressUser := 'editor';
lWoo.WordPressAppPassword := 'abcd efgh ijkl mnop qrst uvwx';
var lMain := lWoo.UploadImage('C:\Fotos\taza.jpg', 'Taza roja');     // Id y Src en la biblioteca de medios
var lFromWeb: TWooImage;
lFromWeb.Src := 'https://example.com/fotos/taza-detras.jpg';          // la descarga WooCommerce
var lProduct := lWoo.Products.Get(7);
lProduct.Images := [lMain, lFromWeb];                                 // principal, luego galería
lWoo.Products.Update(lProduct, ['images']);
```

- `Images` sustituye todas las imágenes: para añadir una a la galería parte de las del producto.
  `Images := nil` las quita todas. Quitar una imagen no la borra de la biblioteca de medios.
- Cuando reenvíes las imágenes leídas, envía solo `Id`: el `Name` que devuelve WooCommerce ya tiene
  la tipografía de WordPress (comillas curvas), y un `Name` no vacío renombra el archivo en la biblioteca.
- Para una URL, el servidor de la tienda tiene que poder alcanzar la dirección: en una tienda de
  desarrollo `https://localhost` no suele funcionar (WooCommerce responde `woocommerce_product_image_upload_error`).
- El nombre del archivo en disco pierde las letras no ASCII (`café.jpg` → `caf_.jpg`); el título de
  la imagen en la biblioteca las conserva.

**Actualizar el stock de muchos productos en una llamada**

```delphi
var lUpdates: TArray<TWooProduct>;
SetLength(lUpdates, 2);
lUpdates[0].Id := 7;   lUpdates[0].ManageStock := True; lUpdates[0].StockQuantity := 12;
lUpdates[1].Id := 8;   lUpdates[1].ManageStock := True; lUpdates[1].StockQuantity := 0;
var lResult := lWoo.Products.Batch(nil, lUpdates, ['manage_stock', 'stock_quantity'], []);
for var lError in lResult.Errors do
  Writeln(lError);   // p. ej. 'update[1] woocommerce_rest_product_invalid_id: Invalid ID.'
```

**Crear un producto variable con una variación**

```delphi
var lProduct: TWooProduct;
lProduct.Name := 'Taza';
lProduct.ProductType := 'variable';
SetLength(lProduct.Attributes, 1);
lProduct.Attributes[0].Name := 'Color';
lProduct.Attributes[0].Variation := True;
lProduct.Attributes[0].Visible := True;
lProduct.Attributes[0].Options := ['Rojo', 'Azul'];
lProduct := lWoo.Products.Add(lProduct);

var lVariation: TWooVariation;
lVariation.RegularPrice := '9.90';
SetLength(lVariation.Attributes, 1);
lVariation.Attributes[0].Name := 'Color';
lVariation.Attributes[0].Option := 'Rojo';
lWoo.Variations(lProduct.Id).Add(lVariation);
```

**Crear un pedido pagado**

```delphi
var lOrder: TWooOrder;
lOrder.PaymentMethod := 'bacs';
lOrder.SetPaid := True;                    // processing, stock descontado
lOrder.Billing.Email := 'cliente@example.es';
SetLength(lOrder.LineItems, 1);
lOrder.LineItems[0].ProductId := 7;
lOrder.LineItems[0].Quantity := 2;
lOrder := lWoo.Orders.Add(lOrder);
```

**Reembolsos.** `TWooRefund.ApiRefund` empieza en `False` (en WooCommerce el valor por defecto es
`True`): el reembolso se registra sin mover dinero. Ponlo a `True` para devolver el dinero a través
de la pasarela.

```delphi
var lRefund: TWooRefund;
lRefund.Amount := '10.00';
lRefund.Reason := 'Devolución';
lRefund.ApiRefund := True;    // reembolso real a través de la pasarela
lWoo.Refunds(1234).Add(lRefund);
```

**Cambiar un ajuste de la tienda**

```delphi
var lSetting := lWoo.Settings('general').Get('woocommerce_specific_allowed_countries');
lSetting.Value := '["IT","FR","DE"]';     // multiselect: texto JSON
lWoo.Settings('general').Update(lSetting, ['value']);
```

## El sample VCL

`Samples\VCL\Woo4DelphiDemo.dpr`: ábrelo en RAD Studio, compílalo y ejecútalo. Su interfaz está en
italiano. Arriba van la URL y las claves; la segunda fila solo sirve para subir imágenes (usuario de
WordPress y contraseña de aplicación). Abajo está el log de cada llamada con el tiempo empleado.

Los ajustes se leen al arrancar desde `Woo4DelphiDemo.ini`, junto al ejecutable, y se guardan en él
al cerrar. También puedes escribirlo a mano:

```ini
[Store]
URL=https://tienda.example.com
ConsumerKey=ck_...
ConsumerSecret=cs_...
QueryStringAuth=0
; 1 solo para tiendas de desarrollo con certificado autofirmado
AcceptAnyCertificate=0

[WordPress]
User=editor
AppPassword=abcd efgh ijkl mnop qrst uvwx
```

> El archivo contiene claves y contraseñas **en claro**: no lo pongas bajo control de versiones y no
> lo distribuyas con el ejecutable.

| Página | Qué prueba |
|--------|------------|
| **Prodotti** (productos) | lista y búsqueda, edición tipada de los campos principales (también EAN, estado del stock, categorías), imágenes (subir archivo, desde URL, elegir la principal, quitar), crear, duplicar, papelera, eliminación definitiva; variaciones: lista, precio y stock, añadir, eliminar |
| **Categorie** (categorías) | lista, crear, renombrar, slug, mover bajo otra categoría, descripción, eliminar |
| **Ordini** (pedidos) | lista por estado, detalle, cambio de estado, notas (también visibles para el cliente), reembolsos, envío de correos, pedido de prueba |
| **Risorse** (recursos) | todos los endpoints tipados: lista con filtros, leer, crear y actualizar desde JSON (pasando por el record), eliminar, batch sobre varias filas |
| **Report e sistema** (informes y sistema) | informe de ventas, más vendidos, totales, estado del sistema, herramientas, moneda, campos personalizados, regiones de una zona, descargas de un cliente |
| **JSON grezzo** (JSON en bruto) | cualquier método sobre cualquier endpoint |

> **Atención**: el sample trabaja sobre la tienda a la que se conecta. Crea, modifica y elimina datos
> reales, cambia estados de pedidos (con los correos de WooCommerce a los clientes), registra
> reembolsos, ejecuta herramientas del sistema. Cada operación destructiva pide confirmación, pero
> úsalo en una **tienda de pruebas**.

Las llamadas se ejecutan en el hilo principal para que el código sea legible: en una aplicación real
muévelas a un hilo (`TTask.Run`) con un `TWooClient` por hilo.

## Verificación

```
dcc32 Woo4Delphi.SelfCheck.dpr  (o dcc64)
Woo4Delphi.SelfCheck.exe                                   comprobaciones offline
Woo4Delphi.SelfCheck.exe Samples\VCL\Woo4DelphiDemo.ini    también contra la tienda
```

Sin parámetros ejecuta las comprobaciones offline: URL y codificación de los parámetros, cabeceras de
autenticación, nombres JSON y valores por defecto de los records, conversores, lectura de los errores.
Con un archivo ini (la sección `[Store]`, la misma del sample VCL) también lee, **en solo lectura**,
un elemento de cada recurso de la tienda: si WooCommerce envía un campo con un tipo inesperado, lo
indica. Un endpoint que no existe en la versión de WooCommerce de la tienda se notifica, sin que falle
la verificación. `AcceptAnyCertificate=1` sirve para una tienda de pruebas con certificado autofirmado.

Los enlaces permanentes de WordPress (Ajustes → Enlaces permanentes) no deben ser "Simple": con ese
ajuste `/wp-json/` no existe y WordPress responde con la página de inicio. El cliente lo indica con un
error `invalid_json` que lo explica.

## Limitaciones conocidas

- Sin OAuth 1.0a: solo tiendas en HTTPS.
- No mapeados: el endpoint de las marcas (`products/brands`; las marcas de un producto sí, en `Brands`),
  la vista previa de los reembolsos (`refunds/preview`) y `compute_totals` (WooCommerce 11.1+), los
  campos que no aparecen en la documentación v3 (por ejemplo `parent_name` de las líneas de pedido).
  Se alcanzan con la capa en bruto.
- `List` mantiene todo en memoria. Si un proxy eliminara la cabecera `X-WP-TotalPages`, una lista
  paginada se detendría en los primeros 100 elementos.
- Llamadas síncronas: ninguna API asíncrona.

## Créditos

Desarrollado por **KD Software Srls** - desarrollador Giordano Giaccaglia.
Web: <https://www.kdsoftware.it> - correo: <info@kdsoftware.it>
