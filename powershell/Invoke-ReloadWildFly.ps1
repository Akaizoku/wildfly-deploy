function Invoke-ReloadWildFly {
  <#
    .SYNOPSIS
    Reload WildFly

    .DESCRIPTION
    Reload a WildFly instance

    .PARAMETER Properties
    The properties parameter corresponds to the application configuration.

    .PARAMETER Unattended
    The unattended switch defines if the script should run in non-interactive mode.

    .NOTES
    File name:      Invoke-ReloadWildFly.ps1
    Author:         Florian Carrier
    Creation date:  16/01/2020
    Last modified:  16/01/2020
    TODO            Handle exception "WFLYCTL0343: The service container has been destabilized by a previous operation and further runtime updates cannot be processed. Restart is required."
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
    # Define number of reties
    $RetryCount = 3
  }
  Process {
    # Check that WildFly is installed
    if (-Not (Test-Path -Path $Properties.JBossHomeDirectory)) {
      Write-Log -Type "WARN" -Object "Path not found $($Properties.JBossHomeDirectory)"
      # Check if JBOSS_HOME environment variable is defined
      if (Test-EnvironmentVariable -Name $Properties.JBossHomeVariable -Scope $Properties.EnvironmentVariableScope) {
        $JBossHome = Get-EnvironmentVariable -Name $Properties.JBossHomeVariable -Scope $Properties.EnvironmentVariableScope
        # Check that JBOSS_HOME path is valid
        if (Test-Path -Path $JBossHome) {
          Write-Log -Type "WARN" -Object "Using $($Properties.JBossHome) environment variable"
          $Properties.JBossHomeDirectory  = $JBossHome
          $Properties.JBossClient         = Join-Path -Path $Properties.JBossHomeDirectory -ChildPath "/bin/jboss-cli.ps1"
        } else {
          Write-Log -Type "WARN" -Object "$($Properties.JBossHome) environment variable points to an invalid location"
          if ($Attended) {
            $Confirm = Confirm-Prompt -Prompt "Do you want to remove the deprecated $($Properties.JBossHome) environment variable?"
          }
          # Remove JBOSS_HOME environment variable
          if ($Confirm -Or $Unattended) {
            Remove-EnvironmentVariable -Name $Properties.JBossHomeVariable -Scope $Properties.EnvironmentVariableScope
          }
          # Stop process
          Write-Log -Type "ERROR" -Object "No installation of WildFly was detected" -ExitCode 1
        }
      } else {
        # Stop process
        Write-Log -Type "ERROR" -Object "No installation of WildFly was detected" -ExitCode 1
      }
    }
    # --------------------------------------------------------------------------
    Write-Log -Type "INFO" -Object "Reloading WildFly"
    # Get admin credentials
    $AdminCredentials = Get-AdminCredentials -Properties $Properties -Unattended:$Unattended
    for ($i=0; $i -le $RetryCount; $i++) {
      # Reload server
      $Reload = Invoke-ReloadServer -Path $Properties.JBossClient -Controller $Properties.Controller -Credentials $AdminCredentials
      # Check outcome
      if (-Not (Test-JBossClientOutcome -Log $Reload)) {
        # Check if java.util.concurrent.CancellationException
        if (Select-String -InputObject $Reload -Pattern "java.util.concurrent.CancellationException" -SimpleMatch -Quiet) {
          # Wait and try again
          Start-Sleep -Seconds 1
        } else {
          Write-Log -Type "WARN"  -Object "WildFly could not be reloaded"
          Write-Log -Type "ERROR" -Object $Reload -ExitCode 1
        }
      } else {
        # Wait for web-server to come back up
        $Running = Wait-WildFly -Path $Properties.JBossClient -Controller $Properties.Controller -Credentials $AdminCredentials -TimeOut 300 -RetryInterval 1
        if (-Not $Running) {
          Write-Log -Type "ERROR" -Object "WildFly failed to come back up" -ExitCode 1
        }
        break
      }
    }
    # --------------------------------------------------------------------------
    Write-Log -Type "CHECK" -Object "WildFly reload complete"
  }
}
