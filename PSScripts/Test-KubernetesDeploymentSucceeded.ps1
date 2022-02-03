[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)]
    [String]$KubectlOutput,
    [Parameter(Mandatory=$true)]
    [String]$Deployment
)

$KubectlObject = ConvertFrom-Json -InputObject $KubectlOutput
$KubectlObject
$Deployment = $KubectlObject.items | Where-Object { $_.metadata.name -eq $Deployment }
Write-Output $($Deployment.metadata.name)
if ($Deployment.status.availableReplicas -gt 0) {

    Write-Output "##vso[task.setvariable variable=DeploymentSucceeded]true"

}
else {

    Write-Output "##vso[task.setvariable variable=DeploymentSucceeded]false"

}

##TO DO: refactor as generalised script for testing k8s output
