# Chocolatey profile
$ChocolateyProfile = "$env:ChocolateyInstall\helpers\chocolateyProfile.psm1"
if (Test-Path($ChocolateyProfile)) {
  Import-Module "$ChocolateyProfile"
}

# Setup batch aliases
DOSKEY py = python

# Setup powershell aliases
Set-Alias -Name py -Value python

# Find repo
function fr() {
  $repos_dir_name = "code"
  $dir = Resolve-Path $(Join-Path $env:HOME $repos_dir_name)
  $codedirs = Get-ChildItem $dir | Where-Object { $_.PSIsContainer }
  $selection = $codedirs | Select-Object -ExpandProperty Name | fzf
  if (-not ($selection)) {
    Write-Host -ForegroundColor Red "No repo selected"
    return
  }
  $path = Join-Path $dir $selection
  Set-Location $path
  Write-Host -ForegroundColor Magenta "Current repo is: $selection"
}

function helpme() {
  Write-Host "You can do these:"
  Write-Host "sab          - (Select and build game)"
  Write-Host "selectgame   - Interactively select a game and go to its folder"
  Write-Host "buildgame    - In game folder, set required unity version, refresh env vars, then build the game"
  Write-Host "copytodevsim - Copies game output to dev sim folder"
  Write-Host "jur          - Interactively select a jurisdiction and copy it to STAGE_HOME\cfg"
  Write-Host "ku           - Kill Unity"
}

function sab() {
  selectgame
  buildgame
}

function selectgame() {
  $prefix = "yash.khade_";
  $dir = "D:\P4"

  if (-not (Test-Path $dir)) {
    Write-Host -Red "Game collection directory not found at '$dir'"
    return
  }

  $gamedirs = Get-ChildItem $dir | Where-Object { $_.PSIsContainer -and $_.Name.StartsWith($prefix) }
  $selection = $gamedirs | Select-Object -ExpandProperty Name | ForEach-Object { $_.Replace($prefix, "") } | fzf
  if (-not ($selection)) {
    Write-Host -ForegroundColor Red "No game selected"
    return
  }
  $path = Join-Path $dir $prefix$selection
  Set-Location $path
  Write-Host -ForegroundColor Magenta "Current Game is: $selection"
}

# Assumes current folder is a game folder
# Set the required unity version for a game
# 
function buildgame() {
  ku
  if (-not (Test-Path make.bat)) {
    Write-Host -ForegroundColor Red "No make.bat file is present in the current folder"
    return
  }
  else {
    Write-Host -ForegroundColor Magenta "make.bat found!"
  }

  if (-not (Test-Path build.json)) {
    Write-Host -ForegroundColor Red "No build.json found"
    return 
  }
  else {
    Write-Host -ForegroundColor Magenta "build.json found!"
  }

  #$unityVersion = Get-Content .\build.json | rg 'ReqUnityVersion\"[^\"]+\"(.*)\"' -o -r '$1'
  $unityVersion = (Get-Content .\build.json | ConvertFrom-Json).ReqUnityVersion
  Write-Host "It is: $unityVersion"
  if ([string]::IsNullOrEmpty($unityVersion)) {
    Write-Host -ForegroundColor Magenta "Build.json not found in game path. Checking GDK folder..."

    # Game's build.json did not have the unity version
    # so retrieve it from the build.json
    $unityVersion = (Get-Content .\GDK\build.json | ConvertFrom-Json).Dependencies.Unity.Version

    if ([string]::IsNullOrEmpty($unityVersion)) {
      Write-Host -ForegroundColor red "No unity path was found in the GDK's build.json"
      return
    } else {
      Write-Host -ForegroundColor Magenta "Found unity path in GDK's build.json!"
    }
  }
  $unityPath = "C:\Program Files\Unity\Hub\Editor\$unityVersion"
  if (-not (Test-Path $unityPath)) {
    Write-Host -ForegroundColor Red "The folder '$unityPath' doesn't exist! Make sure this version of unity is installed."
    return
  }

  [System.Environment]::SetEnvironmentVariable("UNITY_HOME", $unityPath, "User")
  refreshenv # thanks, chocolatey
  Write-Host -ForegroundColor Magenta "Set UNITY_HOME to '$env:UNITY_HOME'"

  Write-Host -ForegroundColor Magenta "Starting game build..."
  ./make.bat -getdeps -buildpsapi
  ./make.bat
}

function copytodevsim() {
  if ($env:WEBAPP_HOME -eq "" -or (-not $env:WEBAPP_HOME)) {
    Write-Host -Red "WEBAPP_HOME environment variable not set!"
    return
  }

  $path1 = "Build\Debug\games"
  $path2 = "Build\Development\games"
  $foundPath = ""

  if (Test-Path $path1) {
    $foundPath = $path1
  } 
  elseif (Test-Path Build\Development\games) {
    $foundPath = $path2
  } else {
    Write-Host -ForegroundColor Red "Compiled game not found at '$path1' or '$path2'. Make sure game is built."
    return
  }

  $path = $(Get-ChildItem $foundPath | Where-Object { $_.PSIsContainer })[0] | Select-Object -ExpandProperty FullName
  Write-Host -ForegroundColor Magenta "Game found at $path!"

  $name = Split-Path $path -leaf

  $gamePath = "$env:WEBAPP_HOME\games\$name"
  if (Test-Path $gamePath) {
    Write-Host -ForegroundColor Yellow "Game folder found at: '$gamePath'. Deleting..."
    Remove-Item -Force -Recurse $gamePath
  }
  Write-Host -ForegroundColor Magenta "Copying compiled game"
  Write-Host -ForegroundColor Magenta "from: '$path'"
  Write-Host -ForegroundColor Magenta "to:   '$gamePath'"
  Copy-Item $path $gamePath -Force -Recurse -Container
}

function jur {
  if ($env:STAGE_HOME -eq "") {
    Write-Host -Red "STAGE_HOME environment variable not set!"
    return
  }

  $prefix = "Jurisdiction_";
  $dir = "D:\Jurisdictions"

  if (-not (Test-Path $dir)) {
    Write-Host -Red "Jurisdiction directory not found at '$dir'"
    return
  }

  $dirs = Get-ChildItem $dir | Where-Object { $_.Extension -eq ".xml" -and $_.Name.StartsWith($prefix) }
  $selection = $dirs | Select-Object -ExpandProperty Name | ForEach-Object { $_.Replace($prefix, "").Replace(".xml", "") } | fzf
  if (-not ($selection)) {
    Write-Host -ForegroundColor Red "No file selected"
    return
  }
  $jurName = "$prefix$selection.xml"
  $jurPath = Join-Path $dir $jurName
  $outputPath = Join-Path $env:STAGE_HOME\cfg "Jurisdiction.xml"

  Write-Host -ForegroundColor Magenta "Copying jurisdiction"
  Write-Host -ForegroundColor Magenta "from: '$jurPath'"
  Write-Host -ForegroundColor Magenta "to:   '$outputPath'"
  Copy-Item -Force -Recurse $jurPath $outputPath
}

function ku {
  Write-Host -ForegroundColor Magenta "Killing Unity if it's up..."
  Stop-Process -Name Unity -ErrorAction SilentlyContinue
}