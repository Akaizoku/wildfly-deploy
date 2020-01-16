function Invoke-RestartWildFly {
  <#
    .SYNOPSIS
    Restart WildFly

    .DESCRIPTION
    Restart a WildFly instance

    .PARAMETER Properties
    The properties parameter corresponds to the application configuration.

    .PARAMETER Unattended
    The unattended switch defines if the script should run in non-interactive mode.

    .NOTES
    File name:      Invoke-RestartWildFly.ps1
    Author:         Florian Carrier
    Creation date:  16/01/2020
    Last modified:  16/01/2020
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
    # --------------------------------------------------------------------------
    # Check if service is defined
    if (-Not (Test-Service -Service $Properties.ServiceName)) {
      Write-Log -Type "ERROR" -Object "WildFly Windows service ""$($Properties.ServiceName)"" could not be found" -ExitCode 1
    }
    # --------------------------------------------------------------------------
    Write-Log -Type "INFO" -Object "Restarting WildFly"
    Restart-Service -Name $Properties.ServiceName -Confirm:$Attended
    # --------------------------------------------------------------------------
    Write-Log -Type "CHECK" -Object "WildFly restart complete"
  }
}
