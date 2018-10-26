$ErrorActionPreference = 'stop'
Install-PackageProvider -Name Nuget -Scope CurrentUser -Force -Confirm:$false
Install-Module -Name PSScriptAnalyzer -Scope CurrentUser -Force -Confirm:$false
Import-Module PSScriptAnalyzer
Invoke-Pester -OutputFile 'TEST-PesterResults.xml' -OutputFormat 'NUnitXml' -Script '.\Tests\*.tests.ps1'
