program DelphiLintClientTest;

{$IFDEF TESTGUI}
{$APPTYPE GUI}
{$ELSE}
{$APPTYPE CONSOLE}
{$ENDIF}
{$STRONGLINKTYPES ON}
uses
  System.SysUtils,
  {$IFDEF TESTGUI}
  DUnitX.Loggers.GUI.VCL,
  Vcl.Forms,
  {$ELSE}
  DUnitX.Loggers.Console,
  {$ENDIF }
  DUnitX.Loggers.Xml.NUnit,
  DUnitX.TestFramework,
  DelphiLintTest.Events in 'DelphiLintTest.Events.pas';

{$IFDEF TESTGUI}

{$R *.res}

begin
  DUnitX.Loggers.GUI.VCL.Run;
{$ELSE}
var
  Runner: ITestRunner;
  Results: IRunResults;
  Logger: ITestLogger;
  NUnitLogger : ITestLogger;
begin
  //Check command line options, will exit if invalid
  TDUnitX.CheckCommandLine;
  try
    //Create the test runner
    Runner := TDUnitX.CreateRunner;
    //Tell the runner to use RTTI to find Fixtures
    Runner.UseRTTI := True;
    //When true, Assertions must be made during tests;
    Runner.FailsOnNoAsserts := True;

    //tell the runner how we will log things
    //Log to the console window if desired
    if TDUnitX.Options.ConsoleMode <> TDunitXConsoleMode.Off then
    begin
      Logger := TDUnitXConsoleLogger.Create(TDUnitX.Options.ConsoleMode = TDunitXConsoleMode.Quiet);
      Runner.AddLogger(logger);
    end;
    //Generate an NUnit compatible XML File
    NUnitLogger := TDUnitXXMLNUnitFileLogger.Create(TDUnitX.Options.XMLOutputFile);
    Runner.AddLogger(NUnitLogger);

    //Run tests
    Results := Runner.Execute;
    if not Results.AllPassed then
      System.ExitCode := EXIT_ERRORS;

    {$IFNDEF CI}
    //We don't want this happening when running under CI.
    if TDUnitX.Options.ExitBehavior = TDUnitXExitBehavior.Pause then
    begin
      System.Write('Done.. press <Enter> key to quit.');
      System.Readln;
    end;
    {$ENDIF}
  except
    on E: Exception do
      System.Writeln(E.ClassName, ': ', E.Message);
  end;
{$ENDIF}
end.