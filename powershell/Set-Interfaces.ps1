function Set-Interfaces {
  <#
    .SYNOPSIS
    Configure WildFly interfaces

    .DESCRIPTION
    Configure interfaces for WildFly

    .PARAMETER Properties
    The properties parameter corressponds to the application configuration.

    .NOTES
    File name:      Set-Interfaces.ps1
    Author:         Florian Carrier
    Creation date:  15/10/2019
    Last modified:  15/01/2020
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
    # --------------------------------------------------------------------------
    # Configuration file
    $ConfigDirectory  = Join-Path -Path $Properties.JBossHomeDirectory  -ChildPath $Properties.WSConfigDirectory
    $StandaloneXML    = Join-Path -Path $ConfigDirectory                -ChildPath $Properties.WSStandaloneXML
    # Check path
    if (-Not (Test-Path -Path $StandaloneXML)) {
      Write-Log -Type "ERROR" -Object "XML configuration file could not be located ($StandaloneXML)" -ExitCode 1
    }
    # --------------------------------------------------------------------------
    # Interfaces nodes
    $Interfaces = @("management", "public")
    # Placeholder success variable
    $Success = $true
  }
  Process {
    Write-Log -Type "INFO" -Object "Configuring interfaces"
    foreach ($Interface in $Interfaces) {
      Write-Log -Type "INFO" -Object "Configuring addresses for $Interface interface"
      if (Set-Interface -Path $StandaloneXML -Name $Interface -AnyAddress) {
        # Write-Log -Type "DEBUG" -Object "Interface ""$Interface"" configured successfully"
      } else {
        Write-Log -Type "WARN" -Object "Interface ""$Interface"" could not be configured"
        $Success = $false
      }
    }
  }
  End {
    # Check outcome
    if ($Success) {
      Write-Log -Type "CHECK" -Object "Interfaces configured successfully"
    } else {
      Write-Log -Type "ERROR" -Object "Interfaces could not be configured" -ExitCode 1
    }
  }
}
