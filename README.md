# NHLPS

A PowerShell module that utilises public NHL APIs to retrieve and display data

## Overview

The NHLPS module at the moment only works with current NHL players and current NHL team rosters. If a player is not part of the NHL or on an active roster, they will not appear in searches.

## Caching
Due to being limited by the official NHL APIs there are a few  calls that are horribly slow that facilitate the searching of players by first/last name. To achieve better performance, certain calls and their data are cached into .json files in ~./.cache folder. 

## Player Information

### Players

#### Get Player
- **Function Name**: `Get-Player`
- **Description**: Retrieve player/s and their detailed statistics. Can search on <strong>firstName</strong> & <strong>lastName</strong> or use <strong>ID</strong>
- **Parameters**:
  - `ID` (int) - Player ID
  - `firstName` (string) - exact match of first name of player
  - `lastName` (string) - exact match of last name of player
- **Response**: [PSCustomObject[]]

###### Example with ID:
```PowerShell
$return = Get-Player -ID 8484153
```

###### Example with firstName:
```PowerShell
$return = Get-Player -firstName Leo
```

###### Example with lastName:
```PowerShell
$return = Get-Player -lastName Carlsson
```

###### Example with both firstName and lastName:
```PowerShell
$return = Get-Player -firstName Leo -lastName Carlsson
```
<details>
    <summary>Example return all data</summary>

```
Get-Player -ID 8484153

playerId            : 8484153
isActive            : True
currentTeamId       : 24
currentTeamAbbrev   : ANA
fullTeamName        : @{default=Anaheim Ducks; fr=Ducks d'Anaheim}
firstName           : @{default=Leo}
lastName            : @{default=Carlsson}
teamLogo            : https://assets.nhle.com/logos/nhl/svg/ANA_light.svg
sweaterNumber       : 91
position            : C
headshot            : https://assets.nhle.com/mugs/nhl/20232024/ANA/8484153.png
heroImage           : https://assets.nhle.com/mugs/actionshots/1296x729/8484153.jpg
heightInInches      : 75
heightInCentimeters : 191
weightInPounds      : 194
weightInKilograms   : 88
birthDate           : 2004-12-26
birthCity           : @{default=Karlstad}
birthCountry        : SWE
shootsCatches       : L
draftDetails        : @{year=2023; teamAbbrev=ANA; round=1; pickInRound=2; overallPick=2}
playerSlug          : leo-carlsson-8484153
inTop100AllTime     : 0
inHHOF              : 0
featuredStats       : @{season=20232024; regularSeason=}
careerTotals        : @{regularSeason=}
shopLink            : #TODO
twitterLink         : #TODO
watchLink           : #TODO
last5Games          : {@{gameId=2023020299; gameTypeId=2; teamAbbrev=ANA; homeRoadFlag=H; gameDate=2023-11-24; goals=0; assists=0; points=0; plusMinus=0; powerPlayGoals=0;
                      shots=1; shifts=19; shorthandedGoals=0; pim=0; opponentAbbrev=LAK; toi=16:05}, @{gameId=2023020290; gameTypeId=2; teamAbbrev=ANA; homeRoadFlag=H;
                      gameDate=2023-11-22; goals=0; assists=1; points=1; plusMinus=0; powerPlayGoals=0; shots=3; shifts=17; shorthandedGoals=0; pim=0; opponentAbbrev=MTL;
                      toi=16:02}, @{gameId=2023020271; gameTypeId=2; teamAbbrev=ANA; homeRoadFlag=H; gameDate=2023-11-19; goals=0; assists=0; points=0; plusMinus=0;
                      powerPlayGoals=0; shots=3; shifts=18; shorthandedGoals=0; pim=0; opponentAbbrev=STL; toi=17:12}, @{gameId=2023020240; gameTypeId=2; teamAbbrev=ANA;
                      homeRoadFlag=R; gameDate=2023-11-15; goals=0; assists=0; points=0; plusMinus=-2; powerPlayGoals=0; shots=0; shifts=22; shorthandedGoals=0; pim=0;
                      opponentAbbrev=COL; toi=17:44}…}
seasonTotals        : {@{season=20152016; gameTypeId=2; leagueAbbrev=WSI U12; teamName=; sequence=206766; gamesPlayed=6; goals=3; assists=1; points=4; pim=2}, @{season=20172018;    
                      gameTypeId=2; leagueAbbrev=U16 Div.1; teamName=; sequence=158274; gamesPlayed=15; goals=13; assists=14; points=27; pim=0}, @{season=20182019; gameTypeId=2;    
                      leagueAbbrev=U16 SM; teamName=; sequence=43127; gamesPlayed=3; goals=1; assists=0; points=1; pim=0}, @{season=20182019; gameTypeId=2; leagueAbbrev=U16
                      Region; teamName=; sequence=43472; gamesPlayed=19; goals=0; assists=10; points=10; pim=8}…}
currentTeamRoster   : {@{playerId=8484153; lastName=; firstName=; playerSlug=leo-carlsson-8484153}, @{playerId=8475842; lastName=; firstName=; playerSlug=sam-carrick-8475842},      
                      @{playerId=8480843; lastName=; firstName=; playerSlug=lukas-dostal-8480843}, @{playerId=8482142; lastName=; firstName=; playerSlug=jamie-drysdale-8482142}…} 
```
</details>

<details>
    <summary>Example return specific property</summary>

```
Get-Player -ID 8476459 | Select-Object -Property sweaterNumber

sweaterNumber
-------------
           93
```
</details>