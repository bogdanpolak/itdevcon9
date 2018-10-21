unit Frame.Import;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.ExtCtrls;

type
  TFrameImport = class(TFrame)
    tmrFrameReady: TTimer;
    procedure tmrFrameReadyTimer(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
    procedure BuildDBGridsForReadersAndReports;
  end;

implementation

{$R *.dfm}

uses
  Vcl.DBGrids, Data.Main, Data.DB, Helper.DBGrid;

procedure TFrameImport.BuildDBGridsForReadersAndReports;
var
  DBGrid1: TDBGrid;
  DataSrc1: TDataSource;
  DBGrid2: TDBGrid;
  DataSrc2: TDataSource;
begin
  // ----------------------------------------------------------
  // TDBGrid with Readers (aligned client)
  DataSrc1 := TDataSource.Create(Self);
  DBGrid1 := TDBGrid.Create(Self);
  DBGrid1.AlignWithMargins := True;
  DBGrid1.Parent := Self;
  DBGrid1.Align := alClient;
  DBGrid1.DataSource := DataSrc1;
  DataSrc1.DataSet := DataModMain.mtabReaders;
  DBGrid1.AutoSizeColumns();
  // ----------------------------------------------------------
  // Splitter (beetwen grids) (aligned bottom)
  with TSplitter.Create(Self) do
  begin
    Align := alBottom;
    Parent := Self;
    Height := 5;
  end;
  // ----------------------------------------------------------
  // TDBGrid with Reports (aligned bottom)
  DBGrid1.Margins.Bottom := 0;
  DataSrc2 := TDataSource.Create(Self);
  DBGrid2 := TDBGrid.Create(Self);
  DBGrid2.AlignWithMargins := True;
  DBGrid2.Parent := Self;
  DBGrid2.Align := alBottom;
  DBGrid2.Height := Self.Height div 3;
  DBGrid2.DataSource := DataSrc2;
  DataSrc2.DataSet := DataModMain.mtabReports;
  DBGrid2.Margins.Top := 0;
  DBGrid2.AutoSizeColumns();
end;

procedure TFrameImport.tmrFrameReadyTimer(Sender: TObject);
begin
  tmrFrameReady.Enabled := False;
end;

end.
