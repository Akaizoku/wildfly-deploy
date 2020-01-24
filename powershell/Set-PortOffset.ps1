function Set-PortOffset {
  <#
    .SYNOPSIS
    Configure port offset

    .DESCRIPTION
    Configure port offset for all sockets

    .PARAMETER Path
    The path parameter corresponds to the path to the configuration file.

    .PARAMETER Group
    The group parameter corresponds to the name of the socket binding group to configure.

    .PARAMETER Value
    The value parameter corresponds to offset number to configure.

    .NOTES
    File name:      Set-PortOffset.ps1
    Author:         Florian Carrier
    Creation date:  12/12/2019
    Last modified:  12/12/2019
  #>
  [CmdletBinding (
    SupportsShouldProcess = $true
  )]
  Param (
    [Parameter (
      Position    = 1,
      Mandatory   = $true,
      HelpMessage = "Path to the configuration file"
    )]
    [ValidateNotNullOrEmpty ()]
    [String]
    $Path,
    [Parameter (
      Position    = 2,
      Mandatory   = $false,
      HelpMessage = "Socket binding group"
    )]
    [ValidateNotNUllOrEmpty ()]
    [String]
    $Group = 'standard-sockets',
    [Parameter (
      Position    = 3,
      Mandatory   = $true,
      HelpMessage = "Port offset value"
    )]
    [ValidateNotNUllOrEmpty ()]
    [Alias ("Offset")]
    [String]
    $Value
  )
  Begin {
    # Get global preference variables
    Get-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
  }
  Process {
    # Check path
    if (Test-Path -Path $Path) {
      try {
        # Load XML content
        $XML = New-Object -TypeName "System.XML.XMLDocument"
        $XML.Load($Path)
        # Select socket binding group node
        $XPath = '/server/socket-binding-group[@name=''' + $Group + ''']'
        $SocketGroupNode = Select-XMLNode -XML $XML -XPath $XPath
        # Define port offset attribute
        $PortOffset = '${jboss.socket.binding.port-offset:' + $Value + '}'
        Write-Log -Type "DEBUG" -Object $PortOffset
        # Set port offset
        $SocketGroupNode.SetAttribute("port-offset", $PortOffset)
        # Save updated XML file
        $XML.Save($Path)
        return $true
      } catch {
        if ($Error[0].Exception) {
          Write-Log -Type "DEBUG" -Object "$($Error[0].Exception)"
        } else {
          Write-Log -Type "DEBUG" -Object "An unknown error occurred"
        }
        return $false
      }
    } else {
      Write-Log -Type "DEBUG" -Object "Path not found $Path"
      return $false
    }
  }
}
