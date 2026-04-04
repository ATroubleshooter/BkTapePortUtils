unit BasicConverter ;

interface
uses Classes, SysUtils,
  AbstractMaker ;

type
  TBasicConverter = class
  private
    tapename:string ;
    makerclass:TMakerClass ;
  public
    constructor Create() ;
    destructor Destroy ; override ;
    procedure SetParamsFromPairs(pairs:TStringList) ;
    procedure Run(const inputfile:string; const outputvalue:string) ;
    function getTapeName():string ;
  end;

implementation
uses AscMaker,WavMaker, Generics.Collections, Math ;

const ASC_NAME_LENGTH = 6 ;
      HEADER_SIZE = 4 ;
      MAX_BLOCK_SIZE = 256 ;

{ TBasicConverter }

constructor TBasicConverter.Create();
begin
  tapename:='PROG' ;
  makerclass:=TAscMaker ;
end;

procedure TBasicConverter.SetParamsFromPairs(pairs: TStringList);
var i:Integer ;
begin
  for i := 0 to pairs.Count-1 do begin
    if pairs.Names[i]='format' then begin
      if pairs.ValueFromIndex[i].ToUpper()='WAV' then makerclass:=TWavMaker else
      if pairs.ValueFromIndex[i].ToUpper()='ASC' then makerclass:=TAscMaker else
      raise Exception.Create('Unknown output format: '+pairs.ValueFromIndex[i]) ;
    end
    else
    if pairs.Names[i]='name' then tapename:=pairs.ValueFromIndex[i] else
      raise Exception.Create('Unknown parameter: '+pairs.Names[i]) ;
  end;
end;

destructor TBasicConverter.Destroy;
begin
  inherited Destroy;
end;

function TBasicConverter.getTapeName: string;
begin
  Result:=tapename ;
end;

procedure TBasicConverter.Run(const inputfile:string; const outputvalue:string);
var maker:TAbstractMaker ;
    s:string ;
    source:TStringList ;
    data:TList<Byte> ;
    i,j,filecnt,blocksize:Integer ;
    buf:TBytes ;
begin
  if not FileExists(inputfile) then raise Exception.Create('Input file not found: '+inputfile) ;

  if tapename.Length>ASC_NAME_LENGTH then
    raise Exception.CreateFmt('Too long tapename (max %d chars)',[ASC_NAME_LENGTH]) ;

  maker:=makerclass.Create(outputvalue,tapename+StringOfChar(' ',ASC_NAME_LENGTH-Length(tapename))) ;

  source:=TStringList.Create ;
  source.LoadFromFile(ParamStr(1),TEncoding.GetEncoding(20866)) ;
  data:=TList<Byte>.Create() ;
  for s in source do begin
    data.AddRange(TEncoding.GetEncoding(20866).GetBytes(s.Trim())) ;
    data.Add($0A) ;
  end;
  data.Add($1A) ;
  source.Free ;

  filecnt:=data.Count div MAX_BLOCK_SIZE ;
  if data.Count mod MAX_BLOCK_SIZE<>0 then Inc(filecnt) ;

  for i := 0 to filecnt-1 do begin
    blocksize:=IfThen(i=filecnt-1,data.Count-(filecnt-1)*MAX_BLOCK_SIZE,MAX_BLOCK_SIZE) ;
    SetLength(buf,blocksize+HEADER_SIZE) ;
    buf[0]:=$EE ;
    buf[1]:=$3D ;
    buf[2]:=Byte(blocksize mod MAX_BLOCK_SIZE) ;
    buf[3]:=Byte(blocksize div MAX_BLOCK_SIZE) ;
    for j := 0 to blocksize-1 do
      buf[HEADER_SIZE+j]:=data[i*MAX_BLOCK_SIZE+j] ;

    maker.WriteDataBlock(buf,i) ;
  end;

  SetLength(buf,6) ;
  buf[0]:=$EE ;
  buf[1]:=$3D ;
  buf[2]:=Byte(2) ;
  buf[3]:=Byte(0) ;
  buf[4]:=Byte(0) ;
  buf[5]:=Byte(0) ;

  maker.WriteFinalBlock(buf) ;
  maker.Free ;
  data.Free ;
end;

end.
