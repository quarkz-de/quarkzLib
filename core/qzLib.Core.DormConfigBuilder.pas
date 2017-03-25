unit qzLib.Core.DormConfigBuilder;

interface

uses
  System.Classes, System.JSON.Builders, System.JSON.Writers, System.JSON.Types,
  dorm.Commons;

type
  TDormLogger = (dlDummy, dlCodeSiteFile, dlCodeSiteLive, dlFile, dlSmartInspect);

  IDormConfigBuilder = interface
    ['{13A4EF3B-3DF6-4B01-97ED-338F5D1156C5}']
    function GetLogger(Index: TdormEnvironment): TDormLogger;
    procedure SetLogger(Index: TdormEnvironment; Value: TDormLogger);
    function BuildConfig: String;
    property Logger[Index: TdormEnvironment]: TDormLogger read GetLogger write SetLogger;
  end;

  TAbstractDormConfigBuilder = class(TInterfacedObject, IDormConfigBuilder)
  private
    FDatabaseConnection: String;
    FUsername: String;
    FPassword: String;
    FLoggers: Array[TdormEnvironment] of TDormLogger;
    procedure WriteSectionValues(const AWriter: TJsonTextWriter;
      const AEnvironment: TdormEnvironment);
    function GetLoggerValue(const AEnvironment: TdormEnvironment): String;
  protected
    property DatabaseConnection: String read FDatabaseConnection;
    function GetUsername: String; virtual;
    function GetPassword: String; virtual;
    function GetDatabaseAdapter: String; virtual; abstract;
    function GetDatabaseConnection: String; virtual;
    function GetHasLogin: Boolean; virtual; abstract;
    function GetHasKeysGenerator: Boolean; virtual; abstract;
    function GetKeysGenerator: String; virtual;
    function GetLogger(Index: TdormEnvironment): TDormLogger;
    procedure SetLogger(Index: TdormEnvironment; Value: TDormLogger);
  public
    constructor Create(const ADatabaseConnection: String); overload; virtual;
    constructor Create(const ADatabaseConnection, AUsername, APassword: String); overload; virtual;
    function BuildConfig: String;
    property Logger[Index: TdormEnvironment]: TDormLogger read GetLogger write SetLogger;
  end;

  TDormSQLiteConfigBuilder = class(TAbstractDormConfigBuilder)
  protected
    function GetDatabaseAdapter: String; override;
    function GetHasLogin: Boolean; override;
    function GetHasKeysGenerator: Boolean; override;
  end;

  TDormFirebirdConfigBuilder = class(TAbstractDormConfigBuilder)
  protected
    function GetDatabaseAdapter: String; override;
    function GetHasLogin: Boolean; override;
    function GetHasKeysGenerator: Boolean; override;
    function GetKeysGenerator: String; override;
  public
    constructor Create(const ADatabaseConnection: String); override;
  end;

implementation

{ TAbstractDormConfigBuilder }

constructor TAbstractDormConfigBuilder.Create(
  const ADatabaseConnection: String);
begin
  Create(ADatabaseConnection, '', '');
end;

constructor TAbstractDormConfigBuilder.Create(const ADatabaseConnection,
  AUsername, APassword: String);
begin
  FLoggers[deDevelopment] := dlDummy;
  FLoggers[deTest] := dlDummy;
  FLoggers[deRelease] := dlDummy;
  FDatabaseConnection := ADatabaseConnection;
  FUsername := AUsername;
  FPassword := APassword;
end;

function TAbstractDormConfigBuilder.GetDatabaseConnection: String;
begin
  Result := FDatabaseConnection;
end;

function TAbstractDormConfigBuilder.GetKeysGenerator: String;
begin
  Result := '';
end;

function TAbstractDormConfigBuilder.GetLogger(
  Index: TdormEnvironment): TDormLogger;
begin
  Result := FLoggers[Index];
end;

function TAbstractDormConfigBuilder.GetLoggerValue(
  const AEnvironment: TdormEnvironment): String;
const
  LoggerValues: array[TDormLogger] of string = (
    'qzLib.Core.DormLoggers.TdormDummyLogger',
    'dorm.loggers.CodeSite.TCodeSiteFileLog',
    'dorm.loggers.CodeSite.TCodeSiteLiveLog',
    'dorm.loggers.FileLog.TdormFileLog',
    'dorm.loggers.SmartInspect.TdormSILog');
begin
  Result := LoggerValues[FLoggers[AEnvironment]];
end;

function TAbstractDormConfigBuilder.GetUsername: String;
begin
  Result := FUsername;
end;

procedure TAbstractDormConfigBuilder.SetLogger(Index: TdormEnvironment;
  Value: TDormLogger);
begin
  FLoggers[Index] := Value;
end;

function TAbstractDormConfigBuilder.GetPassword: String;
begin
  Result := FPassword;
end;

function TAbstractDormConfigBuilder.BuildConfig: String;
var
  StringWriter: TStringWriter;
  Writer: TJsonTextWriter;
begin
  StringWriter := TStringWriter.Create;
  try
    Writer := TJsonTextWriter.Create(StringWriter);
    try
      Writer.Formatting := TJsonFormatting.Indented;

      Writer.WriteStartObject;
      Writer.WritePropertyName('persistence');

      Writer.WriteStartObject;
      WriteSectionValues(Writer, deDevelopment);
      WriteSectionValues(Writer, deTest);
      WriteSectionValues(Writer, deRelease);
      Writer.WriteEndObject;

      Writer.WriteEndObject;

      Result := StringWriter.ToString;
    finally
      Writer.Free;
    end;
  finally
    StringWriter.Free;
  end;
end;

procedure TAbstractDormConfigBuilder.WriteSectionValues(
  const AWriter: TJsonTextWriter; const AEnvironment: TdormEnvironment);
const
  EnvironmentNames: Array[TdormEnvironment] of String = (
    'development', 'test', 'release');
begin
  AWriter.WritePropertyName(EnvironmentNames[AEnvironment]);
  AWriter.WriteStartObject;

  AWriter.WritePropertyName('database_adapter');
  AWriter.WriteValue(GetDatabaseAdapter);

  AWriter.WritePropertyName('database_connection_string');
  AWriter.WriteValue(GetDatabaseConnection);

  AWriter.WritePropertyName('key_type');
  AWriter.WriteValue('integer');

  AWriter.WritePropertyName('logger_class_name');
  AWriter.WriteValue(GetLoggerValue(AEnvironment));

  if GetHasKeysGenerator then
    begin
      AWriter.WritePropertyName('keys_generator');
      AWriter.WriteValue(GetKeysGenerator);
    end;

  if GetHasLogin then
    begin
      AWriter.WritePropertyName('username');
      AWriter.WriteValue(GetUsername);
      AWriter.WritePropertyName('password');
      AWriter.WriteValue(GetPassword);
    end;

  AWriter.WriteEndObject;
end;

{ TDormSQLiteConfigBuilder }

function TDormSQLiteConfigBuilder.GetDatabaseAdapter: String;
begin
  Result := 'dorm.adapter.Sqlite3.TSqlite3PersistStrategy';
end;

function TDormSQLiteConfigBuilder.GetHasKeysGenerator: Boolean;
begin
  Result := false;
end;

function TDormSQLiteConfigBuilder.GetHasLogin: Boolean;
begin
  Result := false;
end;

{ TDormFirebirdConfigBuilder }

constructor TDormFirebirdConfigBuilder.Create(
  const ADatabaseConnection: String);
begin
  Create(ADatabaseConnection, 'sysdba', 'masterkey');
end;

function TDormFirebirdConfigBuilder.GetDatabaseAdapter: String;
begin
  Result := 'dorm.adapter.UIB.Firebird.TUIBFirebirdPersistStrategy';
end;

function TDormFirebirdConfigBuilder.GetHasKeysGenerator: Boolean;
begin
  Result := true;
end;

function TDormFirebirdConfigBuilder.GetHasLogin: Boolean;
begin
  Result := true;
end;

function TDormFirebirdConfigBuilder.GetKeysGenerator: String;
begin
  Result := 'dorm.adapter.UIB.Firebird.TUIBFirebirdTableGenerator';
end;

end.