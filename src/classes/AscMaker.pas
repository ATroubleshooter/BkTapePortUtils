unit AscMaker;

interface
uses Classes, SysUtils,
  AbstractMaker ;

type
  TAscMaker = class(TAbstractMaker)
  private
    procedure WriteASC(const data:TBytes; const filename:string) ;
  public
    procedure WriteDataBlock(const data:TBytes; num:Integer) ; override ;
    procedure WriteFinalBlock(const data:TBytes) ; override ;
  end;

implementation

{ TAscMaker }

procedure TAscMaker.WriteDataBlock(const data:TBytes; num:Integer);
begin
  WriteASC(data,outputvalue+'\'+Format('%s.ASC #%.3d.BIN',[tapenamefixed,num])) ;
end;

procedure TAscMaker.WriteFinalBlock(const data: TBytes);
begin
  WriteASC(data,outputvalue+'\'+tapenamefixed+'.ASC.BIN') ;
end;

procedure TAscMaker.WriteASC(const data: TBytes; const filename: string);
begin
  if FileExists(filename) then SysUtils.DeleteFile(filename) ;

  with TFileStream.Create(filename,fmCreate) do begin
    WriteBuffer(data[0],Length(data)) ;
    Free ;
  end;
end;

end.
