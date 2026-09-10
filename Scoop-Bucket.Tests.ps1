if (!$env:SCOOP_HOME) { $env:SCOOP_HOME = Resolve-Path (scoop prefix scoop) }

# Keep upstream syntax and style checks for the whole repository.
. "$env:SCOOP_HOME\test\Scoop-00File.Tests.ps1" -TestPath $PSScriptRoot

# Do not use Import-Bucket-Tests.ps1's CI changed-file discovery: BuildHelpers
# resolves the Git root and can return non-manifest JSON outside bucket/.
Describe 'Manifest validates against the schema' {
    BeforeDiscovery {
        $manifestFiles = @(Get-ChildItem "$PSScriptRoot/bucket" -Filter '*.json' -File -Recurse |
            ForEach-Object { @{ ManifestPath = $_.FullName } })
    }
    BeforeAll {
        Add-Type -Path "$env:SCOOP_HOME/supporting/validator/bin/Scoop.Validator.dll"
        $validator = New-Object Scoop.Validator("$env:SCOOP_HOME/schema.json", $true)
    }
    It '<ManifestPath>' -ForEach $manifestFiles {
        # Fail on validation errors (including quota errors) rather than silently
        # passing a run in which some manifests were never validated.
        $validator.Validate($ManifestPath)
        if ($validator.Errors.Count -gt 0) {
            Write-Host "  [-] $ManifestPath has $($validator.Errors.Count) Errors!"
            Write-Host $validator.ErrorsAsString -ForegroundColor Yellow
        }
        $validator.Errors.Count | Should -Be 0
    }
}
