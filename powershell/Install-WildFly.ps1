function Install-WildFly {
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
    File name:      Install-WildFly.ps1
    Author:         Florian Carrier
    Creation date:  14/12/2019
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
    # JBoss client path
    $JBossClient = Join-Path -Path $Properties.JBossHomeDirectory -ChildPath "bin\jboss-cli.ps1"
  }
  Process {
    Write-Log -Type "INFO" -Object "Installation of WildFly $($Properties.WildFlyVersion)"
    # Check if JAVA_HOME is set
    if (Test-EnvironmentVariable -Variable $Properties.JavaHomeVariable -Scope $Properties.EnvironmentVariableScope) {
      # Check if Java is installed
      $JavaPath = Get-EnvironmentVariable -Variable $Properties.JavaHomeVariable -Scope $Properties.EnvironmentVariableScope
      if (-Not (Test-Path -Path $JavaPath)) {
        Write-Log -Type "ERROR" -Object "$($Properties.JavaHomeVariable) path not found $JavaPath" -ExitCode 1
      }
    } else {
      Write-Log -Type "ERROR" -Object "$($Properties.JavaHomeVariable) environment variable is not set" -ExitCode 1
    }
    # --------------------------------------------------------------------------
    # Check that WildFly is not already installed
    $Continue = $true
    if (Test-Path -Path $Properties.JBossHomeDirectory) {
      Write-Log -Type "WARN" -Object "Some files already exist in the target installation directory $($Properties.JBossHomeDirectory)"
      $Continue = $false
    }
    # Check if service is defined
    if (Test-Service -Service $Properties.ServiceName) {
      Write-Log -Type "WARN" -Object "A service with the name $($Properties.ServiceName) is already defined"
      $Continue = $false
    }
    # Check if JBOSS_HOME variable is defined
    if (Test-EnvironmentVariable -Variable $Properties.JBossHomeVariable -Scope $Properties.EnvironmentVariableScope) {
      Write-Log -Type "WARN" -Object "The environment variable $($Properties.JBossHomeVariable) is already defined"
      $Continue = $false
    }
    # Cancel installation if issues detected
    if ($Continue -eq $false) {
      Write-Log -Type "ERROR" -Object "A previous installation of WildFly has been detected. Please remove it before launching the installation" -ExitCode 1
    }
    # --------------------------------------------------------------------------
    # Check distribution file integrity
    Assert-Checksum -Properties $Properties
    # --------------------------------------------------------------------------
    # Extract files
    if (Test-Path -Path $Properties.JBossHomeDirectory) {
      Write-Log -Type "DEBUG" -Object $Properties.JBossHomeDirectory
      Write-Log -Type "ERROR" -Object "WildFly is already installed. Please uninstall previous installation first" -ExitCode 1
    } else {
      $WildFlySource = Join-Path -Path $Properties.SrcDirectory -ChildPath $Properties.WildFlyDistribution
      Write-Log -Type "DEBUG" -Object $WildFlySource
      if (Test-Path -Path $WildFlySource) {
        $WildFlyTarget = Split-Path -Path $Properties.JBossHomeDirectory
        Write-Log -Type "INFO" -Object "Extracting WildFly to ""$WildFlyTarget"""
        Expand-CompressedFile -Path $WildFlySource -DestinationPath $WildFlyTarget -Force
      } else {
        Write-Log -Type "ERROR" -Object "WildFly distribution file not found" -ExitCode 1
      }
    }
    # --------------------------------------------------------------------------
    # Set JBOSS_HOME environment variable
    Write-Log -Type "INFO" -Object "Configuring ""$($Properties.JBossHomeVariable)"" environment variable"
    Set-EnvironmentVariable -Variable $Properties.JBossHomeVariable -Value $Properties.JBossHomeDirectory -Scope $Properties.EnvironmentVariableScope
    # --------------------------------------------------------------------------
    # Configure WildFly
    Set-WildFlyConfiguration -Properties $Properties -Unattended:$Unattended
    # --------------------------------------------------------------------------
    # Configure service
    Install-WildFlyService -Properties $Properties -Unattended:$Unattended
    # --------------------------------------------------------------------------
    # Start service
    Write-Log -Type "INFO" -Object "Starting WildFly service ($($Properties.ServiceName))"
    Start-Service -Name $Properties.ServiceName -Confirm:$Attended
    # Wait for web-server to come back up
    $Running  = Wait-WildFly -Path $JBossClient -Controller $Properties.Controller -TimeOut 60 -RetryInterval 1
    if (-Not $Running) {
      Write-Log -Type "ERROR" -Object "WildFly could not be started" -ExitCode 1
    }
    # --------------------------------------------------------------------------
    # Get admin credentials
    $AdminCredentials = Get-AdminCredentials -Properties $Properties -Unattended:$Unattended
    # Configure security
    Set-SecurityModel -JBossHome $Properties.JBossHomeDirectory -Controller $Properties.Controller -Credentials $AdminCredentials -RBAC:$EnableRBAC
    # --------------------------------------------------------------------------
    # Restart WildFly to apply changes
    Write-Log -Type "INFO" -Object "Reloading WildFly"
    $Reload = Invoke-ReloadServer -Path $JBossClient -Controller $Properties.Controller -Credentials $AdminCredentials
    if (-Not (Test-JBossClientOutcome -Log $Reload)) {
      # Check if java.util.concurrent.CancellationException
      if (Select-String -InputObject $Reload -Pattern "java.util.concurrent.CancellationException" -SimpleMatch -Quiet) {
        # Wait and try again
        Start-Sleep -Seconds 2
        $Reload = Invoke-ReloadServer -Path $JBossClient -Controller $Properties.Controller -Credentials $AdminCredentials
        # Check outcome
        if (-Not (Test-JBossClientOutcome -Log $Reload)) {
          # Output error
          Write-Log -Type "ERROR" -Object $Reload
        }
      } else {
        Write-Log -Type "WARN"  -Object "WildFly could not be reloaded"
        Write-Log -Type "ERROR" -Object $Reload
      }
    }
    # --------------------------------------------------------------------------
    Write-Log -Type "CHECK" -Object "WildFly $($Properties.WildFlyVersion) installation complete"
  }
}
