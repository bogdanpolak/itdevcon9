unit Data.Main;

interface

uses
  System.SysUtils, System.Classes, System.JSON,
  FireDAC.Stan.Intf, FireDAC.Stan.Option,
  FireDAC.Stan.Param, FireDAC.Stan.Error, FireDAC.DatS, FireDAC.Phys.Intf,
  FireDAC.DApt.Intf, Data.DB, FireDAC.Comp.DataSet, FireDAC.Comp.Client,
  FireDAC.Stan.StorageJSON;

type
  TDataModMain = class(TDataModule)
    // ------------------------------------------------------
    // Readers Table:
    mtabReaders: TFDMemTable;
    mtabReadersReaderId: TIntegerField;
    mtabReadersFirstName: TWideStringField;
    mtabReadersLastName: TWideStringField;
    mtabReadersEmail: TWideStringField;
    mtabReadersCompany: TWideStringField;
    mtabReadersBooksRead: TIntegerField;
    mtabReadersLastReport: TDateField;
    mtabReadersCreated: TDateField;
    // ------------------------------------------------------
    // Reports Table:
    mtabReports: TFDMemTable;
    // ------------------------------------------------------
    // Books Table:
    mtabBooks: TFDMemTable;
    mtabBooksISBN: TWideStringField;
    mtabBooksTitle: TWideStringField;
    mtabBooksAuthors: TWideStringField;
    mtabBooksStatus: TWideStringField;
    mtabBooksReleseDate: TDateField;
    mtabBooksPages: TIntegerField;
    mtabBooksPrice: TCurrencyField;
    mtabBooksCurrency: TWideStringField;
    mtabBooksImported: TDateField;
    mtabBooksDescription: TWideStringField;
    // ------------------------------------------------------
    FDStanStorageJSONLink1: TFDStanStorageJSONLink;
  private
  public
    procedure ImportNewReadersFromJSON(jsData: TJSONArray);
    procedure OpenDataSets;
  end;

var
  DataModMain: TDataModMain;

implementation

{%CLASSGROUP 'Vcl.Controls.TControl'}

uses
  ClientAPI.Books;
{$R *.dfm}
{ TDataModMain }

function BooksToDateTime(const s: string): TDateTime;
const
  months: array [1 .. 12] of string = ('Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec');
var
  m: string;
  y: string;
  i: Integer;
  mm: Integer;
  yy: Integer;
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

procedure TDataModMain.ImportNewReadersFromJSON(jsData: TJSONArray);
var
  i: Integer;
  row: TJSONObject;
  email: string;
  firstName: string;
  lastName: string;
  company: string;
begin
  for i := 0 to jsData.Count - 1 do
  begin
    row := jsData.Items[i] as TJSONObject;
    email := row.Values['email'].Value;
    if Assigned(row.Values['firstname']) and not row.Values['firstname'].Null
    then
      firstName := row.Values['firstname'].Value;
    if Assigned(row.Values['lastname']) and not row.Values['lastname'].Null then
      lastName := row.Values['lastname'].Value;
    if Assigned(row.Values['company']) and not row.Values['company'].Null then
      company := row.Values['company'].Value;
  end;
end;

procedure TDataModMain.OpenDataSets;
var
  JSONFileName: string;
  fname: string;
  days: Integer;
  half: Int64;
  ms: TMemoryStream;
  tab: TFDMemTable;
  j: Integer;
  recNo: Integer;
  email: string;
begin
  // ----------------------------------------------------------
  // ----------------------------------------------------------
  //
  // Load and open Readers table
  JSONFileName := 'json\dbtable-readers.json';
  if FileExists(JSONFileName) then
    fname := JSONFileName
  else if FileExists('..\..\' + JSONFileName) then
    fname := '..\..\' + JSONFileName
  else
    raise Exception.Create('Error Message');
  mtabReaders.LoadFromFile(fname,sfJSON);
  // ----------------------------------------------------------
  // ----------------------------------------------------------
  //
  // Load and open Books table
  JSONFileName := 'json\dbtable-books.json';
  if FileExists(JSONFileName) then
    fname := JSONFileName
  else if FileExists('..\..\' + JSONFileName) then
    fname := '..\..\' + JSONFileName
  else
    raise Exception.Create('Error Message');
  mtabBooks.LoadFromFile(fname,sfJSON);

end;

end.
