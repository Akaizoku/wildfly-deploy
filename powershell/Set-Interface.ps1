function Set-Interface {
  <#
    .SYNOPSIS
    Configure interface

    .DESCRIPTION
    Configure addresses for a specified interface

    .PARAMETER Path
    The path parameter corresponds to the path to the configuration file.

    .PARAMETER Name
    The name parameter corresponds to the name of the interface to configure.

    .PARAMETER Address
    The address parameter corresponds to the list of addresses to add for the interface.

    .PARAMETER AnyAddress
    The any address switch enables all access for the interface.

    .NOTES
    File name:      Set-Interface.ps1
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
      HelpMessage = "Path to the configuration file"
    )]
    [ValidateNotNullOrEmpty ()]
    [String]
    $Path,
    [Parameter (
      Position    = 2,
      Mandatory   = $true,
      HelpMessage = "Name of the interface"
    )]
    [ValidateNotNUllOrEmpty ()]
    [String]
    $Name,
    [Parameter (
      Position    = 3,
      Mandatory   = $false,
      HelpMessage = "Address"
    )]
    [ValidateNotNUllOrEmpty ()]
    [String[]]
    $Address,
    [Parameter (
      HelpMessage = "Switch to enable any address"
    )]
    [Switch]
    $AnyAddress
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
        # Select interface node
        $XPath = '/server/interfaces/interface[@name="' + $Name + '"]'
        $InterfaceNode = Select-XMLNode -XML $XML -XPath $XPath
        # Configure interface
        if ($AnyAddress) {
          # Create new node with any address
          $NewAddressNode = $XML.CreateElement('any-address' , $XML.DocumentElement.NamespaceURI)
          Write-Log -Type "DEBUG" -Object "+ $($NewAddressNode.OuterXml)"
          # Remove all existing child nodes (and suppress output)
          foreach ($ChildNode in $InterfaceNode.ChildNodes) {
            Write-Log -Type "DEBUG" -Object "- $($ChildNode.OuterXml)"
            $InterfaceNode.RemoveChild($ChildNode) | Out-Null
          }
          # Add new address node (and suppress output)
          $InterfaceNode.AppendChild($NewAddressNode) | Out-Null
        } else {
          foreach ($Value in $Address) {
            # Create new node with new value
            $NewAddressNode = $XML.CreateElement('inet-address value="${jboss.bind.address:' + $Value + '}"' , $XML.DocumentElement.NamespaceURI)
            Write-Log -Type "DEBUG" -Object $NewAddressNode.OuterXml
            # Add new node (and suppress output)
            $InterfaceNode.AppendChild($NewAddressNode) | Out-Null
          }
          # Debug full configuration
          Write-Log -Type "DEBUG" -Object $InterfaceNode.OuterXml
        }
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
