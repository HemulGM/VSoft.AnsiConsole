unit VSoft.AnsiConsole.Live.Exclusivity;

{
  Only one live renderer may run at a time process-wide. A LiveDisplay /
  Status / Progress session acquires the lock at the start of .Start and
  releases it in a try/finally. A second attempt while the lock is held
  raises ELiveDisplayBusy - we don't block because nested live rendering
  would corrupt the shared cursor/line-count state.
}

interface

uses
  System.SysUtils,
  System.SyncObjs;

type
  ELiveDisplayBusy = class(Exception);

  TLiveExclusivityLock = class
  strict private
    class var FCS : TCriticalSection;
    class var FHeld : Boolean;
  public
    class constructor Create;
    class destructor  Destroy;
    class function  TryEnter : Boolean;
    class procedure Leave;
    class procedure EnsureNotHeld;  // raises ELiveDisplayBusy
  end;

implementation

class constructor TLiveExclusivityLock.Create;
begin
  FCS := TCriticalSection.Create;
  FHeld := False;
end;

class destructor TLiveExclusivityLock.Destroy;
begin
  FCS.Free;
end;

class function TLiveExclusivityLock.TryEnter : Boolean;
begin
  FCS.Enter;
  try
    if FHeld then
    begin
      result := False;
      Exit;
    end;
    FHeld := True;
    result := True;
  finally
    FCS.Leave;
  end;
end;

class procedure TLiveExclusivityLock.Leave;
begin
  FCS.Enter;
  try
    FHeld := False;
  finally
    FCS.Leave;
  end;
end;

class procedure TLiveExclusivityLock.EnsureNotHeld;
begin
  if not TryEnter then
    raise ELiveDisplayBusy.Create('Another live display is already active.');
end;

end.
