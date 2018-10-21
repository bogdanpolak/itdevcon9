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
    mtabReportsReaderId: TIntegerField;
    mtabReportsISBN: TWideStringField;
    mtabReportsRating: TIntegerField;
    mtabReportsOppinion: TWideStringField;
    mtabReportsReported: TDateField;
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
    procedure OpenMemDataSet(Dataset:TFDMemTable; const JsonFileName: string);
  public
    procedure OpenDataSets;
    function FindReaderByEmil (const email: string): Variant;
  end;

var
  DataModMain: TDataModMain;

implementation

{%CLASSGROUP 'Vcl.Controls.TControl'}
{$R *.dfm}

uses
  System.Variants, ClientAPI.Books;


function TDataModMain.FindReaderByEmil(const email: string): Variant;
var
  ok: Boolean;
begin
  ok := mtabReaders.Locate('email',email,[]);
  if ok then
    Result := mtabReadersReaderId.Value
  else
    Result := System.Variants.Null()
end;

procedure TDataModMain.OpenMemDataSet(Dataset:TFDMemTable; 
  const JsonFileName: string);
var
  fname: string;
begin
  if FileExists(JSONFileName) then
    fname := JSONFileName
  else if FileExists('..\..\' + JSONFileName) then
    fname := '..\..\' + JSONFileName
  else
    raise Exception.Create('Error Message');
  Dataset.LoadFromFile(fname, sfJSON);
end;

procedure TDataModMain.OpenDataSets;
begin
  OpenMemDataSet('json\dbtable-readers.json', mtabReaders);
  OpenMemDataSet('json\dbtable-books.json',mtabBooks);
  mtabReports.CreateDataSet;
end;

end.
