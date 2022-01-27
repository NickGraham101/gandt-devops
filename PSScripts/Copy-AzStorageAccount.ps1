[CmdletBinding(DefaultParameterSetName="None")]
param(
    [Parameter(Mandatory=$true, ParameterSetName="SourceObject", ValueFromPipeline)]
    [object[]]$SourceAccount,
    [Parameter(Mandatory=$true, ParameterSetName="SourceName")]
    [String]$SourceAccountName,
    [Parameter(Mandatory=$false, ParameterSetName="SourceName")]
    [Parameter(Mandatory=$true, ParameterSetName="SourceKey")]
    [String]$SourceAccountKey,
    [Parameter(Mandatory=$true, ParameterSetName="SourceName")]
    [String]$SourceAccountResourceGroup
)

Process {
    # get storage account context
    if ($PSCmdlet.ParameterSetName -eq "SourceObject") {
        Write-Output "Process storage account $($SourceAccount.StorageAccountName)"
        $SourceAccountName = $SourceAccount.StorageAccountName
        $SourceAccountResourceGroup = $SourceAccount.ResourceGroupName
    }
    else {
        Write-Output "Process storage account $SourceAccountName"
        $SourceAccount = Get-AzStorageAccount -Name $SourceAccountName -ResourceGroupName $SourceAccountResourceGroup -Verbose
    }

    if (@("Storage", "StorageV2") -notcontains $SourceAccount.Kind) {
        Write-Warning "Only supports Storage and StorageV2 account types, skipping $SourceAccountName of type $($SourceAccount.Kind)"
        return
    }

    if ($PSCmdlet.ParameterSetName -ne "SourceKey" -or $PSCmdlet.ParameterSetName -eq "SourceObject") {
        $SourceAccountKey = ((Get-AzStorageAccountKey -AccountName $SourceAccountName -ResourceGroupName $SourceAccountResourceGroup) | Where-Object {$_.KeyName -eq "key1"}).Value
    }
    $SourceContext = New-AzStorageContext -StorageAccountName $SourceAccountName -StorageAccountKey $SourceAccountKey

    # get containers
    $SourceContainers = Get-AzStorageContainer -Context $SourceContext
    Write-Output "Retrieved $($SourceContainers.Count) containers"
    foreach ($SourceContainer in $SourceContainers) {
        ##TO DO: implement copy containers
    }

    # get fileshares
    $SourceFileShares = Get-AzStorageShare -Context $SourceContext
    Write-Output "Retrieved $($SourceFileShares.Count) fileshares"
    foreach ($SourceFileShare in $SourceFileShares) {
        ##TO DO: implement copy fileshares
    }

    # get tables
    $SourceTables = Get-AzStorageTable -Context $SourceContext
    Write-Output "Retrieved $($SourceTables.Count) tables"
    foreach ($SourceTable in $SourceTables) {
        throw "Copy tables not implemented"
    }

    # get queues
    $SourceQueues = Get-AzStorageQueue -Context $SourceContext
    Write-Output "Retrieved $($SourceQueues.Count) queues"
    foreach ($SourceQueue in $SourceQueues) {
        throw "Copy queues not implemented"
    }
}
