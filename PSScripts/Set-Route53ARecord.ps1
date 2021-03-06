[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)]
    [ValidatePattern("[/w.]*\.$")]
    [String]$DomainName,
    [Parameter(Mandatory=$true, ParameterSetName="CName")]
    [String]$CNameRecordName,
    [Parameter(Mandatory=$true, ParameterSetName="CName")]
    [String]$CNameRecordValue,
    [Parameter(Mandatory=$true, ParameterSetName="ARecord")]
    [AllowEmptyString()]
    [String]$HostName,
    [Parameter(Mandatory=$true, ParameterSetName="ARecord")]
    [ipaddress]$IpAddress,
    [Parameter(Mandatory=$false)]
    [int]$TTL = 300
)

$HostedZone = Get-R53Hostedzones | Where-Object {$_.Name -eq $DomainName}

if ($PSCmdlet.ParameterSetName -eq "ARecord") {

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
elseif ($PSCmdlet.ParameterSetName -eq "CName") {

    $RecordSetName = "$CNameRecordName.$DomainName"
    $RecordSetValue = $CNameRecordValue
    $RecordSetType = "CNAME"

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
$Change.ResourceRecordSet.ResourceRecords.Add(@{Value=$RecordSetValue})

$Params = @{
    HostedZoneId=$HostedZone.Id
    ChangeBatch_Comment="This change batch updates the $RecordSetType record for $RecordSetName to $RecordSetValue"
    ChangeBatch_Change=$Change
}

$Params

try {

    Edit-R53ResourceRecordSet @Params

}
catch {

    throw "Error editing Route53 record with params:`n$($Params.Values -join ' ')`n$_"

}