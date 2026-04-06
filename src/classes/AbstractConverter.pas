unit AbstractConverter ;

interface
uses Classes, SysUtils,
  AbstractMaker ;

type
  TAbstractConverter = class
  protected
    tapename:string ;
    silentlen:Integer ;
    makerclass:TMakerClass ;
  public
    procedure SetParamsFromPairs(pairs:TStringList) ;
    constructor Create() ;
    function getTapeName():string ;
  end;

implementation
uses BinMaker,WavMaker ;

{ TAbstractConverter }

constructor TAbstractConverter.Create();
begin
  tapename:='PROG' ;
  makerclass:=TBinMaker ;
  silentlen:=0 ;
end;

procedure TAbstractConverter.SetParamsFromPairs(pairs: TStringList) ;
var i:Integer ;
begin
  for i := 0 to pairs.Count-1 do begin
    if pairs.Names[i]='format' then begin
      if pairs.ValueFromIndex[i].ToUpper()='WAV' then makerclass:=TWavMaker else
      if pairs.ValueFromIndex[i].ToUpper()='BIN' then makerclass:=TBinMaker else
      if pairs.ValueFromIndex[i].ToUpper()='ASC' then makerclass:=TBinMaker else
      raise Exception.Create('Unknown output format: '+pairs.ValueFromIndex[i]) ;
    end
    else
    if pairs.Names[i]='name' then tapename:=pairs.ValueFromIndex[i] else
    if pairs.Names[i]='silentlen' then silentlen:=StrToInt(pairs.ValueFromIndex[i]) else
      raise Exception.Create('Unknown parameter: '+pairs.Names[i]) ;
  end;
end;

function TAbstractConverter.getTapeName: string;
begin
  Result:=tapename ;
end;

end.
