##TO DO: rename this command and update all usage"
[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)]
    [ValidatePattern("[/w.]*\.$")]
    [String]$DomainName,
    [Parameter(Mandatory=$true, ParameterSetName="CName")]
    [Parameter(Mandatory=$true, ParameterSetName="CNameAwsCredentials")]
    [String]$CNameRecordName,
    [Parameter(Mandatory=$true, ParameterSetName="CName")]
    [Parameter(Mandatory=$true, ParameterSetName="CNameAwsCredentials")]
    [String]$CNameRecordValue,
    [Parameter(Mandatory=$true, ParameterSetName="ARecord")]
    [Parameter(Mandatory=$true, ParameterSetName="ARecordAwsCredentials")]
    [AllowEmptyString()]
    [String]$HostName,
    [Parameter(Mandatory=$true, ParameterSetName="ARecord")]
    [Parameter(Mandatory=$true, ParameterSetName="ARecordAwsCredentials")]
    [ipaddress]$IpAddress,
    [Parameter(Mandatory=$true, ParameterSetName="TxtRecord")]
    [Parameter(Mandatory=$true, ParameterSetName="TxtRecordAwsCredentials")]
    [AllowEmptyString()]
    [String]$TxtRecordName,
    [Parameter(Mandatory=$true, ParameterSetName="TxtRecord")]
    [Parameter(Mandatory=$true, ParameterSetName="TxtRecordAwsCredentials")]
    [String]$TxtRecordValue,
    [Parameter(Mandatory=$true, ParameterSetName="ARecordAwsCredentials")]
    [Parameter(Mandatory=$true, ParameterSetName="CNameAwsCredentials")]
    [Parameter(Mandatory=$true, ParameterSetName="TxtRecordAwsCredentials")]
    [string]$AwsAccessKey,
    [Parameter(Mandatory=$true, ParameterSetName="ARecordAwsCredentials")]
    [Parameter(Mandatory=$true, ParameterSetName="CNameAwsCredentials")]
    [Parameter(Mandatory=$true, ParameterSetName="TxtRecordAwsCredentials")]
    [string]$AwsSecretKey,
    [Parameter(Mandatory=$false)]
    [ValidateSet("AWSPowerShell", "AWSPowerShell.NetCore")]
    [string]$AwsPowerShellVersion = "AWSPowerShell.NetCore",
    [Parameter(Mandatory=$false)]
    [int]$TTL = 300

)

Import-Module $AwsPowerShellVersion

if ($PSCmdlet.ParameterSetName -match ".*AwsCredentials$") {
    Set-AwsCredential -Scope Script -AccessKey $AwsAccessKey -SecretKey $AwsSecretKey
}

$HostedZone = Get-R53Hostedzones | Where-Object {$_.Name -eq $DomainName}

if ($PSCmdlet.ParameterSetName -match "^ARecord.*") {

    if ($HostName -eq "") {

        Write-Verbose "Creating record set for root record"
        $RecordSetName = "$DomainName"

    }
    else {

        Write-Verbose "Creating record set for host $HostName record"
        $RecordSetName = "$HostName.$DomainName"

    }

    $RecordSetValue = $IpAddress
    $RecordSetType = "A"

}
elseif ($PSCmdlet.ParameterSetName -match "^CName.*") {

    $RecordSetName = "$CNameRecordName.$DomainName"
    $RecordSetValue = $CNameRecordValue
    $RecordSetType = "CNAME"

}
elseif ($PSCmdlet.ParameterSetName -match "^TxtRecord.*") {

    if ($TxtRecordName -eq "") {

        Write-Verbose "Creating record set for root record"
        $RecordSetName = "$DomainName"

    }
    else {

        Write-Verbose "Creating record set for host $TxtRecordName record"
        $RecordSetName = "$TxtRecordName.$DomainName"

    }
    $RecordSetValue = $TxtRecordValue | ConvertTo-Json
    $RecordSetType = "TXT"

}
else {

    throw "ParameterSetName $($PSCmdlet.ParameterSetName) is an invalid ParameterSetName"

}

# Create DNS record change object
$Change = New-Object Amazon.Route53.Model.Change
$Change.Action = "UPSERT"
$Change.ResourceRecordSet = New-Object Amazon.Route53.Model.ResourceRecordSet
$Change.ResourceRecordSet.Name = $RecordSetName
$Change.ResourceRecordSet.Type = $RecordSetType
$Change.ResourceRecordSet.TTL = $TTL
$Change.ResourceRecordSet.ResourceRecords = @()
$Change.ResourceRecordSet.ResourceRecords.Add(@{Value=$RecordSetValue})

$ChangeComment = "This change batch updates the $RecordSetType record for $RecordSetName to $RecordSetValue"
if ($ChangeComment.Length -gt 256) {
    $ChangeComment = "$($ChangeComment.Substring(0,253))..."
}

$Params = @{
    HostedZoneId=$HostedZone.Id
    ChangeBatch_Comment=$ChangeComment
    ChangeBatch_Change=$Change
}

Write-Verbose "Params:`n$($Params | Out-String)"

try {

    Edit-R53ResourceRecordSet @Params

}
catch {

    throw "Error editing Route53 record with params:`n$($Params.Values -join ' ')`n$_"

}
