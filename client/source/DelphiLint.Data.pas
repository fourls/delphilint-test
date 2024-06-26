{
DelphiLint Client
Copyright (C) 2024 Integrated Application Development

This program is free software; you can redistribute it and/or
modify it under the terms of the GNU Lesser General Public
License as published by the Free Software Foundation; either
version 3 of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
Lesser General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program. If not, see <https://www.gnu.org/licenses/>.
}
unit DelphiLint.Data;

interface

uses
    System.JSON
  , System.Generics.Collections
  ;

type

//______________________________________________________________________________________________________________________

  TSonarHostOptions = record
    Url: string;
    Token: string;

    constructor Create(Url: string; Token: string);
  end;

  TSonarProjectOptions = record
    Host: TSonarHostOptions;
    ProjectKey: string;

    constructor Create(Url: string; Token: string; ProjectKey: string);
  end;

  TInitializeOptions = record
    BdsPath: string;
    CompilerVersion: string;
    SonarHost: TSonarHostOptions;
    SonarDelphiVersion: string;

    constructor Create(BdsPath: string; CompilerVersion: string; SonarDelphiVersion: string);
  end;

  TAnalyzeOptions = record
    BaseDir: string;
    InputFiles: TArray<string>;
    SonarDelphiVersion: string;
    ProjectPropertiesPath: string;
    Sonar: TSonarProjectOptions;

    constructor Create(BaseDir: string; InputFiles: TArray<string>; SonarDelphiVersion: string);
  end;

//______________________________________________________________________________________________________________________

  TRange = class(TObject)
  private
    FStartLine: Integer;
    FStartLineOffset: Integer;
    FEndLine: Integer;
    FEndLineOffset: Integer;
  public
    constructor Create(StartLine: Integer; StartOffset: Integer; EndLine: Integer; EndOffset: Integer);
    constructor CreateFromJson(Json: TJSONObject);

    property StartLine: Integer read FStartLine;
    property StartLineOffset: Integer read FStartLineOffset;
    property EndLine: Integer read FEndLine;
    property EndLineOffset: Integer read FEndLineOffset;
  end;

//______________________________________________________________________________________________________________________

  TIssueStatus = (
    issOpen,
    issConfirmed,
    issReopened,
    issResolved,
    issClosed,
    issAccepted,
    issToReview,
    issReviewed
  );

  TIssueMetadata = class(TObject)
  private
    FAssignee: string;
    FCreationDate: string;
    FStatus: TIssueStatus;
  public
    constructor Create(Assignee: string; Status: TIssueStatus; CreationDate: string);
    constructor CreateFromJson(Json: TJSONObject);

    property Assignee: string read FAssignee;
    property CreationDate: string read FCreationDate;
    property Status: TIssueStatus read FStatus;
  end;

//______________________________________________________________________________________________________________________

  TLintIssue = class(TObject)
  private
    FRuleKey: string;
    FMessage: string;
    FFilePath: string;
    FRange: TRange;
    FMetadata: TIssueMetadata;

  public
    constructor Create(
      RuleKey: string;
      Message: string;
      FilePath: string;
      Range: TRange;
      Metadata: TIssueMetadata = nil);
    constructor CreateFromJson(Json: TJSONObject);
    destructor Destroy; override;

    property RuleKey: string read FRuleKey;
    property Message: string read FMessage;
    property FilePath: string read FFilePath;
    property Range: TRange read FRange write FRange;
    property Metadata: TIssueMetadata read FMetadata write FMetadata;
  end;

//______________________________________________________________________________________________________________________

  TRuleType = (
    rtCodeSmell,
    rtBug,
    rtVulnerability,
    rtSecurityHotspot
  );

  TRuleSeverity = (
    rsInfo,
    rsMinor,
    rsMajor,
    rsCritical,
    rsBlocker
  );

  TCleanCodeAttribute = (
    ccaFormatted,
    ccaConventional,
    ccaIdentifiable,
    ccaClear,
    ccaLogical,
    ccaComplete,
    ccaEfficient,
    ccaFocused,
    ccaDistinct,
    ccaModular,
    ccaTested,
    ccaLawful,
    ccaTrustworthy,
    ccaRespectful
  );

  TCleanCodeAttributeCategory = (
    cccConsistent,
    cccIntentional,
    cccAdaptable,
    cccResponsible
  );

  TSoftwareQuality = (
    sqaSecurity,
    sqaReliability,
    sqaMaintainability
  );

  TImpactSeverity = (
    imsLow,
    imsMedium,
    imsHigh
  );

  TRuleCleanCode = class(TObject)
  private
    FAttribute: TCleanCodeAttribute;
    FCategory: TCleanCodeAttributeCategory;
    FImpacts: TDictionary<TSoftwareQuality, TImpactSeverity>;

  public
    constructor Create(
      Attribute: TCleanCodeAttribute;
      Category: TCleanCodeAttributeCategory;
      Impacts: TDictionary<TSoftwareQuality, TImpactSeverity>
    );
    constructor CreateFromJson(Json: TJSONObject);
    destructor Destroy; override;

    property Attribute: TCleanCodeAttribute read FAttribute;
    property Category: TCleanCodeAttributeCategory read FCategory;
    property Impacts: TDictionary<TSoftwareQuality, TImpactSeverity> read FImpacts;
  end;

  TRule = class(TObject)
  private
    FRuleKey: string;
    FName: string;
    FDesc: string;
    FSeverity: TRuleSeverity;
    FType: TRuleType;
    FCleanCode: TRuleCleanCode;

  public
    constructor Create(
      RuleKey: string;
      Name: string;
      Desc: string;
      Severity: TRuleSeverity;
      RuleType: TRuleType;
      CleanCode: TRuleCleanCode = nil
    );
    constructor CreateFromJson(Json: TJSONObject);
    destructor Destroy; override;

    property RuleKey: string read FRuleKey;
    property Name: string read FName;
    property Desc: string read FDesc;
    property Severity: TRuleSeverity read FSeverity;
    property RuleType: TRuleType read FType;
    property CleanCode: TRuleCleanCode read FCleanCode;
  end;

//______________________________________________________________________________________________________________________

  TLiveIssue = class(TObject)
  private
    FRuleKey: string;
    FMessage: string;
    FFilePath: string;
    FAssignee: string;
    FCreationDate: string;
    FStatus: TIssueStatus;
    FHasMetadata: Boolean;
    FStartLine: Integer;
    FEndLine: Integer;
    FStartLineOffset: Integer;
    FEndLineOffset: Integer;
    FLinesMoved: Integer;
    FTethered: Boolean;
    FLines: TArray<string>;

    function GetStartLine: Integer;
    function GetEndLine: Integer;
  public
    constructor Create(Issue: TLintIssue; IssueLines: TArray<string>; HasMetadata: Boolean = False);

    procedure NewLineMoveSession;
    procedure UpdateTether(LineNum: Integer; LineText: string);
    procedure Untether;

    property RuleKey: string read FRuleKey;
    property Message: string read FMessage;
    property FilePath: string read FFilePath write FFilePath;
    property Assignee: string read FAssignee;
    property CreationDate: string read FCreationDate;
    property Status: TIssueStatus read FStatus;
    property HasMetadata: Boolean read FHasMetadata;

    property OriginalStartLine: Integer read FStartLine;
    property OriginalEndLine: Integer read FEndLine;
    property StartLine: Integer read GetStartLine;
    property EndLine: Integer read GetEndLine;
    property StartLineOffset: Integer read FStartLineOffset;
    property EndLineOffset: Integer read FEndLineOffset;
    property LinesMoved: Integer read FLinesMoved write FLinesMoved;
    property Tethered: Boolean read FTethered;
  end;

//______________________________________________________________________________________________________________________

  TFileAnalysisHistory = record
    AnalysisTime: TDateTime;
    Success: Boolean;
    IssuesFound: Integer;
    FileHash: string;
  end;

//______________________________________________________________________________________________________________________

  TCurrentAnalysis = class(TObject)
  private
    FPaths: TArray<string>;
  public
    constructor Create(Paths: TArray<string>);
    function IncludesFile(const Path: string): Boolean;

    property Paths: TArray<string> read FPaths;
  end;

//______________________________________________________________________________________________________________________

  TFileAnalysisStatus = (
    fasNeverAnalyzed,
    fasOutdatedAnalysis,
    fasUpToDateAnalysis
  );

//______________________________________________________________________________________________________________________

implementation

uses
    System.StrUtils
  , System.SysUtils
  , DelphiLint.Utils
  ;

//______________________________________________________________________________________________________________________

constructor TRange.Create(StartLine: Integer; StartOffset: Integer; EndLine: Integer; EndOffset: Integer);
begin
  inherited Create;
  FStartLine := StartLine;
  FEndLine := EndLine;
  FStartLineOffset := StartOffset;
  FEndLineOffset := EndOffset;
end;

//______________________________________________________________________________________________________________________

constructor TRange.CreateFromJson(Json: TJSONObject);
begin
  inherited Create;
  FStartLine := Json.GetValue<Integer>('startLine', 0);
  FEndLine := Json.GetValue<Integer>('endLine', 0);
  FStartLineOffset := Json.GetValue<Integer>('startOffset', 0);
  FEndLineOffset := Json.GetValue<Integer>('endOffset', 0);
end;

//______________________________________________________________________________________________________________________

constructor TLintIssue.Create(
  RuleKey: string;
  Message: string;
  FilePath: string;
  Range: TRange;
  Metadata: TIssueMetadata
);
begin
  inherited Create;
  FRuleKey := RuleKey;
  FMessage := Message;
  FFilePath := FilePath;
  FRange := Range;
  FMetadata := Metadata;
end;

//______________________________________________________________________________________________________________________

constructor TLintIssue.CreateFromJson(Json: TJSONObject);
var
  RangeJson: TJSONValue;
  MetadataJson: TJSONValue;
begin
  inherited Create;
  FRuleKey := Json.GetValue<string>('ruleKey');
  FMessage := Json.GetValue<string>('message', FRuleKey);
  FFilePath := Json.GetValue<string>('file');
  FRange := nil;

  RangeJson := Json.GetValue<TJSONValue>('range', nil);
  if Assigned(RangeJson) and (RangeJson is TJSONObject) then begin
    FRange := TRange.CreateFromJson(RangeJson as TJSONObject);
  end;

  MetadataJson := Json.GetValue<TJSONValue>('metadata', nil);
  if Assigned(MetadataJson) and (MetadataJson is TJSONObject) then begin
    FMetadata := TIssueMetadata.CreateFromJson(MetadataJson as TJSONObject);
  end;
end;

//______________________________________________________________________________________________________________________

destructor TLintIssue.Destroy;
begin
  FreeAndNil(FRange);
  FreeAndNil(FMetadata);
  inherited;
end;

//______________________________________________________________________________________________________________________

constructor TRuleCleanCode.Create(
  Attribute: TCleanCodeAttribute;
  Category: TCleanCodeAttributeCategory;
  Impacts: TDictionary<TSoftwareQuality, TImpactSeverity>
);
begin
  inherited Create;
  FAttribute := Attribute;
  FCategory := Category;
  FImpacts := Impacts;
end;

//______________________________________________________________________________________________________________________

constructor TRuleCleanCode.CreateFromJson(Json: TJSONObject);
const
  CAttributes: array of string = ['FORMATTED', 'CONVENTIONAL', 'IDENTIFIABLE', 'CLEAR', 'LOGICAL',
    'COMPLETE', 'EFFICIENT', 'FOCUSED', 'DISTINCT', 'MODULAR', 'TESTED', 'LAWFUL', 'TRUSTWORTHY', 'RESPECTFUL'];
  CCategories: array of string = ['CONSISTENT', 'INTENTIONAL', 'ADAPTABLE', 'RESPONSIBLE'];
  CSoftwareQualities: array of string = ['SECURITY', 'RELIABILITY', 'MAINTAINABILITY'];
  CImpactSeverities: array of string = ['LOW', 'MEDIUM', 'HIGH'];
var
  Impacts: TJSONObject;
  Index: Integer;
  Quality: TSoftwareQuality;
  Severity: TImpactSeverity;
begin
  inherited Create;

  FAttribute := TCleanCodeAttribute(IndexStr(Json.GetValue<string>('attribute'), CAttributes));
  FCategory := TCleanCodeAttributeCategory(IndexStr(Json.GetValue<string>('category'), CCategories));
  FImpacts := TDictionary<TSoftwareQuality, TImpactSeverity>.Create;

  Impacts := Json.GetValue<TJSONObject>('impacts');
  for Index := 0 to Impacts.Count - 1 do begin
    Quality := TSoftwareQuality(IndexStr(Impacts.Pairs[Index].JsonString.Value, CSoftwareQualities));
    Severity := TImpactSeverity(IndexStr(Impacts.Pairs[Index].JsonValue.Value, CImpactSeverities));
    FImpacts.Add(Quality, Severity);
  end;
end;

//______________________________________________________________________________________________________________________

destructor TRuleCleanCode.Destroy;
begin
  FreeAndNil(FImpacts);
  inherited;
end;

//______________________________________________________________________________________________________________________

constructor TRule.Create(
  RuleKey: string;
  Name: string;
  Desc: string;
  Severity: TRuleSeverity;
  RuleType: TRuleType;
  CleanCode: TRuleCleanCode
);
begin
  inherited Create;

  FRuleKey := RuleKey;
  FName := Name;
  FDesc := Desc;
  FSeverity := Severity;
  FType := RuleType;
  FCleanCode := CleanCode;
end;

//______________________________________________________________________________________________________________________

constructor TRule.CreateFromJson(Json: TJSONObject);
const
  CSeverities: array of string = ['INFO', 'MINOR', 'MAJOR', 'CRITICAL', 'BLOCKER'];
  CRuleTypes: array of string = ['CODE_SMELL', 'BUG', 'VULNERABILITY', 'SECURITY_HOTSPOT'];
var
  CleanCodeJson: TJSONObject;
begin
  inherited;

  FRuleKey := Json.GetValue<string>('key');
  FName := Json.GetValue<string>('name');
  FDesc := Json.GetValue<string>('desc');
  FSeverity := TRuleSeverity(IndexStr(Json.GetValue<string>('severity'), CSeverities));
  FType := TRuleType(IndexStr(Json.GetValue<string>('type'), CRuleTypes));
  FCleanCode := nil;

  if Json.TryGetValue<TJSONObject>('cleanCode', CleanCodeJson) and Assigned(CleanCodeJson) then begin
    FCleanCode := TRuleCleanCode.CreateFromJson(CleanCodeJson);
  end;
end;

//______________________________________________________________________________________________________________________

destructor TRule.Destroy;
begin
  FreeAndNil(FCleanCode);
  inherited;
end;

//______________________________________________________________________________________________________________________

constructor TIssueMetadata.Create(Assignee: string; Status: TIssueStatus; CreationDate: string);
begin
  inherited Create;
  FAssignee := Assignee;
  FCreationDate := CreationDate;
  FStatus := Status;
end;

//______________________________________________________________________________________________________________________

constructor TIssueMetadata.CreateFromJson(Json: TJSONObject);
const
  CStatuses: array of string = [
    'OPEN',
    'CONFIRMED',
    'REOPENED',
    'RESOLVED',
    'CLOSED',
    'ACCEPTED',
    'TO_REVIEW',
    'REVIEWED'
  ];
begin
  inherited;

  FAssignee := Json.GetValue<string>('assignee');
  FCreationDate := Json.GetValue<string>('creationDate');
  FStatus := TIssueStatus(IndexStr(Json.GetValue<string>('status'), CStatuses));
end;

//______________________________________________________________________________________________________________________

constructor TLiveIssue.Create(Issue: TLintIssue; IssueLines: TArray<string>; HasMetadata: Boolean = False);
begin
  inherited Create;

  FRuleKey := Issue.RuleKey;
  FMessage := Issue.Message;
  FFilePath := Issue.FilePath;

  if Assigned(Issue.Range) then begin
    FStartLine := Issue.Range.StartLine;
    FEndLine := Issue.Range.EndLine;
    FStartLineOffset := Issue.Range.StartLineOffset;
    FEndLineOffset := Issue.Range.EndLineOffset;
  end
  else begin
    FStartLine := 1;
    FEndLine := 1;
    FStartLineOffset := 0;
    FEndLineOffset := 0;
  end;

  if Length(IssueLines) <> (FEndLine - FStartLine + 1) then begin
    raise ERangeError.CreateFmt(
      'Issue spans %d lines (line %d to line %d), but %d lines were associated',
      [
        FEndLine - FStartLine + 1,
        FStartLine,
        FEndLine,
        Length(IssueLines)
      ]);
  end;

  FHasMetadata := HasMetadata;
  if Assigned(Issue.Metadata) then begin
    FAssignee := Issue.Metadata.Assignee;
    FCreationDate := Issue.Metadata.CreationDate;
    FStatus := Issue.Metadata.Status;
  end;

  FLinesMoved := 0;
  FLines := IssueLines;
  FTethered := True;
end;

//______________________________________________________________________________________________________________________

procedure TLiveIssue.Untether;
begin
  FTethered := False;
end;

//______________________________________________________________________________________________________________________

procedure TLiveIssue.UpdateTether(LineNum: Integer; LineText: string);
var
  Delta: Integer;
begin
  if not Tethered then begin
    Exit;
  end;

  Delta := LineNum - StartLine;
  if (Delta >= 0) and (Delta < Length(FLines)) then begin
    if (FLines[Delta] <> LineText) then begin
      Untether;
    end;
  end;
end;

//______________________________________________________________________________________________________________________

function TLiveIssue.GetStartLine: Integer;
begin
  Result := FStartLine + LinesMoved;
end;

//______________________________________________________________________________________________________________________

function TLiveIssue.GetEndLine: Integer;
begin
  Result := FEndLine + LinesMoved;
end;

//______________________________________________________________________________________________________________________

procedure TLiveIssue.NewLineMoveSession;
begin
  FStartLine := StartLine;
  FEndLine := EndLine;
  FLinesMoved := 0;
end;

//______________________________________________________________________________________________________________________

constructor TCurrentAnalysis.Create(Paths: TArray<string>);
begin
  inherited Create;
  FPaths := Paths;
end;

//______________________________________________________________________________________________________________________

function TCurrentAnalysis.IncludesFile(const Path: string): Boolean;
var
  PathEl: string;
begin
  Result := False;

  for PathEl in FPaths do begin
    if NormalizePath(PathEl) = NormalizePath(Path) then begin
      Result := True;
      Exit;
    end;
  end;
end;

//______________________________________________________________________________________________________________________

constructor TAnalyzeOptions.Create(BaseDir: string; InputFiles: TArray<string>; SonarDelphiVersion: string);
begin
  Self.BaseDir := BaseDir;
  Self.InputFiles := InputFiles;
  Self.SonarDelphiVersion := SonarDelphiVersion;
end;

//______________________________________________________________________________________________________________________

constructor TInitializeOptions.Create(BdsPath: string; CompilerVersion: string; SonarDelphiVersion: string);
begin
  Self.BdsPath := BdsPath;
  Self.CompilerVersion := CompilerVersion;
  Self.SonarDelphiVersion := SonarDelphiVersion;
end;

//______________________________________________________________________________________________________________________

constructor TSonarHostOptions.Create(Url: string; Token: string);
begin
  Self.Url := Url;
  Self.Token := Token;
end;

//______________________________________________________________________________________________________________________

constructor TSonarProjectOptions.Create(Url: string; Token: string; ProjectKey: string);
begin
  Self.Host.Url := Url;
  Self.Host.Token := Token;
  Self.ProjectKey := ProjectKey;
end;

end.
