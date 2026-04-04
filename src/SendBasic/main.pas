unit main ;

interface
uses SysUtils, Classes ;

type
  TMain = class
  public
    procedure Run() ;
  end;

implementation
uses Version, ParamsParser, BasicConverter ;

const MAINHELP = 'Converter from Basic for BK-0010 to ASC-files for GID emulator or WAV file for tape port'#13#10+
  'Version: '+TGitVersion.TAG+#13#10+
  'Usage: input_file output_value [parameters]'#13#10+
  'Parameters:'#13#10+
  '/format=ASC|WAV - make ASC file for GID or WAV file for tape port (default ASC)'#13#10+
  '/name=value - set name for LOAD command (default PROG)'#13#10+
  'If /format set to ASC, output_value - directory for saving ASC-files'#13#10+
  'If /format set to WAV, output_value - WAV filename'#13#10 ;

procedure TMain.Run() ;
var pairs:TStringList ;
    converter:TBasicConverter ;
begin
  try
    if ParamCount<2 then begin
      Writeln(MAINHELP) ;
      Halt(1) ;
    end;

    converter:=TBasicConverter.Create() ;

    pairs:=createParamPairsFromIndex(3) ;
    converter.SetParamsFromPairs(pairs) ;
    pairs.Free ;

    converter.Run(ParamStr(1),ParamStr(2)) ;

    Writeln('File(s) written, use LOAD "'+converter.getTapeName()+'" for loading BASIC program') ;
    converter.Free ;
  except
    on E: Exception do begin
      Writeln('Error '+E.ClassName+': '+E.Message);
      Halt(1) ;
    end;
  end;
end ;

end.
