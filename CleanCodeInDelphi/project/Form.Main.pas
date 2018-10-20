﻿unit Form.Main;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs,
  Vcl.StdCtrls, Vcl.ExtCtrls, Vcl.Grids, Vcl.DBGrids, Data.DB,
  ChromeTabs, ChromeTabsClasses, ChromeTabsTypes,
  Fake.FDConnection,
  {TODO 3: [D] Resolve dependency on ExtGUI.ListBox.Books. Too tightly coupled}
  // Dependency is requred by attribute TBooksListBoxConfigurator
  ExtGUI.ListBox.Books;

type
  TFrameClass = class of TFrame;

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
    FBooksConfig: TBooksListBoxConfigurator;
    FApplicationInDeveloperMode: Boolean;
    procedure AutoSizeBooksGroupBoxes();
    procedure NewBooks_LoadFromWebServiceAndInsert;
    function CreateAndShowFrame(FrameClass: TFrameClass;
      const Title: string): TFrame;
    procedure ReaderReports_LoadFromWebServiceAndValidateAndInsert();
    procedure LocateBookByISBN(const bookISBN: string);
    function InsertReader(const firstName: string; const lastName: string;
      const email: string; const company: string;
      const dtReported: TDateTime): integer;
    procedure CreateBooksGridOnFrame(frm: TFrame; GridAlign: TAlign = alClient);
  public
    FDConnection1: TFDConnectionMock;
  end;

var
  Form1: TForm1;

implementation

{$R *.dfm}

uses
  System.StrUtils, System.Math, System.DateUtils,
  System.RegularExpressions, System.JSON,
  Frame.Welcome, Consts.Application, Utils.CipherAES128, Frame.Import,
  Utils.General, Data.Main, ClientAPI.Readers, ClientAPI.Books, Consts.SQL,
  Helper.TJSONObject, Helper.TDataSet, Helper.DBGrid;

const
  SecureKey = 'delphi-is-the-best';
  // SecurePassword = AES 128 ('masterkey',SecureKey)
  SecurePassword = 'hC52IiCv4zYQY2PKLlSvBaOXc14X41Mc1rcVS6kyr3M=';
  Client_API_Token = '20be805d-9cea27e2-a588efc5-1fceb84d-9fb4b67c';

resourcestring
  SWelcomeScreen = 'Welcome screen';
  SDBServerGone = 'Database server is gone';
  SDBConnectionUserPwdInvalid = 'Invalid database configuration.' +
    ' Application database user or password is incorrect.';
  SDBConnectionError = 'Can''t connect to database server. Unknown error.';
  SDBRequireCreate = 'Database is empty. You need to execute script' +
    ' creating required data.';
  SDBErrorSelect = 'Can''t execute SELECT command on the database';
  StrNotSupportedDBVersion = 'Not supported database version. Please' +
    ' update database structures.';
  StrBookIsbnNotFound = 'Book ISBN: %s not found in the database';

function DBVersionToString(VerDB: integer): string;
begin
  Result := (VerDB div 1000).ToString + '.' + (VerDB mod 1000).ToString;
end;

procedure TForm1.FormResize(Sender: TObject);
begin
  AutoSizeBooksGroupBoxes();
end;

{ TODO 2: [Helper] TWinControl class helper }
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

{ TODO 2: [Helper] TJSONObject Class helpper and this method has two responsibilities }
// Warning! In-out var parameter
// extract separate:  GetIsoDateUtc
function IsValidIsoDateUtc(jsObj: TJSONObject; const Field: string;
  var dt: TDateTime): Boolean;
begin
  dt := 0;
  try
    dt := System.DateUtils.ISO8601ToDate(jsObj.Values[Field].Value, False);
    Result := True;
  except
    on E: Exception do
      Result := False;
  end
end;

{ TODO 2: Move into Utils.General }
function CheckEmail(const s: string): Boolean;
const
  EMAIL_REGEX = '^((?>[a-zA-Z\d!#$%&''*+\-/=?^_`{|}~]+\x20*|"((?=[\x01-\x7f])' +
    '[^"\\]|\\[\x01-\x7f])*"\x20*)*(?<angle><))?((?!\.)' +
    '(?>\.?[a-zA-Z\d!#$%&''*+\-/=?^_`{|}~]+)+|"((?=[\x01-\x7f])' +
    '[^"\\]|\\[\x01-\x7f])*")@(((?!-)[a-zA-Z\d\-]+(?<!-)\.)+[a-zA-Z]' +
    '{2,}|\[(((?(?<!\[)\.)(25[0-5]|2[0-4]\d|[01]?\d?\d))' +
    '{4}|[a-zA-Z\d\-]*[a-zA-Z\d]:((?=[\x01-\x7f])[^\\\[\]]|\\' +
    '[\x01-\x7f])+)\])(?(angle)>)$';
begin
  Result := System.RegularExpressions.TRegEx.IsMatch(s, EMAIL_REGEX);
end;

function BooksToDateTime(const s: string): TDateTime;
const
  months: array [1 .. 12] of string = ('Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec');
var
  m: string;
  y: string;
  i: integer;
  mm: integer;
  yy: integer;
begin
  m := s.Substring(0, 3);
  y := s.Substring(4);
  mm := 0;
  for i := 1 to 12 do
    if months[i].ToUpper = m.ToUpper then
      mm := i;
  if mm = 0 then
    raise ERangeError.Create('Incorect mont name in the date: ' + s);
  yy := y.ToInteger();
  Result := EncodeDate(yy, mm, 1);
end;

// TODO 3: Move this procedure into class (idea)
procedure ValidateReport(jsRow: TJSONObject; email: string;
  var dtReported: TDateTime);
begin
  if not CheckEmail(email) then
    raise Exception.Create('Invalid email addres');
  if not IsValidIsoDateUtc(jsRow, 'created', dtReported) then
    raise Exception.Create('Invalid date. Expected ISO format');
end;

procedure TForm1.NewBooks_LoadFromWebServiceAndInsert;
var
  jsBooks: TJSONArray;
  jsBook: TJSONObject;
  i: integer;
  TextBookReleseDate: string;
  b2: TBook;
  b: TBook;
begin
  { TODO 3: Two responsibilities in one method. Needs to be separated }
  // 1) Load new books for Web Service
  // 2) Import books form JSON
  // ** 3) Inserting books into DB table :-)
  jsBooks := ImportBooksFromWebService(Client_API_Token);
  try
    for i := 0 to jsBooks.Count - 1 do
    begin
      jsBook := jsBooks.Items[i] as TJSONObject;
      b := TBook.Create;
      b.status := jsBook.Values['status'].Value;
      b.Title := jsBook.Values['title'].Value;
      b.isbn := jsBook.Values['isbn'].Value;
      b.author := jsBook.Values['author'].Value;
      TextBookReleseDate := jsBook.Values['date'].Value;
      b.releseDate := BooksToDateTime(TextBookReleseDate);
      b.pages := (jsBook.Values['pages'] as TJSONNumber).AsInt;
      b.price := StrToCurr(jsBook.Values['price'].Value);
      b.currency := jsBook.Values['currency'].Value;
      b.description := jsBook.Values['description'].Value;
      b.imported := Now;
      b2 := FBooksConfig.GetBookList(blkAll).FindByISBN(b.isbn);
      if not Assigned(b2) then
      begin
        FBooksConfig.InsertNewBook(b);
        // ----------------------------------------------------------------
        // Append report into the database:
        // Fields: ISBN, Title, Authors, Status, ReleseDate, Pages, Price,
        // Currency, Imported, Description
        DataModMain.mtabBooks.InsertRecord([b.isbn, b.Title, b.author, b.status,
          b.releseDate, b.pages, b.price, b.currency, b.imported,
          b.description]);
      end;
    end;
  finally
    jsBooks.Free;
  end;
end;

procedure TForm1.ReaderReports_LoadFromWebServiceAndValidateAndInsert();
var
  jsReports: TJSONArray;
  i: integer;
  jsReport: TJSONObject;
  email: string;
  dtReported: TDateTime;
  firstName: string;
  lastName: string;
  company: string;
  bookISBN: string;
  bookTitle: string;
  rating: integer;
  oppinion: string;
  ReaderId: Variant;
  ss: array of string;
begin
  jsReports := ImportReaderReportsFromWebService(Client_API_Token);
  try
    for i := 0 to jsReports.Count - 1 do
    begin
      { TODO 3: [A] Extract Reader Report code into the record TReaderReport (model layer) }
      // ----------------------------------------------------------------
      jsReport := jsReports.Items[i] as TJSONObject;
      email := jsReport.Values['email'].Value;
      // ----------------------------------------------------------------
      //
      // Validate imported Reader report
      //
      { TODO 2: email is not required as an parameter. Remove it latter }
      ValidateReport(jsReport, email, dtReported);
      // ----------------------------------------------------------------
      //
      // Read JSON object
      //
      { TODO 3: [A] Move this code into record TReaderReport.LoadFromJSON }
      firstName := VarToStr(jsReport.ValuesEx['firstname']);
      lastName := VarToStr(jsReport.ValuesEx['lastname']);
      company := VarToStr(jsReport.ValuesEx['company']);
      bookISBN := VarToStr(jsReport.ValuesEx['book-isbn']);
      bookTitle := VarToStr(jsReport.ValuesEx['book-title']);
      oppinion := VarToStr(jsReport.ValuesEx['oppinion']);
      if jsReport.FieldHasNotNullValue('rating') then
        rating := jsReport.Values['rating'].GetValue<integer>()
      else
        rating := -1;
      // ----------------------------------------------------------------
      LocateBookByISBN(bookISBN);
      ReaderId := DataModMain.FindReaderByEmil(email);
      if VarIsNull(ReaderId) then
        ReaderId := InsertReader(firstName, lastName, email, company,
          dtReported);
      // ----------------------------------------------------------------
      //
      // Append report into the database:
      // Fields: ReaderId, ISBN, Rating, Oppinion, Reported
      //
      DataModMain.mtabReports.AppendRecord([ReaderId, bookISBN, rating,
        oppinion, dtReported]);
      // ----------------------------------------------------------------
      if FApplicationInDeveloperMode then
        Insert([rating.ToString], ss, maxInt);
    end;
    // ----------------------------------------------------------------
    if FApplicationInDeveloperMode then
      Caption := String.Join(' ,', ss);
  finally
    jsReports.Free;
  end;
end;

procedure TForm1.LocateBookByISBN(const bookISBN: string);
var
  Book: TBook;
begin
  Book := FBooksConfig.GetBookList(blkAll).FindByISBN(bookISBN);
  if not Assigned(Book) then
    raise Exception.Create(Format(StrBookIsbnNotFound, [bookISBN]));
end;

function TForm1.InsertReader(const firstName: string; const lastName: string;
  const email: string; const company: string;
  const dtReported: TDateTime): integer;
var
  ReaderId: integer;
begin
  ReaderId := DataModMain.mtabReaders.GetMaxIntegerValue('ReaderId') + 1;
  //
  // Fields: ReaderId, FirstName, LastName, Email, Company, BooksRead,
  // LastReport, ReadersCreated
  //
  DataModMain.mtabReaders.AppendRecord([ReaderId, firstName, lastName, email,
    company, 1, dtReported, Now]);
end;

procedure TForm1.btnImportClick(Sender: TObject);
var
  frm: TFrameImport;
  tab: TChromeTab;
  DBGrid1: TDBGrid;
  DataSrc1: TDataSource;
  DBGrid2: TDBGrid;
  DataSrc2: TDataSource;
begin
  NewBooks_LoadFromWebServiceAndInsert;
  frm := CreateAndShowFrame(TFrameImport, 'Readers Report') as TFrameImport;
  ReaderReports_LoadFromWebServiceAndValidateAndInsert();
  // ----------------------------------------------------------
  // ----------------------------------------------------------
  //
  // Dynamically Add TDBGrid to TFrameImport
  //
  { TODO 2: Move this GUI creation into TFrameImport }
  DataSrc1 := TDataSource.Create(frm);
  DBGrid1 := TDBGrid.Create(frm);
  DBGrid1.AlignWithMargins := True;
  DBGrid1.Parent := frm;
  DBGrid1.Align := alClient;
  DBGrid1.DataSource := DataSrc1;
  DataSrc1.DataSet := DataModMain.mtabReaders;
  DBGrid1.AutoSizeColumns();
  // ----------------------------------------------------------------
  with TSplitter.Create(frm) do
  begin
    Align := alBottom;
    Parent := frm;
    Height := 5;
  end;
  DBGrid1.Margins.Bottom := 0;
  DataSrc2 := TDataSource.Create(frm);
  DBGrid2 := TDBGrid.Create(frm);
  DBGrid2.AlignWithMargins := True;
  DBGrid2.Parent := frm;
  DBGrid2.Align := alBottom;
  DBGrid2.Height := frm.Height div 3;
  DBGrid2.DataSource := DataSrc2;
  DataSrc2.DataSet := DataModMain.mtabReports;
  DBGrid2.Margins.Top := 0;
  DBGrid2.AutoSizeColumns();
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
  // ----------------------------------------------------------
  // Check: If we are in developer mode
  //
  // Developer mode id used to change application configuration
  // during test
  { TODO 2: [Helper] TApplication.IsDeveloperMode }
{$IFDEF DEBUG}
  Extention := '.dpr';
  ExeName := ExtractFileName(Application.ExeName);
  ProjectFileName := ChangeFileExt(ExeName, Extention);
  FApplicationInDeveloperMode := FileExists(ProjectFileName) or
    FileExists('..\..\' + ProjectFileName);
{$ELSE}
  // To rename attribute (variable in the object) FDevMod I'm using buiid in
  // IDE refactoring which is great, but be aware:
  // Refactoring [Rename Variable] can't find this place :-(
  FDevMod := False;
{$ENDIF}
  pnMain.Caption := '';
end;

procedure TForm1.AutoSizeBooksGroupBoxes();
var
  sum: integer;
  avaliable: integer;
  labelPixelHeight: integer;
begin
  { TODO 3: Move into TBooksListBoxConfigurator }
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

function TForm1.CreateAndShowFrame(FrameClass: TFrameClass;
  const Title: string): TFrame;
var
  tab: TChromeTab;
  frm: TFrame;
begin
  frm := FrameClass.Create(pnMain);
  frm.Parent := pnMain;
  frm.Visible := True;
  frm.Align := alClient;
  tab := ChromeTabs1.Tabs.Add;
  tab.Caption := Title;
  tab.Data := frm;
  Result := frm;
end;

procedure TForm1.Splitter1Moved(Sender: TObject);
begin
  (Sender as TSplitter).Tag := 1;
end;

procedure TForm1.CreateBooksGridOnFrame(frm: TFrame;
  GridAlign: TAlign = alClient);
var
  datasrc: TDataSource;
  DataGrid: TDBGrid;
begin
  datasrc := TDataSource.Create(frm);
  DataGrid := TDBGrid.Create(frm);
  DataGrid.AlignWithMargins := True;
  DataGrid.Parent := frm;
  DataGrid.Align := GridAlign;
  DataGrid.DataSource := datasrc;
  datasrc.DataSet := DataModMain.mtabBooks;
  DataGrid.AutoSizeColumns();
end;

procedure TForm1.tmrAppReadyTimer(Sender: TObject);
var
  frm: TFrameWelcome;
  VersionNr: integer;
  msg1: string;
  UserName: string;
  password: string;
  res: Variant;
begin
  tmrAppReady.Enabled := False;
  if FApplicationInDeveloperMode then
    ReportMemoryLeaksOnShutdown := True;
  frm := CreateAndShowFrame(TFrameWelcome, 'Welcome') as TFrameWelcome;
  // ----------------------------------------------------------
  // ----------------------------------------------------------
  //
  // Connect to database server
  // Check application user and database structure (DB version)
  //
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
    { TODO: Why the application is doing nothing when we successfully connected into the database }
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
  FBooksConfig := TBooksListBoxConfigurator.Create(self);
  FBooksConfig.PrepareListBoxes(lbxBooksReaded, lbxBooksAvaliable2);
  // ----------------------------------------------------------
  if FApplicationInDeveloperMode and InInternalQualityMode then
    CreateBooksGridOnFrame(frm);
end;

end.
