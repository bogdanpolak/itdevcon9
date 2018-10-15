unit ExtGUI.ListBox.Books;

interface

uses
  System.Classes, Vcl.StdCtrls, Vcl.Controls, System.Types, Vcl.Graphics,
  Vcl.ComCtrls, // TODO: To be cleaned
  Winapi.Windows,
  System.SysUtils, // TODO: To be cleaned
  System.JSON, System.Generics.Collections,
  DataAccess.Books;

{ TODO 3: Move class into the separate unit: Model.Book.pas }
// with or without Book Collection?
type
  TBook = class
    status: string;
    title: string;
    isbn: string;
    author: string;
    releseDate: TDateTime;
    pages: integer;
    price: currency;
    currency: string;
    imported: TDateTime;
    description: string;
    constructor Create(Books: IBooksDAO); overload;
  end;

  TBookCollection = class(TObjectList<TBook>)
  public
    procedure LoadDataSet(BooksDAO: IBooksDAO);
    function FindByISBN (const ISBN: string): TBook;
  end;

type
  TBookListKind = (blAll, blOnShelf, blAvaliable);

type
  TBooksListBoxConfigurator = class(TComponent)
  private
    FAllBooks: TBookCollection;
    FListBoxOnShelf: TListBox;
    FListBoxAvaliable: TListBox;
    FBooksOnShelf: TBookCollection;
    FBooksAvaliable: TBookCollection;
    DragedIdx: integer;
    procedure EventOnStartDrag(Sender: TObject; var DragObject: TDragObject);
    procedure EventOnDragDrop(Sender, Source: TObject; X, Y: integer);
    procedure EventOnDragOver(Sender, Source: TObject; X, Y: integer;
      State: TDragState; var Accept: Boolean);
    procedure EventOnDrawItem(Control: TWinControl; Index: integer; Rect: TRect;
      State: TOwnerDrawState);
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure PrepareListBoxes(lbxOnShelf, lbxAvaliable: TListBox);
    function GetBookList (kind: TBookListKind): TBookCollection; 
    function FindBook (isbn: string): TBook; 
  end; 

implementation

uses ClientAPI.Books, // TODO: remove
  DataAccess.Books.FireDAC, Data.Main;
  // TODO: too much coupled (use dependency injection)

const
  Books_API_Token = 'BOOKS-arg58d8jmefcu5-1fceb'; // TODO: remove

constructor TBooksListBoxConfigurator.Create(AOwner: TComponent);
var
  OtherBooks: TBookCollection;
  b: TBook;
  BooksDAO: IBooksDAO;
begin
  inherited;
  // ---------------------------------------------------
  FAllBooks := TBookCollection.Create();
  BooksDAO := GetBooks_FireDAC(DataModMain.mtabBooks);
  FAllBooks.LoadDataSet(BooksDAO);
  // ---------------------------------------------------
  FBooksOnShelf := TBookCollection.Create(false);
  FBooksAvaliable := TBookCollection.Create(false);
  for b in FAllBooks do
  begin
    if b.status = 'on-shelf' then
      FBooksOnShelf.Add(b)
    else if b.status = 'avaliable' then
      FBooksAvaliable.Add(b)
  end;
end;

destructor TBooksListBoxConfigurator.Destroy;
begin
  FAllBooks.Free;
  FBooksOnShelf.Free;
  FBooksAvaliable.Free;
  inherited;
end;

function TBooksListBoxConfigurator.GetBookList (kind: TBookListKind): 
  TBookCollection;
begin
  case kind of
    blAll: Result := FBooks;
    blOnShelf: Result := FBooks;
    blAvaliable: Result := FBooks;
  end;
end;

function TBooksListBoxConfigurator.FindBook (isbn: string): TBook;
begin
  Result := FAllBooks.FindByISBN (isbn);
end;

procedure TBooksListBoxConfigurator.PrepareListBoxes(lbxOnShelf,
  lbxAvaliable: TListBox);
var
  b: TBook;
begin
  FListBoxOnShelf := lbxOnShelf;
  FListBoxAvaliable := lbxAvaliable;
  for b in FBooksAvaliable do
    FListBoxAvaliable.AddItem(b.title, b);
  // -----------------------------------------------------------------
  // ListBox: books on the shelf
  for b in FBooksOnShelf do
    FListBoxOnShelf.AddItem(b.title, b);
  FListBoxOnShelf.OnDragDrop := EventOnDragDrop;
  FListBoxOnShelf.OnDragOver := EventOnDragOver;
  FListBoxOnShelf.OnStartDrag := EventOnStartDrag;
  FListBoxOnShelf.OnDrawItem := EventOnDrawItem;
  FListBoxOnShelf.Style := lbOwnerDrawFixed;
  FListBoxOnShelf.DragMode := dmAutomatic;
  FListBoxOnShelf.ItemHeight := 50;
  // -----------------------------------------------------------------
  // ListBox: books avaliable
  FListBoxAvaliable.OnDragDrop := EventOnDragDrop;
  FListBoxAvaliable.OnDragOver := EventOnDragOver;
  FListBoxAvaliable.OnStartDrag := EventOnStartDrag;
  FListBoxAvaliable.OnDrawItem := EventOnDrawItem;
  FListBoxAvaliable.Style := lbOwnerDrawFixed;
  FListBoxAvaliable.DragMode := dmAutomatic;
  FListBoxAvaliable.ItemHeight := 50;
end;

procedure TBooksListBoxConfigurator.EventOnStartDrag(Sender: TObject;
  var DragObject: TDragObject);
var
  lbx: TListBox;
begin
  lbx := Sender as TListBox;
  DragedIdx := lbx.ItemIndex;
end;

procedure TBooksListBoxConfigurator.EventOnDragDrop(Sender, Source: TObject;
  X, Y: integer);
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
  if lbx1 = FListBoxOnShelf then
  begin
    srcList := FBooksOnShelf;
    dstList := FBooksAvaliable;
  end
  else
  begin
    srcList := FBooksAvaliable;
    dstList := FBooksOnShelf;
  end;
  dstList.Add(srcList.Extract(b));
  lbx1.Items.Delete(DragedIdx);
  lbx2.AddItem(b.title, b);
end;

procedure TBooksListBoxConfigurator.EventOnDragOver(Sender, Source: TObject;
  X, Y: integer; State: TDragState; var Accept: Boolean);
begin
  Accept := (Source is TListBox) and (DragedIdx >= 0) and (Sender <> Source);
end;

procedure TBooksListBoxConfigurator.EventOnDrawItem(Control: TWinControl;
  Index: integer; Rect: TRect; State: TOwnerDrawState);
var
  s: string;
  ACanvas: TCanvas;
  b: TBook;
  r2: TRect;
  lbx: TListBox;
  colorTextTitle: integer;
  colorTextAuthor: integer;
  colorBackground: integer;
  colorGutter: integer;
begin
  // TOwnerDrawState = set of (odSelected, odGrayed, odDisabled, odChecked,
  // odFocused, odDefault, odHotLight, odInactive, odNoAccel, odNoFocusRect,
  // odReserved1, odReserved2, odComboBoxEdit);
  lbx := Control as TListBox;

  // if (odSelected in State) and (odFocused in State) then
  if (odSelected in State) then
  begin
    colorGutter := $F0FFD0;
    colorTextTitle := clHighlightText;
    colorTextAuthor := $FFFFC0;
    colorBackground := clHighlight;
  end
  else
  begin
    colorGutter := $A0FF20;
    colorTextTitle := lbx.Font.Color;
    colorTextAuthor := $909000;
    colorBackground := lbx.Color;
  end;
  b := lbx.Items.Objects[Index] as TBook;
  s := b.title;
  ACanvas := lbx.Canvas;
  ACanvas.Brush.Color := colorBackground;
  r2 := Rect;
  r2.Left := 0;
  ACanvas.FillRect(r2);
  ACanvas.Brush.Color := colorGutter;
  r2 := Rect;
  r2.Left := 0;
  InflateRect(r2, -3, -5);
  r2.Right := r2.Left + 6;
  ACanvas.FillRect(r2);
  ACanvas.Brush.Color := colorBackground;
  Rect.Left := Rect.Left + 13;
  ACanvas.Font.Color := colorTextAuthor;
  ACanvas.Font.Size := lbx.Font.Size;
  ACanvas.TextOut(13, Rect.Top + 2, b.author);
  r2 := Rect;
  r2.Left := 13;
  r2.Top := r2.Top + ACanvas.TextHeight('Ag');
  ACanvas.Font.Color := colorTextTitle;
  ACanvas.Font.Size := lbx.Font.Size + 2;
  InflateRect(r2, -2, -1);
  DrawText(ACanvas.Handle, PChar(s), Length(s), r2,
    // DT_LEFT or DT_WORDBREAK or DT_CALCRECT);
    DT_LEFT or DT_WORDBREAK);
end;

{ TBookCollection }

procedure TBookCollection.LoadDataSet(BooksDAO: IBooksDAO);
begin
  BooksDAO.ForEach(
    procedure(Books: IBooksDAO)
    begin
      self.Add(TBook.Create(Books));
    end);
end;

function TBookCollection.FindByISBN (const ISBN: string): TBook;
begin
  { TODO 0: (sprawdź nazwisko) Dykstra structural programming [exit] }
  { TODO 1: More readable code for b in Items do. Shorter method }
  for i := 0 to Self.Count-1 do
    if Self.Items[i].isbn = ISBN then
    begin
      Result := Self.Items[i];
      exit;
    end;
end

{ TBook }

constructor TBook.Create(Books: IBooksDAO);
begin
  inherited Create;
  self.isbn := Books.fldISBN.Value;
  self.title := Books.fldTitle.Value;
  self.author := Books.fldAuthors.Value;
  self.status := Books.fldStatus.Value;
  self.releseDate := Books.fldReleseDate.Value;
  self.pages := Books.fldPages.Value;
  self.price := Books.fldPrice.Value;
  self.currency := Books.fldCurrency.Value;
  self.imported := Books.fldImported.Value;
  self.description := Books.fldDescription.Value;
end;

end.
