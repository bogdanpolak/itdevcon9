unit DataAccess.Readers.FireDAC;

interface

uses
  Data.DB, System.SysUtils, FireDAC.Comp.DataSet,
  DataAccess.Base, DataAccess.Readers;

type
  TFDReadersDAO = class(TBaseDAO, IReadersDAO)
  strict private
    FImportField: TBooleanField;
    FEmailField: TWideStringField;
    FFirstNameField: TWideStringField;
    FLastNameField: TWideStringField;
    FCompanyField: TWideStringField;
    FDuplicatedField: TBooleanField;
  strict protected
    procedure BindDataSetFields(); override;
  public
    constructor Create(DataSet: TFDDataSet);
    function fldImport: TBooleanField;
    function fldEmail: TWideStringField;
    function fldFirstName: TWideStringField;
    function fldLastName: TWideStringField;
    function fldCompany: TWideStringField;
    function fldDuplicated: TBooleanField;
    procedure ForEach(proc: TProc<IReadersDAO>);
  end;

function GetReader_FireDAC(DataSet: TFDDataSet): IReadersDAO;

implementation

procedure TFDReadersDAO.BindDataSetFields;
begin
  if Assigned(FDataSet) and FDataSet.Active then
  begin
    FImportField := FDataSet.FieldByName('Import') as TBooleanField;
    FEmailField := FDataSet.FieldByName('Email') as TWideStringField;
    FFirstNameField := FDataSet.FieldByName('FirstName') as TWideStringField;
    FLastNameField := FDataSet.FieldByName('LastName') as TWideStringField;
    FCompanyField := FDataSet.FieldByName('Company') as TWideStringField;
    FDuplicatedField := FDataSet.FieldByName('Duplicated') as TBooleanField;
  end
  else
    raise Exception.Create('Error Message');
end;

constructor TFDReadersDAO.Create(DataSet: TFDDataSet);
begin
  inherited Create();
  LinkDataSet(DataSet, true);
end;

function TFDReadersDAO.fldCompany: TWideStringField;
begin
  Result := FCompanyField;
end;

function TFDReadersDAO.fldDuplicated: TBooleanField;
begin
  Result := FDuplicatedField;
end;

function TFDReadersDAO.fldEmail: TWideStringField;
begin
  Result := FEmailField;
end;

function TFDReadersDAO.fldFirstName: TWideStringField;
begin
  Result := FFirstNameField;
end;

function TFDReadersDAO.fldImport: TBooleanField;
begin
  Result := FImportField;
end;

function TFDReadersDAO.fldLastName: TWideStringField;
begin
  Result := FLastNameField;
end;

procedure TFDReadersDAO.ForEach(proc: TProc<IReadersDAO>);
begin
  FDataSet.First;
  while not FDataSet.Eof do
  begin
    proc(self);
    FDataSet.Next;
  end;
end;

function GetReader_FireDAC(DataSet: TFDDataSet): IReadersDAO;
begin
  Result := TFDReadersDAO.Create(DataSet);
end;

end.
