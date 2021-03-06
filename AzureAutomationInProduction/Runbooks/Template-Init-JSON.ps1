Using Module CTToolkit
<#PSScriptInfo

.VERSION 1.0.0

.GUID d5033d8e-237f-42dc-84b7-6d2d20605e9f

.AUTHOR Jakob Gottlieb Svendsen & Andreas Sobczyk , CTGlobal. http://www.ctglobalservices.com

.COMPANYNAME CT Global

.COPYRIGHT CT GLobal

.TAGS 

.LICENSEURI 

.PROJECTURI 

.ICONURI 

.EXTERNALMODULEDEPENDENCIES 

.REQUIREDSCRIPTS 

.EXTERNALSCRIPTDEPENDENCIES 

.RELEASENOTES
Change Log:
1.0.0 - Initial Version
#>
<# 
 .Synopsis
        Awesome template for Azure Automation / SMA.
 .DESCRIPTION 
 Completed script and errors are logged to 1 or more eventlog events in Application Eventlog
Event IDs (Application Log):
1000: Information - Successfully completed
1001: Error - General Error
1002: Error - Error in Toolkit - script continues
1003: Warning - List of machines which is active in SP but not active in SCCM
1004: Error - Server has issue, skipped to next server 

#>
[CmdletBinding()]
Param
(
    [Parameter (Mandatory = $true)]
    [String] $ResourceGroupName,
    [Parameter (Mandatory = $false)]
    [String] $OtherParameter
)
$ErrorActionPreference = "stop"

#//----------------------------------------------------------------------------
#//
#//  Global constant and variable declarations
#//  Shared Resource retrieval (Assets)
#//
#//----------------------------------------------------------------------------
#Constants
$Prefix = "CT-"
    
#Assets
#$Credential = Get-AutomationPSCredential -Name "Graph-Jakob-Runbook-Guru"

#//----------------------------------------------------------------------------
#//  Procedures (Logging etc.)
#//----------------------------------------------------------------------------
#region Procedures
    
#endregion

#//----------------------------------------------------------------------------
#//  Main routines
#//----------------------------------------------------------------------------
#Create return object and send inputs to it
#This has to be executed outside any scoep such as Try or $null = { as we want to read $PSBoundParameters for this scope
$returnData = new-Object CTReturnObject

Try {
    #Redirect all outputs to $null to make sure we only output the return object to output
    $null = . {
        $StartTime = get-date

        Clear-Tracelog #make sure tracelog is cleared, even when running multiple times in same scope
        Add-Tracelog -Message "Init Runbook started at $StartTime"
        Add-Tracelog -Message "Running on: $env:computername"

        #region------------------------------------  Main Code  --------------------------------------------###

        #Call Control Runbook
       
        Add-Tracelog -Message "Executing Control Runbook: Template-Control"
        $Output = .\Template-Control.ps1 -ResourceGroupName $ResourceGroupName -OtherParameter $OtherParameter

        #endregion------------------------------------  Main Code  --------------------------------------------###

        $EndTime = Get-date
        Add-Tracelog -Message "Finished at: $EndTime"
        Add-Tracelog -Message "Total Runtime: $($Endtime - $StartTime)"
        
        #Status
        $returnData.Status = "Success"

        $EndTime = Get-Date
        Add-Tracelog -Message "Init Runbook succesfully ended at $EndTime - Duration: $($EndTime-$StartTime)"
    } # $null = . {

}
Catch {
    $CurrentError = $Error[0]

    #Set returnData object
    $returnData.ErrorMessage = $ErrorMessage
    $returnData.Status = "Failed"
    
    #get error message
    $ErrorMessage = $CurrentError.Exception.Message + "`n $($CurrentError.InvocationInfo.PositionMessage)"
    Add-Tracelog -Message "Error in init runbook: $ErrorMessage"
    
    Write-Error -Message $ErrorMessage -ErrorAction Continue #output error without stopping, for logging purposes.

    #Fail runbook Job
    Write-Error -Message $ErrorMessage -ErrorAction Stop
} 
Finally {
    #Allways return object 
    $returnData.TraceLog = Get-TraceLog 
    $returnData | ConvertTo-JSON 
}
   
#//----------------------------------------------------------------------------
#//  End Script
#//----------------------------------------------------------------------------
#>