unit Form.Main;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs,
  Vcl.StdCtrls, Vcl.ExtCtrls, Vcl.Grids, Vcl.DBGrids, Data.DB,

  ChromeTabs, ChromeTabsClasses, ChromeTabsTypes,
  Mock.MainForm, System.Generics.Collections;

type
  TBook = class
    status: string;
    title: string;
    isbn: string;
    author: string;
    date: string;
    pages: integer;
    price: currency;
    currency: string;
    description: string;
  end;

  TBookCollection = class(TObjectList<TBook>)
  public
    procedure LoadDataFromOpenAPI(const token: string);
  end;

type
  TForm1 = class(TForm)
    GroupBox1: TGroupBox;
    lbBooksAvaliable: TLabel;
    Splitter1: TSplitter;
    lbBooksCooming: TLabel;
    lbxBooksAvaliable: TListBox;
    lbxBooksCooming: TListBox;
    ChromeTabs1: TChromeTabs;
    pnMain: TPanel;
    btnImport: TButton;
    tmrAppReady: TTimer;
    procedure FormCreate(Sender: TObject);
    procedure btnImportClick(Sender: TObject);
    procedure ChromeTabs1ButtonCloseTabClick(Sender: TObject; ATab: TChromeTab;
      var Close: Boolean);
    procedure ChromeTabs1Change(Sender: TObject; ATab: TChromeTab;
      TabChangeType: TTabChangeType);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure FormResize(Sender: TObject);
    procedure lbxBooksStartDrag(Sender: TObject; var DragObject:
        TDragObject);
    procedure lbxBooksDragDrop(Sender, Source: TObject; X, Y: Integer);
    procedure lbxBooksDragOver(Sender, Source: TObject; X, Y: Integer;
        State: TDragState; var Accept: Boolean);
    procedure Splitter1Moved(Sender: TObject);
    procedure tmrAppReadyTimer(Sender: TObject);
  private
    isDeveloperMode: Boolean;
    isDatabaseOK: Boolean;
    AvaliableBooks: TBookCollection;
    CoomingSoonBooks: TBookCollection;
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
  System.StrUtils, System.JSON, System.Math,
  Frame.Welcome, Consts.Application, Utils.CipherAES128, Frame.Import,
  Units.Main, ClientAPI.Contacts, Data.Main, ClientAPI.Books;

const
  SQL_SELECT_DatabaseVersion = 'SELECT versionnr FROM DBInfo';
  SecureKey = 'delphi-is-the-best';
  // SecurePassword = AES 128 ('masterkey',SecureKey)
  SecurePassword = 'hC52IiCv4zYQY2PKLlSvBaOXc14X41Mc1rcVS6kyr3M=';
  Client_API_Token = '20be805d-9cea27e2-a588efc5-1fceb84d-9fb4b67c';
  Books_API_Token = 'BOOKS-arg58d8jmefcu5-1fceb';

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

function AutoSizeColumns(DBGrid: TDBGrid; const MaxRows: integer = 25): integer;

var
  DataSet: TDataSet;
  Bookmark: TBookmark;
  Count, i: integer;
  ColumnsWidth: array of integer;
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

procedure TForm1.btnImportClick(Sender: TObject);
var
  frm: TFrameImport;
  tab: TChromeTab;
  jsData: TJSONArray;
  DBGrid: TDBGrid;
  datasrc: TDataSource;
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
    DBGrid := TDBGrid.Create(frm);
    DBGrid.AlignWithMargins := True;
    DBGrid.Parent := frm;
    DBGrid.Align := alClient;
    DBGrid.DataSource := datasrc;
    // --------
    DataModMain.LoadContactsFromJSON(jsData);
    datasrc.DataSet := DataModMain.mtabContacts;
    AutoSizeColumns(DBGrid);
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
  AvaliableBooks := TBookCollection.Create();
  CoomingSoonBooks := TBookCollection.Create();
end;

procedure TForm1.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  AvaliableBooks.Free;
  CoomingSoonBooks.Free;
end;

procedure TForm1.lbxBooksStartDrag(Sender: TObject; var DragObject:
    TDragObject);
var
  lbx: TListBox;
begin
  lbx := Sender as TListBox;
  DragedIdx := lbx.ItemIndex;
end;

procedure TForm1.lbxBooksDragDrop(Sender, Source: TObject; X, Y:
    Integer);
var
  lbx2: TListBox;
  lbx1: TListBox;
  b: TBook;
  srcList: TBookCollection;
  dstList: TBookCollection;
begin
  lbx1 := Source as TListBox;
  lbx2 := Sender as TListBox;
  b := lbx1.Items.Objects[DragedIdx] as TBook;
  if lbx1=lbxBooksAvaliable then begin
    srcList := AvaliableBooks;
    dstList := CoomingSoonBooks;
  end
  else begin
    srcList := CoomingSoonBooks;
    dstList := AvaliableBooks;
  end;
  dstList.Add(srcList.Extract(b));
  lbx1.Items.Delete(DragedIdx);
  lbx2.AddItem(b.title, b);
end;

procedure TForm1.lbxBooksDragOver(Sender, Source: TObject; X, Y:
    Integer; State: TDragState; var Accept: Boolean);
begin
  Accept := (Source is TListBox) and (DragedIdx>=0) and (Sender <> Source);
end;

procedure TForm1.ResizeGroupBox();
var
  sum: integer;
  avaliable: integer;
  labelPixelHeight: integer;
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
  sum := SumHeightForChildrens(GroupBox1, [lbxBooksAvaliable, lbxBooksCooming]);
  avaliable := GroupBox1.Height - sum - labelPixelHeight;
  if GroupBox1.AlignWithMargins then
    avaliable := avaliable - GroupBox1.Padding.Top - GroupBox1.Padding.Bottom;
  if lbxBooksAvaliable.AlignWithMargins then
    avaliable := avaliable - lbxBooksAvaliable.Margins.Top -
      lbxBooksAvaliable.Margins.Bottom;
  if lbxBooksCooming.AlignWithMargins then
    avaliable := avaliable - lbxBooksCooming.Margins.Top -
      lbxBooksCooming.Margins.Bottom;
  lbxBooksAvaliable.Height := avaliable div 2;
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
  i: Integer;
  b: TBook;
  o: Boolean;
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
  //
  //
  AvaliableBooks.LoadDataFromOpenAPI(Books_API_Token);
  for b in AvaliableBooks do
    if b.status = 'cooming-soon' then
      CoomingSoonBooks.Add(AvaliableBooks.Extract(b));
  for b in AvaliableBooks do
    lbxBooksAvaliable.AddItem(b.title, b);
  for b in CoomingSoonBooks do
    lbxBooksCooming.AddItem(b.title, b);
end;

{ TBookCollection }

procedure TBookCollection.LoadDataFromOpenAPI(const token: string);
var
  jsBooks: TJSONArray;
  i: Integer;
  jsBook: TJSONObject;
  b: TBook;
  fs: TFormatSettings;
  s: string;
begin
  jsBooks := ImportDataFromBooksService(token);
  for i := 0 to jsBooks.Count-1 do
  begin
    jsBook := jsBooks.Items[i] as TJSONObject;
    b := TBook.Create;
    b.status := jsBook.Values['status'].Value;
    b.title := jsBook.Values['title'].Value;
    b.isbn := jsBook.Values['isbn'].Value;
    b.author := jsBook.Values['author'].Value;
    b.date := jsBook.Values['date'].Value;
    b.pages := (jsBook.Values['pages'] as TJSONNumber).AsInt;
    b.price := StrToCurr( jsBook.Values['price'].Value);
    b.currency := jsBook.Values['currency'].Value;
    b.description := jsBook.Values['description'].Value;
    self.Add(b);
  end;
  jsBooks.Free;
end;

end.
