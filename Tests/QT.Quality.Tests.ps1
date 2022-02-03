BeforeDiscovery {
    $Scripts = Get-ChildItem -Path $PSScriptRoot\.. -File -Include "*.ps1", "*.psm1" -Recurse | Where-Object { $_.DirectoryName -notmatch ".*\\Tests|.+\\Tests\\.+" }
    $Rules = Get-ScriptAnalyzerRule
}

Describe "Script code quality tests" -Tags @("Quality") -ForEach $Scripts {
    BeforeAll {
        $Script = $_
    }

    Context "<script>" -ForEach $Rules {
        BeforeAll {
            $Rule = $_
        }
        It "Should pass Script Analyzer rule <Rule>" {
            $Result = Invoke-ScriptAnalyzer -Path $Script.FullName -IncludeRule $Rule
            $Result.Count | Should -Be 0
        }
    }
}
