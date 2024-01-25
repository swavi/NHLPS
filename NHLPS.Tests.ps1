BeforeAll {
    function Get-Planet ([string]$Name = '*') {
        $planets = @(
            @{ Name = 'Mercury' }
            @{ Name = 'Venus'   }
            @{ Name = 'Earth'   }
            @{ Name = 'Mars'    }
            @{ Name = 'Jupiter' }
            @{ Name = 'Saturn'  }
            @{ Name = 'Uranus'  }
            @{ Name = 'Neptune' }
        ) | ForEach-Object { [PSCustomObject] $_ }

        $planets | Where-Object { $_.Name -like $Name }
    }
}

Describe 'Get-Planet' {
    It 'Given no parameters, it lists all 8 planets' {
        $allPlanets = Get-Planet
        $allPlanets.Count | Should -Be 8
    }
}

Describe 'Get-Planet' {
    Context 'no parameters' {
        It 'Earth Bruh' {
            $allPlanets = Get-Planet
            $allPlanets[2].Name | Should -Be 'Earth'
        }    
        It 'Earth Bruh' {
            $allPlanets = Get-Planet
            $allPlanets[2].Name | Should -Be 'Earth'
        }
    }
    Context 'Keyed tests' {
        It '3 should be Mars' {
            $allPlanets = Get-Planet
            $allPlanets[3].Name | Should -Be 'Mars'
        }
    }
}