function Assert-Checksum {
  <#
    .SYNOPSIS
    Check checksum

    .DESCRIPTION
    Check the distribution file against a reference checksum file

    .PARAMETER Properties
    The properties parameter corresponds to the application configuration.

    .NOTES
    File name:      Assert-Checksum.ps1
    Author:         Florian Carrier
    Creation date:  14/12/2019
    Last modified:  16/12/2019
  #>
  [CmdletBinding (
    SupportsShouldProcess = $true
  )]
  Param (
    [Parameter (
      Position    = 1,
      Mandatory   = $true,
      HelpMessage = "List of properties"
    )]
    [ValidateNotNullOrEmpty ()]
    [System.Collections.Specialized.OrderedDictionary]
    $Properties
  )
  Begin {
    # Get global preference variables
    Get-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
    # Distibution source file
    $WildFlySource = Join-Path -Path $Properties.SrcDirectory -ChildPath $Properties.WildFlyDistribution
  }
  Process {
    Write-Log -Type "INFO" -Object "Checking distribution source files"
    if (-Not (Test-Object -Path $WildFlySource)) {
      Write-Log -Type "ERROR" -Object "Path not found $WildFlySource" -ExitCode 1
    }
    # Check filesum
    if ($Properties.ChecksumCheck -eq "true") {
      if (Test-Object -Path $Properties.ChecksumDirectory) {
        # Search for reference file in checksum local directory
        $FileHashName = $Properties.WildFlyDistribution + "." + (Format-String -String $Properties.ChecksumAlgorithm -Format "LowerCase")
        $FileHashPath = Join-Path -Path $Properties.ChecksumDirectory -ChildPath $FileHashName
        # If no packaged checksum file is found
        if (-Not (Test-Path -Path $FileHashPath)) {
          Write-Log -Type "DEBUG" -Object "No reference file found in $($Properties.ChecksumDirectory)"
          # Search for reference file in source directory
          $FileHashPath = Join-Path -Path $Properties.SrcDirectory -ChildPath $FileHashName
          if (-Not (Test-Path -Path $FileHashPath)) {
            Write-Log -Type "DEBUG" -Object "No reference file found in $($Properties.SrcDirectory)"
            Write-Log -Type "WARN"  -Object "No reference checksum file was found for WildFly version $($Properties.WildFlyVersion)"
            Write-Log -Type "ERROR" -Object "WildFly version $($Properties.WildFlyVersion) cannot be installed" -ExitCode 1
          }
        }
        # Get reference file hash
        Write-Log -Type "DEBUG" -Object $FileHashPath
        $ReferenceFileHash = Get-Content -Path $FileHashPath -Encoding "UTF8" -Raw
        Write-Log -Type "DEBUG" -Object "Reference checksum:`t`t`t`t$ReferenceFileHash"
        # Check that file is not corrupted
        $FileHash = Get-FileHash -Path $WildFlySource -Algorithm $Properties.ChecksumAlgorithm | Select-Object -ExpandProperty "Hash"
        Write-Log -Type "DEBUG" -Object "Distribution checksum:`t$FileHash"
        # /!\ Trim reference file hash to prevent formatting issues
        if ($FileHash -eq $ReferenceFileHash.Trim()) {
          Write-Log -Type "CHECK" -Object "Distribution file integrity check successful"
        } else {
          Write-Log -Type "ERROR" -Object "The distribution file is corrupted" -ExitCode 1
        }
      } else {
        Write-Log -Type "ERROR" -Object "Path not found $($Properties.ChecksumDirectory)" -ExitCode 1
      }
    } else {
      Write-Log -Type "WARN" -Object "Skipping source files integrity check"
    }
  }
}
