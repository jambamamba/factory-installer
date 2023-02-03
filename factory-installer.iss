
#define MyAppName "app-factory-installer"
#define MyAppExeName "app-factory-installer.exe"
#define MyAppVersion "1.0"
#define MyAppPublisher ""
#define MyAppURL "http://www.foobar.com/"

#define MSYS64 "C:\msys64"
#define MINGW "C:\msys64\mingw64\bin"
#define BuildDir "C:\repos\factory-installer\x86-build"
; #define PythonDir "C:\Python39"
                  

[Setup]
; NOTE: The value of AppId uniquely identifies this application.
; Do not use the same AppId value in installers for other applications.
; (To generate a new GUID, click Tools | Generate GUID inside the IDE.)
AppId={{B78EBB3A-E401-4A57-8960-B7B8CDB76BCE}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
;AppVerName={#MyAppName} {#MyAppVersion}
AppPublisher={#MyAppPublisher}
AppPublisherURL={#MyAppURL}
AppSupportURL={#MyAppURL}
AppUpdatesURL={#MyAppURL}
DefaultDirName={pf64}\{#MyAppName}
DisableProgramGroupPage=yes
OutputDir={#BuildDir}\install
OutputBaseFilename=FactoryInstallerSetup{#MyAppVersion}
SetupIconFile=/g13158.ico
Compression=lzma
SolidCompression=yes
PrivilegesRequired=admin

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked

[Files]
Source: "{#BuildDir}\{#MyAppExeName}"; DestDir: "{app}"; Flags: ignoreversion
Source: "{#BuildDir}\libssh\src\libssh.dll"; DestDir: "{app}"; Flags: ignoreversion
; Source: "{#BuildDir}\resources.rcc"; DestDir: "{app}"; Flags: ignoreversion
Source: "{#MINGW}\libgcc_s_seh-1.dll"; DestDir: "{app}"; Flags: ignoreversion
Source: "{#MINGW}\libcrypto-1_1-x64.dll"; DestDir: "{app}"; Flags: ignoreversion
Source: "{#MINGW}\libstdc++-6.dll"; DestDir: "{app}"; Flags: ignoreversion
Source: "{#MINGW}\libwinpthread-1.dll"; DestDir: "{app}"; Flags: ignoreversion
Source: "{#MINGW}\zlib1.dll"; DestDir: "{app}"; Flags: ignoreversion
Source: "{#MINGW}\libpcre2-16-0.dll"; DestDir: "{app}"; Flags: ignoreversion
Source: "{#MINGW}\libicuuc62.dll"; DestDir: "{app}"; Flags: ignoreversion
Source: "{#MINGW}\libicuin62.dll"; DestDir: "{app}"; Flags: ignoreversion
Source: "{#MINGW}\libicudt62.dll"; DestDir: "{app}"; Flags: ignoreversion
Source: "{#MINGW}\libpng16-16.dll"; DestDir: "{app}"; Flags: ignoreversion
Source: "{#MINGW}\libharfbuzz-0.dll"; DestDir: "{app}"; Flags: ignoreversion
Source: "{#MINGW}\libfreetype-6.dll"; DestDir: "{app}"; Flags: ignoreversion
Source: "{#MINGW}\libbz2-1.dll"; DestDir: "{app}"; Flags: ignoreversion
Source: "{#MINGW}\libglib-2.0-0.dll"; DestDir: "{app}"; Flags: ignoreversion
Source: "{#MINGW}\libintl-8.dll"; DestDir: "{app}"; Flags: ignoreversion
Source: "{#MINGW}\libiconv-2.dll"; DestDir: "{app}"; Flags: ignoreversion
Source: "{#MINGW}\libgraphite2.dll"; DestDir: "{app}"; Flags: ignoreversion
Source: "{#MINGW}\libpcre-1.dll"; DestDir: "{app}"; Flags: ignoreversion
Source: "{#MINGW}\libjpeg-8.dll"; DestDir: "{app}"; Flags: ignoreversion
Source: "{#MINGW}\..\lib\libSDL2.dll.a"; DestDir: "{app}\libSDL2.dll"; Flags: ignoreversion

; NOTE: Don't use "Flags: ignoreversion" on any shared system files

[Icons]
Name: "{commonprograms}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"
Name: "{commondesktop}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; Tasks: desktopicon

[Run]
; Filename: "powershell.exe"; Parameters: "-NonInteractive -Command netsh advfirewall set global statefulftp disable"; Description: "Disable firewall port 21"; StatusMsg: "Disabling firewall port 21..."; Flags: runascurrentuser runhidden;  
; Filename: "powershell.exe"; Parameters: "-NonInteractive -Command netsh advfirewall firewall add rule name='Madusa Video Server' protocol=UDP dir=in localport=7878-7888 action=allow"; Description: "Allow UDP ports incomming 7878-7888"; StatusMsg: "Allow UDP ports in 7878-7888"; Flags: runascurrentuser runhidden;  
; Filename: "powershell.exe"; Parameters: "-NonInteractive -Command netsh advfirewall firewall add rule name='Madusa Task Server' protocol=TCP dir=in localport=8989 action=allow"; Description: "Allow TCP port incomming 8989"; StatusMsg: "Allow TCP ports in 8989"; Flags: runascurrentuser runhidden;  
Filename: "{app}\{#MyAppExeName}"; Description: "{cm:LaunchProgram,{#StringChange(MyAppName, '&', '&&')}}"; Flags: nowait postinstall skipifsilent

[Registry]
Root: HKLM; Subkey: "SYSTEM\CurrentControlSet\Services\AFD\Parameters"; ValueType: dword; ValueName: "DefaultReceiveWindow"; ValueData: 2097152
Root: HKLM; Subkey: "SYSTEM\CurrentControlSet\Services\AFD\Parameters"; ValueType: dword; ValueName: "DefaultSendWindow"; ValueData: 2097152
