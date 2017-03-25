unit qzLib.Core.DormLoggers;

interface

uses
  dorm.Commons;

type
  TdormDummyLogger = class(TdormInterfacedObject, IdormLogger)
  public
    class procedure register;
    procedure EnterLevel(const Value: string);
    procedure ExitLevel(const Value: string);
    procedure Error(const Value: string);
    procedure Warning(const Value: string);
    procedure Info(const Value: string);
    procedure Debug(const Value: string);
  end;

implementation

{ TdormDummyLogger }

class procedure TdormDummyLogger.Register;
begin

end;

procedure TdormDummyLogger.Debug(const Value: string);
begin

end;

procedure TdormDummyLogger.EnterLevel(const Value: string);
begin

end;

procedure TdormDummyLogger.Error(const Value: string);
begin

end;

procedure TdormDummyLogger.ExitLevel(const Value: string);
begin

end;

procedure TdormDummyLogger.Info(const Value: string);
begin

end;

procedure TdormDummyLogger.Warning(const Value: string);
begin

end;

initialization
  TdormDummyLogger.Register;

end.