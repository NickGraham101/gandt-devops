<#
.SYNOPSIS
Copies secrets from a Key Vault into a temporary KeyVault.  Returns the secret names and current values as an object.

.DESCRIPTION
This script is intended to be used with Import-KeyVaultSecrets to copy a KeyVault from one subscription to another (including in a different tenant).  It backups up the secrets 
from the source Key Vault to a staging Key Vault then returns the name and current value of each secret in an object.  This can be consumed by Import-KeyVaultSecrets which will
write the secrets to a replacement Key Vault in a different subscription.

This script was designed for working with a hobby project.  Before using it in a production environment you should evaluate whether it meets your security requirements.
#>
[CmdletBinding(DefaultParameterSetName="None")]
param(
    [Parameter(Mandatory=$true, ParameterSetName="StagingKeyvVault")]
    [String]$LocalBackupFolderPath,
    [Parameter(Mandatory=$true)]
    [String]$SourceKeyVaultName,
    [Parameter(Mandatory=$true, ParameterSetName="StagingKeyvVault")]
    [String]$StagingKeyVaultName,
    [Parameter(Mandatory=$false, ParameterSetName="StagingKeyvVault")]
    [Switch]$OverwriteStagingKeyVaultSecrets
)

class KeyVaultSecret {
    [String]$SecretName
    [String]$SecretValue
}

$InformationPreference = "Continue"

$SourceKeyVault = Get-AzKeyVault -VaultName $SourceKeyVaultName
if ($StagingKeyVaultName) {
    $StagingKeyVault = Get-AzKeyVault -VaultName $StagingKeyVaultName -ErrorAction SilentlyContinue
    if (!$StagingKeyVault) {
        Write-Information -MessageData "Staging Key Vault $StagingKeyVaultName doesn't exist, creating in resource group $($SourceKeyVault.ResourceGroupName)"
        $StagingKeyVault = New-AzKeyVault -Name $StagingKeyVaultName -ResourceGroupName $SourceKeyVault.ResourceGroupName -Location $SourceKeyVault.Location
    }
}

$Secrets = Get-AzKeyVaultSecret -VaultName $SourceKeyVaultName
$SecretValues = @()

foreach ($Secret in $Secrets) {
    if ($StagingKeyVaultName) {
        # backup and restore key vault secrets to temp key vault in same subscription
        $SecretBackup = Backup-AzKeyVaultSecret -VaultName $SourceKeyVault.VaultName -Name $Secret.Name -OutputFile "$LocalBackupFolderPath\$($Secret.Name).blob" -Force
        $StagingKeyVaultSecretParams = @{
            Name = $Secret.Name
            VaultName = $StagingKeyVault.VaultName
        }
        $BackupDestination = Get-AzKeyVaultSecret @StagingKeyVaultSecretParams -ErrorAction SilentlyContinue
        if ($BackupDestination) {
            Write-Warning "Secret $($Secret.Name) already exists in Key Vault $($StagingKeyVault.VaultName)"
            if ($OverwriteStagingKeyVaultSecrets.IsPresent) {
                Remove-AzKeyVaultSecret @StagingKeyVaultSecretParams -Force
                ##TO DO: implement while loops to confirm secret has been deleted / purged
                Start-Sleep -Seconds 5
                Remove-AzKeyVaultSecret @StagingKeyVaultSecretParams -Force -InRemovedState
                Start-Sleep -Seconds 5
            }
            else {
                Write-Output "OverwriteStagingKeyVaultSecrets not set, skipping"
                continue
            }
        }
        Write-Information -MessageData "Restoring secret $($Secret.Name) to staging Key Vault $($StagingKeyVault.VaultName)"
        Restore-AzKeyVaultSecret -VaultName $StagingKeyVault.VaultName -InputFile $SecretBackup | Out-Null
        Remove-Item -Path $SecretBackup
    }

    # return secret names and values as an object
    $SecretValue = Get-AzKeyVaultSecret -VaultName $Secret.VaultName -Name $Secret.Name -AsPlainText
    $SecretValues += New-Object -TypeName KeyVaultSecret -Property @{ SecretName = $Secret.Name; SecretValue = $SecretValue }
}

$SecretValues
