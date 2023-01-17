program trancannage_PC4;

uses
  Forms,
  trancannage_PC_4 in 'trancannage_PC_4.pas' {Form1};

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TForm1, Form1);
  Application.Run;
end.
