# POST method: $req
$requestBody = Get-Content $req -Raw | ConvertFrom-Json
$name = $requestBody.name

#Get Tweets
# Import the InvokeTwitterAPIs module: https://github.com/MeshkDevs/InvokeTwitterAPIs
Import-Module d:\home\site\wwwroot\AutomationDemoSimple\Modules\InvokeTwitterAPIs.psm1
#Module is failing in Azure Functions



#region Twitter Settings
# Learn how to generate these keys at: https://dev.twitter.com/oauth and https://apps.twitter.com
$accessToken = "xxx-xxx"
$accessTokenSecret = "xxx"
$apiKey = "xxx"
$apiSecret = "xxx"

$twitterOAuth = @{'ApiKey' = $apiKey; 'ApiSecret' = $apiSecret; 'AccessToken' = $accessToken; 'AccessTokenSecret' = $accessTokenSecret}

#endregion
# Hashtags to search (separated by comma) and the number of tweets to return, more examples of search options: https://dev.twitter.com/rest/public/search
$twitterAPIParams = @{'q'='#ExpertsLiveEU'} #;'count' = '5'

# Ger Twitter Data (if SinceId is not Null it will get tweets since that one)
$result = Invoke-TwitterRestMethod -ResourceURL 'https://api.twitter.com/1.1/search/tweets.json' -RestVerb 'GET' -Parameters $twitterAPIParams -OAuthSettings $twitterOAuth -Verbose
	# Parse the Twitter API data
	$twitterData = $result.statuses | Select-Object  -First 1 |% {
	
		$aux = @{
			Id = $_.id_str
			; UserId = $_.user.id
			; UserName = $_.user.name
			; UserScreenName = $_.user.screen_name
			; UserLocation = $_.user.location
			; Text = $_.text
			; CreatedAt =  [System.DateTime]::ParseExact($_.created_at, "ddd MMM dd HH:mm:ss zzz yyyy", [System.Globalization.CultureInfo]::InvariantCulture)		
		}

		# Get the Sentiment Score

		$textEncoded = [System.Web.HttpUtility]::UrlEncode($aux.Text, [System.Text.Encoding]::UTF8)

		$sentimentResult = Invoke-RestMethod -Uri "http://www.sentiment140.com/api/classify?text=$textEncoded" -Method Get -Verbose

		switch($sentimentResult.results[0].polarity)
		{
			"0" { $aux.Add("Sentiment", "Negative") }
			"4" { $aux.Add("Sentiment", "Positive") }
			default { $aux.Add("Sentiment", "Neutral") }
		}
		
		Write-Output $aux
	}

	if ($twitterData -and $twitterData.Count -ne 0)
	{
 	    #Respond to assistant 
        $Response = @{"fulfillmentText" = "This is the latest tweet about Experts Live Europe. The tweet is $($twitterData.Sentiment). The tweet is posted by $($twitterData.UserName). $($twitterData.Text)" }
	}
	else
	{
		Write-Output "No tweets found."
	}

# GET method: each querystring parameter is its own variable
if ($req_query_name) {
    $name = $req_query_name 
}
#>
$ResponseJSON = $Response | ConvertTo-JSON
write-output "Sending response: $ResponseJSON"
Out-File -Encoding Ascii -FilePath $res -inputObject $ResponseJSON
