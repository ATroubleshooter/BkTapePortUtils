unit FocalConverter ;

interface
uses Classes, SysUtils, Generics.Collections,
  AbstractMaker ;

type
  TFocalLine = record
    num1:Integer ;
    num2:Integer ;
    command:string ;
  end;

  TFocalConverter = class
  private
    tapename:string ;
    makerclass:TMakerClass ;
    function CreateFocalProg(const prog:TStringList):TList<TFocalLine> ;
  public
    constructor Create() ;
    destructor Destroy ; override ;
    procedure SetParamsFromPairs(pairs:TStringList) ;
    procedure Run(const inputfile:string; const outputfile:string) ;
    function getTapeName():string ;
  end;

implementation
uses AscMaker,WavMaker, Math ;

const BIN_NAME_LENGTH = 16 ;
      TERM = $8E ; // Конец строки Фокала
      PARITYADD = $00 ; // Добавление в конце строки для четности

// Замены символов в Фокале
      REPLACEMENTS:array [0..12,0..1] of Byte = (
   (ord(' '),$80),
   (ord('+'),$81),
   (ord('-'),$82),
   (ord('/'),$83),
   (ord('*'),$84),
   (ord('^'),$85),
   (ord('('),$86),
   (ord('['),$87),
   (ord(')'),$89),
   (ord(']'),$8A),
   (ord(','),$8C),
   (ord(';'),$8D),
   (ord('='),$8F)
   ) ;

function getFocalFloatAsByte(ff:Integer):Byte ;
begin
  Result:=Trunc(256*((ff)/100)) ;
end;

{ TFocalConverter }

constructor TFocalConverter.Create();
begin
  tapename:='PROG' ;
  makerclass:=TAscMaker ;
end;

procedure TFocalConverter.SetParamsFromPairs(pairs: TStringList);
var i:Integer ;
begin
  for i := 0 to pairs.Count-1 do begin
    if pairs.Names[i]='format' then begin
      if pairs.ValueFromIndex[i].ToUpper()='WAV' then makerclass:=TWavMaker else
      if pairs.ValueFromIndex[i].ToUpper()='BIN' then makerclass:=TAscMaker else
      raise Exception.Create('Unknown output format: '+pairs.ValueFromIndex[i]) ;
    end
    else
    if pairs.Names[i]='name' then tapename:=pairs.ValueFromIndex[i] else
      raise Exception.Create('Unknown parameter: '+pairs.Names[i]) ;
  end;
end;

function TFocalConverter.CreateFocalProg(
  const prog: TStringList): TList<TFocalLine>;
var tmp,tmp1:TArray<string> ;
    fl:TFocalLine ;
    s:string ;
begin
  Result:=TList<TFocalLine>.Create ;
  for s in prog do begin
    if Length(Trim(s))=0 then Continue ;

    tmp:=Trim(s).Split([' '],TStringSplitOptions.ExcludeEmpty) ;
    if Length(tmp)<2 then raise Exception.Create('Not found line number in: '+s);

    fl.command:=Trim(Trim(s).Substring(tmp[0].Length)) ;

    tmp1:=tmp[0].Split(['.']) ;
    if Length(tmp1)<2 then raise Exception.Create('Bad line number: '+tmp[0]);

    fl.num1:=StrToInt(tmp1[0]) ;
    if tmp1[1].Length=1 then tmp1[1]:=tmp1[1]+'0' ;
    fl.num2:=StrToInt(tmp1[1]) ;

    Result.Add(fl) ;
  end;
end;

destructor TFocalConverter.Destroy;
begin
  inherited Destroy;
end;

function TFocalConverter.getTapeName: string;
begin
  Result:=tapename ;
end;

procedure TFocalConverter.Run(const inputfile:string; const outputfile:string);
var stm:TMemoryStream ;
    head,buf,bufnum:TBytes ;
    i,j,k,cnt,size:Integer ;
    start:Cardinal ;
    fl:TFocalLine ;
    lines:TList<TFocalLine> ;
    source:TStringList ;
    enckoi,encsrc:TEncoding ;
    maker:TAbstractMaker ;
begin
  if not FileExists(inputfile) then raise Exception.Create('Input file not found: '+inputfile) ;

  if tapename.Length>BIN_NAME_LENGTH then
    raise Exception.CreateFmt('Too long tapename (max %d chars)',[BIN_NAME_LENGTH]) ;

  encsrc:=TEncoding.GetEncoding(20866) ;
  enckoi:=TEncoding.GetEncoding(20866) ;

  source:=TStringList.Create ;
  source.LoadFromFile(inputfile,encsrc) ;
  lines:=CreateFocalProg(source) ;
  source.Free ;

  // Расчет размера для заголовка
  size:=22 ;
  for fl in lines do begin
    cnt:=enckoi.GetByteCount(fl.command) ;
    Inc(size,cnt+5) ;
    // Коррекция на четность
    if cnt mod 2 = 0 then Inc(size) ;
  end;

  // Заголовок с константами и размером
  SetLength(head,26) ;
  head[0]:=$EA ;
  head[1]:=$03 ;
  head[2]:=Byte(size mod 256) ;
  head[3]:=Byte(size div 256) ;
  head[4]:=$14 ; head[5]:=$00 ; head[6]:=$00 ; head[7]:=$00 ;

  head[8]:=ord('C') ; head[9]:=ord(':') ;  head[10]:=$20 ; head[11]:=$20 ;
  head[12]:=$E6 ; head[13]:=$EF ; head[14]:=$EB ; head[15]:=$E1 ;
  head[16]:=$EC ; head[17]:=$2D ; head[18]:=$E2 ; head[19]:=$EB ;
  head[20]:=$30 ; head[21]:=$30 ; head[22]:=$31 ; head[23]:=$30 ;
  head[24]:=TERM ; head[25]:=PARITYADD ;

  SetLength(bufnum,4) ;
  start:=$FBFE ; // Магическое число размера файла для контрольной суммы

  stm:=TMemoryStream.Create() ;
  stm.WriteBuffer(head,Length(head)) ;

  for i:=0 to lines.count-1 do begin
    buf:=enckoi.GetBytes(lines[i].command) ;
    // Замена символов на фокальные
    for j := 0 to Length(buf)-1 do
      for k := 0 to Length(REPLACEMENTS)-1 do
        if buf[j]=REPLACEMENTS[k,0] then buf[j]:=REPLACEMENTS[k,1] ;

    // Добивка до четности
    if Length(buf) mod 2 = 0 then begin
      SetLength(buf,Length(buf)+2) ;
      buf[Length(buf)-2]:=TERM ;
      buf[Length(buf)-1]:=PARITYADD ;
    end
    else begin
      SetLength(buf,Length(buf)+1) ;
      buf[Length(buf)-1]:=TERM ;
    end;

    // Либо контрольная сумма для последней строки, либо длина строки
    if i=lines.count-1 then begin
      bufnum[0]:=Byte(start mod 256);
      bufnum[1]:=Byte(start div 256);
    end
    else begin
      bufnum[0]:=Length(buf)+2 ;
      bufnum[1]:=$00 ;
    end;
    bufnum[2]:=getFocalFloatAsByte(lines[i].num2) ;
    bufnum[3]:=Byte(lines[i].num1) ;

    // Обновление контрольной суммы
    Dec(start,Length(buf)+4) ;

    stm.WriteBuffer(bufnum,Length(bufnum)) ;
    stm.WriteBuffer(buf,Length(buf)) ;
  end;
  lines.Free ;

  maker:=makerclass.Create(outputfile,tapename+StringOfChar(chr(32),BIN_NAME_LENGTH-Length(tapename))) ;

  SetLength(buf,stm.Size) ;
  stm.Position:=0 ;
  stm.Read(buf,stm.Size) ;
  maker.WriteMonoBlock(buf) ;
  stm.Free ;

  maker.Free ;
end;

end.
