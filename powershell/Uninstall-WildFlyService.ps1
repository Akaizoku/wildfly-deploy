function Uninstall-WildFlyService {
  <#
    .SYNOPSIS
    Uninstall WildFly service

    .DESCRIPTION
    Uninstall the Windows service of a WildFly instance

    .PARAMETER Properties
    The properties parameter corresponds to the application configuration.

    .PARAMETER Unattended
    The unattended switch defines if the script should run in non-interactive mode.

    .NOTES
    File name:      Uninstall-WildFlyService.ps1
    Author:         Florian Carrier
    Creation date:  17/12/2019
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
  }
  Process {
    # Check if service is defined
    if (Test-Service -Service $Properties.ServiceName) {
      $ServiceStatus = Get-Service -Name $Properties.ServiceName | Select-Object -ExpandProperty "Status"
      # Stop service if running
      if ($ServiceStatus -eq "Running") {
        Write-Log -Type "INFO" -Object "Stopping WildFly"
        Stop-Service -Name $Properties.ServiceName
      }
      # ------------------------------------------------------------------------
      # Uninstall service
      # ------------------------------------------------------------------------
      Write-Log -Type "INFO" -Object "Uninstalling WildFly service ($($Properties.ServiceName))"
      if ($Attended) {
        $Confirmation = Confirm-Prompt -Prompt "Do you want to remove the WildFly service ($($Properties.ServiceName))?"
      }
      if ($Unattended -Or $Confirmation) {
        $ServiceConfigurationFile = Join-Path -Path $Properties.JBossHomeDirectory -ChildPath $Properties.WSServiceScript
        # Use quotes to manage paths with spaces
        $UninstallCommand = "cmd.exe /c ""$ServiceConfigurationFile"" uninstall"
        Write-Log -Type "DEBUG" -Object $UninstallCommand
        $ServiceUninstallation = Invoke-Expression -Command $UninstallCommand | Out-String
        Write-Log -Type "DEBUG" -Object $ServiceUninstallation
        # TODO Check outcome
        # ----------------------------------------------------------------------
        # Back-up force removal command
        # ----------------------------------------------------------------------
        # $Uninstall = Invoke-Command -ScriptBlock { sc.exe delete $Properties.ServiceName }
        # if (Select-String -InputObject $Uninstall -Pattern "SUCCESS") {
        #   Write-Log -Type "CHECK" -Object "WildFly service successfully uninstalled"
        # } else {
        #   Write-Log -Type "WARN" -Object "An error occured when uninstalling WildFly service"
        # }
      } else {
        Write-Log -Type "WARN" -Object "The uninstallation of the WildFly service was cancelled by the user"
      }
    } else {
        Write-Log -Type "INFO" -Object "WildFly is not installed as a service"
    }
  }
}
