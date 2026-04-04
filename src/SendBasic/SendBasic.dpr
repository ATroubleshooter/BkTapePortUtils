program SendBasic;

{$APPTYPE CONSOLE}

uses
  main,
  ParamsParser in '..\classes\ParamsParser.pas',
  WavMaker in  '..\classes\WavMaker.pas',
  AscMaker in '..\classes\AscMaker.pas';

begin
  with TMain.Create() do begin
    Run() ;
    Free ;
  end;
end.


