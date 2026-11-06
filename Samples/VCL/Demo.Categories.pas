// Woo4Delphi by KD Software Srls - https://www.kdsoftware.it - info@kdsoftware.it
// Developer: Giordano Giaccaglia

unit Demo.Categories;

// Product categories: list, create, rename, move under another category, delete.

interface

uses
  System.SysUtils,
  System.Classes,
  Vcl.Controls,
  Vcl.Forms,
  Vcl.StdCtrls,
  Vcl.ExtCtrls,
  Vcl.ComCtrls,
  Woo4Delphi.Types,
  Demo.Common;

type
  TCategoriesFrame = class(TFrame)
    PanelTop: TPanel;
    ButtonList: TButton;
    LabelCount: TLabel;
    ListCategories: TListView;
    SplitterRight: TSplitter;
    PanelEdit: TPanel;
    LabelName: TLabel;
    EditName: TEdit;
    LabelSlug: TLabel;
    EditSlug: TEdit;
    LabelParent: TLabel;
    ComboParent: TComboBox;
    LabelDescription: TLabel;
    MemoDescription: TMemo;
    ButtonAdd: TButton;
    ButtonSave: TButton;
    ButtonDelete: TButton;
    procedure ButtonListClick(Sender: TObject);
    procedure ListCategoriesSelectItem(Sender: TObject; Item: TListItem; Selected: Boolean);
    procedure ButtonAddClick(Sender: TObject);
    procedure ButtonSaveClick(Sender: TObject);
    procedure ButtonDeleteClick(Sender: TObject);
  private
    fContext: TDemoContext;
    fCategories: TArray<TWooProductCategory>;
    function Current: TWooProductCategory;
    function CategoryIndex(const AID: Int64): Integer;
    procedure ShowCategories;
    procedure EditsToCategory(var ACategory: TWooProductCategory);
  public
    procedure Setup(const AContext: TDemoContext);
  end;

implementation

{$R *.dfm}

procedure TCategoriesFrame.Setup(const AContext: TDemoContext);
begin
  fContext := AContext;
end;

function TCategoriesFrame.Current: TWooProductCategory;
begin
  if ListCategories.ItemIndex < 0 then
    raise Exception.Create('Seleziona una categoria');
  Result := fCategories[ListCategories.ItemIndex];
end;

function TCategoriesFrame.CategoryIndex(const AID: Int64): Integer;
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

procedure TCategoriesFrame.ShowCategories;
begin
  var lSelected := ListCategories.ItemIndex;  // kept across the refill, so the buttons keep working
  // the parent combo first: reselecting a row sets it
  ComboParent.Items.Clear;
  ComboParent.Items.Add('(nessuna: categoria principale)');
  for var lCategory in fCategories do
    ComboParent.Items.Add(Format('%s (%d)', [lCategory.Name, lCategory.Id]));
  ListCategories.Items.BeginUpdate;
  try
    ListCategories.Items.Clear;
    for var lCategory in fCategories do
    begin
      var lParent := '';
      if CategoryIndex(lCategory.Parent) >= 0 then
        lParent := fCategories[CategoryIndex(lCategory.Parent)].Name;
      AddRow(ListCategories, [lCategory.Id.ToString, lCategory.Name, lCategory.Slug, lParent, lCategory.Count.ToString]);
    end;
  finally
    ListCategories.Items.EndUpdate;
  end;
  if lSelected < ListCategories.Items.Count then
    ListCategories.ItemIndex := lSelected;
  LabelCount.Caption := Format('%d categorie', [Length(fCategories)]);
end;

procedure TCategoriesFrame.EditsToCategory(var ACategory: TWooProductCategory);
begin
  ACategory.Name := EditName.Text;
  ACategory.Slug := Trim(EditSlug.Text);  // empty: WooCommerce derives it from the name
  ACategory.Parent := 0;
  if ComboParent.ItemIndex > 0 then
    ACategory.Parent := fCategories[ComboParent.ItemIndex - 1].Id;
  ACategory.Description := MemoDescription.Text;
end;

procedure TCategoriesFrame.ButtonListClick(Sender: TObject);
begin
  fContext.Run('Elenco categorie', procedure
    begin
      fCategories := fContext.Woo.Categories.List;
      ShowCategories;
    end);
end;

procedure TCategoriesFrame.ListCategoriesSelectItem(Sender: TObject; Item: TListItem; Selected: Boolean);
begin
  if not Selected or (ListCategories.ItemIndex < 0) then
    Exit;
  var lCategory := Current;
  EditName.Text := lCategory.Name;
  EditSlug.Text := lCategory.Slug;
  ComboParent.ItemIndex := CategoryIndex(lCategory.Parent) + 1;  // not found (-1) or none: item 0
  MemoDescription.Text := lCategory.Description;
end;

procedure TCategoriesFrame.ButtonAddClick(Sender: TObject);
begin
  fContext.Run('Crea categoria', procedure
    begin
      var lCategory: TWooProductCategory;
      EditsToCategory(lCategory);
      lCategory := fContext.Woo.Categories.Add(lCategory);
      fCategories := fCategories + [lCategory];
      ShowCategories;
      fContext.Log(Format('Creata la categoria %d "%s" (slug %s)', [lCategory.Id, lCategory.Name, lCategory.Slug]));
    end);
end;

procedure TCategoriesFrame.ButtonSaveClick(Sender: TObject);
begin
  fContext.Run('Salva categoria', procedure
    begin
      var lIndex := ListCategories.ItemIndex;
      var lCategory := Current;
      EditsToCategory(lCategory);
      fCategories[lIndex] := fContext.Woo.Categories.Update(lCategory, ['name', 'slug', 'parent', 'description']);
      ShowCategories;
    end);
end;

procedure TCategoriesFrame.ButtonDeleteClick(Sender: TObject);
begin
  fContext.Run('Elimina categoria', procedure
    begin
      var lCategory := Current;
      if not fContext.Confirm(Format('Eliminare la categoria "%s"? Le categorie non hanno cestino. I suoi %d prodotti ' +
        'restano: chi non ha altre categorie passa a quella predefinita.', [lCategory.Name, lCategory.Count])) then
        Exit;
      fContext.Woo.Categories.Delete(lCategory.Id);
      fCategories := fContext.Woo.Categories.List;  // reloaded: WordPress also moves the children up a level
      ShowCategories;
    end);
end;

end.
