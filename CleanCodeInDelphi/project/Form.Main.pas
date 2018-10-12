unit Form.Main;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs,
  Vcl.StdCtrls, Vcl.ExtCtrls, Vcl.Grids, Vcl.DBGrids, Data.DB,
  ChromeTabs, ChromeTabsClasses, ChromeTabsTypes,
  Mock.MainForm, ExtGUI.ListBox.Books;

type
  TForm1 = class(TForm)
    GroupBox1: TGroupBox;
    lbBooksReaded: TLabel;
    Splitter1: TSplitter;
    lbBooksAvaliable: TLabel;
    lbxBooksReaded: TListBox;
    lbxBooksAvaliable2: TListBox;
    ChromeTabs1: TChromeTabs;
    pnMain: TPanel;
    btnImport: TButton;
    tmrAppReady: TTimer;
    Splitter2: TSplitter;
    procedure FormCreate(Sender: TObject);
    procedure btnImportClick(Sender: TObject);
    procedure ChromeTabs1ButtonCloseTabClick(Sender: TObject; ATab: TChromeTab;
      var Close: Boolean);
    procedure ChromeTabs1Change(Sender: TObject; ATab: TChromeTab;
      TabChangeType: TTabChangeType);
    procedure FormResize(Sender: TObject);
    procedure Splitter1Moved(Sender: TObject);
    procedure tmrAppReadyTimer(Sender: TObject);
  private
    isDeveloperMode: Boolean;
    isDatabaseOK: Boolean;
    DragedIdx: Integer;
    procedure ResizeGroupBox();
  public
    FDConnection1: TFDConnectionMock;
  end;

var
  Form1: TForm1;

implementation

{$R *.dfm}

uses
  System.StrUtils, System.JSON, System.Math, System.DateUtils,
  Frame.Welcome, Consts.Application, Utils.CipherAES128, Frame.Import,
  Units.Main, Data.Main, ClientAPI.Readers, ClientAPI.Books;

const
  SQL_SELECT_DatabaseVersion = 'SELECT versionnr FROM DBInfo';
  SecureKey = 'delphi-is-the-best';
  // SecurePassword = AES 128 ('masterkey',SecureKey)
  SecurePassword = 'hC52IiCv4zYQY2PKLlSvBaOXc14X41Mc1rcVS6kyr3M=';
  Client_API_Token = '20be805d-9cea27e2-a588efc5-1fceb84d-9fb4b67c';

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

function DBVersionToString(VerDB: Integer): string;
begin
  Result := (VerDB div 1000).ToString + '.' + (VerDB mod 1000).ToString;
end;

procedure TForm1.FormResize(Sender: TObject);
begin
  ResizeGroupBox();
end;

function SumHeightForChildrens(Parent: TWinControl;
  ControlsToExclude: TArray<TControl>): Integer;
var
  i: Integer;
  ctrl: Vcl.Controls.TControl;
  isExcluded: Boolean;
  j: Integer;
  sumHeight: Integer;
  ctrlHeight: Integer;
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

function AutoSizeColumns(DBGrid: TDBGrid; const MaxRows: Integer = 25): Integer;

var
  DataSet: TDataSet;
  Bookmark: TBookmark;
  Count, i: Integer;
  ColumnsWidth: array of Integer;
begin
  SetLength(ColumnsWidth, DBGrid.Columns.Count);
  for i := 0 to DBGrid.Columns.Count - 1 do
    if DBGrid.Columns[i].Visible then
      ColumnsWidth[i] := DBGrid.Canvas.TextWidth
        (DBGrid.Columns[i].title.Caption + '   ')
    else
      ColumnsWidth[i] := 0;
  if DBGrid.DataSource <> nil then
    DataSet := DBGrid.DataSource.DataSet
  else
    DataSet := nil;
  if (DataSet <> nil) and DataSet.Active then
  begin
    Bookmark := DataSet.GetBookmark;
    DataSet.DisableControls;
    try
      Count := 0;
      DataSet.First;
      while not DataSet.Eof and (Count < MaxRows) do
      begin
        for i := 0 to DBGrid.Columns.Count - 1 do
          if DBGrid.Columns[i].Visible then
            ColumnsWidth[i] := Max(ColumnsWidth[i],
              DBGrid.Canvas.TextWidth(DBGrid.Columns[i].Field.Text + '   '));
        Inc(Count);
        DataSet.Next;
      end;
    finally
      DataSet.GotoBookmark(Bookmark);
      DataSet.FreeBookmark(Bookmark);
      DataSet.EnableControls;
    end;
  end;
  Count := 0;
  for i := 0 to DBGrid.Columns.Count - 1 do
    if DBGrid.Columns[i].Visible then
    begin
      DBGrid.Columns[i].Width := ColumnsWidth[i];
      Inc(Count, ColumnsWidth[i]);
    end;
  Result := Count - DBGrid.ClientWidth;
end;

{ TODO: Change function name [jsonObjectHasValue] }
function avaliable(jsObject: TJSONObject; const fieldName: string)
  : Boolean; inline;
begin
  Result := Assigned(jsObject.Values[fieldName]) and not jsObject.Values
    [fieldName].Null;
end;

procedure TForm1.btnImportClick(Sender: TObject);
var
  frm: TFrameImport;
  tab: TChromeTab;
  jsData: TJSONArray;
  DBGrid: TDBGrid;
  datasrc: TDataSource;
  i: Integer;
  jsRow: TJSONObject;
  email: string;
  firstName: string;
  lastName: string;
  company: string;
  bookISBN: string;
  bookTitle: string;
  rating: Integer;
  oppinion: string;
  created: string;
  ss: array of string;
  v: string;
  dt: TDateTime;
  maxID: Integer;
begin
  // ----------------------------------------------------------
  // ----------------------------------------------------------
  //
  // 1. Create TFrameImport.
  // 2. Embed frame in pnMain (show)
  // 3. Add new ChromeTab
  //
  frm := TFrameImport.Create(pnMain);
  frm.Parent := pnMain;
  frm.Visible := True;
  frm.Align := alClient;
  tab := ChromeTabs1.Tabs.Add;
  tab.Caption := 'Readers';
  tab.Data := frm;
  // ----------------------------------------------------------
  // ----------------------------------------------------------
  //
  // Add TDBGrid to TFrameImport
  //
  datasrc := TDataSource.Create(frm);
  DBGrid := TDBGrid.Create(frm);
  DBGrid.AlignWithMargins := True;
  DBGrid.Parent := frm;
  DBGrid.Align := alClient;
  DBGrid.DataSource := datasrc;
  datasrc.DataSet := DataModMain.mtabReaders;
  AutoSizeColumns(DBGrid);
  // ----------------------------------------------------------
  // ----------------------------------------------------------
  //
  // Import new reders data from OpenAPI
  //
  jsData := ImportReadersFromWebService(Client_API_Token);
  try
    for i := 0 to jsData.Count - 1 do
    begin
      jsRow := jsData.Items[i] as TJSONObject;
      email := jsRow.Values['email'].Value;
      if avaliable(jsRow, 'firstname') then
        firstName := jsRow.Values['firstname'].Value
      else
        firstName := '';
      if avaliable(jsRow, 'lastname') then
        lastName := jsRow.Values['lastname'].Value
      else
        lastName := '';
      if avaliable(jsRow, 'company') then
        company := jsRow.Values['company'].Value
      else
        company := '';
      if avaliable(jsRow, 'book-isbn') then
        bookISBN := jsRow.Values['book-isbn'].Value
      else
        bookISBN := '';
      if avaliable(jsRow, 'book-title') then
        bookTitle := jsRow.Values['book-title'].Value
      else
        bookTitle := '';
      if avaliable(jsRow, 'rating') then
        rating := (jsRow.Values['rating'] as TJSONNumber).AsInt
      else
        rating := -1;
      if avaliable(jsRow, 'oppinion') then
        oppinion := jsRow.Values['oppinion'].Value
      else
        oppinion := '';
      if avaliable(jsRow, 'created') then
        created := jsRow.Values['created'].Value
      else
        created := '';
      if created <> '' then
        dt := System.DateUtils.ISO8601ToDate(created, False)
      else
        dt := 0;
      maxID := DataModMain.GetMaxValueInDataSet(DataModMain.mtabReaders,
        'ReaderId');
      DataModMain.mtabReaders.AppendRecord([maxID + 1, firstName, lastName,
        email, company, 1, dt, now()]);
      Insert([rating.ToString], ss, maxInt);
    end;
    Caption := String.Join(' ,', ss);
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

procedure TForm1.ResizeGroupBox();
var
  sum: Integer;
  avaliable: Integer;
  labelPixelHeight: Integer;
begin
  (*
    sum := lbxBooksAvaliable.Height + lbxBooksCooming.Height;
    lbxBooksAvaliable.Height := sum div 2;
    lbxBooksCooming.Height := sum div 2;
  *)
  with TBitmap.Create do
  begin
    Canvas.Font.Size := GroupBox1.Font.Height;
    labelPixelHeight := Canvas.TextHeight('Zg');
    Free;
  end;
  sum := SumHeightForChildrens(GroupBox1, [lbxBooksReaded, lbxBooksAvaliable2]);
  avaliable := GroupBox1.Height - sum - labelPixelHeight;
  if GroupBox1.AlignWithMargins then
    avaliable := avaliable - GroupBox1.Padding.Top - GroupBox1.Padding.Bottom;
  if lbxBooksReaded.AlignWithMargins then
    avaliable := avaliable - lbxBooksReaded.Margins.Top -
      lbxBooksReaded.Margins.Bottom;
  if lbxBooksAvaliable2.AlignWithMargins then
    avaliable := avaliable - lbxBooksAvaliable2.Margins.Top -
      lbxBooksAvaliable2.Margins.Bottom;
  lbxBooksReaded.Height := avaliable div 2;
end;

procedure TForm1.Splitter1Moved(Sender: TObject);
begin
  (Sender as TSplitter).Tag := 1;
end;

procedure TForm1.tmrAppReadyTimer(Sender: TObject);
var
  frm: TFrameWelcome;
  tab: TChromeTab;
  VersionNr: Integer;
  msg1: string;
  UserName: string;
  password: string;
  res: Variant;
  i: Integer;
  b: TBook;
  o: Boolean;
  AllBooks: TBookCollection;
  OtherBooks: TBookCollection;
  booksCfg: TBooksListBoxConfigurator;
  datasrc: TDataSource;
  DataGrid: TDBGrid;
begin
  tmrAppReady.Enabled := False;
  if isDeveloperMode then
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
      frm.AddInfo(0, msg1, True);
      frm.AddInfo(1, E.Message, False);
      exit;
    end;
  end;
  try
    res := FDConnection1.ExecSQLScalar(SQL_SELECT_DatabaseVersion);
  except
    on E: EFDDBEngineException do
    begin
      msg1 := IfThen(E.kind = ekObjNotExists, SDBRequireCreate, SDBErrorSelect);
      frm.AddInfo(0, msg1, True);
      frm.AddInfo(1, E.Message, False);
      exit;
    end;
  end;
  VersionNr := res;
  if VersionNr = ExpectedDatabaseVersionNr then
    isDatabaseOK := True
  else
  begin
    frm.AddInfo(0, StrNotSupportedDBVersion, True);
    frm.AddInfo(1, 'Oczekiwana wersja bazy: ' +
      DBVersionToString(ExpectedDatabaseVersionNr), True);
    frm.AddInfo(1, 'Aktualna wersja bazy: ' + DBVersionToString
      (VersionNr), True);
  end;
  // ----------------------------------------------------------
  // ----------------------------------------------------------
  //
  DataModMain.OpenDataSets;
  // ----------------------------------------------------------
  // ----------------------------------------------------------
  //
  // * Initialize ListBox'es for books
  // * Load books form database
  // * Setup drag&drop functionality for two list boxes
  // * Setup OwnerDraw mode
  //
  TBooksListBoxConfigurator.Create(self).PrepareListBoxes(lbxBooksReaded,
    lbxBooksAvaliable2);
  // ----------------------------------------------------------
  // ----------------------------------------------------------
  //
  // Create Books Table
  datasrc := TDataSource.Create(frm);
  DataGrid := TDBGrid.Create(frm);
  DataGrid.AlignWithMargins := True;
  DataGrid.Parent := frm;
  DataGrid.Align := alClient;
  DataGrid.DataSource := datasrc;
  datasrc.DataSet := DataModMain.mtabBooks;
  AutoSizeColumns(DataGrid);
end;

end.
