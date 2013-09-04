unit MainFormUnit;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, System.Win.Registry,
  shellapi, ShlObj, Vcl.Buttons, System.IniFiles;

type
  TForm1 = class(TForm)
    btnImprimir: TButton;
    OpenDialog: TOpenDialog;
    btnConfiguracoes: TBitBtn;
    procedure btnImprimirClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure btnConfiguracoesClick(Sender: TObject);
  private
    ini: TIniFile;
    modeloImpressora: integer;
    procedure printFile(fn: string);
    procedure associateFileType;
    procedure openConfigs;
    procedure parseConfigs;
  end;

var
  Form1: TForm1;

implementation

{$R *.dfm}

uses UnilabelPPLAUnit, UnilabelInterfaceUnit, UnilabelXMLEngineUnit,
  UnilabelZPLUnit, ConfiguracoesFormUn, unilabelConstantsUnit,
  UnilabelTypesUnit;

procedure TForm1.printFile(fn: string);
var
  prnt: IUnilabel;
  engine: TUnilabelXMLEngine;
  printerConfiguration: TPrinterConfiguration;
  contents: TStringList;
begin
  if modeloImpressora = ARGOX_OS_214_PPLA then
    prnt := TUnilabelPPLA.create;
  if modeloImpressora = ZEBRA_TLP_2844 then
    prnt := TUnilabelZPL.create;

  printerConfiguration.name := ini.ReadString('printer','name','');
  prnt.setPrinterConfigurations(printerConfiguration);
  engine := TUnilabelXMLEngine.Create(prnt);
  contents := TStringList.Create;
  try
    contents.LoadFromFile(fn);
    engine.print(contents.GetText);
  finally
    FreeAndNil(engine);
    FreeAndNil(contents);
  end;
end;

procedure TForm1.btnConfiguracoesClick(Sender: TObject);
var
  f: TConfiguracoesForm;
begin
  f := TConfiguracoesForm.Create(nil);
  try
    f.iniFile := ini;
    f.ShowModal;
    parseConfigs;
  finally
    freeAndNil(f);
  end;
end;

procedure TForm1.btnImprimirClick(Sender: TObject);
begin
  with OpenDialog do
    if execute then
      printFile(FileName);
end;

procedure TForm1.FormCreate(Sender: TObject);
begin
  openConfigs;
  if ParamStr(1) <> '' then
  begin
    printFile(ParamStr(1));
    application.Terminate;
  end;
  associateFileType;
end;

procedure TForm1.openConfigs;
var
  iniPath: string;
begin
  iniPath := extractFilePath(Application.ExeName) + 'unilabel.ini';
  ini := TIniFile.Create(iniPath);
  parseConfigs;
end;

procedure TForm1.parseConfigs;
begin
  modeloImpressora := ini.ReadInteger('Impressora', 'Modelo', 0);
end;

procedure TForm1.associateFileType;
begin
  with TRegistry.Create do
  try
    RootKey := HKEY_CURRENT_USER;
    if OpenKey('\Software\Classes\.unilabel', true) then
      WriteString('', 'UnilabelAppDoc');
    if OpenKey('\Software\Classes\UnilabelAppDoc', true) then
      WriteString('', 'Etiquetas Unilabel');
    if OpenKey('\Software\Classes\UnilabelAppDoc\shell\open\command', true) then
      WriteString('', application.ExeName + ' "%1"');
    SHChangeNotify(SHCNE_ASSOCCHANGED, SHCNF_IDLIST, 0, 0);
  finally
    Free;
  end;
end;

end.
