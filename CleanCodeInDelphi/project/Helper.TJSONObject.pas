unit Helper.TJSONObject;

interface

uses
  System.JSON, System.Variants;

type
  THelperJSONObject = class helper for TJSONObject
  private
    function GetValuesEx(const Name: string): Variant;
    procedure SetValuesEx(const Name: string; Value: Variant);
  public
    function FieldHasNotNullValue(const fieldName: string): Boolean;
    function FieldGetIsoDateUtc(const Name: string): TDateTime;
    function FieldIsValidIsoDateUtc(const Name: string): Boolean;
    { TODO : Add XML Documentation summary at least }
    property ValuesEx[const Name: string]: Variant read GetValuesEx
      write SetValuesEx;
  end;

implementation

uses
  System.SysUtils, System.DateUtils;

// ----------------------------------------------------------
//
// Function checks is TJsonObject has field and this field has not null value
//
function THelperJSONObject.FieldHasNotNullValue(const fieldName: string)
  : Boolean;
begin
  Result := Assigned(self.Values[fieldName]) and not self.Values
    [fieldName].Null;
end;

function THelperJSONObject.GetValuesEx(const Name: string): Variant;
var
  jsValue: TJSONValue;
begin
  jsValue := self.Values[Name];
  if Assigned(jsValue) and not(jsValue.Null) then
    Result := jsValue.Value
  else
    Result := Null;
end;

procedure THelperJSONObject.SetValuesEx(const Name: string; Value: Variant);
begin
  { TODO : Not implemented yet }
  raise Exception.Create('Internal developer error. Not implemented yet');
end;

function THelperJSONObject.FieldIsValidIsoDateUtc(const Name: string): Boolean;
begin
  try
    System.DateUtils.ISO8601ToDate(self.Values[Name].Value, False);
    Result := True;
  except
    on E: Exception do
      Result := False;
  end
end;

function THelperJSONObject.FieldGetIsoDateUtc(const Name: string): TDateTime;
begin
  Result := System.DateUtils.ISO8601ToDate(self.Values[Name].Value, False);
end;



end.
