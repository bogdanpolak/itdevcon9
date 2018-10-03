unit Form.Main;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs,
  Vcl.StdCtrls, Vcl.ExtCtrls,
  ChromeTabs, ChromeTabsClasses, Mock.MainForm;

type
  TForm1 = class(TForm)
    GroupBox1: TGroupBox;
    lbTitleFilesToAdd: TLabel;
    Splitter1: TSplitter;
    lbTitleFilesToRemove: TLabel;
    lbxFilesToAdd: TListBox;
    lbxFilesToRemove: TListBox;
    ChromeTabs1: TChromeTabs;
    pnMain: TPanel;
    Button1: TButton;
    tmrAppReady: TTimer;
    procedure FormCreate(Sender: TObject);
    procedure tmrAppReadyTimer(Sender: TObject);
  private
    isDeveloperMode: Boolean;
    isDatabaseOK: Boolean;
  public
    FDConnection1: TFDConnectionMock;
  end;

var
  Form1: TForm1;

implementation

{$R *.dfm}

uses
  System.StrUtils,
  Frame.Welcome, Consts.Application, Utils.CipherAES128;

const
  SQL_SELECT_DatabaseVersion = 'SELECT versionnr FROM DBInfo';
  SecureKey = 'delphi-is-the-best';
  // SecurePassword = AES 128 ('masterkey',SecureKey)
  SecurePassword = 'hC52IiCv4zYQY2PKLlSvBaOXc14X41Mc1rcVS6kyr3M=';

resourcestring
  SWelcomeScreen = 'Ekran powitalny';
  SDBServerGone = 'Nie mo¿na nawiazaæ po³¹czenia z serwerem bazy danych.';
  SDBConnectionUserPwdInvalid = 'B³êdna konfiguracja po³¹czenia z baz¹ danych.'
    + ' Dane u¿ytkownika aplikacyjnego s¹ nie poprawne.';
  SDBConnectionError = 'Nie mo¿na nawiazaæ po³¹czenia z baz¹ danych';
  SDBRequireCreate = 'Baza danych jest pusta.' +
    ' Proszê najpierw uruchomiæ skrypt buduj¹cy strukturê.';
  SDBErrorSelect = 'Nie mo¿na wykonaæ polecenia SELECT w bazie danych.';
  StrNotSupportedDBVersion = 'B³êdna wersja bazy danych. Proszê' +
    ' zaktualizowaæ strukturê bazy.';

procedure TForm1.FormCreate(Sender: TObject);
var
  Extention: string;
  ExeName: string;
  ProjectFileName: string;
begin
{$IFDEF DEBUG}
  Extention := '.dpr';
  ExeName := ExtractFileName(Application.ExeName);
  ProjectFileName := ChangeFileExt(ExeName, Extention);
  isDeveloperMode := FileExists(ProjectFileName) or
    FileExists('..\..\' + ProjectFileName);
{$ELSE}
  isDeveloperMode := False;
{$ENDIF}
end;

function DBVersionToString(VerDB: integer): string;
begin
  Result := (VerDB div 1000).ToString + '.' + (VerDB mod 1000).ToString;
end;

procedure TForm1.tmrAppReadyTimer(Sender: TObject);
var
  frm: TFrameWelcome;
  tab: TChromeTab;
  VersionNr: integer;
  msg1: string;
  UserName: string;
  password: string;
  res: Variant;
begin
  tmrAppReady.Enabled := False;
  // ----------------------------------------------------------
  // ----------------------------------------------------------
  //
  // Create and show Welcome Frame
  //
  frm := TFrameWelcome.Create(pnMain);
  frm.Parent := pnMain;
  frm.Visible := True;
  frm.Align := alClient;
  tab := ChromeTabs1.Tabs.Add;
  tab.Caption := 'Welcome';
  tab.Data := frm;
  // ----------------------------------------------------------
  // ----------------------------------------------------------
  //
  // Connect to database server
  // Check application user and database structure (DB version)
  //
  isDatabaseOK := False;
  try
    UserName := FDManager.ConnectionDefs.ConnectionDefByName
      (FDConnection1.ConnectionDefName).Params.UserName;
    password := AES128_Decrypt(SecurePassword, SecureKey);
    FDConnection1.Open(UserName, password);
  except
    on E: EFDDBEngineException do
    begin
      case E.kind of
        ekUserPwdInvalid:
          msg1 := SDBConnectionUserPwdInvalid;
        ekServerGone:
          msg1 := SDBServerGone;
      else
        msg1 := SDBConnectionError
      end;
      frm.lbxMessages.Items.Add(msg1);
      exit;
    end;
  end;
  try
    res := FDConnection1.ExecSQLScalar(SQL_SELECT_DatabaseVersion);
  except
    on E: EFDDBEngineException do
    begin
      msg1 := IfThen(E.kind = ekObjNotExists, SDBRequireCreate, SDBErrorSelect);
      frm.lbxMessages.Items.Add(msg1);
      exit;
    end;
  end;
  VersionNr := res;
  if VersionNr = ExpectedDatabaseVersionNr then
    isDatabaseOK := True
  else
  begin
    frm.lbxMessages.Items.Add(StrNotSupportedDBVersion);
    frm.lbxMessages.Items.Add('   * Oczekiwana wersja bazy: ' +
      DBVersionToString(ExpectedDatabaseVersionNr));
    frm.lbxMessages.Items.Add('   * Aktualna wersja bazy: ' +
      DBVersionToString(VersionNr));
  end;
  // ----------------------------------------------------------
  // ----------------------------------------------------------
  //
  //
  //
end;

end.
