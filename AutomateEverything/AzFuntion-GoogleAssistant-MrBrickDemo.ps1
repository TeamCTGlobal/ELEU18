try {
    # POST method: $req
    $requestBody = Get-Content $req -Raw | ConvertFrom-Json
    $name = $requestBody.name
    
    #Get query text = sentence
    $queryText = $requestBody.queryResult.queryText
    write-output "Query Text: $queryText"
    
    #Define action words
    $actionsGrab = "grab", "pick up","lift","Lyft"
    $actionsRelease = "release", "let go","drop"
    
    #Prepare regex
    $actions = $actionsGrab + $actionsRelease
    $actionsRegex = [string]::Join('|', $actions)
    
    #Find Action
    if ($queryText -notmatch $actionsRegex) {
        throw "No action found in command"
    } 
    $Action = $Matches[0]
    
    #Find length
    if ($queryText -notmatch "\d+") {
        Throw "No length found in command"
    }
    $Length = $Matches[0]
    
    #Translate action to action param
    switch ($Action) {
        {$_ -in $actionsGrab} { $ActionValue = "grab" }
        {$_ -in $actionsRelease} { $ActionValue = "release" }
    }
    
    #Trigger runbook.
    $Payload = @{
        IPAddress  = "192.168.43.154"
        LengthInCm = $Length
        Action     = $ActionValue
    }
    $Body = $Payload | ConvertTo-Json
    $Uri = "https://s1events.azure-automation.net/webhooks?token=xxxxxx"
    $result = Invoke-WebRequest -Uri $Uri  -Method Post -Body $Body -ContentType "application/json" -UseBasicParsing
    
    #Get Job Id
    $JobId = ($result | COnvertFrom-JSON).JobIds
    
    #Set Reponse Text
    $ResponseText = "I have ordered Mr. Brick to go $Length centimeters and perform a $ActionValue. Please keep calm and wait for Job to finish. Job Id is $JobId. Don't we all love pronouncing globally unique identifiers."
    
}
catch {
    $CurrentError = $Error[0]
    $ResponseText = "Error Occurred: $CurrentError. The received command was. $queryText" #use punctuation for pauses in speech
}
finally {
    #Send Reponse
    $Response = @{"fulfillmentText" = $ResponseText}
    $ResponseJSON = $Response | ConvertTo-JSON
    Write-output $ResponseJSON
    #Send Reponse
    Out-File -Encoding Ascii -FilePath $res -inputObject $ResponseJSON
}
    