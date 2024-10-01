# Import module and force override if currently loaded
BeforeAll {
    Import-Module .\NHLPS\NHLPS.psd1 -Force
}

Describe 'Cache functions' {
    It 'Can load cache from public API' {
        $data = NHLPS\Get-TeamRoster -forceCacheReload
        $data.Count | Should -BeGreaterOrEqual 1
    }

    It 'Can load cache from generated file' {
        $content = Get-Content -Path ./.cache/NHLRoster.json | ConvertFrom-Json
        $content.cacheTime | Should -BeLessThan (Get-Date).AddMinutes(1)
    }

    It 'Can load cache using function' {
        $data = NHLPS\Get-CacheResults -fileName NHLRoster.json
        $data.Count | Should -BeGreaterOrEqual 1
    }
}

Describe 'Player functions' {
    Context 'Get-Player' {
        It 'Can load player using ID' {
            $player = NHLPS\Get-Player -ID 8484153
            $player[0].firstName.default | Should -Be "Leo"
            $player[0].lastName.default | Should -Be "Carlsson"
        }        
        
        It 'Can load player using firstName' {
            $player = NHLPS\Get-Player -firstName "Leo"
            $player[0].firstName.default | Should -Be "Leo"
        }

        It 'Can load player using lastName' {
            $player = NHLPS\Get-Player -lastName "Carlsson"
            $player[0].lastName.default | Should -Be "Carlsson"
        }
    }
}

# Describe 'Team functions' {
#     Context 'Get-Player' {
#         It 'Can load player using ID' {
#             $player = NHLPS\Get-Player -ID 8484153
#             $player.firstName.default | Should -Be "Leo"
#             $player.lastName.default | Should -Be "Carlsson"
#         }        
        
#         It 'Can load player using firstName' {
#             $player = NHLPS\Get-Player -firstName "Leo"
#             $player.firstName.default | Should -Be "Leo"
#         }

#         It 'Can load player using lastName' {
#             $player = NHLPS\Get-Player -lastName "Carlsson"
#             $player.lastName.default | Should -Be "Carlsson"
#         }
#     }
# }