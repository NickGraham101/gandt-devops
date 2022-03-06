[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)]
    [String]$ContainerRegistryResourceGroupName,  
    [Parameter(Mandatory=$true)]
    [String]$DestinationContainerRegistryName,    
    [Parameter(Mandatory=$true)]
    [String]$SourceContainerRegistryName
)

$InformationPreference = "Continue"

# get container registries
$SourceContainerRegistry = Get-AzContainerRegistry -ResourceGroupName $ContainerRegistryResourceGroupName -Name $SourceContainerRegistryName
$DestinationContainerRegistry = Get-AzContainerRegistry -ResourceGroupName $ContainerRegistryResourceGroupName -Name $DestinationContainerRegistryName -ErrorAction SilentlyContinue
if (!$DestinationContainerRegistry) {
    Write-Information -MessageData "Container Registry $DestinationContainerRegistryName doesn't exist, creating in resource group $ContainerRegistryResourceGroupName" -InformationAction Continue
    $DestinationContainerRegistry = New-AzContainerRegistry -ResourceGroupName $ContainerRegistryResourceGroupName -Name $DestinationContainerRegistryName -Sku $SourceContainerRegistry.SkuName -Location $SourceContainerRegistry.Location
}

# get repos
$Repositories = Get-AzContainerRegistryRepository -RegistryName $SourceContainerRegistry.Name
foreach ($Repo in $Repositories) {
    # get images
    $Tags = Get-AzContainerRegistryTag -RegistryName $SourceContainerRegistry.Name -RepositoryName $Repo
    foreach ($Tag in $Tags.Tags) {
        # write images to destination in same resource group
        $SourceImage = "$Repo`:$($Tag.Name)"
        Write-Information -MessageData "Importing $SourceImage from $($SourceContainerRegistry.LoginServer) to $($DestinationContainerRegistry.Name)"
        #https://github.com/Azure/azure-powershell/issues/17348
        #Import-AzContainerRegistryImage -ResourceGroupName $ContainerRegistryResourceGroupName -SourceRegistryUri $SourceContainerRegistry.LoginServer -SourceImage $SourceImage -RegistryName $DestinationContainerRegistry.Name -Debug
        $Source = "$($SourceContainerRegistry.LoginServer)/$SourceImage"
        az acr import --name $DestinationContainerRegistry.Name --source $Source --image $SourceImage
        
        ##TO DO: write images to destination in different tenant
    }
}

