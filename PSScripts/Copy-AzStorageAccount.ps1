<#
.SYNOPSIS
Copies data from one storage account to another

.DESCRIPTION
Copies data from one storage account to another.
Accepts either the name of a single source and destination account or a collection of account objects.  Where a collection is passed in new storage accounts will 
be created in the same resource group with a supplied suffix.
#>
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
    [String]$SourceAccountResourceGroup,
    [Parameter(Mandatory=$true, ParameterSetName="SourceObject")]
    [String]$DestinationAccountNameSuffix,
    [Parameter(Mandatory=$true, ParameterSetName="SourceName")]
    [String]$DestinationAccountName,
    [Parameter(Mandatory=$false, ParameterSetName="SourceName")]
    [Parameter(Mandatory=$true, ParameterSetName="SourceKey")]
    [String]$DestinationAccountKey,
    [Parameter(Mandatory=$true, ParameterSetName="SourceName")]
    [String]$DestinationAccountResourceGroup
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
    # get source storage account context
    if ($PSCmdlet.ParameterSetName -eq "SourceObject") {
        Write-Output "Copying storage account $($SourceAccount.StorageAccountName)"
        $SourceAccountName = $SourceAccount.StorageAccountName
        $SourceAccountResourceGroup = $SourceAccount.ResourceGroupName
    }
    else {
        Write-Output "Copying storage account $SourceAccountName"
        $SourceAccount = Get-AzStorageAccount -Name $SourceAccountName -ResourceGroupName $SourceAccountResourceGroup
    }

    if ($SourceAccount -and @("Storage", "StorageV2") -notcontains $SourceAccount.Kind) {
        Write-Warning "Only supports Storage and StorageV2 account types, skipping $SourceAccountName of type $($SourceAccount.Kind)"
        return
    }

    if ($PSCmdlet.ParameterSetName -ne "SourceKey" -or $PSCmdlet.ParameterSetName -eq "SourceObject") {
        $SourceAccountKey = ((Get-AzStorageAccountKey -AccountName $SourceAccountName -ResourceGroupName $SourceAccountResourceGroup) | Where-Object {$_.KeyName -eq "key1"}).Value
    }
    $SourceContext = New-AzStorageContext -StorageAccountName $SourceAccountName -StorageAccountKey $SourceAccountKey

    # get destination storage account context
    if ($PSCmdlet.ParameterSetName -eq "SourceObject") {
        $DestinationAccountName = "$SourceAccountName$DestinationAccountNameSuffix"
        $DestinationAccountResourceGroup = $SourceAccountResourceGroup
    }
    $DestinationAccount = Get-AzStorageAccount -Name $DestinationAccountName -ResourceGroupName $DestinationAccountResourceGroup -ErrorAction SilentlyContinue
    if (!$DestinationAccount) {
        Write-Output "Destination account $DestinationAccountName not found, creating"
        $DestinationResourceGroupObject = Get-AzResourceGroup -Name $DestinationAccountResourceGroup
        $DestinationAccount = New-AzStorageAccount -SkuName Standard_LRS -Name $DestinationAccountName -ResourceGroupName $DestinationAccountResourceGroup -Location $DestinationResourceGroupObject.Location
        ##TO DO: handle error if unable to create new account
    }

    if ($PSCmdlet.ParameterSetName -ne "SourceKey" -or $PSCmdlet.ParameterSetName -eq "SourceObject") {
        $DestinationAccountKey = ((Get-AzStorageAccountKey -AccountName $DestinationAccountName -ResourceGroupName $DestinationAccountResourceGroup) | Where-Object {$_.KeyName -eq "key1"}).Value
    }
    $DestinationContext = New-AzStorageContext -StorageAccountName $DestinationAccountName -StorageAccountKey $DestinationAccountKey

    # get containers
    $SourceContainers = Get-AzStorageContainer -Context $SourceContext
    Write-Output "Retrieved $($SourceContainers.Count) containers"
    foreach ($SourceContainer in $SourceContainers) {
        ##TO DO: implement copy containers
    }

    # get fileshares and files, copy files
    $SourceFileshares = Get-AzStorageShare -Context $SourceContext
    Write-Output "Retrieved $($SourceFileshares.Count) fileshares"
    foreach ($SourceFileshare in $SourceFileshares | Where-Object { !$_.IsSnapshot }) {
        $DestinationFileshare = Get-AzStorageShare -Context $DestinationContext -Name $SourceFileshare.Name -ErrorAction SilentlyContinue
        if (!$DestinationFileshare) {
            Write-Output "Destination fileshare $($SourceFileshare.Name) doesn't exist, creating ..."
            $DestinationFileshare = New-AzStorageShare -Context $DestinationContext -Name $SourceFileshare.Name
        }
        
        $SourceFileshareFiles = @() 
        $SourceFileshareRoot = Get-AzStorageFile -ShareName $SourceFileshare.Name -Context $SourceContext
        $SourceFileshareFiles += $SourceFileShareRoot | Where-Object { $_.GetType().Name -ne "AzureStorageFileDirectory" }
        foreach ($Directory in $SourceFileShareRoot | Where-Object { $_.GetType().Name -eq "AzureStorageFileDirectory" }) {
            $SourceFileshareFiles += Get-AzStorageFilesRecursively -ObjectName $Directory.Name -ShareName $SourceFileshare.Name -SourceAccountName $SourceAccountName -SourceAccountKey $SourceAccountKey
        }
        Write-Output "Retrieved $($SourceFileshareFiles.Count) files from $($SourceFileshare.Name) fileshare, starting copy $(Get-Date -Format HH:mm:ss)"
        for ($f = 0; $f -lt $SourceFileshareFiles.Count; $f++) {
            $SubDirectories = $SourceFileshareFiles[$f].ShareFileClient.Path -split "/"
            for ($d = 0; $d -lt ($SubDirectories.Count - 1); $d++) {
                $Directory = Get-AzStorageFile -Path ($SubDirectories[0..$d] -join "/") -ShareName $DestinationFileshare.Name -Context $DestinationContext -ErrorAction SilentlyContinue
                if (!$Directory) {
                    Write-Output "Destination directory $($SubDirectories[0..$d] -join "/") doesn't exist, creating ..."
                    New-AzStorageDirectory -Path ($SubDirectories[0..$d] -join "/") -ShareName $DestinationFileshare.Name -Context $DestinationContext | Out-Null
                }
            }
            $FileCopyParams = @{
                SrcFilePath = $SourceFileshareFiles[$f].ShareFileClient.Path
                SrcShareName = $SourceFileshareFiles[$f].ShareFileClient.ShareName
                DestFilePath = $SourceFileshareFiles[$f].ShareFileClient.Path
                DestShareName = $DestinationFileshare.Name
                Context = $SourceContext
                DestContext = $DestinationContext
                ConcurrentTaskCount = 10 #this is the default value
                Force = $true
            }
            Start-AzStorageFileCopy @FileCopyParams | Out-Null
            Write-Progress -PercentComplete (($f/$SourceFileshareFiles.Count)*100) -Activity "Copying files"
        }
        Write-Output "Copy complete $(Get-Date -Format HH:mm:ss)"
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
