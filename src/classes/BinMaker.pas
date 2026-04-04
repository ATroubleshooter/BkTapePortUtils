unit BinMaker;

interface
uses Classes, SysUtils,
  AbstractMaker ;

type
  TBinMaker = class(TAbstractMaker)
  private
    procedure WriteBIN(const data:TBytes; const filename:string) ;
  public
    procedure WriteDataBlock(const data:TBytes; num:Integer) ; override ;
    procedure WriteFinalBlock(const data:TBytes) ; override ;
    procedure WriteMonoBlock(const data:TBytes) ; override ;
  end;

implementation

{ TBinMaker }

procedure TBinMaker.WriteDataBlock(const data:TBytes; num:Integer);
begin
  WriteBIN(data,outputvalue+'\'+Format('%s.ASC #%.3d.BIN',[tapenamefixed,num])) ;
end;

procedure TBinMaker.WriteFinalBlock(const data: TBytes);
begin
  WriteBIN(data,outputvalue+'\'+tapenamefixed+'.ASC.BIN') ;
end;

procedure TBinMaker.WriteMonoBlock(const data: TBytes);
begin
  WriteBIN(data,outputvalue) ;
end;

procedure TBinMaker.WriteBIN(const data: TBytes; const filename: string);
begin
  if FileExists(filename) then SysUtils.DeleteFile(filename) ;

  with TFileStream.Create(filename,fmCreate) do begin
    WriteBuffer(data[0],Length(data)) ;
    Free ;
  end;
end;

end.
