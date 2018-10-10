unit DataAccess.Readers;

interface

uses
  Data.DB, System.SysUtils;

type
  IReadersDAO = interface(IInterface)
    ['{F8482010-9FCB-4994-B7E9-47F1DB115075}']
    function fldImport: TBooleanField;
    function fldEmail: TWideStringField;
    function fldFirstName: TWideStringField;
    function fldLastName: TWideStringField;
    function fldCompany: TWideStringField;
    function fldDuplicated: TBooleanField;
    procedure ForEach(proc: TProc<IReadersDAO>);
  end;

implementation

end.
