function Set-PortNumbers {
  <#
    .SYNOPSIS
    Configure WildFly ports

    .DESCRIPTION
    Configure port numbers for WildFly interfaces

    .PARAMETER Properties
    The properties parameter corresponds to the application configuration.

    .NOTES
    File name:      Set-PortNumbers.ps1
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
    # Define sockets to configure
    $Sockets = [Ordered]@{
      "ajp"                     = $Properties.AJPConnectorPort
      "http"                    = $Properties.HTTPPort
      "https"                   = $Properties.HTTPSPort
      "management-http"         = $Properties.HTTPManagementPort
      "management-https"        = $Properties.HTTPManagementPort
      "txn-recovery-environment"= $Properties.TXNRecoveryPort
      "txn-status-manager"      = $Properties.TXNStatusPort
    }
    # Placeholder success variable
    $Success = $true
  }
  Process {
    Write-Log -Type "INFO" -Object "Configuring ports"
    # --------------------------------------------------------------------------
    # Set port offset
    Write-Log -Type "INFO" -Object "Configuring standard socket port offset"
    if (Set-PortOffset -Path $StandaloneXML -Group 'standard-sockets' -Value $Properties.PortOffset) {
      # Write-Log -Type "CHECK" -Object "Standard socket port offset configured successfully"
    } else {
      Write-Log -Type "ERROR" -Object "Standard socket port offset could not be configured" -ExitCode 1
    }
    # --------------------------------------------------------------------------
    # Loop through sockets
    foreach ($Socket in $Sockets.GetEnumerator()) {
      # Set port number
      Write-Log -Type "INFO" -Object "Configuring $($Socket.Name) socket"
      if (Set-PortNumber -Path $StandaloneXML -Name $Socket.Name -Value $Socket.Value) {
        # Write-Log -Type "CHECK" -Object "Socket ""$($Socket.Name)"" configured successfully"
      } else {
        Write-Log -Type "WARN" -Object "Socket ""$($Socket.Name)"" could not be configured"
        $Success = $false
      }
    }
  }
  End {
    # Check outcome
    if ($Success) {
      Write-Log -Type "CHECK" -Object "Port numbers configured successfully"
    } else {
      Write-Log -Type "ERROR" -Object "Port numbers could not be configured" -ExitCode 1
    }
  }
}
