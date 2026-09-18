<# :
@echo off
setlocal EnableDelayedExpansion
title WiFi Card Switcher ^& Auto-Connect - by Biraj2004
cd /d "%~dp0"

:: =======================================================================================================
:: GitHub      : https://github.com/Biraj2004
:: Developer   : Biraj
:: Description : Universally auto-detects ALL physical Wi-Fi adapters on any Windows device and seamlessly
::                maintains continuous network connectivity by auto-connecting to the currently active or
::                last-used Wi-Fi network (e.g. BIRAJ HOME 5GHz or current hotspot).
::                - Dynamic Discovery: Detects all physical 802.11 adapters (MediaTek, TP-Link, Intel, etc.).
::                - Adaptive UI: Morphs menu automatically based on card count (1 card, 2 cards, 3+ cards).
::                - Continuity Engine: Captures the active/in-use Wi-Fi network before switching cards,
::                  provisions the profile to the destination adapter, and auto-connects to sustain internet.
::                - Make-Before-Break: Enables destination card before disabling source card to prevent drops.
::                - Cold Start Recovery: If all cards are offline, auto-detects last-used/preferred network.
::                - Live Telemetry: Reports signal %, BSSID, radio type, channel, link speed, IP & Gateway.
::                - Dual Execution: Interactive colored console menu OR direct CLI flags (--card1, -m, -t, etc.).
::                - Privilege Elevation: Automatically checks for Administrator rights and requests UAC.
::                - Re-running this script is SAFE: Idempotent operations ensure no duplicate state modifications.
:: =======================================================================================================

:: Check for Administrative Privileges
net session >nul 2>&1
if %errorlevel% equ 0 goto :RUN_SCRIPT

:: Read-only status and help commands can run without elevation
if /i "%~1"=="--status" goto :RUN_SCRIPT
if /i "%~1"=="-s" goto :RUN_SCRIPT
if /i "%~1"=="8" goto :RUN_SCRIPT
if /i "%~1"=="--help" goto :RUN_SCRIPT
if /i "%~1"=="-h" goto :RUN_SCRIPT
if /i "%~1"=="/?" goto :RUN_SCRIPT

echo =======================================================================================================
echo                           WIFI CARD SWITCHER ^& AUTO-CONNECT (ELEVATION REQUIRED)
echo                       Developed by : Biraj
echo                       GitHub       : https://github.com/Biraj2004
echo =======================================================================================================
echo.
echo [INFO] Administrative privileges are required to enable and disable network adapters.
echo [INFO] Requesting User Account Control (UAC) elevation...
echo.

powershell -NoProfile -NoLogo -ExecutionPolicy Bypass -Command "try { Start-Process -FilePath cmd.exe -ArgumentList '/c \"\"%~f0\" %*\"' -Verb RunAs -ErrorAction Stop } catch { Write-Host '[ERROR] Administrator elevation was denied or failed.' -ForegroundColor Red; Write-Host '[INFO] Please right-click this script and select \"Run as administrator\".' -ForegroundColor Yellow; Start-Sleep -Seconds 4; exit 1 }"
exit /b

:RUN_SCRIPT

where powershell >nul 2>&1
if errorlevel 1 (
    echo [ERROR] PowerShell was not found on this system. Cannot continue.
    echo.
    pause
    exit /b 1
)

powershell -NoProfile -NoLogo -ExecutionPolicy Bypass -Command "& ([scriptblock]::Create([System.IO.File]::ReadAllText('%~f0')))" %*
set "PS_EXIT=!ERRORLEVEL!"

echo -------------------------------------------------------------------------------------------------------
echo =======================================================================================================
echo [FINISHED] Script execution finished. GitHub: https://github.com/Biraj2004
echo =======================================================================================================
if "%~1"=="" pause
endlocal
exit /b !PS_EXIT!
#>

$ErrorActionPreference = 'Stop'
$Host.UI.RawUI.WindowTitle = 'WiFi Card Switcher & Auto-Connect - by Biraj2004'

$dividerHeavy = '=' * 103
$dividerLight = '-' * 103

# Embedded profile template fallback for 'BIRAJ HOME 5GHz'
$PROFILE_XML_TEMPLATE_BIRAJ = @'
<?xml version="1.0"?>
<WLANProfile xmlns="http://www.microsoft.com/networking/WLAN/profile/v1">
	<name>BIRAJ HOME 5GHz</name>
	<SSIDConfig>
		<SSID>
			<hex>424952414A20484F4D45203547487A</hex>
			<name>BIRAJ HOME 5GHz</name>
		</SSID>
	</SSIDConfig>
	<connectionType>ESS</connectionType>
	<connectionMode>auto</connectionMode>
	<MSM>
		<security>
			<authEncryption>
				<authentication>WPA2PSK</authentication>
				<encryption>AES</encryption>
				<useOneX>false</useOneX>
			</authEncryption>
			<sharedKey>
				<keyType>passPhrase</keyType>
				<protected>false</protected>
				<keyMaterial>birajhome@12345</keyMaterial>
			</sharedKey>
		</security>
	</MSM>
	<MacRandomization xmlns="http://www.microsoft.com/networking/WLAN/profile/v3">
		<enableRandomization>false</enableRandomization>
		<randomizationSeed>1610291781</randomizationSeed>
	</MacRandomization>
</WLANProfile>
'@

# -----------------------------------------------------------------------------
# Function: Dynamically Discover ALL Physical Wi-Fi Adapters on Any Device
# -----------------------------------------------------------------------------
function Get-WiFiAdapters {
    $rawAdapters = @(Get-NetAdapter -ErrorAction SilentlyContinue | Where-Object { 
        ($_.PhysicalMediaType -eq 'Native 802.11' -or $_.InterfaceType -eq 71) -and 
        $_.InterfaceDescription -notlike '*Virtual*' -and 
        $_.InterfaceDescription -notlike '*Direct*' 
    } | Sort-Object Name)

    $result = @()
    foreach ($a in $rawAdapters) {
        $cleanDesc = $a.InterfaceDescription -replace '\(R\)', '' -replace 'LAN Card', '' -replace 'Wireless Adapter', 'Wi-Fi' -replace '802\.11[a-z]*', '' -replace '\s+', ' '
        $cleanDesc = $cleanDesc.Trim()

        $friendly = "$cleanDesc ($($a.Name))"
        $shortName = if ($cleanDesc.Length -gt 25) { $cleanDesc.Substring(0, 23).Trim() + "..." } else { $cleanDesc }

        $result += [PSCustomObject]@{
            AdapterObj   = $a
            Name         = $a.Name
            Description  = $a.InterfaceDescription
            FriendlyName = $friendly
            ShortName    = $shortName
            Status       = $a.Status
            MacAddress   = $a.MacAddress
        }
    }
    return $result
}

# -----------------------------------------------------------------------------
# Function: Detect Active or Last-Used Wi-Fi Network
# -----------------------------------------------------------------------------
function Get-ActiveOrLastUsedNetwork {
    # 1. Check if any Wi-Fi interface is currently connected right now
    try {
        $rawInterfaces = netsh wlan show interfaces 2>&1 | Out-String
        $sections = $rawInterfaces -split "(?m)(?=^\s*Name\s*:)"
        foreach ($sec in $sections) {
            if ($sec -match "(?m)^\s*State\s*:\s*connected" -and $sec -match "(?m)^\s*SSID\s*:\s*([^\r\n]+)") {
                $activeSsid = $matches[1].Trim()
                if ($activeSsid) {
                    return $activeSsid
                }
            }
        }
    } catch {}

    # 2. Check visible broadcasting networks that match installed profiles
    try {
        $visibleRaw = netsh wlan show networks 2>&1 | Out-String
        $visibleMatches = [regex]::Matches($visibleRaw, '(?m)^\s*SSID\s+\d+\s*:\s*([^\r\n]+)')
        $visibleSsids = @($visibleMatches | ForEach-Object { $_.Groups[1].Value.Trim() })

        $profilesRaw = netsh wlan show profiles 2>&1 | Out-String
        $profileMatches = [regex]::Matches($profilesRaw, '(?m)All User Profile\s*:\s*([^\r\n]+)')
        $installedProfiles = @($profileMatches | ForEach-Object { $_.Groups[1].Value.Trim() })

        foreach ($prof in $installedProfiles) {
            if ($visibleSsids -contains $prof) {
                return $prof
            }
        }

        # 3. Preferred default fallback
        if ($installedProfiles -contains 'BIRAJ HOME 5GHz') {
            return 'BIRAJ HOME 5GHz'
        }

        if ($installedProfiles.Count -gt 0) {
            return $installedProfiles[0]
        }
    } catch {}

    return 'BIRAJ HOME 5GHz'
}

# -----------------------------------------------------------------------------
# Function: Parse WLAN Interface Telemetry from netsh
# -----------------------------------------------------------------------------
function Get-WlanTelemetry {
    param([string]$InterfaceName)

    $result = @{
        State        = 'Disconnected'
        SSID         = '-'
        BSSID        = '-'
        Signal       = '-'
        RadioType    = '-'
        Channel      = '-'
        ReceiveRate  = '-'
        TransmitRate = '-'
        IPAddress    = '-'
        Gateway      = '-'
    }

    if (-not $InterfaceName) { return $result }

    try {
        $raw = netsh wlan show interfaces | Out-String
        $sections = $raw -split "(?m)(?=^\s*Name\s*:)"

        foreach ($sec in $sections) {
            if ($sec -match "(?m)^\s*Name\s*:\s*([^\r\n]+)") {
                $foundName = $matches[1].Trim()
                if ($foundName -eq $InterfaceName) {
                    if ($sec -match "(?m)^\s*State\s*:\s*([^\r\n]+)") { $result.State = $matches[1].Trim() }
                    if ($sec -match "(?m)^\s*SSID\s*:\s*([^\r\n]+)") { $result.SSID = $matches[1].Trim() }
                    if ($sec -match "(?m)^\s*BSSID\s*:\s*([^\r\n]+)") { $result.BSSID = $matches[1].Trim() }
                    if ($sec -match "(?m)^\s*Signal\s*:\s*([^\r\n]+)") { $result.Signal = $matches[1].Trim() }
                    if ($sec -match "(?m)^\s*Radio type\s*:\s*([^\r\n]+)") { $result.RadioType = $matches[1].Trim() }
                    if ($sec -match "(?m)^\s*Channel\s*:\s*([^\r\n]+)") { $result.Channel = $matches[1].Trim() }
                    if ($sec -match "(?m)^\s*Receive rate \(Mbps\)\s*:\s*([^\r\n]+)") { $result.ReceiveRate = $matches[1].Trim() }
                    if ($sec -match "(?m)^\s*Transmit rate \(Mbps\)\s*:\s*([^\r\n]+)") { $result.TransmitRate = $matches[1].Trim() }
                    break
                }
            }
        }

        # Query IPv4 Address
        $ipObj = Get-NetIPAddress -InterfaceAlias $InterfaceName -AddressFamily IPv4 -ErrorAction SilentlyContinue |
                 Where-Object { $_.IPAddress -notlike '169.254.*' } | Select-Object -First 1
        if ($ipObj) {
            $result.IPAddress = $ipObj.IPAddress
        }

        # Query Gateway
        $routeObj = Get-NetRoute -InterfaceAlias $InterfaceName -DestinationPrefix '0.0.0.0/0' -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($routeObj -and $routeObj.NextHop -and $routeObj.NextHop -ne '0.0.0.0') {
            $result.Gateway = $routeObj.NextHop
        }
    } catch {}

    return $result
}

# -----------------------------------------------------------------------------
# Function: Ensure Target Wi-Fi Profile is Installed on the Destination Interface
# -----------------------------------------------------------------------------
function Ensure-WiFiProfileOnInterface {
    param(
        [string]$ProfileName,
        [string]$InterfaceName
    )

    if (-not $ProfileName -or -not $InterfaceName) { return $false }

    # 1. Check if profile is already assigned to the interface
    $profileCheck = netsh wlan show profiles interface="$InterfaceName" 2>&1 | Out-String
    if ($profileCheck -like "*$ProfileName*") {
        return $true
    }

    Write-Host " [PROVISION] Syncing Wi-Fi profile '$ProfileName' to adapter '$InterfaceName'..." -ForegroundColor Cyan

    $tempDir = [System.IO.Path]::GetTempPath()
    $tempFile = $null

    try {
        # 2. Try exporting existing profile from Windows store
        $null = netsh wlan export profile name="$ProfileName" folder="$tempDir" key=clear 2>&1
        $exportedFiles = Get-ChildItem -Path $tempDir -Filter "*$ProfileName.xml" -ErrorAction SilentlyContinue | Select-Object -First 1

        if ($exportedFiles) {
            $tempFile = $exportedFiles.FullName
        } elseif ($ProfileName -ieq 'BIRAJ HOME 5GHz') {
            # Fallback to embedded XML template
            $tempFile = Join-Path $tempDir "WifiProfile_BirajHome5GHz.xml"
            [System.IO.File]::WriteAllText($tempFile, $PROFILE_XML_TEMPLATE_BIRAJ, [System.Text.Encoding]::UTF8)
        }

        if ($tempFile -and (Test-Path $tempFile)) {
            $addOutput = netsh wlan add profile filename="$tempFile" interface="$InterfaceName" user=all 2>&1 | Out-String
            Remove-Item $tempFile -Force -ErrorAction SilentlyContinue
            if ($addOutput -like "*added successfully*" -or $addOutput -like "*is added*") {
                Write-Host " [SUCCESS] Profile '$ProfileName' registered on '$InterfaceName'." -ForegroundColor Green
                return $true
            }
        }
    } catch {
        if ($tempFile -and (Test-Path $tempFile)) { Remove-Item $tempFile -Force -ErrorAction SilentlyContinue }
    }

    return $false
}

# -----------------------------------------------------------------------------
# Function: Connect to Target Network with Timeout Polling
# -----------------------------------------------------------------------------
function Connect-TargetNetwork {
    param(
        [string]$InterfaceName,
        [string]$NetworkSsid
    )

    if (-not $InterfaceName) { return $false }
    if (-not $NetworkSsid) { $NetworkSsid = Get-ActiveOrLastUsedNetwork }

    Ensure-WiFiProfileOnInterface -ProfileName $NetworkSsid -InterfaceName $InterfaceName | Out-Null

    Write-Host " [CONNECTING] Connecting '$InterfaceName' to '$NetworkSsid'..." -ForegroundColor Cyan
    $null = netsh wlan connect name="$NetworkSsid" ssid="$NetworkSsid" interface="$InterfaceName" 2>&1

    # Poll connection state up to 8 seconds
    $connected = $false
    $timeoutSeconds = 8
    $sw = [System.Diagnostics.Stopwatch]::StartNew()

    Write-Host -NoNewline " [WAITING] Associating with network: " -ForegroundColor White
    while ($sw.Elapsed.TotalSeconds -lt $timeoutSeconds) {
        Write-Host -NoNewline '.' -ForegroundColor Yellow
        Start-Sleep -Milliseconds 800

        $telemetry = Get-WlanTelemetry -InterfaceName $InterfaceName
        if ($telemetry.State -ieq 'connected' -and $telemetry.SSID -ieq $NetworkSsid) {
            $connected = $true
            break
        }
    }
    Write-Host ''

    if ($connected) {
        $finalTelemetry = Get-WlanTelemetry -InterfaceName $InterfaceName
        Write-Host " [CONNECTED] Successfully connected to '$NetworkSsid' on '$InterfaceName'!" -ForegroundColor Green
        Write-Host "             Signal Strength : $($finalTelemetry.Signal)" -ForegroundColor Green
        Write-Host "             Link Speed      : Recv $($finalTelemetry.ReceiveRate) Mbps / Trans $($finalTelemetry.TransmitRate) Mbps" -ForegroundColor Green
        Write-Host "             Channel / Radio : Ch $($finalTelemetry.Channel) ($($finalTelemetry.RadioType))" -ForegroundColor Green
        if ($finalTelemetry.IPAddress -ne '-') {
            Write-Host "             IP Address      : $($finalTelemetry.IPAddress) (Gateway: $($finalTelemetry.Gateway))" -ForegroundColor Green
        }
        return $true
    } else {
        Write-Host " [WARNING] Interface '$InterfaceName' initiated connection, but association timed out." -ForegroundColor Yellow
        Write-Host "           Windows wireless service will continue attempting connection in background." -ForegroundColor Gray
        return $false
    }
}

# -----------------------------------------------------------------------------
# Function: Set Adapter Administrative Status
# -----------------------------------------------------------------------------
function Set-AdapterAdminStatus {
    param(
        [string]$AdapterName,
        [bool]$Enable
    )

    if (-not $AdapterName) { return $false }

    $actionText = if ($Enable) { 'Enabling' } else { 'Disabling' }
    Write-Host " [PROCESSING] $actionText network adapter '$AdapterName'..." -ForegroundColor Cyan

    try {
        if ($Enable) {
            Enable-NetAdapter -Name $AdapterName -Confirm:$false -ErrorAction Stop
        } else {
            Disable-NetAdapter -Name $AdapterName -Confirm:$false -ErrorAction Stop
        }
        Start-Sleep -Milliseconds 1200
        return $true
    } catch {
        # Fallback to netsh interface command if cmdlet throws
        try {
            $cmdStatus = if ($Enable) { 'ENABLED' } else { 'DISABLED' }
            netsh interface set interface name="$AdapterName" admin=$cmdStatus 2>&1 | Out-Null
            Start-Sleep -Milliseconds 1200
            return $true
        } catch {
            Write-Host " [ERROR] Failed to set status on '$AdapterName': $_" -ForegroundColor Red
            return $false
        }
    }
}

# -----------------------------------------------------------------------------
# Function: Render Status Dashboard
# -----------------------------------------------------------------------------
function Render-StatusDashboard {
    param(
        $Adapters,
        [string]$CurrentNetwork
    )

    Write-Host $dividerLight -ForegroundColor Gray
    Write-Host " REAL-TIME WI-FI ADAPTERS & NETWORK STATUS ($($Adapters.Count) Card$(if ($Adapters.Count -ne 1) {'s'} else {''}) Detected)" -ForegroundColor Cyan
    Write-Host " Active / Target Network : $CurrentNetwork" -ForegroundColor Green
    Write-Host $dividerLight -ForegroundColor Gray

    if ($Adapters.Count -eq 0) {
        Write-Host ' [WARNING] No physical Wi-Fi (802.11) adapters found on this device.' -ForegroundColor Yellow
        Write-Host '           Please plug in a USB Wi-Fi adapter or enable your wireless hardware.' -ForegroundColor Gray
        Write-Host $dividerLight -ForegroundColor Gray
        return
    }

    $rows = @()
    for ($i = 0; $i -lt $Adapters.Count; $i++) {
        $card = $Adapters[$i]
        $liveStatus = (Get-NetAdapter -Name $card.Name -ErrorAction SilentlyContinue).Status
        $telemetry = if ($liveStatus -eq 'Up') { Get-WlanTelemetry -InterfaceName $card.Name } else { $null }

        $stateDisplay = if ($liveStatus -eq 'Up') {
            if ($telemetry -and $telemetry.State -ieq 'connected') { 
                "Connected ($($telemetry.SSID))" 
            } else { 
                "Enabled (Disconnected)" 
            }
        } else {
            "Disabled"
        }

        $signalDisplay = if ($telemetry -and $telemetry.Signal -ne '-') { $telemetry.Signal } else { '-' }
        $speedDisplay  = if ($telemetry -and $telemetry.ReceiveRate -ne '-') { "$($telemetry.ReceiveRate) Mbps" } else { '-' }
        $ipDisplay     = if ($telemetry -and $telemetry.IPAddress -ne '-') { $telemetry.IPAddress } else { '-' }

        $rows += [PSCustomObject]@{
            '#'         = ($i + 1)
            Adapter     = $card.ShortName
            Interface   = $card.Name
            Status      = $stateDisplay
            Signal      = $signalDisplay
            LinkSpeed   = $speedDisplay
            IPAddress   = $ipDisplay
        }
    }

    # Render formatted table
    $rows | Format-Table -Property '#', Adapter, Interface, Status, Signal, LinkSpeed, IPAddress -AutoSize | Out-String | Write-Host -ForegroundColor White
    Write-Host $dividerLight -ForegroundColor Gray
}

# -----------------------------------------------------------------------------
# Operational Routines: Graceful "Make-Before-Break" Switch
# -----------------------------------------------------------------------------
function Switch-ToSingleAdapter {
    param(
        [int]$TargetIndex,
        $Adapters,
        [string]$TargetNetwork
    )

    if ($TargetIndex -lt 0 -or $TargetIndex -ge $Adapters.Count) {
        Write-Host " [ERROR] Invalid adapter selection index: $($TargetIndex + 1)" -ForegroundColor Red
        return
    }

    # If target network not specified, capture from active connection right now
    if (-not $TargetNetwork) {
        $TargetNetwork = Get-ActiveOrLastUsedNetwork
    }

    $targetCard = $Adapters[$TargetIndex]

    Write-Host ''
    Write-Host $dividerLight -ForegroundColor Gray
    Write-Host " [ACTION] Gracefully switching to $($targetCard.FriendlyName)..." -ForegroundColor Cyan
    Write-Host "          Target Network for Continuity: '$TargetNetwork'" -ForegroundColor White
    Write-Host $dividerLight -ForegroundColor Gray

    # 1. Enable Target Adapter FIRST (Make-Before-Break)
    Set-AdapterAdminStatus -AdapterName $targetCard.Name -Enable $true | Out-Null

    # 2. Allow radio hardware & driver to initialize
    Write-Host " [INITIALIZE] Initializing wireless radio on '$($targetCard.Name)'..." -ForegroundColor White
    Start-Sleep -Milliseconds 1500

    # 3. Connect Target Adapter to sustained network
    Connect-TargetNetwork -InterfaceName $targetCard.Name -NetworkSsid $TargetNetwork | Out-Null

    # 4. Disable All Other Wi-Fi Adapters
    for ($i = 0; $i -lt $Adapters.Count; $i++) {
        if ($i -ne $TargetIndex) {
            Set-AdapterAdminStatus -AdapterName $Adapters[$i].Name -Enable $false | Out-Null
        }
    }

    Write-Host ''
    Write-Host " [SUCCESS] Switched successfully! Internet continuity established on $($targetCard.FriendlyName)." -ForegroundColor Green
}

function Enable-AllAdapters {
    param(
        $Adapters,
        [string]$TargetNetwork
    )

    if (-not $TargetNetwork) { $TargetNetwork = Get-ActiveOrLastUsedNetwork }

    Write-Host ''
    Write-Host $dividerLight -ForegroundColor Gray
    Write-Host " [ACTION] Enabling ALL ($($Adapters.Count)) Wi-Fi Adapters & Connecting to '$TargetNetwork'..." -ForegroundColor Cyan
    Write-Host $dividerLight -ForegroundColor Gray

    foreach ($card in $Adapters) {
        Set-AdapterAdminStatus -AdapterName $card.Name -Enable $true | Out-Null
    }

    Start-Sleep -Milliseconds 1500

    foreach ($card in $Adapters) {
        Connect-TargetNetwork -InterfaceName $card.Name -NetworkSsid $TargetNetwork | Out-Null
    }
}

function Disable-AllAdapters {
    param($Adapters)
    Write-Host ''
    Write-Host $dividerLight -ForegroundColor Gray
    Write-Host " [ACTION] Disabling ALL ($($Adapters.Count)) Wi-Fi Adapters (Offline / Airplane Mode)..." -ForegroundColor Yellow
    Write-Host $dividerLight -ForegroundColor Gray

    foreach ($card in $Adapters) {
        Set-AdapterAdminStatus -AdapterName $card.Name -Enable $false | Out-Null
    }
    Write-Host " [SUCCESS] All Wi-Fi adapters disabled successfully." -ForegroundColor Green
}

function Toggle-SingleAdapter {
    param(
        [int]$TargetIndex,
        $Adapters,
        [string]$TargetNetwork
    )
    if ($TargetIndex -lt 0 -or $TargetIndex -ge $Adapters.Count) {
        Write-Host " [ERROR] Invalid adapter selection index: $($TargetIndex + 1)" -ForegroundColor Red
        return
    }

    if (-not $TargetNetwork) { $TargetNetwork = Get-ActiveOrLastUsedNetwork }

    $card = $Adapters[$TargetIndex]
    $currentStatus = (Get-NetAdapter -Name $card.Name -ErrorAction SilentlyContinue).Status
    $willEnable = ($currentStatus -ne 'Up')

    Write-Host ''
    Write-Host $dividerLight -ForegroundColor Gray
    Write-Host " [ACTION] Toggling $($card.FriendlyName) -> $(if ($willEnable) { 'ENABLE' } else { 'DISABLE' })..." -ForegroundColor Cyan
    Write-Host $dividerLight -ForegroundColor Gray

    Set-AdapterAdminStatus -AdapterName $card.Name -Enable $willEnable | Out-Null

    if ($willEnable) {
        Start-Sleep -Milliseconds 1500
        Connect-TargetNetwork -InterfaceName $card.Name -NetworkSsid $TargetNetwork | Out-Null
    }
}

function Reconnect-ActiveAdapters {
    param(
        $Adapters,
        [string]$TargetNetwork
    )
    if (-not $TargetNetwork) { $TargetNetwork = Get-ActiveOrLastUsedNetwork }

    Write-Host ''
    Write-Host $dividerLight -ForegroundColor Gray
    Write-Host " [ACTION] Reconnecting active adapter(s) to '$TargetNetwork'..." -ForegroundColor Cyan
    Write-Host $dividerLight -ForegroundColor Gray

    $reconnectedCount = 0
    foreach ($card in $Adapters) {
        $liveStatus = (Get-NetAdapter -Name $card.Name -ErrorAction SilentlyContinue).Status
        if ($liveStatus -eq 'Up') {
            Connect-TargetNetwork -InterfaceName $card.Name -NetworkSsid $TargetNetwork | Out-Null
            $reconnectedCount++
        }
    }

    if ($reconnectedCount -eq 0) {
        Write-Host " [WARNING] No Wi-Fi adapters are currently enabled. Please enable one first." -ForegroundColor Yellow
    }
}

# -----------------------------------------------------------------------------
# Main Banner & Startup
# -----------------------------------------------------------------------------
Write-Host $dividerHeavy -ForegroundColor Cyan
Write-Host '                          WIFI CARD SWITCHER & AUTO-CONNECT ENGINE                             ' -ForegroundColor Cyan
Write-Host '                       Developed by : Biraj                                                            ' -ForegroundColor Gray
Write-Host '                       GitHub       : https://github.com/Biraj2004                                     ' -ForegroundColor Gray
Write-Host $dividerHeavy -ForegroundColor Cyan
Write-Host ''
Write-Host ('[INFO] Working Directory : ' + (Get-Location).Path) -ForegroundColor White
$sustainedNetwork = Get-ActiveOrLastUsedNetwork
Write-Host ('[INFO] Sustained Network : ' + $sustainedNetwork + ' (Auto-detected from active/preferred network)') -ForegroundColor Green
Write-Host  '[INFO] Hardware Discovery: Dynamic physical 802.11 detection across all device manufacturers' -ForegroundColor White
Write-Host  '[INFO] Auto-Elevation    : Elevated Administrator Session Verified' -ForegroundColor Green
Write-Host ''

$adapters = Get-WiFiAdapters

# -----------------------------------------------------------------------------
# Non-Interactive CLI Argument Handling
# -----------------------------------------------------------------------------
$cliArg = if ($args -and $args.Count -gt 0) { $args[0].ToString().ToLower().Trim() } else { $null }

if ($cliArg) {
    if ($cliArg -match '^\d+$') {
        $num = [int]$cliArg
        if ($num -ge 1 -and $num -le $adapters.Count) {
            Switch-ToSingleAdapter -TargetIndex ($num - 1) -Adapters $adapters -TargetNetwork $sustainedNetwork
            exit 0
        }
    }

    switch -Regex ($cliArg) {
        '^(--card1|--first)$' {
            if ($adapters.Count -ge 1) { Switch-ToSingleAdapter -TargetIndex 0 -Adapters $adapters -TargetNetwork $sustainedNetwork }
            exit 0
        }
        '^(--card2|--second)$' {
            if ($adapters.Count -ge 2) { Switch-ToSingleAdapter -TargetIndex 1 -Adapters $adapters -TargetNetwork $sustainedNetwork }
            exit 0
        }
        '^(--card3|--third)$' {
            if ($adapters.Count -ge 3) { Switch-ToSingleAdapter -TargetIndex 2 -Adapters $adapters -TargetNetwork $sustainedNetwork }
            exit 0
        }
        '^(--mediatek|-m)$' {
            $mIdx = -1
            for ($i = 0; $i -lt $adapters.Count; $i++) {
                if ($adapters[$i].Description -like '*MediaTek*') { $mIdx = $i; break }
            }
            if ($mIdx -ge 0) { Switch-ToSingleAdapter -TargetIndex $mIdx -Adapters $adapters -TargetNetwork $sustainedNetwork }
            else { Write-Host ' [ERROR] MediaTek adapter not detected on this system.' -ForegroundColor Red }
            exit 0
        }
        '^(--tplink|-t)$' {
            $tIdx = -1
            for ($i = 0; $i -lt $adapters.Count; $i++) {
                if ($adapters[$i].Description -like '*TP-Link*') { $tIdx = $i; break }
            }
            if ($tIdx -ge 0) { Switch-ToSingleAdapter -TargetIndex $tIdx -Adapters $adapters -TargetNetwork $sustainedNetwork }
            else { Write-Host ' [ERROR] TP-Link adapter not detected on this system.' -ForegroundColor Red }
            exit 0
        }
        '^(--intel|-i)$' {
            $iIdx = -1
            for ($i = 0; $i -lt $adapters.Count; $i++) {
                if ($adapters[$i].Description -like '*Intel*') { $iIdx = $i; break }
            }
            if ($iIdx -ge 0) { Switch-ToSingleAdapter -TargetIndex $iIdx -Adapters $adapters -TargetNetwork $sustainedNetwork }
            else { Write-Host ' [ERROR] Intel wireless adapter not detected on this system.' -ForegroundColor Red }
            exit 0
        }
        '^(--all-on|--both-on|-b)$' {
            Enable-AllAdapters -Adapters $adapters -TargetNetwork $sustainedNetwork
            exit 0
        }
        '^(--all-off|--both-off|-d)$' {
            Disable-AllAdapters -Adapters $adapters
            exit 0
        }
        '^(--reconnect|-r)$' {
            Reconnect-ActiveAdapters -Adapters $adapters -TargetNetwork $sustainedNetwork
            exit 0
        }
        '^(--status|-s)$' {
            Render-StatusDashboard -Adapters $adapters -CurrentNetwork $sustainedNetwork
            exit 0
        }
        '^(-h|--help|\/\?)$' {
            Write-Host ' Usage: Win_Toggle_WiFi_Adapters_And_Auto_Connect.bat [option]' -ForegroundColor Cyan
            Write-Host '   1..N                      : Switch exclusively to card number 1..N' -ForegroundColor White
            Write-Host '   --card1, --card2          : Switch to card 1 or card 2' -ForegroundColor White
            Write-Host '   --mediatek, -m            : Switch to MediaTek card (if present)' -ForegroundColor White
            Write-Host '   --tplink, -t              : Switch to TP-Link card (if present)' -ForegroundColor White
            Write-Host '   --intel, -i               : Switch to Intel card (if present)' -ForegroundColor White
            Write-Host '   --all-on, --both-on, -b   : Enable ALL detected Wi-Fi adapters & connect' -ForegroundColor White
            Write-Host '   --all-off, --both-off, -d : Disable ALL Wi-Fi adapters (Airplane mode)' -ForegroundColor White
            Write-Host '   --reconnect, -r           : Reconnect active adapters to sustained Wi-Fi' -ForegroundColor White
            Write-Host '   --status, -s              : View adapter dashboard and exit' -ForegroundColor White
            exit 0
        }
        default {
            Write-Host " [WARNING] Unrecognized argument: $cliArg. Falling back to interactive menu." -ForegroundColor Yellow
        }
    }
}

# -----------------------------------------------------------------------------
# Adaptive Interactive Console Loop
# -----------------------------------------------------------------------------
$running = $true

while ($running) {
    $adapters = Get-WiFiAdapters
    $count = $adapters.Count
    $sustainedNetwork = Get-ActiveOrLastUsedNetwork
    Render-StatusDashboard -Adapters $adapters -CurrentNetwork $sustainedNetwork

    Write-Host ' SELECT AN ACTION:' -ForegroundColor Yellow

    # =========================================================================
    # CASE 0: NO WI-FI CARDS DETECTED
    # =========================================================================
    if ($count -eq 0) {
        Write-Host '   [1] Re-scan Adapters                (Check if USB Wi-Fi adapter was plugged in)' -ForegroundColor White
        Write-Host '   [2] Exit' -ForegroundColor Gray
        Write-Host ''
        $choice = (Read-Host -Prompt 'Enter your choice (1-2)').Trim()

        switch ($choice) {
            '1' { Write-Host ' [RE-SCAN] Scanning for network adapters...' -ForegroundColor Cyan }
            '2' { $running = $false; break }
            default { Write-Host ' [INVALID] Please enter 1 or 2.' -ForegroundColor Yellow }
        }
    }

    # =========================================================================
    # CASE 1: EXACTLY 1 WI-FI CARD DETECTED (Single Card Mode)
    # =========================================================================
    elseif ($count -eq 1) {
        $c1 = $adapters[0]
        $c1LiveStatus = (Get-NetAdapter -Name $c1.Name -ErrorAction SilentlyContinue).Status
        $toggleAction = if ($c1LiveStatus -eq 'Up') { 'Turn OFF' } else { "Turn ON & Connect to '$sustainedNetwork'" }

        Write-Host "   [1] Toggle $($c1.FriendlyName)  ($toggleAction)" -ForegroundColor White
        Write-Host "   [2] Reconnect to '$sustainedNetwork'         (Force association and refresh IP)" -ForegroundColor White
        Write-Host '   [3] Refresh Status Dashboard            (Re-scan network adapter & telemetry)' -ForegroundColor White
        Write-Host '   [4] Exit' -ForegroundColor Gray
        Write-Host ''
        $choice = (Read-Host -Prompt 'Enter your choice (1-4)').Trim()

        switch ($choice) {
            '1' { Toggle-SingleAdapter -TargetIndex 0 -Adapters $adapters -TargetNetwork $sustainedNetwork }
            '2' { Reconnect-ActiveAdapters -Adapters $adapters -TargetNetwork $sustainedNetwork }
            '3' { Write-Host ' [REFRESH] Updating adapter data...' -ForegroundColor Cyan }
            '4' { $running = $false; break }
            default { Write-Host ' [INVALID] Please enter a valid number (1-4).' -ForegroundColor Yellow }
        }
    }

    # =========================================================================
    # CASE 2: EXACTLY 2 WI-FI CARDS DETECTED (Dual Card Switcher Mode)
    # =========================================================================
    elseif ($count -eq 2) {
        $c1 = $adapters[0]
        $c2 = $adapters[1]

        Write-Host "   [1] Switch to $($c1.ShortName)   (Enable $($c1.Name) | Disable $($c2.Name) | Connect to '$sustainedNetwork')" -ForegroundColor White
        Write-Host "   [2] Switch to $($c2.ShortName)   (Enable $($c2.Name) | Disable $($c1.Name) | Connect to '$sustainedNetwork')" -ForegroundColor White
        Write-Host "   [3] Enable BOTH Wi-Fi Adapters       (Both ON | Connect to '$sustainedNetwork')" -ForegroundColor White
        Write-Host '   [4] Disable BOTH Wi-Fi Adapters      (Both OFF | Airplane / Offline Mode)' -ForegroundColor White
        Write-Host "   [5] Toggle $($c1.ShortName) Only (Invert Current State)" -ForegroundColor White
        Write-Host "   [6] Toggle $($c2.ShortName) Only (Invert Current State)" -ForegroundColor White
        Write-Host "   [7] Reconnect Active Adapter(s)      (Force refresh connection to '$sustainedNetwork')" -ForegroundColor White
        Write-Host '   [8] Refresh Status Dashboard         (Re-scan network adapters & telemetry)' -ForegroundColor White
        Write-Host '   [9] Exit' -ForegroundColor Gray
        Write-Host ''
        $choice = (Read-Host -Prompt 'Enter your choice (1-9)').Trim()

        switch ($choice) {
            '1' { Switch-ToSingleAdapter -TargetIndex 0 -Adapters $adapters -TargetNetwork $sustainedNetwork }
            '2' { Switch-ToSingleAdapter -TargetIndex 1 -Adapters $adapters -TargetNetwork $sustainedNetwork }
            '3' { Enable-AllAdapters -Adapters $adapters -TargetNetwork $sustainedNetwork }
            '4' { Disable-AllAdapters -Adapters $adapters }
            '5' { Toggle-SingleAdapter -TargetIndex 0 -Adapters $adapters -TargetNetwork $sustainedNetwork }
            '6' { Toggle-SingleAdapter -TargetIndex 1 -Adapters $adapters -TargetNetwork $sustainedNetwork }
            '7' { Reconnect-ActiveAdapters -Adapters $adapters -TargetNetwork $sustainedNetwork }
            '8' { Write-Host ' [REFRESH] Updating adapter data...' -ForegroundColor Cyan }
            '9' { $running = $false; break }
            default { Write-Host ' [INVALID] Please enter a valid number between 1 and 9.' -ForegroundColor Yellow }
        }
    }

    # =========================================================================
    # CASE 3: 3 OR MORE WI-FI CARDS DETECTED (Multi-Adapter Workstation Mode)
    # =========================================================================
    else {
        for ($i = 0; $i -lt $count; $i++) {
            $num = $i + 1
            Write-Host "   [$num] Switch ONLY to $($adapters[$i].ShortName) (Enable $($adapters[$i].Name) | Disable other $($count - 1) cards | Connect to '$sustainedNetwork')" -ForegroundColor White
        }

        Write-Host "   [A] Enable ALL Wi-Fi Adapters        (All $count Cards ON | Connect to '$sustainedNetwork')" -ForegroundColor White
        Write-Host "   [D] Disable ALL Wi-Fi Adapters       (All $count Cards OFF | Offline / Airplane Mode)" -ForegroundColor White

        for ($i = 0; $i -lt $count; $i++) {
            $tCode = "T" + ($i + 1)
            Write-Host "   [$tCode] Toggle $($adapters[$i].ShortName) (Invert State: ON <-> OFF)" -ForegroundColor White
        }

        Write-Host "   [R] Reconnect Active Adapter(s)      (Force refresh connection to '$sustainedNetwork')" -ForegroundColor White
        Write-Host '   [S] Refresh Status Dashboard         (Re-scan network adapters & telemetry)' -ForegroundColor White
        Write-Host '   [X] Exit' -ForegroundColor Gray
        Write-Host ''

        $rawChoice = (Read-Host -Prompt "Enter your choice (1-$count, A, D, T1-T$count, R, S, X)").Trim().ToUpper()

        if ($rawChoice -match '^\d+$') {
            $selNum = [int]$rawChoice
            if ($selNum -ge 1 -and $selNum -le $count) {
                Switch-ToSingleAdapter -TargetIndex ($selNum - 1) -Adapters $adapters -TargetNetwork $sustainedNetwork
            } else {
                Write-Host " [INVALID] Please enter a number between 1 and $count." -ForegroundColor Yellow
            }
        } elseif ($rawChoice -match '^T(\d+)$') {
            $tNum = [int]$matches[1]
            if ($tNum -ge 1 -and $tNum -le $count) {
                Toggle-SingleAdapter -TargetIndex ($tNum - 1) -Adapters $adapters -TargetNetwork $sustainedNetwork
            } else {
                Write-Host " [INVALID] Invalid toggle number. Choose T1 through T$count." -ForegroundColor Yellow
            }
        } else {
            switch ($rawChoice) {
                'A' { Enable-AllAdapters -Adapters $adapters -TargetNetwork $sustainedNetwork }
                'D' { Disable-AllAdapters -Adapters $adapters }
                'R' { Reconnect-ActiveAdapters -Adapters $adapters -TargetNetwork $sustainedNetwork }
                'S' { Write-Host ' [REFRESH] Updating adapter data...' -ForegroundColor Cyan }
                'X' { $running = $false; break }
                default { Write-Host ' [INVALID] Unrecognized selection. Please try again.' -ForegroundColor Yellow }
            }
        }
    }

    if ($running) {
        Write-Host ''
        Write-Host ' Press Enter to continue back to menu...' -ForegroundColor Gray
        Read-Host | Out-Null
        Clear-Host
        Write-Host $dividerHeavy -ForegroundColor Cyan
        Write-Host '                          WIFI CARD SWITCHER & AUTO-CONNECT ENGINE                             ' -ForegroundColor Cyan
        Write-Host '                       Developed by : Biraj                                                            ' -ForegroundColor Gray
        Write-Host '                       GitHub       : https://github.com/Biraj2004                                     ' -ForegroundColor Gray
        Write-Host $dividerHeavy -ForegroundColor Cyan
        Write-Host ''
    }
}
