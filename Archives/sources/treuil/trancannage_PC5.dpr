program trancannage_PC5;

uses
  Forms,
  trancannage_PC_5 in 'trancannage_PC_5.pas' {Form1};

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TForm1, Form1);
  Application.Run;
end.
