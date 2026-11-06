// Woo4Delphi by KD Software Srls - https://www.kdsoftware.it - info@kdsoftware.it
// Developer: Giordano Giaccaglia

unit Demo.Products;

// Products and their variations, through the typed records: what most integrations need.

interface

uses
  System.SysUtils,
  System.Classes,
  System.Net.URLClient,
  Vcl.Controls,
  Vcl.Forms,
  Vcl.StdCtrls,
  Vcl.ExtCtrls,
  Vcl.ComCtrls,
  Vcl.CheckLst,
  Vcl.Dialogs,
  Woo4Delphi.Types,
  Demo.Common;

type
  TProductsFrame = class(TFrame)
    PanelTop: TPanel;
    EditSearch: TEdit;
    ButtonList: TButton;
    LabelCount: TLabel;
    ListProducts: TListView;
    SplitterRight: TSplitter;
    PanelEdit: TScrollBox;
    LabelName: TLabel;
    EditName: TEdit;
    LabelSku: TLabel;
    EditSku: TEdit;
    LabelEan: TLabel;
    EditEan: TEdit;
    LabelRegularPrice: TLabel;
    EditRegularPrice: TEdit;
    LabelSalePrice: TLabel;
    EditSalePrice: TEdit;
    LabelStatus: TLabel;
    ComboStatus: TComboBox;
    CheckManageStock: TCheckBox;
    LabelStock: TLabel;
    EditStock: TEdit;
    LabelStockStatus: TLabel;
    ComboStockStatus: TComboBox;
    LabelCategories: TLabel;
    ListCategories: TCheckListBox;
    LabelImages: TLabel;
    ListImages: TListBox;
    PanelImageButtons: TPanel;
    ButtonImageFile: TButton;
    ButtonImageMain: TButton;
    ButtonImageRemove: TButton;
    PanelImageUrl: TPanel;
    EditImageUrl: TEdit;
    ButtonImageUrl: TButton;
    OpenDialogImage: TOpenDialog;
    ButtonAdd: TButton;
    ButtonSave: TButton;
    ButtonDuplicate: TButton;
    ButtonTrash: TButton;
    ButtonDelete: TButton;
    MemoJSON: TMemo;
    SplitterBottom: TSplitter;
    PanelVariations: TPanel;
    PanelVariationsTop: TPanel;
    ButtonVariations: TButton;
    EditVarPrice: TEdit;
    EditVarStock: TEdit;
    ButtonVarSave: TButton;
    EditVarAttribute: TEdit;
    EditVarOption: TEdit;
    ButtonVarAdd: TButton;
    ButtonVarDelete: TButton;
    ListVariations: TListView;
    procedure ButtonListClick(Sender: TObject);
    procedure ListProductsSelectItem(Sender: TObject; Item: TListItem; Selected: Boolean);
    procedure ButtonAddClick(Sender: TObject);
    procedure ButtonSaveClick(Sender: TObject);
    procedure ButtonDuplicateClick(Sender: TObject);
    procedure ButtonTrashClick(Sender: TObject);
    procedure ButtonDeleteClick(Sender: TObject);
    procedure ButtonVariationsClick(Sender: TObject);
    procedure ListVariationsSelectItem(Sender: TObject; Item: TListItem; Selected: Boolean);
    procedure ButtonVarSaveClick(Sender: TObject);
    procedure ButtonVarAddClick(Sender: TObject);
    procedure ButtonVarDeleteClick(Sender: TObject);
    procedure ButtonImageFileClick(Sender: TObject);
    procedure ButtonImageUrlClick(Sender: TObject);
    procedure ButtonImageMainClick(Sender: TObject);
    procedure ButtonImageRemoveClick(Sender: TObject);
  private
    fContext: TDemoContext;
    fProducts: TArray<TWooProduct>;
    fVariations: TArray<TWooVariation>;
    fCategories: TArray<TWooProductCategory>;  // the shop's categories, one checkbox each
    fImages: TArray<TWooImage>;  // the edited product's images: the first is the main one
    function Current: TWooProduct;
    procedure ShowImages;
    function CategoryIndex(const AID: Int64): Integer;
    procedure CheckSavedEan(const ASaved: TWooProduct);
    function CurrentVariation: TWooVariation;
    procedure ShowProducts;
    procedure ShowVariations;
    procedure ShowVariationRows;
    procedure EditsToProduct(var AProduct: TWooProduct);
  public
    procedure Setup(const AContext: TDemoContext);
    // Uploads the files to the media library and appends them to the images (ButtonImageFile's work)
    procedure UploadImages(const AFileNames: TStrings);
  end;

implementation

{$R *.dfm}

const
  // the JSON keys ButtonSave sends: every other field of the product stays as it is in the shop
  cEditedFields: array[0..10] of string = ('name', 'sku', 'global_unique_id', 'regular_price', 'sale_price', 'status',
    'manage_stock', 'stock_quantity', 'stock_status', 'categories', 'images');

procedure TProductsFrame.Setup(const AContext: TDemoContext);
begin
  fContext := AContext;
end;

function TProductsFrame.Current: TWooProduct;
begin
  if ListProducts.ItemIndex < 0 then
    raise Exception.Create('Seleziona un prodotto');
  Result := fProducts[ListProducts.ItemIndex];
end;

function TProductsFrame.CurrentVariation: TWooVariation;
begin
  if ListVariations.ItemIndex < 0 then
    raise Exception.Create('Seleziona una variazione');
  Result := fVariations[ListVariations.ItemIndex];
end;

function TProductsFrame.CategoryIndex(const AID: Int64): Integer;
begin
  Result := 0;
  for var lCategory in fCategories do
  begin
    if lCategory.Id = AID then
      Exit;
    Inc(Result);
  end;
  Result := -1;
end;

procedure TProductsFrame.CheckSavedEan(const ASaved: TWooProduct);
begin
  if ASaved.GlobalUniqueId <> Trim(EditEan.Text) then
    fContext.Log(Format('Attenzione: WooCommerce ha salvato l''EAN come "%s" (tiene solo cifre e trattini)',
      [ASaved.GlobalUniqueId]));
end;

procedure TProductsFrame.ShowImages;
begin
  ListImages.Items.Clear;
  for var lImage in fImages do
  begin
    var lRole := 'galleria';
    if ListImages.Items.Count = 0 then
      lRole := 'PRINCIPALE';
    var lName := lImage.Name;
    if lName = '' then
      lName := lImage.Src.Substring(lImage.Src.LastIndexOf('/') + 1);
    var lWhere := Format('id %d', [lImage.Id]);
    if lImage.Id = 0 then
      lWhere := 'da scaricare al salvataggio';
    ListImages.Items.Add(Format('%s: %s (%s)', [lRole, lName, lWhere]));
  end;
end;

procedure TProductsFrame.UploadImages(const AFileNames: TStrings);
begin
  fContext.Run('Carica immagini', procedure
    begin
      if (fContext.Woo.WordPressUser = '') or (fContext.Woo.WordPressAppPassword = '') then
        raise Exception.Create('Per caricare immagini compila "Utente WordPress" e "Password per le applicazioni" ' +
          'nella seconda riga in alto (WooCommerce non ha un caricamento di file: serve WordPress)');
      for var lFileName in AFileNames do
      begin
        var lImage := fContext.Woo.UploadImage(lFileName);
        fImages := fImages + [lImage];  // one by one: an error keeps the files uploaded so far
        ShowImages;
        PanelEdit.ScrollInView(ListImages);  // the list sits below the fold of the edit panel
        fContext.Log(Format('Caricata %s: id %d, %s', [ExtractFileName(lFileName), lImage.Id, lImage.Src]));
      end;
      fContext.Log('Le immagini sono nella libreria media: premi "Salva modifiche" per collegarle al prodotto');
    end);
end;

procedure TProductsFrame.ButtonImageFileClick(Sender: TObject);
begin
  if OpenDialogImage.Execute then
    UploadImages(OpenDialogImage.Files);
end;

procedure TProductsFrame.ButtonImageUrlClick(Sender: TObject);
begin
  if Trim(EditImageUrl.Text) = '' then
    Exit;
  var lImage: TWooImage;  // Id 0: WooCommerce downloads Src into the media library when the product is saved
  lImage.Src := Trim(EditImageUrl.Text);
  fImages := fImages + [lImage];
  ShowImages;
  EditImageUrl.Clear;
end;

procedure TProductsFrame.ButtonImageMainClick(Sender: TObject);
begin
  var lIndex := ListImages.ItemIndex;
  if lIndex <= 0 then
    Exit;
  var lImage := fImages[lIndex];
  Delete(fImages, lIndex, 1);
  Insert(lImage, fImages, 0);
  ShowImages;
  ListImages.ItemIndex := 0;
end;

procedure TProductsFrame.ButtonImageRemoveClick(Sender: TObject);
begin
  if ListImages.ItemIndex < 0 then
    Exit;
  Delete(fImages, ListImages.ItemIndex, 1);  // off the product only: the file stays in the media library
  ShowImages;
end;

procedure TProductsFrame.ShowProducts;
begin
  var lSelected := ListProducts.ItemIndex;  // kept across the refill, so the buttons keep working
  ListProducts.Items.BeginUpdate;
  try
    ListProducts.Items.Clear;
    for var lProduct in fProducts do
      AddRow(ListProducts, [lProduct.Id.ToString, lProduct.Name, lProduct.Sku, lProduct.ProductType, lProduct.Price,
        if lProduct.ManageStock then lProduct.StockQuantity.ToString else lProduct.StockStatus]);
  finally
    ListProducts.Items.EndUpdate;
  end;
  if lSelected < ListProducts.Items.Count then
    ListProducts.ItemIndex := lSelected;
  LabelCount.Caption := Format('%d prodotti', [Length(fProducts)]);
end;

procedure TProductsFrame.ShowVariations;
begin
  var lSelected := ListVariations.ItemIndex;
  try
    ShowVariationRows;
  finally
    if lSelected < ListVariations.Items.Count then
      ListVariations.ItemIndex := lSelected;
  end;
end;

procedure TProductsFrame.ShowVariationRows;
begin
  ListVariations.Items.BeginUpdate;
  try
    ListVariations.Items.Clear;
    for var lVariation in fVariations do
    begin
      var lAttributes := '';
      for var lAttribute in lVariation.Attributes do
        lAttributes := lAttributes + lAttribute.Name + '=' + lAttribute.Option + ' ';
      AddRow(ListVariations, [lVariation.Id.ToString, lVariation.Sku, lAttributes.Trim, lVariation.RegularPrice,
        if lVariation.ManageStock then lVariation.StockQuantity.ToString else lVariation.StockStatus]);
    end;
  finally
    ListVariations.Items.EndUpdate;
  end;
end;

procedure TProductsFrame.EditsToProduct(var AProduct: TWooProduct);
begin
  AProduct.Name := EditName.Text;
  AProduct.Sku := EditSku.Text;
  AProduct.GlobalUniqueId := Trim(EditEan.Text);
  AProduct.RegularPrice := EditRegularPrice.Text;
  AProduct.SalePrice := EditSalePrice.Text;
  AProduct.Status := ComboStatus.Text;
  AProduct.ManageStock := CheckManageStock.Checked;
  AProduct.StockQuantity := StrToIntDef(EditStock.Text, 0);
  AProduct.StockStatus := ComboStockStatus.Text;  // WooCommerce recomputes it from the quantity when ManageStock
  AProduct.Images := nil;
  for var lImage in fImages do
  begin
    // id and src only: the Name WooCommerce returns has curled quotes, sent back it would rename the file
    var lSent: TWooImage;
    lSent.Id := lImage.Id;
    lSent.Src := lImage.Src;
    AProduct.Images := AProduct.Images + [lSent];
  end;
  if fCategories = nil then
    Exit;  // categories never loaded: leave the product's as they are
  var lCategories: TArray<TWooTermRef> := nil;
  for var lRef in AProduct.Categories do
    if CategoryIndex(lRef.Id) < 0 then  // created after the list was loaded: no checkbox, keep it
      lCategories := lCategories + [lRef];
  for var i := 0 to ListCategories.Items.Count - 1 do  // one checkbox per fCategories item
    if ListCategories.Checked[i] then
    begin
      var lRef: TWooTermRef;  // on write WooCommerce reads only the id
      lRef.Id := fCategories[i].Id;
      lRef.Name := fCategories[i].Name;
      lCategories := lCategories + [lRef];
    end;
  AProduct.Categories := lCategories;  // none: WooCommerce puts the product in the default category
end;

procedure TProductsFrame.ButtonListClick(Sender: TObject);
begin
  fContext.Run('Elenco prodotti', procedure
    begin
      var lParams: TArray<TNameValuePair> := nil;
      if EditSearch.Text <> '' then
        lParams := [TNameValuePair.Create('search', EditSearch.Text)];
      fCategories := fContext.Woo.Categories.List;  // before ShowProducts: reselecting a row checks the boxes
      ListCategories.Items.Clear;
      for var lCategory in fCategories do
        ListCategories.Items.Add(lCategory.Name);
      fProducts := fContext.Woo.Products.List(lParams);
      ShowProducts;
    end);
end;

procedure TProductsFrame.ListProductsSelectItem(Sender: TObject; Item: TListItem; Selected: Boolean);
begin
  if not Selected or (ListProducts.ItemIndex < 0) then
    Exit;
  var lProduct := Current;
  EditName.Text := lProduct.Name;
  EditSku.Text := lProduct.Sku;
  EditEan.Text := lProduct.GlobalUniqueId;
  EditRegularPrice.Text := lProduct.RegularPrice;
  EditSalePrice.Text := lProduct.SalePrice;
  ComboStatus.ItemIndex := ComboStatus.Items.IndexOf(lProduct.Status);
  CheckManageStock.Checked := lProduct.ManageStock;
  EditStock.Text := lProduct.StockQuantity.ToString;
  ComboStockStatus.ItemIndex := ComboStockStatus.Items.IndexOf(lProduct.StockStatus);
  fImages := lProduct.Images;
  ShowImages;
  for var i := 0 to ListCategories.Items.Count - 1 do
    ListCategories.Checked[i] := False;
  for var lRef in lProduct.Categories do
    if CategoryIndex(lRef.Id) >= 0 then
      ListCategories.Checked[CategoryIndex(lRef.Id)] := True;
  MemoJSON.Text := PrettyJSON(fContext.Woo.ToJSON<TWooProduct>(lProduct));
  fVariations := nil;
  ShowVariations;
end;

procedure TProductsFrame.ButtonAddClick(Sender: TObject);
begin
  fContext.Run('Crea prodotto', procedure
    begin
      var lProduct: TWooProduct;  // initializes itself: no garbage reaches the shop
      lProduct.ProductType := 'simple';
      EditsToProduct(lProduct);
      lProduct := fContext.Woo.Products.Add(lProduct);
      CheckSavedEan(lProduct);
      fProducts := fProducts + [lProduct];
      ShowProducts;
      fContext.Log(Format('Creato il prodotto %d "%s"', [lProduct.Id, lProduct.Name]));
    end);
end;

procedure TProductsFrame.ButtonSaveClick(Sender: TObject);
begin
  fContext.Run('Salva prodotto', procedure
    begin
      var lIndex := ListProducts.ItemIndex;
      var lProduct := Current;
      EditsToProduct(lProduct);
      fProducts[lIndex] := fContext.Woo.Products.Update(lProduct, cEditedFields);
      CheckSavedEan(fProducts[lIndex]);
      if lProduct.ManageStock and (fProducts[lIndex].StockStatus <> lProduct.StockStatus) then
        fContext.Log('Stato magazzino calcolato da WooCommerce dalla quantit'#$E0': ' + fProducts[lIndex].StockStatus);
      ShowProducts;
    end);
end;

procedure TProductsFrame.ButtonDuplicateClick(Sender: TObject);
begin
  fContext.Run('Duplica prodotto', procedure
    begin
      var lCopy := fContext.Woo.DuplicateProduct(Current.Id);
      fProducts := fProducts + [lCopy];
      ShowProducts;
      fContext.Log(Format('Copia creata: %d "%s" (%s)', [lCopy.Id, lCopy.Name, lCopy.Status]));
    end);
end;

procedure TProductsFrame.ButtonTrashClick(Sender: TObject);
begin
  fContext.Run('Prodotto nel cestino', procedure
    begin
      var lProduct := Current;
      if fContext.Confirm(Format('Spostare "%s" nel cestino?', [lProduct.Name])) then
        fProducts[ListProducts.ItemIndex] := fContext.Woo.Products.Delete(lProduct.Id);
      ShowProducts;
    end);
end;

procedure TProductsFrame.ButtonDeleteClick(Sender: TObject);
begin
  fContext.Run('Elimina prodotto', procedure
    begin
      var lProduct := Current;
      if not fContext.Confirm(Format('Eliminare DEFINITIVAMENTE "%s"?', [lProduct.Name])) then
        Exit;
      fContext.Woo.Products.Delete(lProduct.Id, True);
      Delete(fProducts, ListProducts.ItemIndex, 1);
      ShowProducts;
    end);
end;

procedure TProductsFrame.ButtonVariationsClick(Sender: TObject);
begin
  fContext.Run('Elenco variazioni', procedure
    begin
      fVariations := fContext.Woo.Variations(Current.Id).List;
      ShowVariations;
    end);
end;

procedure TProductsFrame.ListVariationsSelectItem(Sender: TObject; Item: TListItem; Selected: Boolean);
begin
  if not Selected or (ListVariations.ItemIndex < 0) then
    Exit;
  var lVariation := CurrentVariation;
  EditVarPrice.Text := lVariation.RegularPrice;
  EditVarStock.Text := if lVariation.ManageStock then lVariation.StockQuantity.ToString else '';
end;

procedure TProductsFrame.ButtonVarSaveClick(Sender: TObject);
begin
  fContext.Run('Salva variazione', procedure
    begin
      var lIndex := ListVariations.ItemIndex;
      var lVariation := CurrentVariation;
      lVariation.RegularPrice := EditVarPrice.Text;
      lVariation.ManageStock := EditVarStock.Text <> '';  // empty stock = managed by the parent product
      lVariation.StockQuantity := StrToIntDef(EditVarStock.Text, 0);
      fVariations[lIndex] := fContext.Woo.Variations(Current.Id).Update(lVariation,
        ['regular_price', 'manage_stock', 'stock_quantity']);
      ShowVariations;
    end);
end;

procedure TProductsFrame.ButtonVarAddClick(Sender: TObject);
begin
  fContext.Run('Crea variazione', procedure
    begin
      var lVariation: TWooVariation;
      lVariation.RegularPrice := EditVarPrice.Text;
      lVariation.ManageStock := EditVarStock.Text <> '';
      lVariation.StockQuantity := StrToIntDef(EditVarStock.Text, 0);
      SetLength(lVariation.Attributes, 1);
      lVariation.Attributes[0].Name := EditVarAttribute.Text;
      lVariation.Attributes[0].Option := EditVarOption.Text;
      fVariations := fVariations + [fContext.Woo.Variations(Current.Id).Add(lVariation)];
      ShowVariations;
    end);
end;

procedure TProductsFrame.ButtonVarDeleteClick(Sender: TObject);
begin
  fContext.Run('Elimina variazione', procedure
    begin
      var lVariation := CurrentVariation;
      if not fContext.Confirm(Format('Eliminare la variazione %d? Le variazioni non hanno cestino.', [lVariation.Id])) then
        Exit;
      fContext.Woo.Variations(Current.Id).Delete(lVariation.Id);
      Delete(fVariations, ListVariations.ItemIndex, 1);
      ShowVariations;
    end);
end;

end.
