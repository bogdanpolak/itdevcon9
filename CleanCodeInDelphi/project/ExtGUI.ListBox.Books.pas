unit ExtGUI.ListBox.Books;

interface

uses
  System.Classes, Vcl.StdCtrls, Vcl.Controls, System.Types, Vcl.Graphics,
  Vcl.ComCtrls, // TODO: To be cleaned
  Winapi.Windows,
  System.SysUtils, // TODO: To be cleaned
  System.JSON,  System.Generics.Collections;

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
  TBooksListBoxConfigurator = class(TComponent)
  private
    FListBoxOnShelf: TListBox;
    FListBoxAvaliable: TListBox;
    FBooksOnShelf: TBookCollection;
    FBooksAvaliable: TBookCollection;
    DragedIdx: integer;
    procedure EventOnStartDrag(Sender: TObject; var DragObject: TDragObject);
    procedure EventOnDragDrop(Sender, Source: TObject; X, Y: integer);
    procedure EventOnDragOver(Sender, Source: TObject; X, Y: integer;
      State: TDragState; var Accept: Boolean);
    procedure EventOnDrawItem(Control: TWinControl; Index: Integer; Rect: TRect;
      State: TOwnerDrawState);
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure PrepareListBoxes (lbxOnShelf, lbxAvaliable: TListBox);
  end;

implementation

uses ClientAPI.Books;

const
  Books_API_Token = 'BOOKS-arg58d8jmefcu5-1fceb';

constructor TBooksListBoxConfigurator.Create(AOwner: TComponent);
var
  AllBooks: TBookCollection;
  OtherBooks: TBookCollection;
  b: TBook;
begin
  inherited;
  FBooksOnShelf := TBookCollection.Create();
  FBooksAvaliable := TBookCollection.Create();
  AllBooks := TBookCollection.Create(false);
  OtherBooks := TBookCollection.Create();
  AllBooks.LoadDataFromOpenAPI(Books_API_Token);
  for b in AllBooks do
  begin
    if b.status = 'on-shelf' then
      FBooksOnShelf.Add(b)
    else if b.status = 'avaliable' then
      FBooksAvaliable.Add(b)
    else
      OtherBooks.Add(b);
  end;
  AllBooks.Free;
  OtherBooks.Free;
end;

destructor TBooksListBoxConfigurator.Destroy;
begin
  FBooksOnShelf.Free;
  FBooksAvaliable.Free;
  inherited;
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
    Index: Integer; Rect: TRect; State: TOwnerDrawState);
var
  s: string;
  ACanvas: TCanvas;
  b: TBook;
  r2: TRect;
  lbx: TListBox;
  colorTextTitle: Integer;
  colorTextAuthor: Integer;
  colorBackground: Integer;
  colorGutter: Integer;
begin
  // TOwnerDrawState = set of (odSelected, odGrayed, odDisabled, odChecked,
  // odFocused, odDefault, odHotLight, odInactive, odNoAccel, odNoFocusRect,
  // odReserved1, odReserved2, odComboBoxEdit);
  lbx := Control as TListBox;

  // if (odSelected in State) and (odFocused in State) then
  if (odSelected in State) then
  begin
    colorGutter := $f0ffd0;
    colorTextTitle := clHighlightText;
    colorTextAuthor := $ffffc0;
    colorBackground := clHighlight;
  end
  else
  begin
    colorGutter := $a0ff20;
    colorTextTitle := lbx.Font.Color;
    colorTextAuthor := $909000;
    colorBackground := lbx.Color;
  end;
  b := lbx.Items.Objects[Index] as TBook;
  s := b.title;
  ACanvas := lbx.Canvas;
  ACanvas.Brush.Color := colorBackground;
  r2 := Rect;  r2.Left := 0;
  ACanvas.FillRect(r2);
  ACanvas.Brush.Color := colorGutter;
  r2 := Rect; r2.Left := 0;
  InflateRect(r2,-3,-5);
  r2.Right := r2.Left+6;
  ACanvas.FillRect(r2);
  ACanvas.Brush.Color := colorBackground;
  Rect.Left := Rect.Left + 13;
  ACanvas.Font.Color := colorTextAuthor;
  ACanvas.Font.Size := lbx.Font.Size;
  ACanvas.TextOut(13,Rect.Top+2,b.author);
  r2 := Rect;
  r2.Left := 13;
  r2.Top := r2.Top + ACanvas.TextHeight('Ag');
  ACanvas.Font.Color := colorTextTitle;
  ACanvas.Font.Size := lbx.Font.Size+2;
  InflateRect(r2,-2,-1);
  DrawText(ACanvas.Handle,
    PChar(s),
    Length(s),
    r2,
    // DT_LEFT or DT_WORDBREAK or DT_CALCRECT);
    DT_LEFT or DT_WORDBREAK);
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
  jsBooks := ImportBooksFromWebService(token);
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
