unit Data.Main;

interface

uses
  System.SysUtils, System.Classes, System.JSON,
  FireDAC.Stan.Intf, FireDAC.Stan.Option,
  FireDAC.Stan.Param, FireDAC.Stan.Error, FireDAC.DatS, FireDAC.Phys.Intf,
  FireDAC.DApt.Intf, Data.DB, FireDAC.Comp.DataSet, FireDAC.Comp.Client;

type
  TDataModMain = class(TDataModule)
    mtabContacts: TFDMemTable;
    mtabContactsImport: TBooleanField;
    mtabContactsEmail: TWideStringField;
    mtabContactsFirstName: TWideStringField;
    mtabContactsLastName: TWideStringField;
    mtabContactsCompany: TWideStringField;
    mtabContactsDuplicated: TBooleanField;
    mtabContactsConflicts: TBooleanField;
    mtabContactsCurFirstName: TWideStringField;
    mtabContactsCurLastName: TWideStringField;
    mtabContactsCurCompany: TWideStringField;
  private
    { Private declarations }
  public
    procedure LoadContactsFromJSON (jsData: TJSONArray);
  end;

var
  DataModMain: TDataModMain;

implementation

{%CLASSGROUP 'Vcl.Controls.TControl'}

{$R *.dfm}

{ TDataModMain }

procedure TDataModMain.LoadContactsFromJSON(jsData: TJSONArray);
var
  i: Integer;
  row: TJSONObject;
  email: string;
begin
  mtabContacts.Open;
  mtabContacts.EmptyDataSet;
  mtabContactsImport.DisplayValues := ';';
  for i := 0 to jsData.Count - 1 do
  begin
    mtabContacts.Append;
    mtabContactsImport.Value := True;
    row := jsData.Items[i] as TJSONObject;
    email := row.Values['email'].Value;
    mtabContactsEmail.Value := email;
    if Assigned(row.Values['firstname']) then
      mtabContactsFirstName.Value := row.Values['firstname'].Value;
    if Assigned(row.Values['lastname']) then
      mtabContactsLastName.Value := row.Values['lastname'].Value;
    if Assigned(row.Values['company']) then
      mtabContactsCompany.Value := row.Values['company'].Value;
    mtabContactsDuplicated.Value := False;
    mtabContactsImport.Value := not mtabContactsDuplicated.Value;
    mtabContactsConflicts.Value := False;
    mtabContacts.Post;
  end;
end;

end.
