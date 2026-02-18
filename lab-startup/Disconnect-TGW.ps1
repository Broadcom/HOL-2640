# --- 1. CONFIGURATION ---
$nsxManager = "YOUR_NSX_IP"
$user       = "admin"
$credsPath  = "/home/holuser/creds.txt"

# --- 2. AUTOMATED CREDENTIAL RETRIEVAL ---
if (Test-Path $credsPath) {
    # Read the first line and trim any accidental whitespace/newlines
    $passwordPlain = (Get-Content -Path $credsPath -TotalCount 1).Trim()
}
else {
    Write-Host "ERROR: Credential file not found at $credsPath" -ForegroundColor Red
    Read-Host -Prompt "Press Enter to exit"
    exit
}

# --- 3. PREPARE ENVIRONMENT ---
# Bypass SSL certificate warnings
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
add-type @"
    using System.Net;
    using System.Security.Cryptography.X509Certificates;
    public class TrustAllCertsPolicy : ICertificatePolicy {
        public bool CheckValidationResult(ServicePoint srvPoint, X509Certificate certificate, WebRequest request, int certificateProblem) {
            return true;
        }
    }
"@
[Net.ServicePointManager]::CertificatePolicy = New-Object TrustAllCertsPolicy

# Create Auth Header using the retrieved password
$authHeader = @{
    "Authorization" = "Basic " + [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes("${user}:${passwordPlain}"))
    "Content-Type"  = "application/json"
}

# --- 4. FETCH AND DISCONNECT ---
$baseUrl = "https://$nsxManager/policy/api/v1/orgs/default/projects/default/transit-gateways/default/attachments"

try {
    Write-Host "Connecting to NSX Manager..." -ForegroundColor Cyan
    $response = Invoke-RestMethod -Uri $baseUrl -Method Get -Headers $authHeader
    
    if ($response.results.Count -eq 0) {
        Write-Host "No active attachments found to disconnect." -ForegroundColor Yellow
    }
    else {
        foreach ($attachment in $response.results) {
            $id = $attachment.id
            $name = $attachment.display_name
            
            Write-Host "Disconnecting: $name (ID: $id)..." -ForegroundColor White
            $deleteUrl = "$baseUrl/$id"
            Invoke-RestMethod -Uri $deleteUrl -Method Delete -Headers $authHeader
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
