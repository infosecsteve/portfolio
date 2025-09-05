# Login to Azure
Connect-AzAccount

# Optional: Set the subscription context
# Set-AzContext -SubscriptionId "<your-subscription-id>"

# Get all App Registrations
$applications = Get-AzADApplication

# Set threshold (e.g., show credentials expiring in the next 30 days)
$thresholdDate = (Get-Date).AddDays(30)
$now = Get-Date

# Create a list to hold results
$results = @()

foreach ($app in $applications) {
    $appId = $app.AppId
    $displayName = $app.DisplayName

    # Check Password Credentials (client secrets)
    foreach ($secret in $app.PasswordCredentials) {
        if ($secret.EndDateTime -lt $now -or $secret.EndDateTime -lt $thresholdDate) {
            $status = if ($secret.EndDateTime -lt $now) { "Expired" } else { "Expiring Soon" }
            $results += [PSCustomObject]@{
                AppName       = $displayName
                AppId         = $appId
                CredentialType = "Client Secret"
                EndDate       = $secret.EndDateTime
                Status        = $status
            }
        }
    }

    # Check Key Credentials (certificates)
    foreach ($cert in $app.KeyCredentials) {
        if ($cert.EndDateTime -lt $now -or $cert.EndDateTime -lt $thresholdDate) {
            $status = if ($cert.EndDateTime -lt $now) { "Expired" } else { "Expiring Soon" }
            $results += [PSCustomObject]@{
                AppName       = $displayName
                AppId         = $appId
                CredentialType = "Certificate"
                EndDate       = $cert.EndDateTime
                Status        = $status
            }
        }
    }
}

# Export to CSV
$results | Sort-Object EndDate | Export-Csv -Path $exportPath -NoTypeInformation -Encoding UTF8

Write-Host "✅ Export complete: $exportPath"
