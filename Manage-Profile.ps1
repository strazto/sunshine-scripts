<#

.SYNOPSIS
    Save the current DisplayMagician profile and apply a new one, or revert to the saved profile.

.DESCRIPTION
    - Save-AndSetProfile captures the current profile (Name|UUID) into “prev_profile.txt” next to this script and applies the given UUID.
    - Revert-Profile reads that file, extracts the UUID, and reverts to it.

    Usage:
      • To apply a new profile and save the old one:
          .\Manage-Profile.ps1 -Uuid <GUID>
      • To revert to the previously saved profile:
          .\Manage-Profile.ps1 -Undo

#>

#–– Configuration ––
$ExePath    = "C:\Program Files\DisplayMagician\DisplayMagicianConsole.exe"

# Save file path lives alongside this script
$SaveFile   = Join-Path -Path $PSScriptRoot -ChildPath "prev_profile.txt"

function Save-AndSetProfile {
    param(
        [Parameter(Mandatory)]
        [string]$Uuid
    )

    # 1. Capture current profile
    & "$ExePath" CurrentProfile -p |
        Out-File -FilePath $SaveFile -Encoding UTF8

    # 2. Apply the new profile
    & "$ExePath" ChangeProfile $Uuid
}

function Revert-Profile {
    # 1. Read saved line
    if (-Not (Test-Path $SaveFile)) {
        Write-Error "Save file '$SaveFile' not found."
        exit 1
    }
    $line = Get-Content -Path $SaveFile -TotalCount 1

    # 2. Parse UUID
    $parts = $line -split '\|'
    if ($parts.Length -ne 2) {
        Write-Error "Invalid format in '$SaveFile'. Expected 'Name|UUID'. Got: $line"
        exit 1
    }
    $oldUuid = $parts[1].Trim()

    # 3. Revert to saved profile
    & "$ExePath" ChangeProfile $oldUuid
}

#–– Entry point ––
param(
    [Parameter(ParameterSetName = 'Apply', Position = 0)]
    [string]$Uuid,

    [Parameter(ParameterSetName = 'Revert')]
    [switch]$Undo
)

switch ($PSCmdlet.ParameterSetName) {
    'Apply'  { Save-AndSetProfile -Uuid $Uuid }
    'Revert' { Revert-Profile }
    default  {
        Write-Error "Specify either -Uuid <GUID> to apply a new profile or -Undo to revert."
        exit 1
    }
}
