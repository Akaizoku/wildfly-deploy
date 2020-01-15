function Get-AdminCredentials {
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
      HelpMessage = "Run script in unattended mode"
    )]
    [Switch]
    $Unattended
  )
  Begin {

  }
  Process {
    # Get admin credentials
    if ($Unattended) {
      # Use provided credentials
      $EncryptionKey = Get-Content -Path (Join-Path -Path $Properties.SecurityDirectory -ChildPath $Properties.EncryptionKey) -Encoding "UTF8"
      try {
        $AdminCredentials = New-Object -TypeName "System.Management.Automation.PSCredential" -ArgumentList ($Properties.AdminUsername, (ConvertTo-SecureString -String $Properties.AdminPassword -Key $EncryptionKey))
      } catch {
        Write-Log -Type "ERROR" -Object "The provided password could not be decrypted. Please ensure the encryption key is used for the encryption." -ExitCode 1
      }
    } else {
      # Prompt user for credentials
      $AdminCredentials = Get-Credential -Message "Please enter a username and password for WildFly administration user"
    }
    return $AdminCredentials
  }
}
