unit ClientAPI.Contacts;

interface

uses
  System.JSON;

function ImportDataFromClientService (const token:string): TJSONArray;

implementation

uses
  System.SysUtils, System.IOUtils;

function GetContactsFromService (const token:string): TJSONValue;
var
  JSONFileName: string;
  fname: string;
  FileContent: string;
begin
  JSONFileName := 'import-data.json';
  if FileExists(JSONFileName) then
    fname := JSONFileName
  else if FileExists('..\..\'+JSONFileName) then
    fname := '..\..\'+JSONFileName
  else
    raise Exception.Create('Error Message');
  FileContent := TFile.ReadAllText(fname,TEncoding.UTF8);
  Result := TJSONObject.ParseJSONValue(FileContent);
end;

function ImportDataFromClientService (const token:string): TJSONArray;
var
  jsValue: TJSONValue;
begin
  jsValue := GetContactsFromService (token);
  if jsValue is TJSONArray then
    Result := jsValue as TJSONArray
  else begin
    jsValue.Free;
    Result := nil;
  end;
end;

end.
