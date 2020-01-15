function Invoke-ConfigureWildFly {
  <#
    .SYNOPSIS
    Configure WildFly

    .DESCRIPTION
    Configure a WildFly instance

    .PARAMETER Properties
    The properties parameter corresponds to the application configuration.

    .PARAMETER Unattended
    The unattended switch defines if the script should run in non-interactive mode.

    .NOTES
    File name:      Invoke-ConfigureWildFly.ps1
    Author:         Florian Carrier
    Creation date:  10/01/2020
    Last modified:  10/01/2020
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
    # Role-based access control model switch
    if ($Properties.EnableRBAC -eq "true") {
      $EnableRBAC = $true
    } else {
      $EnableRBAC = $false
    }
  }
  Process {
    # Check that WildFly is installed
    if (-Not (Test-Path -Path $Properties.JBossHomeDirectory)) {
      Write-Log -Type "WARN" -Object "Path not found $($Properties.JBossHomeDirectory)"
      # Check if JBOSS_HOME environment variable is defined
      if (Test-EnvironmentVariable -Name $Properties.JBossHome -Scope $Properties.EnvironmentVariableScope) {
        $JBossHome = Get-EnvironmentVariable -Name $Properties.JBossHome -Scope $Properties.EnvironmentVariableScope
        # Check that JBOSS_HOME path is valid
        if (Test-Path -Path $JBossHome) {
          Write-Log -Type "WARN" -Object "Using $($Properties.JBossHome) environment variable"
          $Properties.JBossHomeDirectory = $JBossHome
        } else {
          Write-Log -Type "WARN" -Object "$($Properties.JBossHome) environment variable points to an invalid location"
          if ($Attended) {
            $Confirm = Confirm-Prompt -Prompt "Do you want to remove the deprecated $($Properties.JBossHome) environment variable?"
          }
          # Remove JBOSS_HOME environment variable
          if ($Confirm -Or $Unattended) {
            Remove-EnvironmentVariable -Name $Properties.JBossHome -Scope $Properties.EnvironmentVariableScope
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
    # Check if service is defined
    if (-Not (Test-Service -Service $Properties.ServiceName)) {
      Write-Log -Type "ERROR" -Object "WildFly Windows service ""$($Properties.ServiceName)"" could not be found" -ExitCode 1
    }
    # --------------------------------------------------------------------------
    Write-Log -Type "INFO" -Object "Configuration of WildFly $($Properties.WildFlyVersion)"
    # Check service status
    $ServiceStatus = Get-Service -Name $Properties.ServiceName | Select-Object -ExpandProperty "Status"
    # Stop service if running
    if ($ServiceStatus -eq "Running") {
      Write-Log -Type "INFO" -Object "Stopping WildFly"
      Stop-Service -Name $Properties.ServiceName -Force -Confirm:$Attended
    }
    # Configure WildFly
    Set-WildFlyConfiguration -Properties $Properties -Unattended:$Unattended
    # --------------------------------------------------------------------------
    # Restart service to apply changes
    Write-Log -Type "DEBUG" -Object "Re-starting WildFly"
    Restart-Service -Name $Properties.ServiceName -Confirm:$Attended
    # Wait for web-server to come back up
    # Get admin credentials
    $AdminCredentials = Get-AdminCredentials -Properties $Properties -Unattended:$Unattended
    $Running = Wait-WildFly -Path $Properties.JBossCli -Controller $Properties.Controller -Credentials $AdminCredentials -TimeOut 60 -RetryInterval 1
    if (-Not $Running) {
      Write-Log -Type "ERROR" -Object "Timeout. $($WebServer.Name) could not be restarted" -ExitCode 1
    }
    # --------------------------------------------------------------------------
    # Configure security
    Set-SecurityModel -JBossHome $Properties.JBossHomeDirectory -Controller $Properties.Controller -Credentials $AdminCredentials -RBAC:$EnableRBAC
    # --------------------------------------------------------------------------
    Write-Log -Type "INFO" -Object "Re-starting WildFly"
    # WARNING Wait 3 seconds to prevent issue causing WildFly service start operation to fail when WildFly is still loading in the background
    Start-Sleep -Seconds 3
    # Restart service
    Restart-Service -Name $Properties.ServiceName -Confirm:$Attended
    # --------------------------------------------------------------------------
    Write-Log -Type "CHECK" -Object "WildFly $($Properties.WildFlyVersion) configuration complete"
  }
}
