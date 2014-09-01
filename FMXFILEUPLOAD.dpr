program FMXFILEUPLOAD;

uses
  System.StartUpCopy,
  FMX.MobilePreview,
  FMX.Forms,
  uMain in 'uMain.pas' {MainForm},
  uImagePopup in 'uImagePopup.pas' {Form2};

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TMainForm, MainForm);
  Application.CreateForm(TForm2, Form2);
  Application.Run;
end.
