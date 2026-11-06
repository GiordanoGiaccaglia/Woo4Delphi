// Woo4Delphi by KD Software Srls - https://www.kdsoftware.it - info@kdsoftware.it
// Developer: Giordano Giaccaglia

unit Demo.Raw;

// The raw layer: any method on any endpoint, for what the typed records do not cover.

interface

uses
  System.SysUtils,
  System.Classes,
  Vcl.Controls,
  Vcl.Forms,
  Vcl.StdCtrls,
  Vcl.ExtCtrls,
  Demo.Common;

type
  TRawFrame = class(TFrame)
    PanelTop: TPanel;
    ComboMethod: TComboBox;
    EditEndpoint: TEdit;
    ButtonSend: TButton;
    LabelInfo: TLabel;
    LabelBody: TLabel;
    MemoBody: TMemo;
    SplitterBody: TSplitter;
    MemoResponse: TMemo;
    procedure ButtonSendClick(Sender: TObject);
  private
    fContext: TDemoContext;
  public
    procedure Setup(const AContext: TDemoContext);
  end;

implementation

uses
  System.JSON;

{$R *.dfm}

procedure TRawFrame.Setup(const AContext: TDemoContext);
begin
  fContext := AContext;
end;

procedure TRawFrame.ButtonSendClick(Sender: TObject);
begin
  fContext.Run(ComboMethod.Text + ' ' + EditEndpoint.Text, procedure
    begin
      var lWoo := fContext.Woo;
      var lBody: TJSONValue := nil;
      if ComboMethod.ItemIndex in [1, 2] then  // POST, PUT
      begin
        lBody := TJSONValue.ParseJSONValue(MemoBody.Text);
        if lBody = nil then
          raise Exception.Create('Il body non '#$E8' JSON valido');
      end;
      try
        var lAnswer: TJSONValue;
        case ComboMethod.ItemIndex of
          0: lAnswer := lWoo.Get(EditEndpoint.Text);
          1: lAnswer := lWoo.Post(EditEndpoint.Text, lBody);
          2: lAnswer := lWoo.Put(EditEndpoint.Text, lBody);
        else
          lAnswer := lWoo.Delete(EditEndpoint.Text);
        end;
        try
          MemoResponse.Text := lAnswer.Format(2);
        finally
          lAnswer.Free;
        end;
        LabelInfo.Caption := Format('X-WP-Total: %d   X-WP-TotalPages: %d', [lWoo.LastTotal, lWoo.LastTotalPages]);
      finally
        lBody.Free;
      end;
    end);
end;

end.
