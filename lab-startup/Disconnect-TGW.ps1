# --- 1. CONFIGURATION ---
$nsxManager = "YOUR_NSX_IP"
$user       = "admin"
$credsPath  = "/home/holuser/creds.txt"

# --- 2. AUTOMATED CREDENTIAL RETRIEVAL (STRICT SCRUB) ---
if (Test-Path $credsPath) {
    # -Encoding utf8 handles the BOM; -Raw treats the file as one string
    $rawContent = Get-Content -Path $credsPath -Raw -Encoding utf8
    
    # Regex '\S+' matches only the first block of non-whitespace characters
    # This effectively deletes the '10' (Line Feed) and any trailing spaces
    if ($rawContent -match '(\S+)') {
        $passwordPlain = $matches[1]
    } else {
        Write-Host "ERROR: Credential file is empty or contains only whitespace." -ForegroundColor Red
        exit
    }
}
else {
    Write-Host "ERROR: Credential file not found at $credsPath" -ForegroundColor Red
    exit
}

# --- 3. PREPARE AUTH ---
# Convert to UTF8 bytes (standard for NSX 9) and encode to Base64
$pair = "${user}:${passwordPlain}"
$bytes = [System.Text.Encoding]::UTF8.GetBytes($pair)
$base64 = [Convert]::ToBase64String($bytes)

$authHeader = @{
    "Authorization" = "Basic $base64"
    "Content-Type"  = "application/json"
}

# Create Auth Header using the retrieved password
$authHeader = @{
    "Authorization" = "Basic " + [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes("${user}:${passwordPlain}"))
    "Content-Type"  = "application/json"
}

# --- 4. EXECUTION ---
$baseUrl = "https://$nsxManager/policy/api/v1/orgs/default/projects/default/transit-gateways/default/attachments"

try {
    Write-Host "Connecting to NSX Manager..." -ForegroundColor Cyan
    $response = Invoke-RestMethod -Uri $baseUrl -Method Get -Headers $authHeader -SkipCertificateCheck -NoProxy
    
    if ($response.results.Count -eq 0) {
        Write-Host "No active attachments found to disconnect from TGW." -ForegroundColor Yellow
    }
    else {
        foreach ($attachment in $response.results) {
            $id = $attachment.id
            $name = $attachment.display_name
            
            Write-Host "Disconnecting: $name (ID: $id) from TGW" -ForegroundColor White
            $deleteUrl = "$baseUrl/$id"
            Invoke-RestMethod -Uri $deleteUrl -Method Delete -Headers $authHeader -SkipCertificateCheck -NoProxy
            Write-Host "Successfully removed $name." -ForegroundColor Green
        }
    }
}
catch {
    Write-Host "`nERROR: API Call failed." -ForegroundColor Red
    Write-Host "Check the credentials in $credsPath and ensure NSX Manager is reachable." -ForegroundColor Gray
}

Write-Host "`nTask Complete." -ForegroundColor White
Read-Host -Prompt "Press Enter to close"
