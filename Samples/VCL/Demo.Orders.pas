// Woo4Delphi by KD Software Srls - https://www.kdsoftware.it - info@kdsoftware.it
// Developer: Giordano Giaccaglia

unit Demo.Orders;

// Orders: list by status, detail, status change, notes, refunds, e-mails, a test order.

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
  Woo4Delphi.Types,
  Demo.Common;

type
  TOrdersFrame = class(TFrame)
    PanelTop: TPanel;
    ComboFilter: TComboBox;
    ButtonList: TButton;
    LabelCount: TLabel;
    ListOrders: TListView;
    SplitterRight: TSplitter;
    PanelDetail: TPanel;
    MemoOrder: TMemo;
    PanelStatus: TPanel;
    ComboStatus: TComboBox;
    ButtonStatus: TButton;
    LabelNotes: TLabel;
    ListNotes: TListBox;
    PanelNote: TPanel;
    EditNote: TEdit;
    CheckCustomerNote: TCheckBox;
    ButtonAddNote: TButton;
    ButtonDeleteNote: TButton;
    LabelRefunds: TLabel;
    ListRefunds: TListBox;
    PanelRefund: TPanel;
    EditRefundAmount: TEdit;
    EditRefundReason: TEdit;
    CheckApiRefund: TCheckBox;
    ButtonRefund: TButton;
    PanelEmail: TPanel;
    ComboTemplates: TComboBox;
    ButtonSendEmail: TButton;
    PanelNewOrder: TPanel;
    EditNewProduct: TEdit;
    EditNewQuantity: TEdit;
    EditNewEmail: TEdit;
    CheckSetPaid: TCheckBox;
    ButtonCreateOrder: TButton;
    procedure ButtonListClick(Sender: TObject);
    procedure ListOrdersSelectItem(Sender: TObject; Item: TListItem; Selected: Boolean);
    procedure ButtonStatusClick(Sender: TObject);
    procedure ButtonAddNoteClick(Sender: TObject);
    procedure ButtonDeleteNoteClick(Sender: TObject);
    procedure ButtonRefundClick(Sender: TObject);
    procedure ButtonSendEmailClick(Sender: TObject);
    procedure ButtonCreateOrderClick(Sender: TObject);
  private
    fContext: TDemoContext;
    fOrders: TArray<TWooOrder>;
    fNotes: TArray<TWooOrderNote>;
    fTemplates: TArray<TWooEmailTemplate>;
    function Current: TWooOrder;
    procedure ShowOrders;
    procedure ShowOrderRows;
    procedure ShowDetail(const AOrder: TWooOrder);
  public
    procedure Setup(const AContext: TDemoContext);
  end;

implementation

{$R *.dfm}

procedure TOrdersFrame.Setup(const AContext: TDemoContext);
begin
  fContext := AContext;
end;

function TOrdersFrame.Current: TWooOrder;
begin
  if ListOrders.ItemIndex < 0 then
    raise Exception.Create('Seleziona un ordine');
  Result := fOrders[ListOrders.ItemIndex];
end;

procedure TOrdersFrame.ShowOrders;
begin
  var lSelected := ListOrders.ItemIndex;  // kept across the refill, so the buttons keep working
  try
    ShowOrderRows;
  finally
    if lSelected < ListOrders.Items.Count then
      ListOrders.ItemIndex := lSelected;
  end;
end;

procedure TOrdersFrame.ShowOrderRows;
begin
  ListOrders.Items.BeginUpdate;
  try
    ListOrders.Items.Clear;
    for var lOrder in fOrders do
      AddRow(ListOrders, [lOrder.Id.ToString, lOrder.Number, lOrder.DateCreated, lOrder.Status,
        Trim(lOrder.Billing.FirstName + ' ' + lOrder.Billing.LastName), lOrder.Total + ' ' + lOrder.Currency]);
  finally
    ListOrders.Items.EndUpdate;
  end;
  LabelCount.Caption := Format('%d ordini', [Length(fOrders)]);
end;

procedure TOrdersFrame.ShowDetail(const AOrder: TWooOrder);
begin
  MemoOrder.Lines.BeginUpdate;
  try
    MemoOrder.Lines.Clear;
    MemoOrder.Lines.Add(Format('Ordine %s (id %d) - %s - %s', [AOrder.Number, AOrder.Id, AOrder.Status, AOrder.DateCreated]));
    MemoOrder.Lines.Add(Format('Cliente: %s %s <%s>  id %d', [AOrder.Billing.FirstName, AOrder.Billing.LastName,
      AOrder.Billing.Email, AOrder.CustomerId]));
    MemoOrder.Lines.Add(Format('Fatturazione: %s, %s %s (%s)', [AOrder.Billing.Address1, AOrder.Billing.Postcode,
      AOrder.Billing.City, AOrder.Billing.Country]));
    MemoOrder.Lines.Add(Format('Spedizione: %s, %s %s (%s)', [AOrder.Shipping.Address1, AOrder.Shipping.Postcode,
      AOrder.Shipping.City, AOrder.Shipping.Country]));
    MemoOrder.Lines.Add(Format('Pagamento: %s  pagato il %s', [AOrder.PaymentMethodTitle, AOrder.DatePaid]));
    MemoOrder.Lines.Add('');
    for var lLine in AOrder.LineItems do
      MemoOrder.Lines.Add(Format('%4d x %-30s  %10s  (prodotto %d, variazione %d)', [lLine.Quantity, lLine.Name,
        lLine.Total, lLine.ProductId, lLine.VariationId]));
    for var lShipping in AOrder.ShippingLines do
      MemoOrder.Lines.Add(Format('       %-30s  %10s', [lShipping.MethodTitle, lShipping.Total]));
    MemoOrder.Lines.Add(Format('Totale %s %s (IVA %s, sconti %s)', [AOrder.Total, AOrder.Currency, AOrder.TotalTax,
      AOrder.DiscountTotal]));
  finally
    MemoOrder.Lines.EndUpdate;
  end;
end;

procedure TOrdersFrame.ButtonListClick(Sender: TObject);
begin
  fContext.Run('Elenco ordini', procedure
    begin
      var lParams: TArray<TNameValuePair> := nil;
      if ComboFilter.ItemIndex > 0 then
        lParams := [TNameValuePair.Create('status', ComboFilter.Text)];
      fOrders := fContext.Woo.Orders.List(lParams);
      ShowOrders;
    end);
end;

procedure TOrdersFrame.ListOrdersSelectItem(Sender: TObject; Item: TListItem; Selected: Boolean);
begin
  if not Selected or (ListOrders.ItemIndex < 0) then
    Exit;
  var lOrder := Current;
  ShowDetail(lOrder);
  ComboStatus.ItemIndex := ComboStatus.Items.IndexOf(lOrder.Status);
  fContext.Run('Note, rimborsi e modelli e-mail', procedure
    begin
      fNotes := fContext.Woo.OrderNotes(lOrder.Id).List;
      ListNotes.Items.Clear;
      for var lNote in fNotes do
        ListNotes.Items.Add(Format('%s  %s%s', [lNote.DateCreated, if lNote.CustomerNote then '[cliente] ' else '',
          lNote.Note]));
      ListRefunds.Items.Clear;
      for var lRefund in fContext.Woo.Refunds(lOrder.Id).List do
        ListRefunds.Items.Add(Format('%s  %s  %s', [lRefund.DateCreated, lRefund.Amount, lRefund.Reason]));
      fTemplates := fContext.Woo.OrderEmailTemplates(lOrder.Id);
      ComboTemplates.Items.Clear;
      ComboTemplates.Items.Add('Dettagli ordine (fattura)');
      for var lTemplate in fTemplates do
        ComboTemplates.Items.Add(lTemplate.Title + ' (' + lTemplate.Id + ')');
      ComboTemplates.ItemIndex := 0;
    end);
end;

procedure TOrdersFrame.ButtonStatusClick(Sender: TObject);
begin
  fContext.Run('Cambia stato', procedure
    begin
      var lIndex := ListOrders.ItemIndex;
      var lOrder := Current;
      if not fContext.Confirm(Format('Portare l''ordine %s a "%s"? WooCommerce invia le sue e-mail al cliente.',
        [lOrder.Number, ComboStatus.Text])) then
        Exit;
      fOrders[lIndex] := fContext.Woo.UpdateOrderStatus(lOrder.Id, ComboStatus.Text);
      ShowOrders;
      ShowDetail(fOrders[lIndex]);
    end);
end;

procedure TOrdersFrame.ButtonAddNoteClick(Sender: TObject);
begin
  fContext.Run('Aggiungi nota', procedure
    begin
      var lNote: TWooOrderNote;
      lNote.Note := EditNote.Text;
      lNote.CustomerNote := CheckCustomerNote.Checked;  // True: the customer sees it and gets an e-mail
      lNote := fContext.Woo.OrderNotes(Current.Id).Add(lNote);
      fNotes := fNotes + [lNote];
      ListNotes.Items.Add(lNote.DateCreated + '  ' + lNote.Note);
      EditNote.Clear;
    end);
end;

procedure TOrdersFrame.ButtonDeleteNoteClick(Sender: TObject);
begin
  fContext.Run('Elimina nota', procedure
    begin
      if ListNotes.ItemIndex < 0 then
        raise Exception.Create('Seleziona una nota');
      var lIndex := ListNotes.ItemIndex;
      if not fContext.Confirm('Eliminare la nota selezionata?') then
        Exit;
      fContext.Woo.OrderNotes(Current.Id).Delete(fNotes[lIndex].Id);
      Delete(fNotes, lIndex, 1);
      ListNotes.Items.Delete(lIndex);
    end);
end;

procedure TOrdersFrame.ButtonRefundClick(Sender: TObject);
begin
  fContext.Run('Rimborso', procedure
    begin
      var lOrder := Current;
      var lRefund: TWooRefund;  // ApiRestock = True, ApiRefund = False unless checked
      lRefund.Amount := EditRefundAmount.Text;
      lRefund.Reason := EditRefundReason.Text;
      lRefund.ApiRefund := CheckApiRefund.Checked;
      if not fContext.Confirm(Format('Rimborsare %s %s sull''ordine %s%s?', [lRefund.Amount, lOrder.Currency,
        lOrder.Number, if lRefund.ApiRefund then ' TRAMITE IL GATEWAY (movimento di denaro reale)' else ''])) then
        Exit;
      lRefund := fContext.Woo.Refunds(lOrder.Id).Add(lRefund);
      ListRefunds.Items.Add(Format('%s  %s  %s', [lRefund.DateCreated, lRefund.Amount, lRefund.Reason]));
    end);
end;

procedure TOrdersFrame.ButtonSendEmailClick(Sender: TObject);
begin
  fContext.Run('Invia e-mail', procedure
    begin
      var lTemplateID := '';
      if ComboTemplates.ItemIndex > 0 then
        lTemplateID := fTemplates[ComboTemplates.ItemIndex - 1].Id;
      fContext.Log(fContext.Woo.SendOrderEmail(Current.Id, lTemplateID));
    end);
end;

procedure TOrdersFrame.ButtonCreateOrderClick(Sender: TObject);
begin
  fContext.Run('Crea ordine', procedure
    begin
      var lOrder: TWooOrder;
      lOrder.Status := 'pending';
      lOrder.SetPaid := CheckSetPaid.Checked;
      lOrder.Billing.Email := EditNewEmail.Text;
      SetLength(lOrder.LineItems, 1);
      lOrder.LineItems[0].ProductId := StrToInt64(EditNewProduct.Text);
      lOrder.LineItems[0].Quantity := StrToIntDef(EditNewQuantity.Text, 1);
      lOrder := fContext.Woo.Orders.Add(lOrder);
      fOrders := fOrders + [lOrder];
      ShowOrders;
      fContext.Log(Format('Creato l''ordine %s (id %d), totale %s', [lOrder.Number, lOrder.Id, lOrder.Total]));
    end);
end;

end.
