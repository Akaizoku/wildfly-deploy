function Uninstall-WildFly {
  <#
    .SYNOPSIS
    Uninstall WildFly

    .DESCRIPTION
    Uninstall a WildFly instance

    .PARAMETER Properties
    The properties parameter corresponds to the application configuration.

    .PARAMETER Unattended
    The unattended switch defines if the script should run in non-interactive mode.

    .NOTES
    File name:      Uninstall-WildFly.ps1
    Author:         Florian Carrier
    Creation date:  15/12/2019
    Last modified:  10/02/2020
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
    $Properties,
    [Parameter (
      HelpMessage = "No interaction mode"
    )]
    [Switch]
    $Unattended
  )
  Begin {
    # Get global preference variables
    Get-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
    # Interactive mode
    $Attended = -Not $Unattended
  }
  Process {
    Write-Log -Type "INFO" -Object "Uninstallation of WildFly $($Properties.WildFlyVersion)"
    # --------------------------------------------------------------------------
    # Uninstall service
    Uninstall-WildFlyService -Properties $Properties -Unattended:$Unattended
    # --------------------------------------------------------------------------
    # Check environment variable
    if (Test-EnvironmentVariable -Variable $Properties.JBossHomeVariable -Scope $Properties.EnvironmentVariableScope) {
      $JBossHome = Get-EnvironmentVariable -Variable $Properties.JBossHomeVariable -Scope $Properties.EnvironmentVariableScope
      if (Test-Path -Path $JBossHome) {
        if ($JBossHome -ne $Properties.JBossHomeDirectory) {
          Write-Log -Type "WARN" -Object "The $($Properties.JBossHomeVariable) environment variable points to a different installation"
          $Confirm = Confirm-Prompt -Prompt "Do you also want to remove $JBossHome?"
          if ($Confirm -Or ($Properties.UseEnvironmentVariable -And $Unattended)) {
            # Clean-up files
            Write-Log -Type "INFO"  -Object "Removing files from $JBossHome"
            # TODO add catch if files are locked
            Start-Sleep -Seconds 1
            Remove-Item -Path $JBossHome -Recurse -Force -Confirm:$Attended -ErrorAction "SilentlyContinue" -ErrorVariable $RemoveErrors
            # Check errors
            if ($RemoveErrors) {
              foreach ($RemoveError in $RemoveErrors) {
                Write-Log -Type "DEBUG" -Object $RemoveError
              }
              Write-Log -Type "ERROR" -Object "Some files could not be removed"
              Write-Log -Type "WARN"  -Object "Please check and manually clear $JBossHome"
            }
            # Remove environment variable
            Write-Log -Type "INFO" -Object "Removing $($Properties.JBossHomeVariable) environment variable"
            Remove-EnvironmentVariable -Variable $Properties.JBossHomeVariable -Scope $Properties.EnvironmentVariableScope -Confirm:$Attended
          }
        } else {
          # Remove environment variable
          Write-Log -Type "INFO" -Object "Removing $($Properties.JBossHomeVariable) environment variable"
          Remove-EnvironmentVariable -Variable $Properties.JBossHomeVariable -Scope $Properties.EnvironmentVariableScope -Confirm:$Attended
        }
      } else {
        Write-Log -Type "WARN" -Object "$($Properties.JBossHomeVariable) path not found $JBossHome"
        if ($Attended) {
          $Delete = Confirm-Prompt -Prompt "Do you want to remove the $Properties.JBossHomeVariable environment variable?"
        }
        if ($Unattended -Or $Delete) {
          Write-Log -Type "INFO" -Object "Removing $($Properties.JBossHomeVariable) environment variable"
          Remove-EnvironmentVariable -Variable $Properties.JBossHomeVariable -Scope $Properties.EnvironmentVariableScope
        }
      }
    } else {
      Write-Log -Type "INFO" -Object "$($Properties.JBossHomeVariable) environment variable is not defined"
    }
    # --------------------------------------------------------------------------
    # Clean-up install location from configuration file
    if (Test-Path -Path $Properties.JBossHomeDirectory) {
      # Clean-up files
      Write-Log -Type "INFO"  -Object "Removing WildFly files"
      Write-Log -Type "DEBUG" -Object $Properties.JBossHomeDirectory
      # TODO add catch if files are locked
      Start-Sleep -Seconds 3
      Remove-Item -Path $Properties.JBossHomeDirectory -Recurse -Force -Confirm:$Attended -ErrorAction "SilentlyContinue" -ErrorVariable $RemoveErrors
      # Check errors
      if ($RemoveErrors -Or $Error) {
        # Output caught errors
        foreach ($RemoveError in $RemoveErrors) {
          Write-Log -Type "DEBUG" -Object $RemoveError
        }
        # Output uncaught errors
        foreach ($UncaughtError in $Error) {
          Write-Log -Type "DEBUG" -Object $UncaughtError
        }
        Write-Log -Type "ERROR" -Object "Some files could not be removed"
        Write-Log -Type "WARN"  -Object "Please check and manually clear $JBossHome"
      }
    }
    # --------------------------------------------------------------------------
    # Clean-up parent installation path
    if (Test-Path -Path $Properties.InstallationPath) {
      $RemainingContent = Get-ChildItem -Path $Properties.InstallationPath
      if ($RemainingContent.Count -eq 0) {
        Write-Log -Type "INFO"  -Object "Cleaning-up installation path"
        Write-Log -Type "DEBUG" -Object $Properties.InstallationPath
        Remove-Item -Path $Properties.InstallationPath -Recurse -Force -Confirm:$Attended
      }
    }
    # --------------------------------------------------------------------------
    Write-Log -Type "CHECK" -Object "WildFly $($Properties.WildFlyVersion) uninstallation complete"
  }
}
