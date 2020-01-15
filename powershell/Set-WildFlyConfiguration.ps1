function Set-WildFlyConfiguration {
  <#
    .SYNOPSIS
    Install WildFly

    .DESCRIPTION
    Install and configure a WildFly instance

    .PARAMETER Properties
    The properties parameter corresponds to the application configuration.

    .PARAMETER Unattended
    The unattended switch defines if the script should run in non-interactive mode.

    .NOTES
    File name:      Set-WildFlyConfiguration.ps1
    Author:         Florian Carrier
    Creation date:  09/01/2020
    Last modified:  09/01/2020
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
  }
  Process {
    # Set Java virtual machine (JVM) options
    $BinDirectory         = Join-Path -Path $Properties.JBossHomeDirectory  -ChildPath $Properties.WildFlyBinDirectory
    $JVMConfigurationFile = Join-Path -Path $BinDirectory                   -ChildPath $Properties.WSStandaloneConfig
    # Check path
    if (Test-Path -Path $JVMConfigurationFile) {
      Write-Log -Type "INFO" -Object "Configuring Java options"
      if (Set-JavaOptions -Path $JVMConfigurationFile -JavaOptions $JavaOptions) {
        Write-Log -Type "CHECK" -Object "Java options configured successfully"
      } else {
        Write-Log -Type "ERROR" -Object "Java options could not be configured" -ExitCode 1
      }
    } else {
      Write-Log -Type "ERROR" -Object "Standalone configuration file could not be located ($JVMConfigurationFile)" -ExitCode 1
    }
    # --------------------------------------------------------------------------
    # Configure interfaces
    Set-Interfaces -Properties $Properties
    # --------------------------------------------------------------------------
    # Configure ports
    Set-PortNumbers -Properties $Properties
    # --------------------------------------------------------------------------
    # Write-Log -Type "INFO" -Object "Configuring logging options"
    # TODO configure logging
  }
}
