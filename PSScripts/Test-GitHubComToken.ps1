<#
    .SYNOPSIS
    Checks the github.com token Renovate uses before it runs.

    .DESCRIPTION
    Calls api.github.com/rate_limit with the token. A missing, undefined, expired or revoked token
    logs a pipeline error, posts a Slack alert and throws so Renovate does not raise PRs without lock
    files. A token expiring within ExpiryWarningDays logs a pipeline warning and posts a Slack warning.

    .PARAMETER GitHubComToken
    The github.com token. An undefined pipeline variable is passed through as the literal "$(Name)".

    .PARAMETER SlackApiUrl
    Slack webhook URL for alerts.

    .PARAMETER BuildUrl
    Link to the pipeline run, included in Slack messages.

    .PARAMETER BuildName
    Text for the pipeline run link.

    .PARAMETER ExpiryWarningDays
    Warn when the token expires within this many days.

    .EXAMPLE
    Test-GitHubComToken.ps1 -GitHubComToken $env:GITHUB_COM_TOKEN -SlackApiUrl "https://hooks.slack.com/..." -BuildUrl "https://dev.azure.com/..." -BuildName "renovate"
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [String]$GitHubComToken,
    [Parameter(Mandatory = $true)]
    [String]$SlackApiUrl,
    [Parameter(Mandatory = $true)]
    [String]$BuildUrl,
    [Parameter(Mandatory = $true)]
    [String]$BuildName,
    [Parameter(Mandatory = $false)]
    [Int]$ExpiryWarningDays = 14
)

$RenewInstructions = "Create a new fine-grained PAT (public repositories, read-only) and update the RenovateGitHubComToken secret."
$SlackParams = @{
    SlackApiUrl  = $SlackApiUrl
    MessageTitle = "Weekly Renovate Update"
}
$RunLink = "<$BuildUrl|$BuildName>"

$Problem = $null
if ([string]::IsNullOrWhiteSpace($GitHubComToken) -or $GitHubComToken -match '^\$\(') {
    $Problem = "no github.com token is configured"
}
else {
    $Response = Invoke-WebRequest -Uri "https://api.github.com/rate_limit" -Headers @{ Authorization = "Bearer $GitHubComToken" } -SkipHttpErrorCheck
    if ($Response.StatusCode -eq 401) {
        $Problem = "the github.com token has expired or been revoked"
    }
    elseif ($Response.StatusCode -ne 200) {
        $Problem = "api.github.com returned $($Response.StatusCode) when checking the token"
    }
}

if ($Problem) {
    $Message = "Renovate did not run: $Problem. $RenewInstructions"
    Write-Output "##vso[task.logissue type=error]$Message"
    & $PSScriptRoot/Send-SlackMessage.ps1 @SlackParams -Emoji ":rotating_light:" -FallBackMessage $Message -MarkdownMessage "$RunLink $Message"
    throw $Message
}

# Header is absent for tokens without an expiry, e.g. "2026-12-01 00:00:00 UTC"
$Expiry = $Response.Headers['github-authentication-token-expiration'] | Select-Object -First 1
if ($Expiry -match '^\d{4}-\d{2}-\d{2}') {
    $ExpiryDate = [DateTime]::ParseExact($Matches[0], 'yyyy-MM-dd', [Globalization.CultureInfo]::InvariantCulture)
    $DaysLeft = [Math]::Floor(($ExpiryDate - [DateTime]::UtcNow.Date).TotalDays)
    Write-Output "github.com token expires $Expiry ($DaysLeft days)"
    if ($DaysLeft -le $ExpiryWarningDays) {
        $Message = "The Renovate github.com token expires in $DaysLeft days ($Expiry). $RenewInstructions"
        Write-Output "##vso[task.logissue type=warning]$Message"
        & $PSScriptRoot/Send-SlackMessage.ps1 @SlackParams -Emoji ":warning:" -FallBackMessage $Message -MarkdownMessage "$RunLink $Message"
    }
}
