program SendFocal;

{$APPTYPE CONSOLE}

uses
  main,
  ParamsParser in '..\classes\ParamsParser.pas',
  WavMaker in  '..\classes\WavMaker.pas',
  BinMaker in '..\classes\BinMaker.pas',
  FocalConverter in  '..\classes\FocalConverter.pas' ;

begin
  with TMain.Create() do begin
    Run() ;
    Free ;
  end;
end.


