[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)]
    [String]$KubectlOutput,
    [Parameter(Mandatory=$true)]
    [String]$Namespace
)

$KubectlObject = ConvertFrom-Json -InputObject $KubectlOutput
$KubectlObject
$Namespace = $KubectlObject.items | Where-Object { $_.metadata.name -eq $Namespace }
Write-Host $($Namespace.metadata.name)
if ($Namespace) { 
    
    Write-Output "##vso[task.setvariable variable=NamespaceExists]true" 

}
else {

    Write-Output "##vso[task.setvariable variable=NamespaceExists]false" 

}