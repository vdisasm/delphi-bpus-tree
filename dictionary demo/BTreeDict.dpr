program BTreeDict;

uses
  Vcl.Forms,
  Unit1 in 'Unit1.pas' {Form1} ,
  uRebuild in 'uRebuild.pas',
  uConsts in 'uConsts.pas';

{$R *.res}


begin
  ReportMemoryLeaksOnShutdown := True;
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TForm1, Form1);
  Application.Run;

end.
