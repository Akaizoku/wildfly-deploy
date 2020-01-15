#Requires -Version 5.0
#Requires -RunAsAdministrator

<#
  .SYNOPSIS
  Setup WildFLy

  .DESCRIPTION
  Setup and configure WildFly

  .PARAMETER Action
  The action parameter corresponds to the operation to perform.
  Three values are available:
  - configure: configure the application
  - install: install the application
  - show: display configuration
  - uninstall: uninstall the application

  .PARAMETER Version
  The optional version parameter allows to overwrite the application version defined in the configuration file.

  .PARAMETER Unattended
  The unattended switch define if the script should run in silent mode without any user interaction.

  .NOTES
  File name:      Deploy-WildFly.psm1
  Author:         Florian Carrier
  Creation date:  27/11/2018
  Last modified:  15/01/2020
  Dependency:     - PowerShell Tool Kit (PSTK)
                  - WildFly PowerShell Module (PSWF)

  .LINK
  https://svn.wkfs-frc.local/svn/PS/trunk/wildfly-deploy

  .LINK
  https://www.powershellgallery.com/packages/PSTK

  .LINK
  https://www.powershellgallery.com/packages/PSWF
#>

[CmdletBinding (
  SupportsShouldProcess = $true
)]

# Static parameters
Param (
  [Parameter (
    Position    = 1,
    Mandatory   = $false,
    HelpMessage = "Action to perform"
  )]
  [ValidateSet (
    "configure",
    "install",
    "show",
    "uninstall"
  )]
  [String]
  $Action,
  [Parameter (
    Position    = 2,
    Mandatory   = $false,
    HelpMessage = "Application version"
  )]
  # TODO add version format validation
  [String]
  $Version,
  [Parameter (
    HelpMessage = "Run script in non-interactive mode"
  )]
  [Switch]
  $Unattended
)

# Dynamic parameters
# DynamicParam {
#   $SourceFiles  = Get-ChildItem -Path $Properties.SrcDirectory -Filter "wildfly-*.zip"
#   $Versions     = New-Object -TypeName "System.Collections.ArrayList"
#   foreach ($SourceFile in $SourceFiles) {
#     $Version = Select-String -InputObject $SourceFile.BaseName -Pattern '(?<=wildfly-).+' | ForEach-Object { $_.Matches.Value }
#     [Void]$Versions.Add($Version)
#   }
#   New-DynamicParameter -Name "Version" -Type "String" -Position 2 -HelpMessage "Application version" -ValidateSet $Versions
# }

Begin {
  # ----------------------------------------------------------------------------
  # Global preferences
  # ----------------------------------------------------------------------------
  # $ErrorActionPreference = "Stop"
  # $DebugPreference = "Continue"
  # Set-StrictMode -Version Latest

  # ----------------------------------------------------------------------------
  # Global variables
  # ----------------------------------------------------------------------------
  # General
  $ScriptName         = [System.IO.Path]::GetFileNameWithoutExtension($MyInvocation.MyCommand.Name)
  $ISOTimeStamp       = Get-Date -Format "dd-MM-yyyy_HHmmss"

  # Configuration
  $LibDirectory       = Join-Path -Path $PSScriptRoot -ChildPath "lib"
  $ConfDirectory      = Join-Path -Path $PSScriptRoot -ChildPath "conf"
  $DefaultProperties  = "default.ini"
  $CustomProperties   = "custom.ini"

  # ----------------------------------------------------------------------------
  # Modules
  # ----------------------------------------------------------------------------
  # List all required modules
  $Modules = @("PSTK", "PSWF")
  foreach ($Module in $Modules) {
    try {
      # Check if module is installed
      Import-Module -Name "$Module" -ErrorAction "Stop" -Force
      Write-Log -Type "CHECK" -Object "The $Module module was successfully loaded."
    } catch {
      # Else check if package is available locally
      try {
        Import-Module -Name (Join-Path -Path $LibDirectory -ChildPath "$Module") -ErrorAction "Stop" -Force
        Write-Log -Type "CHECK" -Object "The $Module module was successfully loaded from the library directory."
      } catch {
        Throw "The $Module library could not be loaded. Make sure it has been made available on the machine or manually put it in the ""$LibDirectory"" directory"
      }
    }
  }

  # ----------------------------------------------------------------------------
  # Script configuration
  # ----------------------------------------------------------------------------
  # General settings
  $Properties = Get-Properties -File $DefaultProperties -Directory $ConfDirectory -Custom $CustomProperties
  # Resolve relative paths
  Write-Log -Type "DEBUG" -Object "Script structure check"
  $Properties = Get-Path -PathToResolve $Properties.RelativePaths -Hashtable $Properties -Root $PSScriptRoot

  # Transcript
  $FormattedAction  = Format-String -String $Action -Format "TitleCase"
  $Transcript       = Join-Path -Path $Properties.LogDirectory -ChildPath "${FormattedAction}-WildFly_${ISOTimeStamp}.log"
  Start-Script -Transcript $Transcript

  # Log command line
  Write-Log -Type "DEBUG" -Object $PSCmdlet.MyInvocation.Line

  # Service properties
  $ValidateSet = @(
    "SHORTNAME"
    "DISPLAYNAME"
    "DESCRIPTION"
  )
  $ServiceProperties = Get-Properties -File $Properties.ServiceProperties -Directory $Properties.ConfDirectory -ValidateSet $ValidateSet

  # Java options
  $JavaOptions = ((Get-Content -Path (Join-Path -Path $Properties.ConfDirectory -ChildPath $Properties.JavaOptions)) -NotMatch '^#' | Out-String).Trim()

  # ----------------------------------------------------------------------------
  # Functions
  # ----------------------------------------------------------------------------
  # Load PowerShell functions
  $Functions = Get-ChildItem -Path $Properties.PSDirectory
  foreach ($Function in $Functions) {
    Write-Log -Type "DEBUG" -Object "Import $($Function.Name)"
    try   { . $Function.FullName }
    catch { Write-Error -Message "Failed to import function $($Function.FullName): $_" }
  }

  # ----------------------------------------------------------------------------
  # Variables
  # ----------------------------------------------------------------------------
  # (Re)load environment variables
  Write-Log -Type "DEBUG" -Object "Load environment variables"
  $EnvironmentVariables = @(
    $Properties.JavaHome,
    $Properties.JBossHome
  )
  foreach ($EnvironmentVariable in $EnvironmentVariables) {
    Sync-EnvironmentVariable -Name $EnvironmentVariable -Scope $Properties.EnvironmentVariableScope | Out-Null
  }

  # Version overwrite
  if ($PSBoundParameters.ContainsKey("Version")) {
    $Properties.WildFlyVersion = $Version
  }

  # General variables
  $Properties.WildFlyDistribution = "wildfly-" + $Properties.WildFlyVersion + ".zip"
  $Properties.JBossHomeDirectory  = Join-Path -Path $Properties.JBossHomeLocation   -ChildPath $Properties.WildFlyDistribution.Replace(".zip", "")
  $Properties.JBossCli            = Join-Path -Path $Properties.JBossHomeDirectory  -ChildPath $Properties.JBossCli
  $Properties.ServiceName         = $ServiceProperties.SHORTNAME
  $Properties.Hostname            = Get-EnvironmentVariable -Name "ComputerName" -Scope "Process"
  $Properties.Protocol            = "HTTP"
  $Properties.ManagementPort      = $Properties.HTTPManagementPort
  $Properties.Controller          = $Properties.Hostname + ':' + $Properties.ManagementPort
}

Process {
  # Check operation to perform
  switch ($Action) {
    "install"   {
      Install-WildFly -Properties $Properties -Unattended:$Unattended
    }
    # --------------------------------------------------------------------------
    "uninstall" {
      Uninstall-WildFly -Properties $Properties -Unattended:$Unattended
    }
    # --------------------------------------------------------------------------
    "configure" {
      Invoke-ConfigureWildFly -Properties $Properties -Unattended:$Unattended
    }
    # --------------------------------------------------------------------------
    "show" {
      # Display default x custom script configuration
      Write-Log -Type "INFO" -Object "Script configuration"
      Write-Host -Object ($Properties | Out-String).Trim() -ForegroundColor "Cyan"
      # Display service configuration
      Write-Log -Type "INFO" -Object "Service configuration"
      Write-Host -Object ($ServiceProperties | Out-String).Trim() -ForegroundColor "Cyan"
      # Display JVM configuration
      Write-Log -Type "INFO" -Object "Java options"
      Write-Host -Object ($JavaOptions | Out-String).Trim() -ForegroundColor "Cyan"
    }
    # --------------------------------------------------------------------------
    default {
      Write-Log -Type "ERROR" -Object "Operation not supported" -ExitCode 1
    }
  }
}

End {
  Stop-Script -ExitCode 0
}
