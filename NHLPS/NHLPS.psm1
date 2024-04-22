$script:apiURL1 = "https://api-web.nhle.com/v1"
$script:apiURL2 = "https://api.nhle.com"
$script:cacheMins = "60"

function Invoke-ApiCall {
    Param (
        [Parameter(Mandatory = $True)][ValidateSet('Get', 'Post', 'Put', 'Delete')][string] $callMethod,
        [Parameter(Mandatory = $True)][string] $apiURL,
        [Parameter(Mandatory = $True)][string] $urlTemplate,
        [Parameter(Mandatory = $False)] $body
    )
    try {
        $URL = $apiURL+$script:apiVersion+$urlTemplate
        # $headers = @{Authorization = "Bearer $($Global:EnvConfig.SecretServer.token)" }
        if ($body) {
            $response = Invoke-RestMethod -Uri $URL -UseBasicParsing -Method $callMethod -Body $body -ContentType 'application/json'
        } else {
            $response = Invoke-RestMethod -Uri $URL -UseBasicParsing -Method $callMethod
        }
        # return $URL
    } catch {
        if ($_ -like "*404*") {
            return $false
        } else {
            $msg = "NHL api call failed - $URL, $_"
            # Write-Error $msg
            throw $msg
        }
    }

    return $response
}

function Get-Team {
    # Temp
    Param
    (
        [parameter(Mandatory=$false)]
        [Int]
        $ID,

        [parameter(Mandatory=$false)]
        [String]
        $triCode
    )

    # Set all static API call variables
    $callMethod = "GET"
    $apiURL = $script:apiURL2
    $urlTemplate = "/stats/rest/en/team"

    if (($PSBoundParameters.ContainsKey('ID')) -and (($PSBoundParameters.ContainsKey('triCode')))) {
        Write-Error "Do not call function with both ID and triCode set"
        return $false | Out-Null
    } 

    if ($PSBoundParameters.ContainsKey('ID')) {
        $results = Invoke-ApiCall -callMethod $callMethod -apiURL $apiURL -urlTemplate $urlTemplate
        return $results.data | Where-Object { $_.id -like $ID }
    }

    if ($PSBoundParameters.ContainsKey('triCode')) {
        $results = Invoke-ApiCall -callMethod $callMethod -apiURL $apiURL -urlTemplate $urlTemplate
        return $results.data | Where-Object { $_.rawTriCode -like $triCode }
    }

    # If both are null - get all teams
    if (($null -ne $ID) -and ($null -ne $triCode)) {
        $results = Invoke-ApiCall -callMethod $callMethod -apiURL $apiURL -urlTemplate $urlTemplate
        return $results.data
    }
}

function Get-TeamRoster {
    Param
    (
        [parameter(Mandatory=$false)]
        [Int]
        $ID,

        [parameter(Mandatory=$false)]
        [String]
        $triCode,

        [parameter(Mandatory=$false)]
        [Switch]
        $forceCacheReload
    )
    # If both are set - return out, 
    if (($PSBoundParameters.ContainsKey('ID')) -and (($PSBoundParameters.ContainsKey('triCode')))) {
        Write-Error "Do not call function with both ID and triCode set"
        return $false | Out-Null
    }

    # Set all static API call variables
    $callMethod = "GET"
    $apiURL = $script:apiURL1
    $urlTemplate = "/roster"

    if ($PSBoundParameters.ContainsKey('ID')) {
        # get the Team to retrieve the team tricode
        $team = Get-Team -ID $ID
        $triCode = $team.triCode
        $urlTemplateLoop = "$urlTemplate/$triCode/current"
        $results = Invoke-ApiCall -callMethod $callMethod -apiURL $apiURL -urlTemplate $urlTemplateLoop
        if ($results) {
            $teamRoster = @()
            $teamRoster+=$results.forwards
            $teamRoster+=$results.defensemen
            $teamRoster+=$results.goalies
            $teamRoster | ForEach-Object { $_ | Add-Member -MemberType NoteProperty -Name "TeamCode" -Value $triCode}
            return $teamRoster
        } else {
            Write-Error "No roster found for team with ID: $ID"
            return $false | Out-Null
        }
    }

    if ($PSBoundParameters.ContainsKey('triCode')) {
        $urlTemplateLoop = "$urlTemplate/$triCode/current"
        $results = Invoke-ApiCall -callMethod $callMethod -apiURL $apiURL -urlTemplate $urlTemplateLoop
        if ($results) {
            $teamRoster = @()
            $teamRoster+=$results.forwards
            $teamRoster+=$results.defensemen
            $teamRoster+=$results.goalies
            $teamRoster | ForEach-Object { $_ | Add-Member -MemberType NoteProperty -Name "TeamCode" -Value $triCode}
            return $teamRoster
        } else {
            Write-Error "No roster found for team with ID: $ID"
            return $false | Out-Null
        }
    }

    # If neither get all team rosters
    if ((!$PSBoundParameters.ContainsKey('ID')) -and ((!$PSBoundParameters.ContainsKey('triCode')))) {
        # See if we have cached the results
        if (!$forceCacheReload) {
            $cache = Get-CacheResults -fileName NHLRoster.json
            if ($cache) {
                return $cache
            }
        }
        # First get all teams
        $allTeams = Get-Team
        Write-Verbose "Found $($allTeams.Count) teams"

        $rosterReturn = @()
        # Loop through teams and perform API calls - add to rosterReturn array
        for ($i = 0; $i -le $($allTeams.Count); $i++ ) {
            $teamRoster = @()
            if ($allTeams[$i].rawTricode) {
                $urlTemplateLoop = "$urlTemplate/$($allTeams[$i].rawTricode)/current"
                $results = Invoke-ApiCall -callMethod $callMethod -apiURL $apiURL -urlTemplate $urlTemplateLoop
                if ($results) {
                    $teamRoster+=$results.forwards
                    $teamRoster+=$results.defensemen
                    $teamRoster+=$results.goalies
                    $teamRoster | ForEach-Object { $_ | Add-Member -MemberType NoteProperty -Name "TeamCode" -Value $($allTeams[$i].rawTricode)}
                    $rosterReturn+=$teamRoster
                    Write-Verbose "Roster found for $($allTeams[$i].rawTricode) forwards: $($results.forwards.Count) - defensemen: $($results.defensemen.Count) - goalies: $($results.goalies.Count)"
                } else {
                    Write-Verbose "No roster found for $($allTeams[$i].rawTricode)"
                }
            } else {
                Write-Debug "No tricode found for $($allTeams[$i])"
            }
            $PercentComplete = ([math]::ceiling(($i / $allTeams.Count) * 100))
            Write-Progress -Activity "Retrieving Team Rosters" -Status "$PercentComplete% Complete:" -PercentComplete $PercentComplete
        }
        Invoke-CacheResults -fileName NHLRoster.json -data $rosterReturn
        return $rosterReturn
    }
}

function Get-Player {
    [CmdletBinding(DefaultParameterSetName = 'ID')]
    Param
    (
        [parameter(Mandatory=$true,
        ParameterSetName="ID")]
        [Int]
        $ID,

        [parameter(Mandatory=$false,
        ParameterSetName="name")]
        [String]
        $firstName,
    
        [parameter(Mandatory=$false,
        ParameterSetName="name")]
        [String]
        $lastName
    )
    $callMethod = "GET"
    $apiURL = $script:apiURL1

    # If ID is set - ignore all other parameters - get player info
    if ($ID) {
        $urlTemplate = "/player/$ID/landing"

        $results = Invoke-ApiCall -callMethod $callMethod -apiURL $apiURL -urlTemplate $urlTemplate
        if ($results) {
            return $results
        } else {
            return "No player found with ID: $ID"
        }
    # else we need to search on certain parameters
    } else {
        $nhlRoster = Get-TeamRoster
        if (($PSBoundParameters.ContainsKey('firstName')) -and (($PSBoundParameters.ContainsKey('lastName')))) {
            $foundPlayers = $nhlRoster | Where-Object {$_.firstName.default -like $firstName -and $_.lastName.default -like $lastName}
        } 
        if ($PSBoundParameters.ContainsKey('firstName')) {
            $foundPlayers = $nhlRoster | Where-Object {$_.firstName.default -like $firstName}
        }
    
        if ($PSBoundParameters.ContainsKey('lastName')) {
            $foundPlayers = $nhlRoster | Where-Object {$_.lastName.default -like $lastName}
        }

        # if (!$foundPlayers) {
        #     Write-Error "No players found with inputted criteria"
        #     return $false | Out-Null
        # }

        $return = @()
        foreach ($player in $foundPlayers) {
            $ID = $player.id
            $urlTemplate = "/player/$ID/landing"
            $results = Invoke-ApiCall -callMethod $callMethod -apiURL $apiURL -urlTemplate $urlTemplate
            $return+=$results
        }

        return $return
    }
}

function Get-PlayerSchedule {

}

function Get-TeamSchedule {
    Param
    (
        [parameter(Mandatory=$false)]
        [String]
        $triCode,

        [parameter(Mandatory=$false)]
        [ValidateSet("Day", "Week", "Month", "Year", IgnoreCase = $false)]
        [String]
        $period,

        [parameter(Mandatory=$false)]
        [String]
        $date
    )

    # If both are set - return out, 
    if (($PSBoundParameters.ContainsKey('ID')) -and (($PSBoundParameters.ContainsKey('triCode')))) {
        Write-Error "Do not call function with both ID and triCode set"
        return $false | Out-Null
    }

    $callMethod = "GET"
    $apiURL = $script:apiURL1
    switch ($period) {
        "Day" {
            $urlTemplate = "/club-schedule/"
        }
        "Week" {
            $urlTemplate = "/club-schedule/"
        }
        "Month" {
            $urlTemplate = "/club-schedule/"
        }
        "Year" {
            $urlTemplate = "club-schedule-season/"
        }
    }

    # If tricode is set get schedule for one team only
    if ($PSBoundParameters.ContainsKey('triCode')) {
        $urlTemplate += $triCode
    # else get schedules for all teams
    } else {
        
    }
}

function Invoke-CacheResults {
    Param
    (
        [parameter(Mandatory=$true)]
        [String]
        $fileName,
                
        [parameter(Mandatory=$true)]
        [PSCustomObject[]]
        $data
    )

    if (!(Test-Path -Path ./.cache)) {
        Write-Warning "No cache directory present - creating.."
        New-Item -ItemType Directory -Path ./.cache
    }

    if (!(Test-Path -Path ./.cache/$fileName)) {
        Write-Warning "No file ./.cache/$fileName present - creating.."
        New-Item -ItemType File -Path ./.cache/ -Name $fileName
    }

    $date = Get-Date
    $jsonData = $data | ConvertTo-Json
    $content = @"
    {
        "cacheTime": "$date",
        "data": $jsonData
    }
"@

    Set-Content -Path ./.cache/$fileName -Value $content
}

function Get-CacheResults {
    Param
    (
        [parameter(Mandatory=$true)]
        [String]
        $fileName
    )

    # Check if file exists
    if (Test-Path -Path ./.cache/$fileName) {
        $content = Get-Content -Path ./.cache/$fileName | ConvertFrom-Json

        if (!$content.cacheTime) {
            Write-Warning "Cache file $fileName is corrupted - will continue and rebuild post function"
            return $false | Out-Null
        } else {
            $date = [System.DateTime]$($content.cacheTime)
            $date2 = [System.DateTime]$(Get-Date)
            $difference = New-TimeSpan -start $date -end $date2
            $totalMins = 0
            $totalMins = $totalMins + $difference.Minutes
            $totalMins = $totalMins + (1440 * $difference.Days)
            $totalMins = $totalMins + (60 * $difference.Hours)
            
            if ($totalMins -lt $script:cacheMins) {
                return $content.data
            } else {
                Write-Warning "$fileName cache has expired - regenerating from API..."
                return $false | Out-Null
            }
        }
    } else {
        # Write-Warning "Cache file file does not exist"
        return $false | Out-Null
    }
}