program SendBasic;

{$APPTYPE CONSOLE}

uses
  main,
  ParamsParser in '..\classes\ParamsParser.pas';

begin
  with TMain.Create() do begin
    Run() ;
    Free ;
  end;
end.


