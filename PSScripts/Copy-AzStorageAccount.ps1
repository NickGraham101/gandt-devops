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

Begin {
    function Get-AzStorageFilesRecursively {
        param(
            [Parameter(Mandatory=$true)]
            [String]$ObjectName,
            [Parameter(Mandatory=$true)]
            [String]$ShareName,
            [Parameter(Mandatory=$true)]
            [String]$SourceAccountName,
            [Parameter(Mandatory=$true)]
            [String]$SourceAccountKey
        )
    
        $SourceContext = New-AzStorageContext -StorageAccountName $SourceAccountName -StorageAccountKey $SourceAccountKey
        $SourceStorageFiles = Get-AzStorageFile -Path $ObjectName -ShareName $SourceFileShare.Name -Context $SourceContext | Get-AzStorageFile
        foreach ($Object in $SourceStorageFiles) {
            if ($Object.GetType().Name -eq "AzureStorageFileDirectory") {
                Write-Verbose "Getting files from directory $($SourceFileShare.Name)"
                Get-AzStorageFilesRecursively -ObjectName $Object.ShareDirectoryClient.Path -ShareName $SourceFileShare.Name -SourceAccountName $SourceAccountName -SourceAccountKey $SourceAccountKey
            }
            else {
                Write-Verbose "Found file $($Object.Name)"
                $Object
            }
        }
    }
}

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

    ##TO DO: check for destination account, ?create if doesn't exist

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
    $SourceFileshares = Get-AzStorageShare -Context $SourceContext
    Write-Output "Retrieved $($SourceFileshares.Count) fileshares"
    foreach ($SourceFileshare in $SourceFileshares | Where-Object { !$_.IsSnapshot }) {
        $SourceFileshareFiles = @() 
        $SourceFileshareRoot = Get-AzStorageFile -ShareName $SourceFileshare.Name -Context $SourceContext
        $SourceFileshareFiles += $SourceFileShareRoot | Where-Object { $_.GetType().Name -ne "AzureStorageFileDirectory" }
        foreach ($Directory in $SourceFileShareRoot | Where-Object { $_.GetType().Name -eq "AzureStorageFileDirectory" }) {
            $SourceFileshareFiles += Get-AzStorageFilesRecursively -ObjectName $Directory.Name -ShareName $SourceFileshare.Name -SourceAccountName $SourceAccountName -SourceAccountKey $SourceAccountKey
        }
        Write-Output "Retrieved $($SourceFileshareFiles.Count) files from $($SourceFileshare.Name) fileshare"
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
