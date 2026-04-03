unit main ;

interface
uses SysUtils, Classes ;

type
  TMain = class
  public
    procedure Run() ;
  end;

implementation
uses Generics.Collections,  Math,
  Version, ParamsParser,WavMaker ;

const MAINHELP = 'Converter from Basic for BK-0010 to ASC-files for GID emulator or WAV file for tape port'#13#10+
  'Version: '+TGitVersion.TAG+#13#10+
  'Usage: input_file output_value [parameters]'#13#10+
  'Parameters:'#13#10+
  '/format=ASC|WAV - make ASC file for GID or WAV file for tape port (default ASC)'#13#10+
  '/name=value - set name for LOAD command (default PROG)'#13#10+
  'If /format set to ASC, output_value - directory for saving ASC-files'#13#10+
  'If /format set to WAV, output_value - WAV filename'#13#10 ;

ASC_NAME_LENGTH = 6 ;
HEADER_SIZE = 4 ;
MAX_BLOCK_SIZE = 256 ;

type TOutFormat = (ofASC,ofWAV) ;

procedure TMain.Run() ;
var i:Integer ;
    pairs:TStringList ;
    inputfile,outputvalue:string ;
    tapename,tapenamefixed:string ;
    outformat:TOutFormat;

    s:string ;
    source:TStringList ;
    data:TList<Byte> ;
    j,filecnt,blocksize:Integer ;
    wm:TWavMaker ;
    buf:TBytes ;
    binfile:string ;
begin
  try
    if ParamCount<2 then begin
      Writeln(MAINHELP) ;
      Halt(1) ;
    end;

    inputfile:=ParamStr(1) ;
    if not FileExists(inputfile) then raise Exception.Create('Input file not found: '+inputfile) ;

    outputvalue:=ParamStr(2) ;
    tapename:='PROG' ;
    outformat:=ofASC ;
    pairs:=createParamPairsFromIndex(3) ;
    for i := 0 to pairs.Count-1 do begin
      if pairs.Names[i]='format' then begin
        if pairs.ValueFromIndex[i].ToUpper()='WAV' then outformat:=ofWAV else
        if pairs.ValueFromIndex[i].ToUpper()='ASC' then outformat:=ofASC else
        raise Exception.Create('Unknown output format: '+pairs.ValueFromIndex[i]) ;
      end
      else
      if pairs.Names[i]='name' then tapename:=pairs.ValueFromIndex[i] else
        raise Exception.Create('Unknown parameter: '+pairs.Names[i]) ;
    end;
    pairs.Free ;

    if outformat=ofASC then
      if tapename.Length>ASC_NAME_LENGTH then
        raise Exception.CreateFmt('Too long typename (max %d chars)',[ASC_NAME_LENGTH]) ;

    source:=TStringList.Create ;
    source.LoadFromFile(inputfile,TEncoding.GetEncoding(20866)) ;
    data:=TList<Byte>.Create() ;
    for s in source do begin
      data.AddRange(TEncoding.GetEncoding(20866).GetBytes(s.Trim())) ;
      data.Add($0A) ;
    end;
    data.Add($1A) ;
    source.Free ;

    filecnt:=data.Count div MAX_BLOCK_SIZE ;
    if data.Count mod MAX_BLOCK_SIZE<>0 then Inc(filecnt) ;

    tapenamefixed:=tapename+StringOfChar(' ',ASC_NAME_LENGTH-Length(tapename)) ;

    wm:=TWavMaker.Create() ;
    for i := 0 to filecnt-1 do begin
      blocksize:=IfThen(i=filecnt-1,data.Count-(filecnt-1)*MAX_BLOCK_SIZE,MAX_BLOCK_SIZE) ;
      SetLength(buf,blocksize+HEADER_SIZE) ;
      buf[0]:=$EE ;
      buf[1]:=$3D ;
      buf[2]:=Byte(blocksize mod MAX_BLOCK_SIZE) ;
      buf[3]:=Byte(blocksize div MAX_BLOCK_SIZE) ;
      for j := 0 to blocksize-1 do
        buf[HEADER_SIZE+j]:=data[i*MAX_BLOCK_SIZE+j] ;

      if outformat=ofWAV then
        wm.AppendBinData(buf,Format('%s.ASC #%.3d',[tapenamefixed,i])+Chr(26))
      else begin
        binfile:=outputvalue+'\'+Format('%s.ASC #%.3d.BIN',[tapenamefixed,i]) ;
        if FileExists(binfile) then SysUtils.DeleteFile(binfile) ;

        with TFileStream.Create(binfile,fmCreate) do begin
          WriteBuffer(buf[0],Length(buf)) ;
          Free ;
        end;
      end;
    end;

    SetLength(buf,6) ;
    buf[0]:=$EE ;
    buf[1]:=$3D ;
    buf[2]:=Byte(2) ;
    buf[3]:=Byte(0) ;
    buf[4]:=Byte(0) ;
    buf[5]:=Byte(0) ;

    if outformat=ofWAV then begin
      wm.AppendBinData(buf,tapenamefixed+'.ASC'+Chr(32)+Chr(32)+StringOfChar(Chr(0),4)) ;
      wm.WriteToWav(outputvalue) ;
    end
    else begin
      binfile:=outputvalue+'\'+tapenamefixed+'.ASC.BIN' ;
      if FileExists(binfile) then SysUtils.DeleteFile(binfile) ;

      with TFileStream.Create(binfile,fmCreate) do begin
        WriteBuffer(buf[0],Length(buf)) ;
        Free ;
      end;
    end;

    Writeln('File(s) written, use LOAD "'+tapename+'" for loading BASIC program') ;
    data.Free ;

  except
    on E: Exception do begin
      Writeln('Error '+E.ClassName+': '+E.Message);
      Halt(1) ;
    end;
  end;
end ;

end.
