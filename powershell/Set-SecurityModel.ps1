function Set-SecurityModel {
  <#
    .SYNOPSIS
    Setup WildFLy security model

    .DESCRIPTION
    Setup and configure WildFly security model

    .PARAMETER JBossHome
    The JBoss home parameter corresponds to the path to the JBoss home directory.

    .PARAMETER Controller
    The controller parameter corresponds to the hostname and port of the JBoss host.

    .PARAMETER Credentials
    The credentials parameter corresponds to the credentials of the administration account to create.

    .PARAMETER RBAC
    The RBAC switch defines if the role-based access control security model should be enabled.

    .INPUTS
    None. You cannot pipe objects to Set-SecurityModel.

    .OUTPUTS
    None. Set-SecurityModel does not output anything but writes to the host.

    .NOTES
    File name:      Set-SecurityModel.ps1
    Author:         Florian Carrier
    Creation date:  21/10/2019
    Last modified:  09/01/2020
  #>
  [CmdletBinding (
    SupportsShouldProcess = $true
  )]
  Param (
    [Parameter (
      Position    = 1,
      Mandatory   = $false,
      HelpMessage = "Path to the JBoss home directory"
    )]
    [ValidateNotNUllOrEmpty ()]
    [String]
    $JBossHome,
    [Parameter (
      Position    = 2,
      Mandatory   = $false,
      HelpMessage = "Controller"
    )]
    # TODO validate format
    [ValidateNotNUllOrEmpty ()]
    [String]
    $Controller,
    [Parameter (
      Position    = 3,
      Mandatory   = $false,
      HelpMessage = "Admin user credentials"
    )]
    [ValidateNotNUllOrEmpty ()]
    [System.Management.Automation.PSCredential]
    $Credentials,
    [Parameter (
      HelpMessage = "Switch to enable role-based access control security model (RBAC)"
    )]
    [Switch]
    $RBAC
  )
  Begin {
    # Get global preference variables
    Get-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
    # Define script paths
    $JBossClient    = Join-Path -Path $JBossHome -ChildPath "bin\jboss-cli.ps1"
    $AddUserScript  = Join-Path -Path $JBossHome -ChildPath "bin\add-user.ps1"
    # Define variables
    $Role       = "Administrator"
    $UserGroup  = "Administrators"
    $Realm      = "ManagementRealm"
  }
  Process {
    if ($RBAC) {
      # ------------------------------------------------------------------------
      # Setup role-based access control model (RBAC)
      # ------------------------------------------------------------------------
      # TODO add check if version <= 7
      # ------------------------------------------------------------------------
      # Create administration role
      Write-Log -Type "INFO" -Object "Creating $Role role"
      $AddSecurityRole = Add-SecurityRole -Path $JBossClient -Controller $Controller -Role $Role
      Assert-JBossClientOutcome -Log $AddSecurityRole -Object "$Role security role" -Verb "create"
      # ------------------------------------------------------------------------
      # Create application administration user
      Write-Log -Type "INFO" -Object "Add user $($AdminCredentials.UserName) to management realm"
      $AddUser = Add-User -Path $AddUserScript -Credentials $AdminCredentials -Realm $Realm -UserGroup $UserGroup
      # Check that user has been added
      if (Test-User -JBossHome $JBossHome -UserName $AdminCredentials.UserName -Realm $Realm) {
        Write-Log -Type "CHECK" -Object "User $($AdminCredentials.UserName) successfully added"
      } else {
        Write-Log -Type "WARN"  -Object "User $($AdminCredentials.UserName) could not be added"
        Write-Log -Type "ERROR" -Object $AddUser -ExitCode 1
      }
      # ------------------------------------------------------------------------
      # Map administration user group to administration role
      Write-Log -Type "INFO" -Object "Grant role $Role to user group $UserGroup"
      $GrantSecurityRole = Grant-SecurityRole -Path $JBossClient -Controller $Controller -Role $Role -UserGroup $UserGroup
      Assert-JBossClientOutcome -Log $GrantSecurityRole -Object "$Role security role" -Verb "grant"
      # ------------------------------------------------------------------------
      # Enable RBAC
      Write-Log -Type "INFO" -Object "Enabling role-based access control security model"
      $EnableRBAC = Enable-RBAC -Path $JBossClient -Controller $Controller -Credentials $AdminCredentials
      Assert-JBossClientOutcome -Log $EnableRBAC -Object "RBAC security model" -Verb "enable"
    } else {
      # ------------------------------------------------------------------------
      # Setup administration console with simple (standard) security model
      # ------------------------------------------------------------------------
      # Add admin user
      $AddUser = Add-User -Path $AddUserScript -Credentials $AdminCredentials -Realm $Realm
      # Check that user has been added
      if (Test-User -JBossHome $JBossHome -UserName $AdminCredentials.UserName -Realm $Realm) {
        Write-Log -Type "CHECK" -Object "User $($AdminCredentials.UserName) successfully added"
      } else {
        Write-Log -Type "WARN"  -Object "User $($AdminCredentials.UserName) could not be added"
        Write-Log -Type "ERROR" -Object $AddUser -ExitCode 1
      }
    }
  }
}
