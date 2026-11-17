# ===== setup.ps1 -- POORA FILE REPLACE KORO =====
# Fix: Windows "Application Control policy blocked" (os error 4551) = uv er download kora python.exe block.
# Ekhon: system e Python 3.10-3.12 / Node 18+ thakle SEGULA-i use hobe (download skip). Na thakle tabei private download.
$ErrorActionPreference = 'Stop'
$ProgressPreference    = 'SilentlyContinue'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$Root = $PSScriptRoot
$P    = Join-Path $Root '.portable'
New-Item -ItemType Directory -Force $P | Out-Null

$env:PYTHONNOUSERSITE = '1'
Remove-Item Env:PYTHONPATH -ErrorAction SilentlyContinue
Remove-Item Env:PYTHONHOME -ErrorAction SilentlyContinue

function Check($what) { if ($LASTEXITCODE -ne 0) { throw "$what failed (exit $LASTEXITCODE)" } }

function Test-Exe($exe, $arguments) {
    try { & $exe @arguments *> $null; return ($LASTEXITCODE -eq 0) } catch { return $false }
}

function Find-SystemPython {
    # Direct install paths (PATH refresh na hole-o detect korbe)
    $direct = @(
        "$env:LocalAppData\Programs\Python\Python312\python.exe",
        "$env:LocalAppData\Programs\Python\Python311\python.exe",
        "$env:LocalAppData\Programs\Python\Python310\python.exe",
        "$env:ProgramFiles\Python312\python.exe",
        "$env:ProgramFiles\Python311\python.exe",
        "$env:ProgramFiles\Python310\python.exe"
    )
    foreach ($d in $direct) {
        if (-not (Test-Path $d)) { continue }
        try {
            $o = & $d -c "import sys;print(sys.version_info[0])" 2>$null
            if ($LASTEXITCODE -eq 0 -and "$o".Trim() -eq '3') { return $d }
        } catch { continue }
    }
    $cands = @(@('py','-3.12'), @('py','-3.11'), @('py','-3.10'), @('python'), @('python3'))
    foreach ($c in $cands) {
        $cmd = Get-Command $c[0] -ErrorAction SilentlyContinue
        if (-not $cmd) { continue }
        $pre = @(); if ($c.Count -gt 1) { $pre = @($c[1]) }
        try {
            $out = & $cmd.Source @pre -c "import sys;print(sys.executable+'|'+str(sys.version_info[0])+'.'+str(sys.version_info[1]))" 2>$null
            if ($LASTEXITCODE -ne 0 -or -not $out) { continue }
            $parts = ([string]$out).Trim().Split('|')
            $ver = [version]$parts[1]
            if ($ver -ge [version]'3.10' -and $ver -lt [version]'3.13' -and (Test-Path $parts[0])) { return $parts[0] }
        } catch { continue }
    }
    return $null
}

# ---------- 1+2) Python venv ----------
$venv = Join-Path $P 'venv'
$py   = Join-Path $venv 'Scripts\python.exe'
$uv   = Join-Path $P 'uv.exe'
$venvOk = (Test-Path $py) -and (Test-Exe $py @('-c','import sys'))

if (-not $venvOk) {
    if (Test-Path $venv) { Remove-Item $venv -Recurse -Force }
    $sysPy = Find-SystemPython
    if ($sysPy) {
        Write-Host "[1/5] System Python found: $sysPy (download skip)"
        Write-Host '[2/5] Creating venv from system Python...'
        & $sysPy -m venv $venv
        Check 'venv creation'
    } else {
        Write-Host '[1/5] System Python not found -> downloading uv...'
        $env:UV_PYTHON_INSTALL_DIR = Join-Path $P 'python'
        $env:UV_CACHE_DIR          = Join-Path $P 'cache'
        $env:UV_PYTHON_PREFERENCE  = 'only-managed'
        if (-not (Test-Path $uv)) {
            $zip = Join-Path $P 'uv.zip'; $tmp = Join-Path $P 'uvtmp'
            Invoke-WebRequest 'https://github.com/astral-sh/uv/releases/latest/download/uv-x86_64-pc-windows-msvc.zip' -OutFile $zip
            Expand-Archive $zip $tmp -Force
            $found = Get-ChildItem $tmp -Recurse -Filter uv.exe | Select-Object -First 1
            if (-not $found) { throw 'uv.exe not found in archive' }
            Copy-Item $found.FullName $uv -Force
            Remove-Item $zip, $tmp -Recurse -Force
        }
        Write-Host '[2/5] Creating private Python 3.11 venv...'
        & $uv venv --python 3.11 $venv
        Check 'venv creation'
    }
    if (-not (Test-Exe $py @('-c','import sys'))) {
        throw "Python is blocked by Windows Application Control (Smart App Control / WDAC). Install Python 3.11 from python.org (signed) then run setup.bat again."
    }
} else {
    Write-Host '[1-2/5] venv already OK (skip)'
}

# ---------- 3) backend deps ----------
Write-Host '[3/5] Installing backend dependencies (TensorFlow is large, wait)...'
& $py -m pip install --upgrade pip --disable-pip-version-check
Check 'pip upgrade'
& $py -m pip install --disable-pip-version-check -r (Join-Path $Root 'backend\requirements.txt') waitress==3.0.0
Check 'pip install'

# ---------- 4) Node ----------
$npm = $null; $nodeDir = $null
$sysNode = Get-Command node -ErrorAction SilentlyContinue
$sysNpm  = Get-Command npm.cmd -ErrorAction SilentlyContinue
if ($sysNode -and $sysNpm) {
    try {
        $nv = [version]((& $sysNode.Source -v).Trim().TrimStart('v'))
        if ($nv -ge [version]'18.0.0') { $npm = $sysNpm.Source; Write-Host "[4/5] System Node v$nv found (download skip)" }
    } catch {}
}
if (-not $npm) {
    $node = Join-Path $P 'node'
    if (-not (Test-Path (Join-Path $node 'node.exe'))) {
        Write-Host '[4/5] Downloading private Node 20...'
        if (Test-Path $node) { Remove-Item $node -Recurse -Force }
        $nz = Join-Path $P 'node.zip'
        Invoke-WebRequest 'https://nodejs.org/dist/v20.18.0/node-v20.18.0-win-x64.zip' -OutFile $nz
        Expand-Archive $nz $P -Force
        Rename-Item (Join-Path $P 'node-v20.18.0-win-x64') 'node'
        Remove-Item $nz -Force
    }
    $env:Path = "$node;$env:Path"
    $npm = Join-Path $node 'npm.cmd'
}

# ---------- 5) build frontend ----------
Write-Host '[5/5] Building frontend...'
$env:npm_config_cache       = Join-Path $P 'npm-cache'
$env:REACT_APP_API_BASE_URL = 'http://localhost:5055'
$env:GENERATE_SOURCEMAP     = 'false'
$env:INLINE_RUNTIME_CHUNK   = 'false'
$env:CI                     = 'false'

Push-Location (Join-Path $Root 'frontend')
try {
    & $npm ci --no-audit --no-fund
    Check 'npm ci'
    & $npm run build
    Check 'npm run build'
} finally { Pop-Location }

if (-not (Test-Path (Join-Path $Root 'frontend\build\index.html'))) { throw 'Frontend build missing' }
Write-Host 'OK'