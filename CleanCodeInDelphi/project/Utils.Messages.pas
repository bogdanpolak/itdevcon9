unit Utils.Messages;

interface

uses
  Winapi.Messages, Winapi.Windows,
  Vcl.Forms,
  System.Classes, System.Contnrs;

const
  WM_FRAME_MESSAGE = WM_USER + 101;
  
type
  TMyMessage = class
    Kind: string;
    Text: string;
    TagInteger: integer;
    TagFloat: double;
    TagBoolean: boolean;
    Data: Pointer;
    Obj: TObject;
  end;

  TMessages = class (TObjectList)
  private
    function GetItem(Index: Integer): TMyMessage; inline;
    procedure SetItem(Index: Integer; AMessage: TMyMessage); inline;
  public
    Listeners: Array of TFrame;
    function Add(msg: TMyMessage): Integer; inline;
    property Items[Index: Integer]: TMyMessage read GetItem write SetItem; default;
    procedure RegisterListener(frm: TFrame);
    procedure ProcessMessages;
  end;

implementation

function TMessages.Add(msg: TMyMessage): Integer;
begin
  Result := inherited Add (msg);
end;

function TMessages.GetItem(Index: Integer): TMyMessage;
var
  obj: TObject;
begin
  obj := inherited GetItem(Index);
  Result := obj as TMyMessage;
end;

procedure TMessages.ProcessMessages;
var
  i: Integer;
  msg: TMyMessage;
  j: Integer;
  frame: TFrame;
begin
  // TODO: Migrate to System.Messaging
  for i := 0 to self.Count-1 do begin
    msg := self.Items[i];
    for j := 0 to Length(Listeners)-1 do
    begin
      frame := Listeners[j];
      SendMessage(frame.Handle,WM_FRAME_MESSAGE,1,NativeInt(msg));
    end;
  end;
  self.Clear;
end;

procedure TMessages.RegisterListener(frm: TFrame);
var
  n: Integer;
begin
  n := Length(Listeners);
  SetLength (Listeners,n+1);
  Listeners[n] := frm;
end;

procedure TMessages.SetItem(Index: Integer; AMessage: TMyMessage);
begin
  inherited SetItem (Index, AMessage);
end;

end.
