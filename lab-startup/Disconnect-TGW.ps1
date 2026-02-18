# --- 1. CONFIGURATION ---
$nsxManager = "nsx-mgmt-a.site-a.vcf.lab"
$user       = "admin"

# --- 2. SECURE LOGIN ---
Write-Host "--- NSX 9 Transit Gateway Disconnect Tool ---" -ForegroundColor Cyan
# This will prompt the user and hide the characters as they type
$passwordPlain = Read-Host -Prompt "Please enter the password for $user"

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

# Create Auth Header using the password provided by the user
$authHeader = @{
    "Authorization" = "Basic " + [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes("${user}:${passwordPlain}"))
    "Content-Type"  = "application/json"
}

# --- 4. FETCH AND DISCONNECT ---
$baseUrl = "https://$nsxManager/policy/api/v1/orgs/default/projects/default/transit-gateways/default/attachments"

try {
    Write-Host "`nConnecting to NSX Manager..." -ForegroundColor White
    $response = Invoke-RestMethod -Uri $baseUrl -Method Get -Headers $authHeader
    
    if ($response.results.Count -eq 0) {
        Write-Host "No connections found to disconnect." -ForegroundColor Yellow
    }
    else {
        # Loop through all attachments and remove them one by one (Batch Mode)
        foreach ($attachment in $response.results) {
            $id = $attachment.id
            $name = $attachment.display_name
            
            Write-Host "Disconnecting: $name..." -ForegroundColor Cyan
            $deleteUrl = "$baseUrl/$id"
            Invoke-RestMethod -Uri $deleteUrl -Method Delete -Headers $authHeader
            Write-Host "Successfully removed $name." -ForegroundColor Green
        }
    }
}
catch {
    Write-Host "`nERROR: Authentication failed or connection refused." -ForegroundColor Red
    Write-Host "Check your password and NSX Manager IP ($nsxManager)." -ForegroundColor Gray
}

# Keep window open for the user
Write-Host "`nTask Complete." -ForegroundColor White
Read-Host -Prompt "Press Enter to close this window"
