function Install-WildFlyService {
  <#
    .SYNOPSIS
    Install WildFly service

    .DESCRIPTION
    Install and configure a WildFly instance as a Windows service

    .PARAMETER Properties
    The properties parameter corresponds to the application configuration.

    .PARAMETER Unattended
    The unattended switch defines if the script should run in non-interactive mode.

    .NOTES
    File name:      Install-WildFlyService.ps1
    Author:         Florian Carrier
    Creation date:  16/12/2019
    Last modified:  10/01/2020
    TODO            Add check for version < 10
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
    Write-Log -Type "INFO" -Object "Configuring WildFly service"
    # Setup service files
    $ServiceSource = Join-Path -Path $Properties.JBossHomeDirectory -ChildPath $Properties.ServiceDirectory
    $ServiceTarget = Join-Path -Path $Properties.JBossHomeDirectory -ChildPath $Properties.WildFlyBinDirectory
    Write-Log -Type "DEBUG" -Object "Copy files from $ServiceSource to $ServiceTarget"
    Copy-Item -Path $ServiceSource -Destination $ServiceTarget -Recurse -Force
    # Update configuration
    $ServiceLeaf              = Split-Path  -Path $ServiceSource -Leaf
    $ServiceConfigurationFile = Join-Path   -Path $Properties.JBossHomeDirectory -ChildPath $Properties.WSServiceScript
    $ServiceConfiguration     = Get-Content -Path $ServiceConfigurationFile
    # Select first line of configuration
    $StartingLine = $ServiceConfiguration | Select-String -Pattern 'rem defaults'   | Select-Object -ExpandProperty "LineNumber"
    # Select first line of next section
    $EndingLine   = $ServiceConfiguration | Select-String -Pattern 'set COMMAND=%1' | Select-Object -ExpandProperty "LineNumber"
    # Identify the lines in scope
    $LineNumbers = New-Object -TypeName "System.Collections.ArrayList"
    for ($i = $StartingLine; $i -lt $EndingLine - 1; $i++) {
      # Write-Log -Type "DEBUG" -Object $i
      [Void]$LineNumbers.Add($i)
    }
    $Content  = $ServiceConfiguration | Select-Object -Index $LineNumbers
    $Index    = 0
    # Loop through each line of configuration
    foreach ($Line in $Content) {
      if ($Line.StartsWith("set ")) {
        $Config   = $Line.Split("=")
        $Property = $Config[0].Replace('set ', '')
        if ($ServiceProperties.$Property) {
          if ($ServiceProperties.$Property -ne $null) {
            $NewConfig = "set $($Property)=$($ServiceProperties.$Property)"
            # Update configuration
            $ServiceConfiguration[$LineNumbers[$Index]] = $NewConfig
          } elseif (($Properties.WildFlyVersion -eq "10.1.0.Final") -And ($Property -eq "DESCRIPTION")) {
            # Fix WildFly 10.1.0 service description bug (https://issues.jboss.org/browse/WFCORE-1719)
            $Value =$Config[1].Replace('"', '')
            $NewConfig = "set $Property=$Value"
            # Update configuration
            $ServiceConfiguration[$LineNumbers[$Index]] = $NewConfig
          }
        }
      }
      # New configuration with line number
      Write-Log -Type "DEBUG" -Object "$($LineNumbers[$Index])`t$($ServiceConfiguration[$LineNumbers[$Index]])"
      # Increment index
      $Index++
    }
    # Overwrite default configuration
    Set-Content -Path $ServiceConfigurationFile -Value $ServiceConfiguration -Force
    # --------------------------------------------------------------------------
    # Install service
    # --------------------------------------------------------------------------
    Write-Log -Type "INFO" -Object "Installing WildFly service"
    # Use quotes to manage paths with spaces
    $InstallCommand = "cmd.exe /c ""$ServiceConfigurationFile"" install"
    # Workaround to fix STARTUP_MODE issue
    if ($ServiceProperties.STARTUP_MODE -eq $true) {
      $InstallCommand = $InstallCommand + " /startup"
    }
    if ($Attended) {
      $Confirmation = Confirm-Prompt -Prompt "Do you want to proceed with the installation of the WildFly service?"
    }
    if ($Unattended -Or $Confirmation) {
      Write-Log -Type "DEBUG" -Object $InstallCommand
      $ServiceInstallation = Invoke-Expression -Command $InstallCommand | Out-String
      Write-Log -Type "DEBUG" -Object $ServiceInstallation
      # TODO Check outcome
    } else {
      Write-Log -Type "WARN"  -Object "The installation of the WildFly service was cancelled by the user"
      Write-Log -Type "ERROR" -Object "The installation of WildFly cannot be completed without installing the service" -ExitCode 1
    }
  }
}
