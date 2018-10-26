Param($artifactsFolder, $ResourceGroup, $AutomationAccountName)

#--- Variables ---#
#$ResourceGroup = "ASO_Playground"
#$AutomationAccountName = "ASO-Playground"
#$artifactsFolder = "$(System.DefaultWorkingDirectory)"
#-----------------#

Write-Output("Resource Group: " +  $ResourceGroup)
Write-Output("Automation Account Name: " +  $AutomationAccountName)

$Files = Get-ChildItem -Path $artifactsFolder -Recurse -File |? {$_.Extension -eq ".ps1"}
Write-Output("Listing Artifacts" )
$Files

foreach ($File in $Files) {
    Write-Output("Syncing " +  $File.FullName )
    $AST = [System.Management.Automation.Language.Parser]::ParseFile($File.FullName, [ref]$null, [ref]$null);
    If ($AST.EndBlock.Extent.Text.ToLower().StartsWith("workflow"))
    {
        Write-Verbose "File is a PowerShell workflow"
        $AutomationScript = Import-AzureRmAutomationRunbook -Path $File.FullName -AutomationAccountName $AutomationAccountName -ResourceGroupName $ResourceGroup -Type PowerShellWorkflow -Force -Published 
    }
    If ($AST.EndBlock.Extent.Text.ToLower().StartsWith("configuration"))
    {
        Write-Verbose "File is a configuration script"
        $AutomationScript = Import-AzureRmAutomationDscConfiguration -Path $File.FullName -AutomationAccountName $AutomationAccountName -ResourceGroupName $ResourceGroup -Force -Published
    }
    If (!($AST.EndBlock.Extent.Text.ToLower().StartsWith("configuration") -or ($AST.EndBlock.Extent.Text.ToLower().StartsWith("workflow"))))
    {
        Write-Verbose "File is a powershell script"
        $AutomationScript = Import-AzureRmAutomationRunbook -Path $File.FullName -AutomationAccountName $AutomationAccountName -ResourceGroupName $ResourceGroup -Type PowerShell -Force -Published 
    }
}