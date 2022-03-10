[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingConvertToSecureStringWithPlainText', '', Justification='Required for Set-AzKeyVaultSecret')]
[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)]
    [Object[]]$Secrets,
    [Parameter(Mandatory=$true)]
    [String]$DestinationKeyVaultName
)

class KeyVaultSecret {
    [String]$SecretName
    [String]$SecretValue
}

$InformationPreference = "Continue"

##TO DO: validate input
# try {
#     $Secrets = [KeyVaultSecret[]]$Secrets
# }
# catch {
#     throw "Invalid object type for secrets"
# }

$DestinationKeyVault = Get-AzKeyVault -VaultName $DestinationKeyVaultName -ErrorAction SilentlyContinue
if ($DestinationKeyVault) {
    foreach ($Secret in $Secrets) {
        Write-Information -MessageData "Importing $($Secret.SecretName) in $($DestinationKeyVault.VaultName)"
        $SecureString = $Secret.SecretValue | ConvertTo-SecureString -AsPlainText -Force
        Set-AzKeyVaultSecret  -VaultName $DestinationKeyVault.VaultName -Name $Secret.SecretName -SecretValue $SecureString | Out-Null
        Remove-Variable SecureString
    }
}
else {
    throw "Key Vault $DestinationKeyVaultName doesn't exist"
}
