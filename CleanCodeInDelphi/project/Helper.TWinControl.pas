unit Helper.TWinControl;

interface

uses
  Vcl.Controls;

type
  THelperWinControl = class helper for TWinControl
    procedure HideAllChildFrames;
    function SumHeightForChildrens(ControlsToExclude: TArray<TControl>)
      : integer;
  end;

implementation

uses
  Vcl.Forms;

procedure THelperWinControl.HideAllChildFrames();
var
  i: integer;
begin
  for i := self.ControlCount - 1 downto 0 do
    if self.Controls[i] is TFrame then
      (self.Controls[i] as TFrame).Visible := False;
end;

function THelperWinControl.SumHeightForChildrens(ControlsToExclude
  : TArray<TControl>): integer;
var
  i: integer;
  ctrl: Vcl.Controls.TControl;
  isExcluded: Boolean;
  j: integer;
  sumHeight: integer;
  ctrlHeight: integer;
begin
  sumHeight := 0;
  for i := 0 to self.ControlCount - 1 do
  begin
    ctrl := self.Controls[i];
    isExcluded := False;
    for j := 0 to Length(ControlsToExclude) - 1 do
      if ControlsToExclude[j] = ctrl then
        isExcluded := True;
    if not isExcluded then
    begin
      if ctrl.AlignWithMargins then
        ctrlHeight := ctrl.Height + ctrl.Margins.Top + ctrl.Margins.Bottom
      else
        ctrlHeight := ctrl.Height;
      sumHeight := sumHeight + ctrlHeight;
    end;
  end;
  Result := sumHeight;
end;

end.
