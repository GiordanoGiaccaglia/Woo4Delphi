# Woo4Delphi

[English](README.md) | [Italiano](README.it.md) | [Español](README.es.md) | **Français** | [Deutsch](README.de.md)

Par [KD Software Srls](https://www.kdsoftware.it) - développeur Giordano Giaccaglia - <info@kdsoftware.it>

Client de la **WooCommerce REST API v3** pour Delphi 13 Florence : deux units à ajouter au projet,
RTL uniquement (`System.Net.HttpClient`, `System.JSON`), aucun paquet à installer.

- Toutes les ressources de la v3 (produits, variations, commandes, clients, codes promo, taxes,
  expédition, réglages, paiements, webhooks, rapports, état du système, données) sous forme de
  **records Delphi typés**.
- Une seule façon de travailler sur chaque ressource : `List`, `Get`, `Add`, `Update`, `Delete`, `Batch`.
- Les modifications n'envoient **que les champs que vous indiquez** : un champ que vous ne nommez pas
  n'est jamais écrasé.
- Une couche JSON brute pour tout le reste.

| Fichier | Contenu |
|---------|---------|
| `Woo4Delphi.Types.pas` | Les records de toutes les ressources, champ par champ d'après la documentation v3 |
| `Woo4Delphi.Client.pas` | `TWooClient`, `TWooEndpoint<T>`, `EWooError` |
| `Woo4Delphi.SelfCheck.dpr` | Vérification en ligne de commande (hors ligne, et en direct sur une boutique) |
| `Samples\VCL\Woo4DelphiDemo.dpr` | Application VCL avec une page par domaine, pour essayer toutes les fonctions |

## Prérequis

- Delphi 13 Florence (il utilise l'expression `if … then … else` et les records managés), Win32 ou Win64.
- WooCommerce avec la REST API v3 (WooCommerce 3.5 ou ultérieur) accessible en **HTTPS**.
- Une paire de clés REST : dans WordPress, *WooCommerce → Réglages → Avancé → API REST → Ajouter une clé*.
  Droit *Lecture* pour lire, *Lecture/Écriture* pour modifier.

## Démarrage rapide

Ajoutez `Woo4Delphi.Types.pas` et `Woo4Delphi.Client.pas` au projet (ou leur dossier au search path).

```delphi
uses
  System.Net.URLClient,   // TNameValuePair, pour les filtres
  Woo4Delphi.Types,
  Woo4Delphi.Client;

var lWoo := TWooClient.Create('https://boutique.example.com', 'ck_...', 'cs_...');
try
  // un record : rien à libérer
  var lProduct := lWoo.Products.Get(7);
  lProduct.RegularPrice := '12.50';
  lProduct.StockQuantity := 0;
  lWoo.Products.Update(lProduct, ['regular_price', 'stock_quantity']);   // seulement ces deux champs

  // toutes les pages, filtrées
  for var lOrder in lWoo.Orders.List([TNameValuePair.Create('status', 'processing')]) do
    Writeln(lOrder.Number, '  ', lOrder.Billing.City, '  ', lOrder.Total, ' ', lOrder.Currency);

  lWoo.UpdateOrderStatus(1234, 'completed');
finally
  lWoo.Free;
end;
```

## Concepts

### Les records

Chaque ressource est un record (`TWooProduct`, `TWooOrder`, `TWooCustomer`…). Le compilateur gère les
chaînes et les tableaux : aucun `Free`, aucune fuite de mémoire.

- **Noms** : un champ Delphi correspond à la clé JSON en snake_case (`RegularPrice` ↔ `regular_price`,
  `DateCreatedGmt` ↔ `date_created_gmt`). Là où la règle ne suffit pas, ou si la clé est un mot réservé,
  il y a un `[JsonName]` : `ProductType` ↔ `type`, `IsVirtual` ↔ `virtual`, `RateClass` ↔ `class`,
  `Caption` ↔ `label`, `DefaultValue` ↔ `default`, `Address1` ↔ `address_1`.
- **Clés inconnues** : ignorées en lecture, jamais envoyées en écriture. Un `null` devient 0, `''`,
  `False` ou un record vide.
- **Initialisation automatique** : les records que l'on peut créer se remettent à zéro tout seuls et
  prennent les valeurs par défaut de WooCommerce quand elles ne sont pas nulles.
  `var lCoupon: TWooCoupon;` suffit, `Default()` est inutile :

  | Record | Valeurs par défaut non nulles |
  |--------|-------------------------------|
  | `TWooProduct` | `ReviewsAllowed = True`, `DownloadLimit = -1`, `DownloadExpiry = -1` |
  | `TWooVariation` | `DownloadLimit = -1`, `DownloadExpiry = -1` |
  | `TWooTaxRate` | `Priority = 1`, `Shipping = True` |
  | `TWooShippingZoneMethod` | `Enabled = True` |
  | `TWooRefund` | `ApiRestock = True` ; `ApiRefund = False` (voir *Remboursements*) |

- **Prix et totaux** sont des chaînes, tels que WooCommerce les envoie (`'9.90'`). Pour calculer :
  `StrToFloat(lProduct.RegularPrice, TFormatSettings.Invariant)`.
- **Dates** : ce sont les chaînes ISO de WooCommerce. `DateCreated` est à l'heure de la boutique, sans
  fuseau ; `DateCreatedGmt` est en UTC : `ISO8601ToDate(lOrder.DateCreatedGmt, True)`.
- **Champs « JSON text »** : certaines valeurs ont un type variable ou des clés dynamiques et arrivent
  sous forme de texte JSON dans une chaîne : la `Value` des `MetaData` quand ce n'est pas une chaîne, la
  `Value` des réglages multiselect (`'["IT","FR"]'`), les `Settings` des passerelles et des modes
  d'expédition, les `Options` des réglages, les `Totals` du rapport des ventes, le `Price` des lignes de
  commande (un nombre en JSON). Pour envoyer un objet ou un tableau, affectez son texte JSON :
  `lGateway.Settings := '{"title":"Virement"}'`.
- **Variations** : quand le stock est géré par le produit parent, WooCommerce envoie
  `"manage_stock": "parent"` ; le record le lit comme `ManageStock = False`.

### Les endpoints : `TWooEndpoint<T>`

`lWoo.Products`, `lWoo.Variations(IDProduit)`, `lWoo.Settings('general')`… renvoient un
`TWooEndpoint<T>`, toujours avec les mêmes méthodes :

| Méthode | HTTP | Ce qu'elle fait |
|---------|------|-----------------|
| `List(AParams)` | GET | **Toutes les pages**, 100 éléments par requête ; une seule requête sur les endpoints non paginés |
| `Get(ID)` | GET | Un élément ; `ID` numérique ou chaîne (`'woocommerce_currency'`, `'bacs'`, `'IT'`) |
| `Add(Item)` | POST | Crée. N'envoie ni les champs en lecture seule (`id`, `price`, `permalink`, `date_created`…) ni les chaînes et tableaux vides : WooCommerce applique ses valeurs par défaut |
| `Update(Item, Champs)` | PUT | N'envoie **que** les clés JSON indiquées ; prend l'ID dans `Item`. Une clé qui n'est pas un champ du record lève `EArgumentException` |
| `Delete(ID, AForce)` | DELETE | Produits, commandes, codes promo : sans `AForce` ils vont à la corbeille. Les autres ressources n'ont pas de corbeille : la suppression est toujours définitive |
| `Batch(Créer, MettreÀJour, Champs, Supprimer)` | POST …/batch | Jusqu'à 100 éléments au total par appel. `Errors` liste les éléments refusés |

`Update` demande la liste des champs parce qu'un record ne distingue pas « non renseigné » de « vide » :
l'envoyer en entier remettrait à zéro les champs que vous n'avez ni lus ni renseignés. La façon naturelle
est de lire, modifier, puis enregistrer les champs modifiés :

```delphi
var lCustomer := lWoo.Customers.Get(42);
lCustomer.Billing.Phone := '+33 1 23 45 67 89';
lWoo.Customers.Update(lCustomer, ['billing']);   // l'objet billing entier, tel que lu et modifié
```

### Filtres et pagination

Les filtres sont les paramètres de la documentation WooCommerce, sous forme de paires nom/valeur :

```delphi
var lOrders := lWoo.Orders.List([
  TNameValuePair.Create('status', 'processing'),
  TNameValuePair.Create('modified_after', '2026-11-01T00:00:00')]);
```

`List` fixe lui-même `per_page` et `page` et charge tout en mémoire. Sur de très gros catalogues,
utilisez la couche brute page par page (`lWoo.Get('products', [per_page, page])`) : après chaque
appel, `LastTotal` et `LastTotalPages` donnent les en-têtes `X-WP-Total` et `X-WP-TotalPages`.

### Erreurs

- `EWooError` : toute réponse non 2xx. `StatusCode` est le statut HTTP, `Code` le code WooCommerce
  (`woocommerce_rest_product_invalid_id`, `rest_invalid_param`, `rest_no_route`…), `Message` le texte.
  Si un proxy répond avec une page HTML, `Code` vaut `http_<statut>`.
- `EArgumentException` : URL non HTTPS, champ inconnu dans `Update`, record sans ID dans `Update`.
- Les erreurs réseau de `THTTPClient` (`ENetHTTPClientException`) passent telles quelles.

### Couche brute

Pour ce que les records ne couvrent pas : `Get`, `Post`, `Put`, `Delete`, `GetAll` travaillent sur des
`TJSONValue`, avec des endpoints relatifs à `/wp-json/wc/v3/`. **C'est à vous de libérer la valeur renvoyée.**

```delphi
var lAnswer := lWoo.Get('orders/123', [TNameValuePair.Create('dp', '4')]);
try
  Writeln(lAnswer.Format(2));
finally
  lAnswer.Free;
end;
```

`lWoo.ToJSON<T>(Record)` et `lWoo.ParseJSON<T>(Texte)` convertissent un record en JSON WooCommerce et
inversement, avec les mêmes règles de nommage : utile pour les logs, les sauvegardes, les appels bruts.

### Authentification et connexion

- HTTPS uniquement : WooCommerce n'accepte les clés en Basic auth que sur HTTPS (sur HTTP il faut
  OAuth 1.0a, non implémenté), et sur HTTP la clé secrète circulerait en clair.
- `QueryStringAuth := True` : pour les hébergeurs (PHP en CGI/FastCGI) qui suppriment l'en-tête
  `Authorization` et répondent 401 avec des clés valides. Les clés passent alors aussi dans la query
  string, donc **dans les logs du serveur**.
- `lWoo.HTTP` est le `THTTPClient` sous-jacent : délais (`ConnectionTimeout`, `ResponseTimeout`), proxy
  et, pour les seules boutiques de développement avec certificat auto-signé, `ValidateServerCertificateCallback`.
- Un `TWooClient` par thread : `LastTotal`/`LastTotalPages` décrivent le dernier appel de cette instance.

## Référence des endpoints

| Domaine | Méthode du client | Record | Opérations | Notes |
|---------|-------------------|--------|------------|-------|
| Produits | `Products` | `TWooProduct` | toutes + Batch | corbeille |
| | `DuplicateProduct(ID)` | `TWooProduct` | POST …/duplicate | la copie est créée en brouillon |
| Médiathèque | `UploadImage(File, Alt)` | `TWooImage` | POST /wp/v2/media | WordPress, pas WooCommerce : voir *Images du produit* |
| Variations | `Variations(IDProduit)` | `TWooVariation` | toutes + Batch | |
| Attributs globaux | `Attributes` | `TWooProductAttribute` | toutes + Batch | non paginé |
| Termes d'attribut | `AttributeTerms(IDAttribut)` | `TWooAttributeTerm` | toutes + Batch | |
| Catégories | `Categories` | `TWooProductCategory` | toutes + Batch | |
| Étiquettes | `Tags` | `TWooProductTag` | toutes + Batch | |
| Classes d'expédition | `ShippingClasses` | `TWooShippingClass` | toutes + Batch | |
| Avis | `Reviews` | `TWooProductReview` | toutes + Batch | |
| Champs personnalisés | `ProductCustomFieldNames` | `TArray<string>` | liste | versions récentes de WooCommerce |
| Commandes | `Orders` | `TWooOrder` | toutes + Batch | corbeille ; `SetPaid` à la création |
| | `UpdateOrderStatus(ID, Statut)` | `TWooOrder` | PUT | e-mails et stock comme depuis l'administration |
| Notes de commande | `OrderNotes(IDCommande)` | `TWooOrderNote` | List, Get, Add, Delete | `CustomerNote = True` prévient le client |
| Remboursements d'une commande | `Refunds(IDCommande)` | `TWooRefund` | List, Get, Add, Delete | voir *Remboursements* |
| Tous les remboursements | `AllRefunds` | `TWooRefund` | List | `ParentId` = commande |
| E-mails de commande | `OrderEmailTemplates(ID)`, `SendOrderEmail(ID, Modèle, Email, Forcer)` | `TWooEmailTemplate` | GET, POST | modèle vide = détails de la commande (facture) |
| Clients | `Customers` | `TWooCustomer` | toutes + Batch | rôle *customer* uniquement (filtre `role=all` pour tous) |
| | `CustomerDownloads(ID)` | `TWooDownload` | GET | |
| Codes promo | `Coupons` | `TWooCoupon` | toutes + Batch | corbeille |
| Taux de taxe | `TaxRates` | `TWooTaxRate` | toutes + Batch | |
| Classes de taxe | `TaxClasses` | `TWooTaxClass` | List, Add, Delete(slug) | la supprimer efface aussi ses taux |
| Webhooks | `Webhooks` | `TWooWebhook` | toutes + Batch | `Secret` signe les payloads |
| Groupes de réglages | `SettingGroups` | `TWooSettingGroup` | List | index : les options sont dans `Settings(groupe)` |
| Réglages | `Settings(IDGroupe)` | `TWooSetting` | List, Get, Update, Batch | `Value` en texte JSON pour les multiselect |
| Passerelles de paiement | `PaymentGateways` | `TWooPaymentGateway` | List, Get, Update | |
| Zones d'expédition | `ShippingZones` | `TWooShippingZone` | List, Get, Add, Update, Delete | la zone 0 ne peut pas être supprimée |
| Régions d'une zone | `ShippingZoneLocations(ID)`, `UpdateShippingZoneLocations(ID, Régions)` | `TWooZoneLocation` | GET, PUT | le PUT remplace toutes les régions |
| Modes d'une zone | `ShippingZoneMethods(IDZone)` | `TWooShippingZoneMethod` | List, Get, Add, Update, Delete | ID = `InstanceId` ; `MethodId` obligatoire à la création |
| Modes d'expédition | `ShippingMethods` | `TWooShippingMethod` | List, Get | |
| Rapports | `Reports` | `TWooIndexEntry` | List | index des rapports |
| | `SalesReport(Filtres)` | `TWooSalesReport` | GET | `period` ou `date_min`/`date_max` |
| | `TopSellersReport(Filtres)` | `TWooTopSeller` | GET | |
| | `ReportTotals('orders')` | `TWooReportTotal` | GET | coupons, customers, orders, products, reviews |
| État du système | `SystemStatus` | `TWooSystemStatus` | GET | environnement, base de données, extensions, thème, réglages, sécurité, pages |
| Outils du système | `SystemTools`, `RunSystemTool(ID)` | `TWooSystemTool` | List, Get, PUT | certains outils sont destructifs |
| Données | `Data` | `TWooIndexEntry` | List | index |
| | `Continents`, `Countries` | `TWooContinent`, `TWooCountry` | List, Get(code) | |
| | `Currencies` | `TWooCurrency` | List, Get(code) | `Get('current')` = devise de la boutique |

*Toutes* = `List`, `Get`, `Add`, `Update`, `Delete`. Sur les endpoints que WooCommerce ne prévoit pas
(par exemple `Add` sur `Countries`), le serveur répond par une `EWooError` de code `rest_no_route`.

## Recettes

**Images du produit : principale et galerie**

Dans `TWooProduct.Images`, la première image est la principale, les autres forment la galerie.
WooCommerce n'accepte que des images déjà présentes dans la médiathèque (par `Id`) ou une URL à
télécharger (`Id` 0 et `Src`). Il n'a pas d'endpoint pour envoyer des fichiers : un fichier du disque
doit d'abord être envoyé dans la médiathèque de WordPress avec `UploadImage`. Cet endpoint
(`/wp/v2/media`) **n'accepte pas les clés WooCommerce** : il faut un utilisateur WordPress autorisé à
téléverser des fichiers et un de ses *mots de passe d'application* (Comptes → Profil → Mots de passe
d'application), pas le mot de passe de connexion.

```delphi
lWoo.WordPressUser := 'editor';
lWoo.WordPressAppPassword := 'abcd efgh ijkl mnop qrst uvwx';
var lMain := lWoo.UploadImage('C:\Photos\tasse.jpg', 'Tasse rouge');   // Id et Src dans la médiathèque
var lFromWeb: TWooImage;
lFromWeb.Src := 'https://example.com/photos/tasse-dos.jpg';            // WooCommerce la télécharge
var lProduct := lWoo.Products.Get(7);
lProduct.Images := [lMain, lFromWeb];                                   // principale, puis galerie
lWoo.Products.Update(lProduct, ['images']);
```

- `Images` remplace toutes les images : pour en ajouter une à la galerie, partez de celles du produit.
  `Images := nil` les retire toutes. Retirer une image ne la supprime pas de la médiathèque.
- Quand vous renvoyez les images lues, n'envoyez que `Id` : le `Name` renvoyé par WooCommerce a déjà
  la typographie de WordPress (apostrophes courbes), et un `Name` non vide renomme le fichier dans la
  médiathèque.
- Pour une URL, le serveur de la boutique doit pouvoir joindre l'adresse : sur une boutique de
  développement, `https://localhost` ne fonctionne généralement pas (WooCommerce répond
  `woocommerce_product_image_upload_error`).
- Le nom du fichier sur le disque perd ses lettres non ASCII (`café.jpg` → `caf_.jpg`) ; le titre de
  l'image dans la médiathèque les conserve.

**Mettre à jour le stock de nombreux produits en un appel**

```delphi
var lUpdates: TArray<TWooProduct>;
SetLength(lUpdates, 2);
lUpdates[0].Id := 7;   lUpdates[0].ManageStock := True; lUpdates[0].StockQuantity := 12;
lUpdates[1].Id := 8;   lUpdates[1].ManageStock := True; lUpdates[1].StockQuantity := 0;
var lResult := lWoo.Products.Batch(nil, lUpdates, ['manage_stock', 'stock_quantity'], []);
for var lError in lResult.Errors do
  Writeln(lError);   // par ex. 'update[1] woocommerce_rest_product_invalid_id: Invalid ID.'
```

**Créer un produit variable avec une variation**

```delphi
var lProduct: TWooProduct;
lProduct.Name := 'Tasse';
lProduct.ProductType := 'variable';
SetLength(lProduct.Attributes, 1);
lProduct.Attributes[0].Name := 'Couleur';
lProduct.Attributes[0].Variation := True;
lProduct.Attributes[0].Visible := True;
lProduct.Attributes[0].Options := ['Rouge', 'Bleu'];
lProduct := lWoo.Products.Add(lProduct);

var lVariation: TWooVariation;
lVariation.RegularPrice := '9.90';
SetLength(lVariation.Attributes, 1);
lVariation.Attributes[0].Name := 'Couleur';
lVariation.Attributes[0].Option := 'Rouge';
lWoo.Variations(lProduct.Id).Add(lVariation);
```

**Créer une commande payée**

```delphi
var lOrder: TWooOrder;
lOrder.PaymentMethod := 'bacs';
lOrder.SetPaid := True;                    // processing, stock décrémenté
lOrder.Billing.Email := 'client@example.fr';
SetLength(lOrder.LineItems, 1);
lOrder.LineItems[0].ProductId := 7;
lOrder.LineItems[0].Quantity := 2;
lOrder := lWoo.Orders.Add(lOrder);
```

**Remboursements.** `TWooRefund.ApiRefund` vaut d'abord `False` (dans WooCommerce la valeur par défaut
est `True`) : le remboursement est enregistré sans mouvement d'argent. Mettez-le à `True` pour rendre
l'argent via la passerelle.

```delphi
var lRefund: TWooRefund;
lRefund.Amount := '10.00';
lRefund.Reason := 'Retour';
lRefund.ApiRefund := True;    // remboursement réel via la passerelle
lWoo.Refunds(1234).Add(lRefund);
```

**Modifier un réglage de la boutique**

```delphi
var lSetting := lWoo.Settings('general').Get('woocommerce_specific_allowed_countries');
lSetting.Value := '["IT","FR","DE"]';     // multiselect : texte JSON
lWoo.Settings('general').Update(lSetting, ['value']);
```

## Le sample VCL

`Samples\VCL\Woo4DelphiDemo.dpr` : ouvrez-le dans RAD Studio, compilez et lancez. Son interface est en
italien. En haut se trouvent l'URL et les clés ; la deuxième ligne ne sert qu'à envoyer des images
(utilisateur WordPress et mot de passe d'application). En bas, le journal de chaque appel avec sa durée.

Les réglages sont lus au démarrage depuis `Woo4DelphiDemo.ini`, à côté de l'exécutable, et y sont
enregistrés à la fermeture. Vous pouvez aussi l'écrire à la main :

```ini
[Store]
URL=https://boutique.example.com
ConsumerKey=ck_...
ConsumerSecret=cs_...
QueryStringAuth=0
; 1 uniquement pour les boutiques de développement avec certificat auto-signé
AcceptAnyCertificate=0

[WordPress]
User=editor
AppPassword=abcd efgh ijkl mnop qrst uvwx
```

> Le fichier contient des clés et des mots de passe **en clair** : ne le mettez pas sous gestion de
> versions et ne le distribuez pas avec l'exécutable.

| Page | Ce qu'elle teste |
|------|------------------|
| **Prodotti** (produits) | liste et recherche, modification typée des champs principaux (y compris EAN, état du stock, catégories), images (envoyer un fichier, depuis une URL, choisir la principale, retirer), créer, dupliquer, corbeille, suppression définitive ; variations : liste, prix et stock, ajouter, supprimer |
| **Categorie** (catégories) | liste, créer, renommer, slug, déplacer sous une autre catégorie, description, supprimer |
| **Ordini** (commandes) | liste par statut, détail, changement de statut, notes (y compris visibles par le client), remboursements, envoi d'e-mails, commande de test |
| **Risorse** (ressources) | tous les endpoints typés : liste avec filtres, lire, créer et mettre à jour depuis du JSON (en passant par le record), supprimer, batch sur plusieurs lignes |
| **Report e sistema** (rapports et système) | rapport des ventes, meilleures ventes, totaux, état du système, outils, devise, champs personnalisés, régions d'une zone, téléchargements d'un client |
| **JSON grezzo** (JSON brut) | n'importe quelle méthode sur n'importe quel endpoint |

> **Attention** : le sample travaille sur la boutique à laquelle il se connecte. Il crée, modifie et
> supprime des données réelles, change des statuts de commande (avec les e-mails de WooCommerce aux
> clients), enregistre des remboursements, exécute des outils système. Chaque opération destructive
> demande confirmation, mais utilisez-le sur une **boutique de test**.

Les appels s'exécutent dans le thread principal pour garder le code lisible : dans une vraie
application, déplacez-les dans un thread (`TTask.Run`) avec un `TWooClient` par thread.

## Vérification

```
dcc32 Woo4Delphi.SelfCheck.dpr  (ou dcc64)
Woo4Delphi.SelfCheck.exe                                   contrôles hors ligne
Woo4Delphi.SelfCheck.exe Samples\VCL\Woo4DelphiDemo.ini    aussi sur la boutique
```

Sans paramètre, il exécute les contrôles hors ligne : URL et encodage des paramètres, en-têtes
d'authentification, noms JSON et valeurs par défaut des records, convertisseurs, lecture des erreurs.
Avec un fichier ini (la section `[Store]`, la même que celle du sample VCL), il lit aussi, **en lecture
seule**, un élément de chaque ressource de la boutique : si WooCommerce envoie un champ d'un type
inattendu, il le signale. Un endpoint absent de la version de WooCommerce de la boutique est signalé,
sans faire échouer la vérification. `AcceptAnyCertificate=1` sert pour une boutique de test avec
certificat auto-signé.

Les permaliens de WordPress (Réglages → Permaliens) ne doivent pas être « Simple » : avec ce réglage
`/wp-json/` n'existe pas et WordPress répond avec la page d'accueil. Le client le signale par une
erreur `invalid_json` qui l'explique.

## Limites connues

- Pas d'OAuth 1.0a : boutiques en HTTPS uniquement.
- Non mappés : l'endpoint des marques (`products/brands` ; les marques d'un produit le sont, dans
  `Brands`), l'aperçu des remboursements (`refunds/preview`) et `compute_totals` (WooCommerce 11.1+),
  les champs absents de la documentation v3 (par exemple `parent_name` des lignes de commande). La
  couche brute permet d'y accéder.
- `List` garde tout en mémoire. Si un proxy supprimait l'en-tête `X-WP-TotalPages`, une liste paginée
  s'arrêterait aux 100 premiers éléments.
- Appels synchrones : aucune API asynchrone.

## Crédits

Développé par **KD Software Srls** - développeur Giordano Giaccaglia.
Site : <https://www.kdsoftware.it> - e-mail : <info@kdsoftware.it>
