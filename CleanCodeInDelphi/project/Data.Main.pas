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
    mtabBooksDescription: TWideStringField;
    // ------------------------------------------------------
    FDStanStorageJSONLink1: TFDStanStorageJSONLink;
  private
    { Private declarations }
  public
    procedure ImportNewReadersFromJSON(jsData: TJSONArray);
    procedure OpenDataSets;
  end;

var
  DataModMain: TDataModMain;

implementation

{%CLASSGROUP 'Vcl.Controls.TControl'}
{$R *.dfm}
{ TDataModMain }

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
  JSONFileName := 'json\dbtable-readers.json';
  if FileExists(JSONFileName) then
    fname := JSONFileName
  else if FileExists('..\..\' + JSONFileName) then
    fname := '..\..\' + JSONFileName
  else
    raise Exception.Create('Error Message');
  mtabReaders.LoadFromFile(fname);
end;

end.
