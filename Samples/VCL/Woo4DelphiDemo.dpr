// Woo4Delphi by KD Software Srls - https://www.kdsoftware.it - info@kdsoftware.it
// Developer: Giordano Giaccaglia

program Woo4DelphiDemo;

uses
  Vcl.Forms,
  Woo4Delphi.Types in '..\..\Woo4Delphi.Types.pas',
  Woo4Delphi.Client in '..\..\Woo4Delphi.Client.pas',
  Demo.Common in 'Demo.Common.pas',
  Demo.Products in 'Demo.Products.pas' {ProductsFrame: TFrame},
  Demo.Categories in 'Demo.Categories.pas' {CategoriesFrame: TFrame},
  Demo.Orders in 'Demo.Orders.pas' {OrdersFrame: TFrame},
  Demo.Resources in 'Demo.Resources.pas' {ResourcesFrame: TFrame},
  Demo.Reports in 'Demo.Reports.pas' {ReportsFrame: TFrame},
  Demo.Raw in 'Demo.Raw.pas' {RawFrame: TFrame},
  Demo.Main in 'Demo.Main.pas' {MainForm};

// Opening this .dpr in RAD Studio creates Woo4DelphiDemo.dproj and .res (icon, manifest, themes).

begin
  ReportMemoryLeaksOnShutdown := True;  // a leak shows a dialog on exit
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TMainForm, MainForm);
  Application.Run;
end.
