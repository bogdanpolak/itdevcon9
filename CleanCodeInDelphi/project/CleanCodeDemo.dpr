program CleanCodeDemo;

uses
  Vcl.Forms,
  Form.Main in 'Form.Main.pas' {Form1},
  Frame.Welcome in 'Frame.Welcome.pas' {FrameWelcome: TFrame},
  Mock.MainForm in 'Mock.MainForm.pas',
  Consts.Application in 'Consts.Application.pas',
  Utils.CipherAES128 in 'Utils.CipherAES128.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TForm1, Form1);
  Application.Run;
end.
