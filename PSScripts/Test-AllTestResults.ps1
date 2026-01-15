[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [String]$AzureDevOpsOrganizationName,
    [Parameter(Mandatory = $true)]
    [String]$BuildId,
    [Parameter(Mandatory = $true)]
    [String]$ModulePath,
    [Parameter(Mandatory = $true)]
    [String]$PatToken,
    [Parameter(Mandatory = $true)]
    [String]$ProjectId
)

Import-Module $ModulePath
$TestRuns = Get-TestRun -Instance $AzureDevOpsOrganizationName -PatToken $PatToken -ProjectId $ProjectId -BuildId $BuildId | Sort-Object -Property Name, CompletedDate -Descending
Write-Verbose "TestRuns:`n$($TestRuns | Format-Table -AutoSize | Out-String)"

if ($TestRuns.Count -eq 0) {
    Write-Error "No test results retrieved."
}

$LatestTestRuns = @()
# we expect there to be multiple distinct outputs of these types, they will only be ran once so select them all
$LatestTestRuns += $TestRuns | Where-Object { $_.Name -match "^VSTest_TestResults_\d+$" -or $_.Name -eq "JUnit_junit.xml" }

$TestRunTypes = $TestRuns.Name | ForEach-Object { ($_ -split "_")[0] } | Sort-Object | Get-Unique
# other types of tests may be ran multiple times as integration and functional tests can be flakey, get the latest result of each type
foreach ($RunType in ($TestRunTypes -notmatch"JUnit|VSTest")) {
    $LatestTestRuns += $TestRuns | Where-Object { $_.Name -match "^$RunType`_\d+_" } | Sort-Object -Top 1
}
Write-Verbose "LastTestRuns:`n$($LatestTestRuns | Format-Table -AutoSize | Out-String)"

$TotalTests = ($LatestTestRuns | Measure-Object -Property TotalTests -Sum).Sum
Write-Verbose "TotalTests: $TotalTests"
Write-Output "##vso[task.setvariable variable=TotalTests]$TotalTests"

$FailedTests = ($LatestTestRuns | Measure-Object -Property FailedTests -Sum).Sum
Write-Verbose "FailedTests: $FailedTests"
Write-Output "##vso[task.setvariable variable=FailedTests]$FailedTests"

$SlackTable = @()
foreach ($TestRun in $LatestTestRuns) {
    $SlackTable += "• $($TestRun.Name): $($TestRun.PassedTests) / $($TestRun.TotalTests)"
}
$SlackTableText = $SlackTable -join " %0D%0A"
Write-Verbose "SlackTableText: $SlackTableText"
Write-Output "##vso[task.setvariable variable=SlackTableText]$SlackTableText"

$CompletedTestRunCount = $LatestTestRuns.Count
Write-Verbose "CompletedTestRunCount: $CompletedTestRunCount"
Write-Output "##vso[task.setvariable variable=CompletedTestRunCount]$CompletedTestRunCount"

if (($LatestTestRuns | Where-Object { $_.FailedTests -gt 0 }).Count -gt 0) {
    Write-Error "At least one test failed."
    Write-Output "$($LatestTestRuns | Format-Table -AutoSize | Out-String)"
}
