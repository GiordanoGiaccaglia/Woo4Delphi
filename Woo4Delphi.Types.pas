// Woo4Delphi by KD Software Srls - https://www.kdsoftware.it - info@kdsoftware.it
// Developer: Giordano Giaccaglia

unit Woo4Delphi.Types;

// WooCommerce REST v3 resources as records, field by field from the official v3 documentation.
// Nothing to Free: strings and arrays are managed by the compiler.
//
// - Field names map to JSON keys by PascalCase -> snake_case (RegularPrice <-> regular_price);
//   [JsonName] only where that rule does not fit or the key is a Delphi reserved word
//   (type, virtual, class, label, default, file).
// - JSON keys not declared here are skipped on read and never sent on write.
//   A JSON null arrives as 0 / '' / False / an empty record.
// - Records you can create initialize themselves: a plain "var lCoupon: TWooCoupon;" starts
//   zeroed, with WooCommerce's own defaults where they are not zero (ReviewsAllowed = True,
//   DownloadLimit = -1, TaxRate.Priority = 1...). No stack garbage reaches the shop.
// - Prices and totals are strings, as WooCommerce sends them ('9.90'):
//     StrToFloat(lProduct.RegularPrice, TFormatSettings.Invariant)
// - Dates are the ISO strings WooCommerce sends; DateCreated is shop time, DateCreatedGmt is UTC:
//     ISO8601ToDate(lOrder.DateCreatedGmt, True)
// - Fields marked "JSON text" hold mixed-type or keyed-object values as raw JSON text
//   (e.g. Settings = '{"title":{...}}'). Assign JSON text to send an object or array back.

interface

uses
  System.Rtti,
  System.TypInfo,
  System.JSON.Types,
  System.JSON.Readers,
  System.JSON.Writers,
  System.JSON.Serializers;

type
  // Variations answer "manage_stock": "parent" when the parent product manages the stock:
  // read as False (the variation itself does not manage it), written as a plain boolean.
  TWooManageStockConverter = class(TJsonConverter)
  public
    function CanConvert(ATypeInf: PTypeInfo): Boolean; override;
    function ReadJson(const AReader: TJsonReader; ATypeInf: PTypeInfo; const AExistingValue: TValue;
      const ASerializer: TJsonSerializer): TValue; override;
    procedure WriteJson(const AWriter: TJsonWriter; const AValue: TValue; const ASerializer: TJsonSerializer); override;
  end;

  // Any JSON value into a string field: a string as is, anything else (number, boolean, object,
  // array) as its JSON text. Written back as raw JSON when the text is an object or an array.
  TWooTextConverter = class(TJsonConverter)
  public
    function CanConvert(ATypeInf: PTypeInfo): Boolean; override;
    function ReadJson(const AReader: TJsonReader; ATypeInf: PTypeInfo; const AExistingValue: TValue;
      const ASerializer: TJsonSerializer): TValue; override;
    procedure WriteJson(const AWriter: TJsonWriter; const AValue: TValue; const ASerializer: TJsonSerializer); override;
  end;

  { Shared pieces }

  TWooMeta = record
    Id: Int64;
    Key: string;
    [JsonConverter(TWooTextConverter)]
    Value: string;          // JSON text when the value is not a string
    class operator Initialize(out Dest: TWooMeta);
  end;

  TWooDimensions = record
    Length: string;
    Width: string;
    Height: string;
  end;

  TWooFile = record
    Id: string;
    Name: string;
    [JsonName('file')]
    Url: string;
  end;

  // A category, tag or brand as referenced by a product: on write only Id counts
  TWooTermRef = record
    Id: Int64;
    Name: string;
    Slug: string;
    class operator Initialize(out Dest: TWooTermRef);
  end;

  // In TWooProduct.Images the first image is the main one, the others the gallery
  TWooImage = record
    Id: Int64;              // media library ID; 0: WooCommerce downloads Src into the media library
    DateCreated: string;
    DateCreatedGmt: string;
    DateModified: string;
    DateModifiedGmt: string;
    Src: string;
    Name: string;           // read: the title as displayed (quotes curled); written when not empty: renames it
    Alt: string;            // written when not empty
    class operator Initialize(out Dest: TWooImage);
  end;

  // An attribute of a product: Options lists its values
  TWooAttribute = record
    Id: Int64;              // 0 = custom attribute, defined on this product only
    Name: string;
    Position: Integer;
    Visible: Boolean;
    Variation: Boolean;     // used to build the variations
    Options: TArray<string>;
    class operator Initialize(out Dest: TWooAttribute);
  end;

  // One attribute value: a variation's attributes, a product's default attributes
  TWooAttributeOption = record
    Id: Int64;              // 0 = custom attribute: Name identifies it
    Name: string;
    Option: string;         // e.g. 'Red'
    class operator Initialize(out Dest: TWooAttributeOption);
  end;

  TWooAddress = record
    FirstName: string;
    LastName: string;
    Company: string;
    [JsonName('address_1')]
    Address1: string;
    [JsonName('address_2')]
    Address2: string;
    City: string;
    State: string;
    Postcode: string;
    Country: string;        // ISO 3166-1 alpha-2, e.g. IT
    Email: string;          // billing only
    Phone: string;
  end;

  // A tax applied to a line: Id is the tax rate
  TWooLineTax = record
    Id: Int64;
    Total: string;
    Subtotal: string;
    class operator Initialize(out Dest: TWooLineTax);
  end;

  { Products }

  TWooProduct = record
    Id: Int64;
    Name: string;
    Slug: string;
    Permalink: string;              // read-only
    DateCreated: string;            // read-only
    DateCreatedGmt: string;         // read-only
    DateModified: string;           // read-only
    DateModifiedGmt: string;        // read-only
    [JsonName('type')]
    ProductType: string;            // simple, grouped, external, variable
    Status: string;                 // draft, pending, private, publish
    Featured: Boolean;
    CatalogVisibility: string;      // visible, catalog, search, hidden
    Description: string;
    ShortDescription: string;
    Sku: string;
    GlobalUniqueId: string;         // GTIN, UPC, EAN or ISBN
    Price: string;                  // read-only: the price in effect now
    RegularPrice: string;
    SalePrice: string;
    DateOnSaleFrom: string;
    DateOnSaleFromGmt: string;
    DateOnSaleTo: string;
    DateOnSaleToGmt: string;
    PriceHtml: string;              // read-only
    OnSale: Boolean;                // read-only
    Purchasable: Boolean;           // read-only
    TotalSales: Integer;            // read-only
    [JsonName('virtual')]
    IsVirtual: Boolean;
    Downloadable: Boolean;
    Downloads: TArray<TWooFile>;
    DownloadLimit: Integer;         // -1 = unlimited
    DownloadExpiry: Integer;        // days, -1 = never
    ExternalUrl: string;
    ButtonText: string;
    TaxStatus: string;              // taxable, shipping, none
    TaxClass: string;
    ManageStock: Boolean;
    StockQuantity: Integer;         // meaningful only with ManageStock
    StockStatus: string;            // instock, outofstock, onbackorder
    Backorders: string;             // no, notify, yes
    BackordersAllowed: Boolean;     // read-only
    Backordered: Boolean;           // read-only
    SoldIndividually: Boolean;
    Weight: string;
    Dimensions: TWooDimensions;
    ShippingRequired: Boolean;      // read-only
    ShippingTaxable: Boolean;       // read-only
    ShippingClass: string;          // slug
    ShippingClassId: Int64;         // read-only
    ReviewsAllowed: Boolean;
    AverageRating: string;          // read-only
    RatingCount: Integer;           // read-only
    RelatedIds: TArray<Int64>;      // read-only
    UpsellIds: TArray<Int64>;
    CrossSellIds: TArray<Int64>;
    ParentId: Int64;
    PurchaseNote: string;
    Categories: TArray<TWooTermRef>;
    Tags: TArray<TWooTermRef>;
    Brands: TArray<TWooTermRef>;
    Images: TArray<TWooImage>;
    Attributes: TArray<TWooAttribute>;
    DefaultAttributes: TArray<TWooAttributeOption>;
    Variations: TArray<Int64>;      // read-only: IDs of the variations
    GroupedProducts: TArray<Int64>;
    MenuOrder: Integer;
    MetaData: TArray<TWooMeta>;
    class operator Initialize(out Dest: TWooProduct);
  end;

  TWooVariation = record
    Id: Int64;
    DateCreated: string;            // read-only
    DateCreatedGmt: string;         // read-only
    DateModified: string;           // read-only
    DateModifiedGmt: string;        // read-only
    Description: string;
    Permalink: string;              // read-only
    Sku: string;
    GlobalUniqueId: string;
    Price: string;                  // read-only
    RegularPrice: string;
    SalePrice: string;
    DateOnSaleFrom: string;
    DateOnSaleFromGmt: string;
    DateOnSaleTo: string;
    DateOnSaleToGmt: string;
    OnSale: Boolean;                // read-only
    Status: string;                 // publish, private, draft, pending
    Purchasable: Boolean;           // read-only
    [JsonName('virtual')]
    IsVirtual: Boolean;
    Downloadable: Boolean;
    Downloads: TArray<TWooFile>;
    DownloadLimit: Integer;         // -1 = unlimited
    DownloadExpiry: Integer;        // days, -1 = never
    TaxStatus: string;
    TaxClass: string;
    [JsonConverter(TWooManageStockConverter)]
    ManageStock: Boolean;           // False also when the parent product manages the stock
    StockQuantity: Integer;
    StockStatus: string;
    Backorders: string;
    BackordersAllowed: Boolean;     // read-only
    Backordered: Boolean;           // read-only
    Weight: string;
    Dimensions: TWooDimensions;
    ShippingClass: string;
    [JsonConverter(TWooTextConverter)]
    ShippingClassId: string;        // read-only
    Image: TWooImage;
    Attributes: TArray<TWooAttributeOption>;
    MenuOrder: Integer;
    MetaData: TArray<TWooMeta>;
    class operator Initialize(out Dest: TWooVariation);
  end;

  // A global attribute (Products > Attributes), with its terms at AttributeTerms(Id)
  TWooProductAttribute = record
    Id: Int64;
    Name: string;
    Slug: string;
    [JsonName('type')]
    AttributeType: string;          // select
    OrderBy: string;                // menu_order, name, name_num, id
    HasArchives: Boolean;
    class operator Initialize(out Dest: TWooProductAttribute);
  end;

  TWooAttributeTerm = record
    Id: Int64;
    Name: string;
    Slug: string;
    Description: string;
    MenuOrder: Integer;
    Count: Integer;                 // read-only
    class operator Initialize(out Dest: TWooAttributeTerm);
  end;

  TWooProductCategory = record
    Id: Int64;
    Name: string;
    Slug: string;
    Parent: Int64;
    Description: string;
    Display: string;                // default, products, subcategories, both
    Image: TWooImage;
    MenuOrder: Integer;
    Count: Integer;                 // read-only
    class operator Initialize(out Dest: TWooProductCategory);
  end;

  // Tags and shipping classes share this shape
  TWooProductTag = record
    Id: Int64;
    Name: string;
    Slug: string;
    Description: string;
    Count: Integer;                 // read-only
    class operator Initialize(out Dest: TWooProductTag);
  end;
  TWooShippingClass = TWooProductTag;

  TWooProductReview = record
    Id: Int64;
    DateCreated: string;            // read-only
    DateCreatedGmt: string;         // read-only
    ProductId: Int64;
    Status: string;                 // approved, hold, spam, unspam, trash, untrash
    Reviewer: string;
    ReviewerEmail: string;
    Review: string;
    Rating: Integer;                // 0..5
    Verified: Boolean;
    class operator Initialize(out Dest: TWooProductReview);
  end;

  { Orders }

  // A line of an order, or of a refund. RefundTotal/RefundTax are used only to create a refund.
  TWooOrderLine = record
    Id: Int64;
    Name: string;
    ProductId: Int64;
    VariationId: Int64;             // 0 for a simple product
    Quantity: Integer;
    TaxClass: string;
    Subtotal: string;               // before discounts
    SubtotalTax: string;            // read-only
    Total: string;                  // after discounts, tax excluded
    TotalTax: string;               // read-only
    Taxes: TArray<TWooLineTax>;     // read-only
    MetaData: TArray<TWooMeta>;
    Sku: string;                    // read-only
    [JsonConverter(TWooTextConverter)]
    Price: string;                  // read-only; WooCommerce sends a number here
    RefundTotal: string;            // refund create: amount for this line, tax excluded
    RefundTax: TArray<TWooLineTax>; // refund create: Id = tax rate, Total = amount
    class operator Initialize(out Dest: TWooOrderLine);
  end;

  TWooTaxLine = record
    Id: Int64;
    RateCode: string;
    RateId: Int64;
    [JsonName('label')]
    Caption: string;
    Compound: Boolean;
    TaxTotal: string;
    ShippingTaxTotal: string;
    MetaData: TArray<TWooMeta>;
  end;

  TWooShippingLine = record
    Id: Int64;
    MethodTitle: string;
    MethodId: string;
    Total: string;
    TotalTax: string;               // read-only
    Taxes: TArray<TWooLineTax>;     // read-only
    MetaData: TArray<TWooMeta>;
    class operator Initialize(out Dest: TWooShippingLine);
  end;

  TWooFeeLine = record
    Id: Int64;
    Name: string;
    TaxClass: string;
    TaxStatus: string;              // taxable, none
    Total: string;
    TotalTax: string;               // read-only
    Taxes: TArray<TWooLineTax>;     // read-only
    MetaData: TArray<TWooMeta>;
    class operator Initialize(out Dest: TWooFeeLine);
  end;

  TWooCouponLine = record
    Id: Int64;
    Code: string;
    Discount: string;               // read-only
    DiscountTax: string;            // read-only
    MetaData: TArray<TWooMeta>;
    class operator Initialize(out Dest: TWooCouponLine);
  end;

  TWooOrderRefundRef = record
    Id: Int64;
    Reason: string;
    Total: string;
  end;

  TWooOrder = record
    Id: Int64;
    ParentId: Int64;
    Number: string;                 // read-only
    OrderKey: string;               // read-only
    CreatedVia: string;             // set on create only
    Version: string;                // read-only
    Status: string;                 // pending, processing, on-hold, completed, cancelled, refunded, failed, trash
    Currency: string;
    DateCreated: string;            // read-only
    DateCreatedGmt: string;         // read-only
    DateModified: string;           // read-only
    DateModifiedGmt: string;        // read-only
    DiscountTotal: string;          // read-only
    DiscountTax: string;            // read-only
    ShippingTotal: string;          // read-only
    ShippingTax: string;            // read-only
    CartTax: string;                // read-only
    Total: string;                  // read-only
    TotalTax: string;               // read-only
    PricesIncludeTax: Boolean;      // read-only
    CustomerId: Int64;              // 0 for a guest order
    CustomerIpAddress: string;      // read-only
    CustomerUserAgent: string;      // read-only
    CustomerNote: string;
    Billing: TWooAddress;
    Shipping: TWooAddress;
    PaymentMethod: string;
    PaymentMethodTitle: string;
    TransactionId: string;
    DatePaid: string;               // read-only, '' when not paid yet
    DatePaidGmt: string;            // read-only
    DateCompleted: string;          // read-only
    DateCompletedGmt: string;       // read-only
    CartHash: string;               // read-only
    MetaData: TArray<TWooMeta>;
    LineItems: TArray<TWooOrderLine>;
    TaxLines: TArray<TWooTaxLine>;  // read-only
    ShippingLines: TArray<TWooShippingLine>;
    FeeLines: TArray<TWooFeeLine>;
    CouponLines: TArray<TWooCouponLine>;
    Refunds: TArray<TWooOrderRefundRef>; // read-only
    SetPaid: Boolean;               // write-only: on create, marks it paid (processing, stock reduced)
    class operator Initialize(out Dest: TWooOrder);
  end;

  TWooOrderNote = record
    Id: Int64;
    Author: string;                 // read-only
    DateCreated: string;            // read-only
    DateCreatedGmt: string;         // read-only
    Note: string;
    CustomerNote: Boolean;          // True = visible to the customer, who gets an e-mail
    AddedByUser: Boolean;
    class operator Initialize(out Dest: TWooOrderNote);
  end;

  TWooRefund = record
    Id: Int64;
    ParentId: Int64;                // the order; filled by the store-wide AllRefunds list
    DateCreated: string;            // read-only
    DateCreatedGmt: string;         // read-only
    Amount: string;                 // takes precedence over the line totals
    Reason: string;
    RefundedBy: Int64;
    RefundedPayment: Boolean;       // read-only
    MetaData: TArray<TWooMeta>;
    LineItems: TArray<TWooOrderLine>;
    TaxLines: TArray<TWooTaxLine>;  // read-only
    ShippingLines: TArray<TWooShippingLine>;
    FeeLines: TArray<TWooFeeLine>;
    ApiRefund: Boolean;             // write-only. False here (WooCommerce: True): set it to move money via the gateway
    ApiRestock: Boolean;            // write-only. True, as in WooCommerce: refunded items go back to stock
    class operator Initialize(out Dest: TWooRefund);
  end;

  TWooEmailTemplate = record
    Id: string;                     // e.g. customer_completed_order, customer_invoice
    Title: string;
    Description: string;
  end;

  { Customers }

  TWooCustomer = record
    Id: Int64;
    DateCreated: string;            // read-only
    DateCreatedGmt: string;         // read-only
    DateModified: string;           // read-only
    DateModifiedGmt: string;        // read-only
    Email: string;
    FirstName: string;
    LastName: string;
    Role: string;                   // read-only
    Username: string;
    Password: string;               // write-only
    Billing: TWooAddress;
    Shipping: TWooAddress;
    IsPayingCustomer: Boolean;      // read-only
    AvatarUrl: string;              // read-only
    MetaData: TArray<TWooMeta>;
    class operator Initialize(out Dest: TWooCustomer);
  end;

  TWooDownload = record
    DownloadId: string;
    DownloadUrl: string;
    ProductId: Int64;
    ProductName: string;
    DownloadName: string;
    OrderId: Int64;
    OrderKey: string;
    [JsonConverter(TWooTextConverter)]
    DownloadsRemaining: string;     // a number, or 'unlimited'
    AccessExpires: string;          // a date, or 'never'
    AccessExpiresGmt: string;
    [JsonName('file')]
    FileInfo: TWooFile;
  end;

  { Coupons }

  TWooCoupon = record
    Id: Int64;
    Code: string;
    Amount: string;                 // a number even for a percentage
    DateCreated: string;            // read-only
    DateCreatedGmt: string;         // read-only
    DateModified: string;           // read-only
    DateModifiedGmt: string;        // read-only
    DiscountType: string;           // percent, fixed_cart, fixed_product
    Description: string;
    DateExpires: string;
    DateExpiresGmt: string;
    UsageCount: Integer;            // read-only
    IndividualUse: Boolean;
    ProductIds: TArray<Int64>;
    ExcludedProductIds: TArray<Int64>;
    UsageLimit: Integer;            // 0 = unlimited
    UsageLimitPerUser: Integer;     // 0 = unlimited
    LimitUsageToXItems: Integer;    // 0 = no limit
    FreeShipping: Boolean;
    ProductCategories: TArray<Int64>;
    ExcludedProductCategories: TArray<Int64>;
    ExcludeSaleItems: Boolean;
    MinimumAmount: string;
    MaximumAmount: string;
    EmailRestrictions: TArray<string>;
    [JsonConverter(TWooTextConverter)]
    UsedBy: string;                 // read-only, JSON text: user IDs and guest e-mails
    MetaData: TArray<TWooMeta>;
    class operator Initialize(out Dest: TWooCoupon);
  end;

  { Taxes }

  TWooTaxRate = record
    Id: Int64;
    Country: string;                // '' = every country
    State: string;
    Postcode: string;               // deprecated since WooCommerce 5.3: use Postcodes
    City: string;                   // deprecated since WooCommerce 5.3: use Cities
    Postcodes: TArray<string>;
    Cities: TArray<string>;
    Rate: string;                   // percent, e.g. '22.0000'
    Name: string;
    Priority: Integer;              // 1 by default
    Compound: Boolean;
    Shipping: Boolean;              // True by default: the rate applies to shipping too
    Order: Integer;
    [JsonName('class')]
    RateClass: string;              // tax class slug, 'standard' or e.g. 'reduced-rate'
    class operator Initialize(out Dest: TWooTaxRate);
  end;

  TWooTaxClass = record
    Slug: string;                   // read-only
    Name: string;
  end;

  { Webhooks }

  TWooWebhook = record
    Id: Int64;
    Name: string;
    Status: string;                 // active, paused, disabled
    Topic: string;                  // e.g. order.created, product.updated
    Resource: string;               // read-only
    Event: string;                  // read-only
    Hooks: TArray<string>;          // read-only
    DeliveryUrl: string;
    Secret: string;                 // write-only: signs the payloads (X-WC-Webhook-Signature)
    DateCreated: string;            // read-only
    DateCreatedGmt: string;         // read-only
    DateModified: string;           // read-only
    DateModifiedGmt: string;        // read-only
    class operator Initialize(out Dest: TWooWebhook);
  end;

  { Settings and payment gateways }

  TWooSettingGroup = record
    Id: string;
    [JsonName('label')]
    Caption: string;
    Description: string;
    ParentId: string;
    [JsonConverter(TWooTextConverter)]
    SubGroups: string;              // JSON text
  end;

  TWooSetting = record
    Id: string;                     // e.g. woocommerce_currency
    [JsonName('label')]
    Caption: string;
    Description: string;
    [JsonConverter(TWooTextConverter)]
    Value: string;                  // JSON text for a multiselect: '["IT","FR"]'
    [JsonName('default'), JsonConverter(TWooTextConverter)]
    DefaultValue: string;
    Tip: string;
    Placeholder: string;
    [JsonName('type')]
    SettingType: string;            // text, email, number, color, password, textarea, select, multiselect, radio, image_width, checkbox
    [JsonConverter(TWooTextConverter)]
    Options: string;                // JSON text: {"value": "caption", ...}
    GroupId: string;
  end;

  TWooPaymentGateway = record
    Id: string;                     // e.g. bacs, cheque, cod, paypal
    Title: string;
    Description: string;
    [JsonConverter(TWooTextConverter)]
    Order: string;                  // a number, or '' when not sorted
    Enabled: Boolean;
    MethodTitle: string;            // read-only
    MethodDescription: string;      // read-only
    MethodSupports: TArray<string>; // read-only, e.g. products, refunds
    [JsonConverter(TWooTextConverter)]
    Settings: string;               // JSON text; to change one send '{"title":"Bank transfer"}'
  end;

  { Shipping }

  TWooShippingZone = record
    Id: Int64;                      // 0 = "Locations not covered by your other zones"
    Name: string;
    Order: Integer;
    class operator Initialize(out Dest: TWooShippingZone);
  end;

  TWooZoneLocation = record
    Code: string;                   // e.g. IT, IT:MI, EU, 20100, 20*
    [JsonName('type')]
    LocationType: string;           // postcode, state, country, continent
  end;

  TWooShippingZoneMethod = record
    InstanceId: Int64;
    Title: string;                  // read-only
    Order: Integer;
    Enabled: Boolean;               // True by default
    MethodId: string;               // flat_rate, free_shipping, local_pickup; required on create
    MethodTitle: string;            // read-only
    MethodDescription: string;      // read-only
    [JsonConverter(TWooTextConverter)]
    Settings: string;               // JSON text; to change one send '{"cost":"5.00"}'
    class operator Initialize(out Dest: TWooShippingZoneMethod);
  end;

  TWooShippingMethod = record
    Id: string;
    Title: string;
    Description: string;
  end;

  { Reports and data }

  // An entry of the reports or data index
  TWooIndexEntry = record
    Slug: string;
    Description: string;
  end;

  TWooSalesReport = record
    [JsonConverter(TWooTextConverter)]
    TotalSales: string;
    [JsonConverter(TWooTextConverter)]
    NetSales: string;
    [JsonConverter(TWooTextConverter)]
    AverageSales: string;
    TotalOrders: Integer;
    TotalItems: Integer;
    [JsonConverter(TWooTextConverter)]
    TotalTax: string;
    [JsonConverter(TWooTextConverter)]
    TotalShipping: string;
    [JsonConverter(TWooTextConverter)]
    TotalRefunds: string;
    [JsonConverter(TWooTextConverter)]
    TotalDiscount: string;
    TotalsGroupedBy: string;        // day, week, month
    [JsonConverter(TWooTextConverter)]
    Totals: string;                 // JSON text: {"2026-11-05": {"sales": ..., "orders": ...}, ...}
    TotalCustomers: Integer;
  end;

  TWooTopSeller = record
    Title: string;
    ProductId: Int64;
    Quantity: Integer;
  end;

  TWooReportTotal = record
    Slug: string;
    Name: string;
    [JsonConverter(TWooTextConverter)]
    Total: string;
  end;

  TWooState = record
    [JsonConverter(TWooTextConverter)]
    Code: string;                   // some countries' codes come as JSON numbers (PHP numeric array keys)
    Name: string;
  end;

  // Countries; continents fill the currency and unit fields too
  TWooCountry = record
    Code: string;                   // ISO 3166-1 alpha-2
    Name: string;
    CurrencyCode: string;
    CurrencyPos: string;
    DecimalSep: string;
    DimensionUnit: string;
    NumDecimals: Integer;
    States: TArray<TWooState>;
    ThousandSep: string;
    WeightUnit: string;
  end;

  TWooContinent = record
    Code: string;
    Name: string;
    Countries: TArray<TWooCountry>;
  end;

  TWooCurrency = record
    Code: string;                   // ISO 4217
    Name: string;
    Symbol: string;                 // may be an HTML entity, e.g. &euro;
  end;

  { System status }

  TWooEnvironment = record
    HomeUrl: string;
    SiteUrl: string;
    Version: string;                // WooCommerce
    LogDirectory: string;
    LogDirectoryWritable: Boolean;
    WpVersion: string;
    WpMultisite: Boolean;
    WpMemoryLimit: Int64;
    WpDebugMode: Boolean;
    WpCron: Boolean;
    WpEnvironmentType: string;
    Language: string;
    ServerInfo: string;
    PhpVersion: string;
    PhpPostMaxSize: Int64;
    PhpMaxExecutionTime: Integer;
    PhpMaxInputVars: Integer;
    CurlVersion: string;
    SuhosinInstalled: Boolean;
    MaxUploadSize: Int64;
    MysqlVersion: string;
    DefaultTimezone: string;
    FsockopenOrCurlEnabled: Boolean;
    SoapclientEnabled: Boolean;
    DomdocumentEnabled: Boolean;
    GzipEnabled: Boolean;
    MbstringEnabled: Boolean;
    RemotePostSuccessful: Boolean;
    [JsonConverter(TWooTextConverter)]
    RemotePostResponse: string;
    RemoteGetSuccessful: Boolean;
    [JsonConverter(TWooTextConverter)]
    RemoteGetResponse: string;
  end;

  TWooDatabase = record
    WcDatabaseVersion: string;
    DatabasePrefix: string;
    MaxmindGeoipDatabase: string;
    [JsonConverter(TWooTextConverter)]
    DatabaseTables: string;         // JSON text
  end;

  TWooPlugin = record
    Plugin: string;
    Name: string;
    Version: string;
    VersionLatest: string;
    Url: string;
    AuthorName: string;
    AuthorUrl: string;
    NetworkActivated: Boolean;
  end;

  TWooTheme = record
    Name: string;
    Version: string;
    VersionLatest: string;
    AuthorUrl: string;
    IsChildTheme: Boolean;
    HasWoocommerceSupport: Boolean;
    HasWoocommerceFile: Boolean;
    HasOutdatedTemplates: Boolean;
    [JsonConverter(TWooTextConverter)]
    Overrides: string;              // JSON text
    ParentName: string;
    ParentVersion: string;
    ParentAuthorUrl: string;
  end;

  TWooStoreSettings = record
    ApiEnabled: Boolean;
    ForceSsl: Boolean;
    Currency: string;
    CurrencySymbol: string;
    CurrencyPosition: string;
    ThousandSeparator: string;
    DecimalSeparator: string;
    NumberOfDecimals: Integer;
    GeolocationEnabled: Boolean;
    [JsonConverter(TWooTextConverter)]
    Taxonomies: string;             // JSON text
  end;

  TWooSecurity = record
    SecureConnection: Boolean;
    HideErrors: Boolean;
  end;

  TWooSystemPage = record
    PageName: string;
    [JsonConverter(TWooTextConverter)]
    PageId: string;
    PageSet: Boolean;
    PageExists: Boolean;
    PageVisible: Boolean;
    Shortcode: string;
    ShortcodeRequired: Boolean;
    ShortcodePresent: Boolean;
  end;

  TWooSystemStatus = record
    Environment: TWooEnvironment;
    Database: TWooDatabase;
    ActivePlugins: TArray<TWooPlugin>;
    Theme: TWooTheme;
    Settings: TWooStoreSettings;
    Security: TWooSecurity;
    Pages: TArray<TWooSystemPage>;
  end;

  TWooSystemTool = record
    Id: string;                     // e.g. clear_transients, recount_terms, regenerate_product_lookup_tables
    Name: string;
    Action: string;
    Description: string;
    Success: Boolean;               // after RunSystemTool
    Message: string;                // after RunSystemTool
  end;

implementation

uses
  System.SysUtils,
  System.Classes,
  System.JSON;

{ TWooManageStockConverter }

function TWooManageStockConverter.CanConvert(ATypeInf: PTypeInfo): Boolean;
begin
  Result := ATypeInf = TypeInfo(Boolean);
end;

function TWooManageStockConverter.ReadJson(const AReader: TJsonReader; ATypeInf: PTypeInfo;
  const AExistingValue: TValue; const ASerializer: TJsonSerializer): TValue;
begin
  Result := (AReader.TokenType = TJsonToken.Boolean) and AReader.Value.AsBoolean;
end;

procedure TWooManageStockConverter.WriteJson(const AWriter: TJsonWriter; const AValue: TValue;
  const ASerializer: TJsonSerializer);
begin
  AWriter.WriteValue(AValue.AsBoolean);
end;

{ TWooTextConverter }

function TWooTextConverter.CanConvert(ATypeInf: PTypeInfo): Boolean;
begin
  Result := ATypeInf = TypeInfo(string);
end;

function TWooTextConverter.ReadJson(const AReader: TJsonReader; ATypeInf: PTypeInfo;
  const AExistingValue: TValue; const ASerializer: TJsonSerializer): TValue;
begin
  case AReader.TokenType of
    TJsonToken.String:
      Result := AReader.Value.AsString;
    TJsonToken.Null, TJsonToken.Undefined:
      Result := '';
  else
    begin
      // the JSON writer formats numbers with invariant settings: 9.95 stays '9.95'
      var lText := TStringWriter.Create;
      var lWriter := TJsonTextWriter.Create(lText);
      try
        lWriter.WriteToken(AReader);
        lWriter.Flush;
        Result := lText.ToString;
      finally
        lWriter.Free;
        lText.Free;
      end;
    end;
  end;
end;

procedure TWooTextConverter.WriteJson(const AWriter: TJsonWriter; const AValue: TValue;
  const ASerializer: TJsonSerializer);
begin
  var lText := AValue.AsString;
  if lText.StartsWith('{') or lText.StartsWith('[') then
  begin
    var lJSON := TJSONValue.ParseJSONValue(lText);
    try
      if lJSON <> nil then
      begin
        AWriter.WriteRawValue(lText);
        Exit;
      end;
    finally
      lJSON.Free;
    end;
  end;
  AWriter.WriteValue(lText);
end;

{ Initialize: zero every field (managed ones are still nil here), then WooCommerce's defaults }

class operator TWooMeta.Initialize(out Dest: TWooMeta);
begin
  FillChar(Dest, SizeOf(Dest), 0);
end;

class operator TWooTermRef.Initialize(out Dest: TWooTermRef);
begin
  FillChar(Dest, SizeOf(Dest), 0);
end;

class operator TWooImage.Initialize(out Dest: TWooImage);
begin
  FillChar(Dest, SizeOf(Dest), 0);
end;

class operator TWooAttribute.Initialize(out Dest: TWooAttribute);
begin
  FillChar(Dest, SizeOf(Dest), 0);
end;

class operator TWooAttributeOption.Initialize(out Dest: TWooAttributeOption);
begin
  FillChar(Dest, SizeOf(Dest), 0);
end;

class operator TWooLineTax.Initialize(out Dest: TWooLineTax);
begin
  FillChar(Dest, SizeOf(Dest), 0);
end;

class operator TWooProduct.Initialize(out Dest: TWooProduct);
begin
  FillChar(Dest, SizeOf(Dest), 0);
  Dest.ReviewsAllowed := True;
  Dest.DownloadLimit := -1;
  Dest.DownloadExpiry := -1;
end;

class operator TWooVariation.Initialize(out Dest: TWooVariation);
begin
  FillChar(Dest, SizeOf(Dest), 0);
  Dest.DownloadLimit := -1;
  Dest.DownloadExpiry := -1;
end;

class operator TWooProductAttribute.Initialize(out Dest: TWooProductAttribute);
begin
  FillChar(Dest, SizeOf(Dest), 0);
end;

class operator TWooAttributeTerm.Initialize(out Dest: TWooAttributeTerm);
begin
  FillChar(Dest, SizeOf(Dest), 0);
end;

class operator TWooProductCategory.Initialize(out Dest: TWooProductCategory);
begin
  FillChar(Dest, SizeOf(Dest), 0);
end;

class operator TWooProductTag.Initialize(out Dest: TWooProductTag);
begin
  FillChar(Dest, SizeOf(Dest), 0);
end;

class operator TWooProductReview.Initialize(out Dest: TWooProductReview);
begin
  FillChar(Dest, SizeOf(Dest), 0);
end;

class operator TWooOrderLine.Initialize(out Dest: TWooOrderLine);
begin
  FillChar(Dest, SizeOf(Dest), 0);
end;

class operator TWooShippingLine.Initialize(out Dest: TWooShippingLine);
begin
  FillChar(Dest, SizeOf(Dest), 0);
end;

class operator TWooFeeLine.Initialize(out Dest: TWooFeeLine);
begin
  FillChar(Dest, SizeOf(Dest), 0);
end;

class operator TWooCouponLine.Initialize(out Dest: TWooCouponLine);
begin
  FillChar(Dest, SizeOf(Dest), 0);
end;

class operator TWooOrder.Initialize(out Dest: TWooOrder);
begin
  FillChar(Dest, SizeOf(Dest), 0);
end;

class operator TWooOrderNote.Initialize(out Dest: TWooOrderNote);
begin
  FillChar(Dest, SizeOf(Dest), 0);
end;

class operator TWooRefund.Initialize(out Dest: TWooRefund);
begin
  FillChar(Dest, SizeOf(Dest), 0);
  Dest.ApiRestock := True;
end;

class operator TWooCustomer.Initialize(out Dest: TWooCustomer);
begin
  FillChar(Dest, SizeOf(Dest), 0);
end;

class operator TWooCoupon.Initialize(out Dest: TWooCoupon);
begin
  FillChar(Dest, SizeOf(Dest), 0);
end;

class operator TWooTaxRate.Initialize(out Dest: TWooTaxRate);
begin
  FillChar(Dest, SizeOf(Dest), 0);
  Dest.Priority := 1;
  Dest.Shipping := True;
end;

class operator TWooWebhook.Initialize(out Dest: TWooWebhook);
begin
  FillChar(Dest, SizeOf(Dest), 0);
end;

class operator TWooShippingZone.Initialize(out Dest: TWooShippingZone);
begin
  FillChar(Dest, SizeOf(Dest), 0);
end;

class operator TWooShippingZoneMethod.Initialize(out Dest: TWooShippingZoneMethod);
begin
  FillChar(Dest, SizeOf(Dest), 0);
  Dest.Enabled := True;
end;

end.
