unit AbstractMaker;

interface
uses Classes, SysUtils ;

type
  TAbstractMaker = class
  protected
    outputvalue:string; 
    tapenamefixed:string;
  public
    constructor Create(const Aoutputvalue:string; const Atapenamefixed:string) ;
    procedure WriteDataBlock(const data:TBytes; num:Integer) ; virtual ; abstract ;
    procedure WriteFinalBlock(const data:TBytes) ; virtual ; abstract ;
  end;

  TMakerClass = class of TAbstractMaker ;

implementation

{ TAbstractMaker }

constructor TAbstractMaker.Create(const Aoutputvalue, Atapenamefixed: string);
begin
  outputvalue:=Aoutputvalue ;
  tapenamefixed:=Atapenamefixed ;
end;

end.
