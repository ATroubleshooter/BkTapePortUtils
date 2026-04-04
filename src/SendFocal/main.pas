unit main ;

interface
uses SysUtils, Classes ;

type
  TMain = class
  public
    procedure Run() ;
  end;

implementation
uses Version, ParamsParser, FocalConverter ;

const MAINHELP = 'Converter from Focal for BK-0010 to BIN-file for GID emulator or WAV file for tape port'#13#10+
  'Version: '+TGitVersion.TAG+#13#10+
  'Usage: input_file output_file [parameters]'#13#10+
  'Parameters:'#13#10+
  '/format=BIN|WAV - make BIN file for GID or WAV file for tape port (default BIN)'#13#10+
  '/name=value - set name for L G command (default PROG)'#13#10+
  '"name" parameter not using for BIN file, only for encoding WAV file internal data' ;

procedure TMain.Run() ;
var pairs:TStringList ;
    converter:TFocalConverter ;
begin
  try
    if ParamCount<2 then begin
      Writeln(MAINHELP) ;
      Halt(1) ;
    end;

    converter:=TFocalConverter.Create() ;

    pairs:=createParamPairsFromIndex(3) ;
    converter.SetParamsFromPairs(pairs) ;
    pairs.Free ;

    converter.Run(ParamStr(1),ParamStr(2)) ;

    Writeln('File(s) written, use L G '+converter.getTapeName()+' for loading FOCAL program') ;
    converter.Free ;
  except
    on E: Exception do begin
      Writeln('Error '+E.ClassName+': '+E.Message);
      Halt(1) ;
    end;
  end;
end ;

end.
