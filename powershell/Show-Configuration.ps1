function Show-Configuration {
  <#
    .SYNOPSIS
    Show configuration

    .DESCRIPTION
    Display the configuration of the WildFly deployment utility

    .PARAMETER Properties
    The properties parameter corresponds to the application configuration.

    .PARAMETER ServiceProperties
    The service properties parameter corresponds to the configuration of the service.

    .PARAMETER JavaOptions
    The Java options parameter corresponds to the configuration of the Java Virtual Machine (JVM).

    .NOTES
    File name:      Show-Configuration.ps1
    Author:         Florian Carrier
    Creation date:  16/01/2020
    Last modified:  17/01/2020
  #>
  [CmdletBinding (
    SupportsShouldProcess = $true
  )]
  Param (
    [Parameter (
      Position    = 1,
      Mandatory   = $true,
      HelpMessage = "Script configuration"
    )]
    [ValidateNotNullOrEmpty ()]
    [System.Collections.Specialized.OrderedDictionary]
    $Properties,
    [Parameter (
      Position    = 2,
      Mandatory   = $true,
      HelpMessage = "Service configuration"
    )]
    [ValidateNotNullOrEmpty ()]
    [System.Collections.Specialized.OrderedDictionary]
    $ServiceProperties,
    [Parameter (
      Position    = 3,
      Mandatory   = $true,
      HelpMessage = "Java options"
    )]
    [ValidateNotNullOrEmpty ()]
    [String]
    $JavaOptions
  )
  Begin {
    # Get global preference variables
    Get-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
    # Display colour
    $Colour = "Cyan"
  }
  Process {
    # Display default x custom script configuration
    Write-Log -Type "INFO" -Object "Script configuration"
    Write-Host -Object ($Properties | Out-String).Trim() -ForegroundColor $Colour
    # Display service configuration
    Write-Log -Type "INFO" -Object "Service configuration"
    Write-Host -Object ($ServiceProperties | Out-String).Trim() -ForegroundColor $Colour
    # Display JVM configuration
    Write-Log -Type "INFO" -Object "Java options"
    Write-Host -Object ($JavaOptions | Out-String).Trim() -ForegroundColor $Colour
  }
}
