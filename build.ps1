# Build ft_ping with Visual Studio
# Run this from the ft_ping directory

$ErrorActionPreference = "Stop"

Write-Host "Building ft_ping with MSVC..." -ForegroundColor Cyan

# Find MSVC compiler
$msvcPath = "C:\Program Files\Microsoft Visual Studio\2022\Community\VC\Tools\MSVC"
if (Test-Path $msvcPath) {
    $versions = Get-ChildItem $msvcPath -Directory | Sort-Object Name -Descending
    if ($versions) {
        $latestVersion = $versions[0].FullName
        $vcvarsPath = "$latestVersion\bin\Hostx64\x64\vcvars64.bat"

        if (Test-Path $vcvarsPath) {
            Write-Host "Found MSVC at: $latestVersion"

            # Create output directories
            New-Item -ItemType Directory -Force -Path "bin\Debug", "bin\Release", "obj\Debug", "obj\Release" | Out-Null

            # Compile using cl.exe
            $includePath = "$latestVersion\include"
            $libPath = "$latestVersion\lib\Hostx64\x64"

            Write-Host "Compiling main.c..." -ForegroundColor Yellow

            $compileCmd = "cl.exe /W3 /EHsc /Od /I includes srcs\main.c ws2_32.lib /Fe:bin\Debug\ft_ping.exe /Fo:obj\Debug\"

            Write-Host "Command: $compileCmd"

            # Run from Developer Command Prompt environment
            & cmd /c "call `"$vcvarsPath`" && $compileCmd"
        }
    }
}
else {
    Write-Host "MSVC not found at default location." -ForegroundColor Red
    Write-Host "Please open Visual Studio Developer Command Prompt and run:" -ForegroundColor Yellow
    Write-Host "  cl /W3 /EHsc /I includes srcs\main.c ws2_32.lib /Fe:ft_ping.exe"
}