unit Form.Main;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs,
  Vcl.StdCtrls, Vcl.ExtCtrls,
  ChromeTabs, ChromeTabsClasses, ChromeTabsTypes,
  Mock.MainForm, Data.DB, Vcl.Grids, Vcl.DBGrids;

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
    btnImport: TButton;
    tmrAppReady: TTimer;
    procedure btnImportClick(Sender: TObject);
    procedure ChromeTabs1ButtonCloseTabClick(Sender: TObject; ATab: TChromeTab;
      var Close: Boolean);
    procedure ChromeTabs1Change(Sender: TObject; ATab: TChromeTab;
      TabChangeType: TTabChangeType);
    procedure FormCreate(Sender: TObject);
    procedure FormResize(Sender: TObject);
    procedure Splitter1Moved(Sender: TObject);
    procedure tmrAppReadyTimer(Sender: TObject);
  private
    isDeveloperMode: Boolean;
    isDatabaseOK: Boolean;
    procedure ResizeGroupBox();
  public
    FDConnection1: TFDConnectionMock;
  end;

var
  Form1: TForm1;

implementation

{$R *.dfm}

uses
  System.StrUtils, System.JSON,
  Frame.Welcome, Consts.Application, Utils.CipherAES128, Frame.Import,
  Units.Main, ClientAPI.Contacts, Data.Main;

const
  SQL_SELECT_DatabaseVersion = 'SELECT versionnr FROM DBInfo';
  SecureKey = 'delphi-is-the-best';
  // SecurePassword = AES 128 ('masterkey',SecureKey)
  SecurePassword = 'hC52IiCv4zYQY2PKLlSvBaOXc14X41Mc1rcVS6kyr3M=';
  Client_API_Token = '20be805d-9cea27e2-a588efc5-1fceb84d-9fb4b67c';

resourcestring
  SWelcomeScreen = 'Ekran powitalny';
  SDBServerGone = 'Nie mo�na nawiaza� po��czenia z serwerem bazy danych.';
  SDBConnectionUserPwdInvalid = 'B��dna konfiguracja po��czenia z baz� danych.'
    + ' Dane u�ytkownika aplikacyjnego s� nie poprawne.';
  SDBConnectionError = 'Nie mo�na nawiaza� po��czenia z baz� danych';
  SDBRequireCreate = 'Baza danych jest pusta.' +
    ' Prosz� najpierw uruchomi� skrypt buduj�cy struktur�.';
  SDBErrorSelect = 'Nie mo�na wykona� polecenia SELECT w bazie danych.';
  StrNotSupportedDBVersion = 'B��dna wersja bazy danych. Prosz�' +
    ' zaktualizowa� struktur� bazy.';

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
  pnMain.Caption := '';
end;

function DBVersionToString(VerDB: integer): string;
begin
  Result := (VerDB div 1000).ToString + '.' + (VerDB mod 1000).ToString;
end;

procedure TForm1.FormResize(Sender: TObject);
begin
  ResizeGroupBox();
end;

function SumHeightForChildrens(Parent: TWinControl;
  ControlsToExclude: TArray<TControl>): integer;
var
  i: integer;
  ctrl: Vcl.Controls.TControl;
  isExcluded: Boolean;
  j: integer;
  sumHeight: integer;
  ctrlHeight: integer;
begin
  sumHeight := 0;
  for i := 0 to Parent.ControlCount - 1 do
  begin
    ctrl := Parent.Controls[i];
    isExcluded := False;
    for j := 0 to Length(ControlsToExclude) - 1 do
      if ControlsToExclude[j] = ctrl then
        isExcluded := True;
    if not isExcluded then
    begin
      if ctrl.AlignWithMargins then
        ctrlHeight := ctrl.Height + ctrl.Margins.Top + ctrl.Margins.Bottom
      else
        ctrlHeight := ctrl.Height;
      sumHeight := sumHeight + ctrlHeight;
    end;
  end;
  Result := sumHeight;
end;

procedure TForm1.btnImportClick(Sender: TObject);
var
  frm: TFrameImport;
  tab: TChromeTab;
  jsData: TJSONArray;
  dbgrid: TDBGrid;
  datasrc: TDataSource;
  i: Integer;
  row: TJSONObject;
  email: string;
begin
  // ----------------------------------------------------------
  // ----------------------------------------------------------
  //
  // Create and show Import Frame
  //
  frm := TFrameImport.Create(pnMain);
  frm.Parent := pnMain;
  frm.Visible := True;
  frm.Align := alClient;
  tab := ChromeTabs1.Tabs.Add;
  tab.Caption := 'Import';
  tab.Data := frm;
  // ----------------------------------------------------------
  // ----------------------------------------------------------
  //
  // Import data from OpenAPI
  //
  jsData := ImportDataFromClientService(Client_API_Token);
  try
    datasrc := TDataSource.Create(frm);
    dbgrid := TDBGrid.Create(frm);
    dbgrid.AlignWithMargins := True;
    dbgrid.Parent := frm;
    dbgrid.Align := alClient;
    dbgrid.DataSource := datasrc;
    // --------
    DataModMain.LoadContactsFromJSON(jsData);
    datasrc.DataSet := DataModMain.mtabContacts;
  finally
    jsData.Free;
  end;

end;

procedure TForm1.ChromeTabs1ButtonCloseTabClick(Sender: TObject;
  ATab: TChromeTab; var Close: Boolean);
var
  obj: TObject;
begin
  obj := TObject(ATab.Data);
  (obj as TFrame).Free;
end;

procedure TForm1.ChromeTabs1Change(Sender: TObject; ATab: TChromeTab;
  TabChangeType: TTabChangeType);
var
  obj: TObject;
begin
  if Assigned(ATab) then
  begin
    obj := TObject(ATab.Data);
    if (TabChangeType = tcActivated) and Assigned(obj) then
    begin
      HideAllChildFrames(pnMain);
      (obj as TFrame).Visible := True;
    end;
  end;
end;

procedure TForm1.ResizeGroupBox();
var
  sum: integer;
  avaliable: integer;
  labelPixelHeight: integer;
begin
  (*
    sum := lbxFilesToAdd.Height + lbxFilesToRemove.Height;
    lbxFilesToAdd.Height := sum div 2;
    lbxFilesToRemove.Height := sum div 2;
  *)
  with TBitmap.Create do
  begin
    Canvas.Font.Size := GroupBox1.Font.Height;
    labelPixelHeight := Canvas.TextHeight('Zg');
    Free;
  end;
  sum := SumHeightForChildrens(GroupBox1, [lbxFilesToAdd, lbxFilesToRemove]);
  avaliable := GroupBox1.Height - sum - labelPixelHeight;
  if GroupBox1.AlignWithMargins then
    avaliable := avaliable - GroupBox1.Padding.Top - GroupBox1.Padding.Bottom;
  if lbxFilesToAdd.AlignWithMargins then
    avaliable := avaliable - lbxFilesToAdd.Margins.Top -
      lbxFilesToAdd.Margins.Bottom;
  if lbxFilesToRemove.AlignWithMargins then
    avaliable := avaliable - lbxFilesToRemove.Margins.Top -
      lbxFilesToRemove.Margins.Bottom;
  lbxFilesToAdd.Height := avaliable div 2;
end;

procedure TForm1.Splitter1Moved(Sender: TObject);
begin
  (Sender as TSplitter).Tag := 1;
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
  ReportMemoryLeaksOnShutdown := True;
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
