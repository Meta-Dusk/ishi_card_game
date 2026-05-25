; Safe to share publicly — contains no private data
; Paths are relative to the '../windows/' folder

#define MyAppName "Ishi"
#ifndef MyAppVersion
#define MyAppVersion "0.14.0"
#endif
#define MyAppPublisher "MetaDusk Inc."
#define MyAppURL "https://github.com/Meta-Dusk/ishi_card_game"
#define MyAppExeName "ishi.exe"
#define MyAppAssocName MyAppName + " File"
#define MyAppAssocExt ".icg"
#define MyAppAssocKey StringChange(MyAppAssocName, " ", "") + MyAppAssocExt

[Setup]
AppId={{EB4A787C-0EF2-4206-8BE0-76FA552D44B9}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppPublisher={#MyAppPublisher}
AppPublisherURL={#MyAppURL}
AppSupportURL={#MyAppURL}
AppUpdatesURL={#MyAppURL}
DefaultDirName={autopf}\{#MyAppName}
UninstallDisplayIcon={app}\{#MyAppExeName}
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
ChangesAssociations=no
DisableProgramGroupPage=yes
PrivilegesRequiredOverridesAllowed=dialog
OutputDir=..\dist\installer
OutputBaseFilename={#MyAppName}_v{#MyAppVersion}-Win64-Installer
Compression=lzma
SolidCompression=yes
WizardStyle=modern
SetupIconFile=runner\resources\app_icon.ico
SignTool=signtool
SignedUninstaller=yes

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked

[Files]
Source: "..\build\windows\x64\runner\Release\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs
; NOTE: Don't use "Flags: ignoreversion" on any shared system files

Source: "runner\resources\app_icon.ico"; DestDir: "{app}"; DestName: "icon.ico"; Flags: ignoreversion

[Icons]
Name: "{autoprograms}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; IconFilename: "{app}\icon.ico"
Name: "{autodesktop}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; IconFilename: "{app}\icon.ico"; Tasks: desktopicon

[Run]
Filename: "{app}\{#MyAppExeName}"; Description: "{cm:LaunchProgram,{#StringChange(MyAppName, '&', '&&')}}"; Flags: nowait postinstall skipifsilent