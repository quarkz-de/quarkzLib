unit qzLib.Core.DormConfigBuilder;

interface

uses
  System.Classes, System.JSON.Builders, System.JSON.Writers, System.JSON.Types;

type
  IDormConfigBuilder = interface
    ['{13A4EF3B-3DF6-4B01-97ED-338F5D1156C5}']
    function BuildConfig: String;
  end;

  TAbstractDormConfigBuilder = class(TInterfacedObject, IDormConfigBuilder)
  private
    FDatabaseConnection: String;
    FUsername: String;
    FPassword: String;
    procedure WriteSectionValues(const AWriter: TJsonTextWriter;
      const AObjectName: String);
  protected
    property DatabaseConnection: String read FDatabaseConnection;
    function GetUsername: String; virtual;
    function GetPassword: String; virtual;
    function GetDatabaseAdapter: String; virtual; abstract;
    function GetDatabaseConnection: String; virtual;
    function GetHasLogin: Boolean; virtual; abstract;
    function GetHasKeysGenerator: Boolean; virtual; abstract;
    function GetKeysGenerator: String; virtual;
  public
    constructor Create(const ADatabaseConnection: String); overload; virtual;
    constructor Create(const ADatabaseConnection, AUsername, APassword: String); overload; virtual;
    function BuildConfig: String;
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
    constructor Create(const ADatabaseConnection: String); overload; virtual;
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

function TAbstractDormConfigBuilder.GetUsername: String;
begin
  Result := FUsername;
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
      WriteSectionValues(Writer, 'development');
      WriteSectionValues(Writer, 'test');
      WriteSectionValues(Writer, 'release');
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
  const AWriter: TJsonTextWriter; const AObjectName: String);
begin
  AWriter.WritePropertyName(AObjectName);
  AWriter.WriteStartObject;

  AWriter.WritePropertyName('database_adapter');
  AWriter.WriteValue(GetDatabaseAdapter);

  AWriter.WritePropertyName('database_connection_string');
  AWriter.WriteValue(GetDatabaseConnection);

  AWriter.WritePropertyName('key_type');
  AWriter.WriteValue('integer');

  AWriter.WritePropertyName('logger_class_name');
  AWriter.WriteValue('dorm.loggers.FileLog.TdormFileLog');

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