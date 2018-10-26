[CmdletBinding()]
param(
	[string]$SourceDir = $env:BUILD_SOURCESDIRECTORY
)

Describe 'General - Testing all scripts and modules against the Script Analyzer Rules' {
    $scriptsModules = Get-ChildItem $SourceDir -Include *.psd1, *.psm1, *.ps1 -Exclude *.tests*.ps1 -Recurse | ? {$_.Directory -notlike "*\tests*"}
    Context "Checking files to test exist and Invoke-ScriptAnalyzer cmdLet is available" {
        It "Checking files exist to test." {
            $scriptsModules.count | Should Not Be 0
        }
        It "Checking Invoke-ScriptAnalyzer exists." {
            { Get-Command Invoke-ScriptAnalyzer -ErrorAction Stop } | Should Not Throw
        }
    }

    $scriptAnalyzerRules = Get-ScriptAnalyzerRule

    forEach ($scriptModule in $scriptsModules) {
        switch -wildCard ($scriptModule) { 
            '*.psm1' { $typeTesting = 'Module' } 
            '*.ps1' { $typeTesting = 'Script' } 
            '*.psd1' { $typeTesting = 'Manifest' } 
		}
		
        Context "Checking $typeTesting - $($scriptModule) - conforms to Script Analyzer Rules" {
            $analysis = Invoke-ScriptAnalyzer -Path $scriptModule.FullName -IncludeDefaultRules
            $scriptAnalyzerRules = Get-ScriptAnalyzerRule

            forEach ($rule in $scriptAnalyzerRules) {
                It "Script Analyzer Rule $($rule.RuleName)" {
                    If ($analysis.RuleName -contains $rule) {
                        $Errors = $analysis | Where-Object {($_.RuleName -eq $rule) -and ($_.Severity -eq 'Error')}
                        $Warnings = $analysis | Where-Object {($_.RuleName -eq $rule) -and ($_.Severity -eq 'Warning')}

						if($Errors.Count -ne 0){
                            Write-Host "##vso[task.logissue type=error;] - $($errors.count) Errors(s) - $rule" $($errors | Out-String) 
							#Write-Warning -Message ($Errors | Out-String)
						}
						if($Warnings.Count -ne 0){
							Write-Host "##vso[task.logissue type=warning;] - $($Warnings.count) Warning(s) - $rule" $($Warnings | Out-String) 
							#Write-Warning -Message ($Warnings | Out-String)
						}

                        $Errors.Count | Should Be 0
                    }
                }
            }
        }
    }
}