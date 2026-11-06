// Woo4Delphi by KD Software Srls - https://www.kdsoftware.it - info@kdsoftware.it
// Developer: Giordano Giaccaglia

unit Demo.Common;

// What the demo pages share: the connection, the call log, and Run, which wraps every call.

interface

uses
  System.SysUtils,
  System.Classes,
  System.Net.URLClient,
  Vcl.ComCtrls,
  Woo4Delphi.Client;

type
  TDemoContext = class
  private
    fWoo: TWooClient;
    fLog: TProc<string>;
    fErrorCount: Integer;
    fAutoConfirm: Boolean;
    fWordPressUser: string;
    fWordPressAppPassword: string;
    function GetWoo: TWooClient;
  public
    constructor Create(const ALog: TProc<string>);
    destructor Destroy; override;
    procedure Connect(const AURL, AKey, ASecret: string; const AQueryStringAuth, AAcceptAnyCertificate: Boolean);
    // For uploading images only; applies at once, also to an open connection
    procedure SetWordPressLogin(const AUser, AAppPassword: string);
    procedure Log(const AText: string);
    // One call: hourglass, elapsed time in the log, an exception logged instead of a dialog
    procedure Run(const ACaption: string; const AProc: TProc);
    // Asks before a destructive call; AutoConfirm answers yes, for scripted runs
    function Confirm(const AQuestion: string): Boolean;
    property Woo: TWooClient read GetWoo;
    property ErrorCount: Integer read fErrorCount;
    property AutoConfirm: Boolean read fAutoConfirm write fAutoConfirm;
  end;

// 'status=processing&search=caffe' -> name/value pairs (URLFor encodes them)
function ParseParams(const AText: string): TNameValueArray;
// Comma-separated JSON keys -> array, e.g. 'regular_price, stock_quantity'
function ParseFields(const AText: string): TArray<string>;
function PrettyJSON(const AJSON: string): string;
// The value of AKey in a JSON object, '' when missing
function JSONField(const AJSON, AKey: string): string;
// The first field that describes an item: name, title, code, number, e-mail...
function Describe(const AJSON: string): string;
procedure AddRow(const AList: TListView; const AValues: array of string);

implementation

uses
  System.Diagnostics,
  System.JSON,
  System.UITypes,
  Vcl.Controls,
  Vcl.Forms,
  Vcl.Dialogs;

procedure AcceptAnyCertificate(const Sender: TObject; const ARequest: TURLRequest; const Certificate: TCertificate;
  var Accepted: Boolean);
begin
  Accepted := True;
end;

{ TDemoContext }

constructor TDemoContext.Create(const ALog: TProc<string>);
begin
  inherited Create;
  fLog := ALog;
end;

destructor TDemoContext.Destroy;
begin
  fWoo.Free;
  inherited Destroy;
end;

function TDemoContext.GetWoo: TWooClient;
begin
  if fWoo = nil then
    raise Exception.Create('Non connesso: inserisci URL e chiavi, poi premi Connetti');
  Result := fWoo;
end;

procedure TDemoContext.Connect(const AURL, AKey, ASecret: string; const AQueryStringAuth, AAcceptAnyCertificate: Boolean);
begin
  FreeAndNil(fWoo);  // a field tested for nil by GetWoo
  fWoo := TWooClient.Create(AURL, AKey, ASecret);
  fWoo.QueryStringAuth := AQueryStringAuth;
  SetWordPressLogin(fWordPressUser, fWordPressAppPassword);
  if AAcceptAnyCertificate then
    fWoo.HTTP.ValidateServerCertificateCallback := AcceptAnyCertificate;
end;

procedure TDemoContext.SetWordPressLogin(const AUser, AAppPassword: string);
begin
  fWordPressUser := AUser;
  fWordPressAppPassword := AAppPassword;
  if fWoo <> nil then
  begin
    fWoo.WordPressUser := AUser;
    fWoo.WordPressAppPassword := AAppPassword;
  end;
end;

procedure TDemoContext.Log(const AText: string);
begin
  fLog(FormatDateTime('hh:nn:ss', Now) + '  ' + AText);
end;

procedure TDemoContext.Run(const ACaption: string; const AProc: TProc);
begin
  var lWatch := TStopwatch.StartNew;
  Screen.Cursor := crHourGlass;
  try
    try
      AProc();
      Log(Format('%s: OK (%d ms)', [ACaption, lWatch.ElapsedMilliseconds]));
    except
      on E: Exception do
      begin
        Inc(fErrorCount);
        Log(Format('%s: ERRORE %s: %s', [ACaption, E.ClassName, E.Message]));
      end;
    end;
  finally
    Screen.Cursor := crDefault;
  end;
end;

function TDemoContext.Confirm(const AQuestion: string): Boolean;
begin
  Result := fAutoConfirm or (MessageDlg(AQuestion, mtConfirmation, [mbYes, mbNo], 0) = mrYes);
end;

{ helpers }

function ParseParams(const AText: string): TNameValueArray;
begin
  Result := nil;
  for var lPart in AText.Split(['&'], TStringSplitOptions.ExcludeEmpty) do
  begin
    var lEqual := lPart.IndexOf('=');
    if lEqual < 0 then
      Result := Result + [TNameValuePair.Create(lPart.Trim, '')]
    else
      Result := Result + [TNameValuePair.Create(lPart.Substring(0, lEqual).Trim, lPart.Substring(lEqual + 1).Trim)];
  end;
end;

function ParseFields(const AText: string): TArray<string>;
begin
  Result := nil;
  for var lField in AText.Split([','], TStringSplitOptions.ExcludeEmpty) do
    if lField.Trim <> '' then
      Result := Result + [lField.Trim];
end;

function PrettyJSON(const AJSON: string): string;
begin
  var lValue := TJSONValue.ParseJSONValue(AJSON);
  try
    if lValue = nil then
      Result := AJSON
    else
      Result := lValue.Format(2);
  finally
    lValue.Free;
  end;
end;

function JSONField(const AJSON, AKey: string): string;
begin
  Result := '';
  var lValue := TJSONValue.ParseJSONValue(AJSON);
  try
    if lValue is TJSONObject then
    begin
      var lField := TJSONObject(lValue).Values[AKey];
      if lField <> nil then
        Result := lField.Value;
    end;
  finally
    lValue.Free;
  end;
end;

function Describe(const AJSON: string): string;
const
  cKeys: array[0..10] of string = ('name', 'title', 'code', 'number', 'email', 'label', 'note', 'reviewer',
    'method_id', 'description', 'slug');
begin
  for var lKey in cKeys do
  begin
    Result := JSONField(AJSON, lKey);
    if Result <> '' then
      Exit;
  end;
  Result := '';
end;

procedure AddRow(const AList: TListView; const AValues: array of string);
begin
  var lItem := AList.Items.Add;
  lItem.Caption := AValues[0];
  for var i := 1 to High(AValues) do
    lItem.SubItems.Add(AValues[i]);
end;

end.
