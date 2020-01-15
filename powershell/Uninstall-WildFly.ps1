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
    Last modified:  13/01/2020
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
      $JBossHomeVariable = Get-EnvironmentVariable -Variable $Properties.JBossHomeVariable -Scope $Properties.EnvironmentVariableScope
      if (Test-Path -Path $JBossHomeVariable) {
        if ($JBossHomeVariable -ne $Properties.JBossHomeDirectory) {
          Write-Log -Type "WARN" -Object "The $($Properties.JBossHome) environment variable points to a different installation"
          $Confirm = Confirm-Prompt -Prompt "Do you also want to remove $JBossHomeVariable?"
          if ($Confirm -Or ($Properties.UseEnvironmentVariable -And $Unattended)) {
            # Clean-up files
            Write-Log -Type "INFO"  -Object "Removing files from $JBossHomeVariable"
            Write-Log -Type "DEBUG" -Object $JBossHomeVariable
            # TODO add catch if files are locked
            Start-Sleep -Seconds 1
            Remove-Item -Path $JBossHomeVariable -Recurse -Force -Confirm:$Attended -ErrorVariable $RemoveErrors
            # Check errors
            if ($RemoveErrors) {
              foreach ($RemoveError in $RemoveErrors) {
                Write-Log -Type "DEBUG" -Object $RemoveError
              }
              Write-Log -Type "ERROR" -Object "Some files could not be removed"
              Write-Log -Type "WARN"  -Object "Please check and manually clear $JBossHome"
            }
            # Remove environment variable
            Write-Log -Type "INFO" -Object "Removing $($Properties.JBossHome) environment variable"
            Remove-EnvironmentVariable -Variable $Properties.JBossHomeVariable -Scope $Properties.EnvironmentVariableScope -Confirm:$Attended
          }
        } else {
          # Remove environment variable
          Write-Log -Type "INFO" -Object "Removing $($Properties.JBossHome) environment variable"
          Remove-EnvironmentVariable -Variable $Properties.JBossHomeVariable -Scope $Properties.EnvironmentVariableScope -Confirm:$Attended
        }
      } else {
        Write-Log -Type "WARN" -Object "$($Properties.JBossHome) path not found $JBossHomeVariable"
        if ($Attended) {
          $Delete = Confirm-Prompt -Prompt "Do you want to remove the $Properties.JBossHomeVariable environment variable?"
        }
        if ($Unattended -Or $Delete) {
          Write-Log -Type "INFO" -Object "Removing $($Properties.JBossHome) environment variable"
          Remove-EnvironmentVariable -Variable $Properties.JBossHomeVariable -Scope $Properties.EnvironmentVariableScope
        }
      }
    } else {
      Write-Log -Type "INFO" -Object "$($Properties.JBossHome) environment variable is not defined"
    }
    # ------------------------------------------------------------------------
    # Clean-up install location from configuration file
    if (Test-Path -Path $Properties.JBossHomeDirectory) {
      # Clean-up files
      Write-Log -Type "INFO"  -Object "Removing WildFly files"
      Write-Log -Type "DEBUG" -Object $Properties.JBossHomeDirectory
      # TODO add catch if files are locked
      Start-Sleep -Seconds 1
      Remove-Item -Path $Properties.JBossHomeDirectory -Recurse -Force -Confirm:$Attended -ErrorVariable $RemoveErrors
      # Check errors
      if ($RemoveErrors) {
        foreach ($RemoveError in $RemoveErrors) {
          Write-Log -Type "DEBUG" -Object $RemoveError
        }
        Write-Log -Type "ERROR" -Object "Some files could not be removed"
        Write-Log -Type "WARN"  -Object "Please check and manually clear $JBossHome"
      }
    }
    Write-Log -Type "CHECK" -Object "WildFly $($Properties.WildFlyVersion) uninstallation complete"
  }
}
