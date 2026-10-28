Describe "Test-GitHubComToken Unit Tests" -Tags @("Unit") {

    BeforeAll {
        Set-Location $PSScriptRoot/../PSScripts/

        $TestParams = @{
            GitHubComToken = "not-a-real-token"
            SlackApiUrl = "https://hooks.slack.example.com/not-a-real-webhook"
            BuildUrl = "https://dev.azure.example.com/build/1"
            BuildName = "renovate"
        }

        function New-GitHubResponse {
            param([Int]$StatusCode, [String]$Expiry)
            $Headers = @{}
            if ($Expiry) {
                $Headers['github-authentication-token-expiration'] = @($Expiry)
            }
            return [PSCustomObject]@{
                StatusCode = $StatusCode
                Headers = $Headers
            }
        }

        function Get-ExpiryInDays {
            param([Int]$Days)
            return [DateTime]::UtcNow.Date.AddDays($Days).ToString("yyyy-MM-dd 00:00:00 'UTC'")
        }

        Mock Invoke-RestMethod
    }

    Context "No token is configured" {
        It "Should alert Slack and throw without calling GitHub when the token is <Description>" -TestCases @(
            @{ Description = "empty"; Token = "" }
            @{ Description = "an undefined pipeline variable"; Token = '$(RenovateGitHubComToken)' }
        ) {
            Mock Invoke-WebRequest
            $Params = $TestParams.Clone()
            $Params.GitHubComToken = $Token
            $Output = [System.Collections.ArrayList]::new()

            { .\Test-GitHubComToken.ps1 @Params | ForEach-Object { $null = $Output.Add($_) } } | Should -Throw "*no github.com token is configured*"
            $Output | Should -Contain "##vso[task.logissue type=error]Renovate did not run: no github.com token is configured. Create a new fine-grained PAT (public repositories, read-only) and update the RenovateGitHubComToken secret."
            Assert-MockCalled -CommandName Invoke-WebRequest -Exactly -Times 0
            Assert-MockCalled -CommandName Invoke-RestMethod -ParameterFilter { ($Body | ConvertFrom-Json).icon_emoji -eq ":rotating_light:" } -Exactly -Times 1
        }
    }

    Context "GitHub rejects the token" {
        It "Should alert Slack and throw when GitHub returns <StatusCode>" -TestCases @(
            @{ StatusCode = 401; Problem = "the github.com token has expired or been revoked" }
            @{ StatusCode = 500; Problem = "api.github.com returned 500 when checking the token" }
        ) {
            Mock Invoke-WebRequest -MockWith { New-GitHubResponse -StatusCode $StatusCode }

            { .\Test-GitHubComToken.ps1 @TestParams } | Should -Throw "*$Problem*"
            Assert-MockCalled -CommandName Invoke-WebRequest -ParameterFilter { $Headers.Authorization -eq "Bearer not-a-real-token" } -Exactly -Times 1
            Assert-MockCalled -CommandName Invoke-RestMethod -ParameterFilter {
                $SlackBody = $Body | ConvertFrom-Json
                $SlackBody.icon_emoji -eq ":rotating_light:" -and $SlackBody.blocks[0].text.text -like "<https://dev.azure.example.com/build/1|renovate> Renovate did not run: $Problem*"
            } -Exactly -Times 1
        }
    }

    Context "Token is valid" {
        It "Should not alert Slack when the token has no expiry" {
            Mock Invoke-WebRequest -MockWith { New-GitHubResponse -StatusCode 200 }

            { .\Test-GitHubComToken.ps1 @TestParams } | Should -Not -Throw
            Assert-MockCalled -CommandName Invoke-RestMethod -Exactly -Times 0
        }

        It "Should not alert Slack when the token expires in 15 days" {
            $Expiry = Get-ExpiryInDays -Days 15
            Mock Invoke-WebRequest -MockWith { New-GitHubResponse -StatusCode 200 -Expiry $Expiry }

            $Output = .\Test-GitHubComToken.ps1 @TestParams
            $Output | Should -Be "github.com token expires $Expiry (15 days)"
            Assert-MockCalled -CommandName Invoke-RestMethod -Exactly -Times 0
        }

        It "Should warn Slack without throwing when the token expires in <Days> days" -TestCases @(
            @{ Days = 14 }
            @{ Days = 1 }
        ) {
            $Expiry = Get-ExpiryInDays -Days $Days
            Mock Invoke-WebRequest -MockWith { New-GitHubResponse -StatusCode 200 -Expiry $Expiry }

            $Output = .\Test-GitHubComToken.ps1 @TestParams
            $Output | Should -Contain "##vso[task.logissue type=warning]The Renovate github.com token expires in $Days days ($Expiry). Create a new fine-grained PAT (public repositories, read-only) and update the RenovateGitHubComToken secret."
            Assert-MockCalled -CommandName Invoke-RestMethod -ParameterFilter { ($Body | ConvertFrom-Json).icon_emoji -eq ":warning:" } -Exactly -Times 1
        }

        It "Should warn Slack with a custom ExpiryWarningDays" {
            $Expiry = Get-ExpiryInDays -Days 20
            Mock Invoke-WebRequest -MockWith { New-GitHubResponse -StatusCode 200 -Expiry $Expiry }

            .\Test-GitHubComToken.ps1 @TestParams -ExpiryWarningDays 30 | Out-Null
            Assert-MockCalled -CommandName Invoke-RestMethod -ParameterFilter { ($Body | ConvertFrom-Json).icon_emoji -eq ":warning:" } -Exactly -Times 1
        }
    }
}
