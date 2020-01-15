# WildFly-deploy

WildFly deploy is a small PowerShell utility that offers an automation framework to quickly and easily setup a web-server on a local machine.

## Table of contents

<!-- TOC depthFrom:2 depthTo:6 withLinks:1 updateOnSave:1 orderedList:1 -->

1.  [Table of contents](#table-of-contents)
2.  [Usage](#usage)
3.  [Pre-requisites](#pre-requisites)
    1.  [Permissions](#permissions)
    2.  [PowerShell version](#powershell-version)
    3.  [PowerShell Tool Kit](#powershell-tool-kit)
4.  [Configuration](#configuration)
    1.  [Script configuration](#script-configuration)
    2.  [Service configuration](#service-configuration)
    3.  [Java Virtual Machine configuration](#java-virtual-machine-configuration)
    4.  [Security](#security)
5.  [Parameters](#parameters)
    1.  [Action](#action)
        1.  [Configure](#configure)
        2.  [Install](#install)
        3.  [Show](#show)
        4.  [Uninstall](#uninstall)
    2.  [Unattended](#unattended)
6.  [Known issues](#known-issues)
    1.  [Failure to remove files](#failure-to-remove-files)
7.  [Roadmap](#roadmap)
8.  [Contact](#contact)

<!-- /TOC -->

## Usage

1.  Check the `default.ini` configuration file located under the `conf` folder;
2.  If needed, add custom configuration to the `custom.ini` configuration file in the same configuration folder;
3.  Run the `Deploy-WildFly.ps1` script located with the appropriate parameter for the action to execute:
    -   configure
    -   install
    -   show
    -   uninstall
4.  Check the logs.

## Pre-requisites

### Permissions

This script requires administrator rights to be run.

### PowerShell version

This script requires PowerShell version 5.0 or later to be run.

### PowerShell Tool Kit

This script makes use of functions from the [PowerShell Tool Kit (PSTK)](https://www.powershellgallery.com/packages/PSTK) module. It must be installed on the local machine or copied in a `lib` folder at the root of the directory.

```
.wildfly-deploy
+---conf
+---lib
|   \---PSTK
+---logs
+---powershell
\---res
```

## Configuration

### Script configuration

The default configuration of the utility is stored into `default.ini`. This file should not be amended. All custom configuration must be made in the `custom.ini` file. Any customisation done in that file will override the default values.

Below is an example of configuration file:

```ini
[Paths]
# Configuration directory
ConfDirectory       = \conf
# Directory containing the libraries
LibDirectory        = \lib

[Filenames]
# Server properties
ServerProperties    = server.ini
# Custom configuration
CustomProperties    = custom.ini
```

**Remark:** Sections (and comments) are ignored in these configuration files. You can make use of them for improved readability.

### Service configuration

To configure the Windows service for WildFly, please edit the configuration file `service.properties` located in the `conf` directory.

### Java Virtual Machine configuration

To configure the Java Virtual Machine (JVM), please edit the configuration file `jvm.properties` located in the `conf` directory.

### Security

When running in unattended mode, the script will use the administrator credentials provided in the configuration file. The password provided **must** be stored as a plain-text representation of a secure string encrypted using the encryption key provided in the directory `res\security`.

In order to generate the required value, please use the command below with the corresponding password:

```powershell
ConvertFrom-SecureString -SecureString (ConvertTo-SecureString -String "<password>" -AsPlainText -Force) -Key (Get-Content -Path ".\res\security\encryption.key")
```

## Parameters

### Action

The _action_ parameter takes four possible values:

-   Configure
-   Install
-   Show
-   Uninstall

#### Configure

The _configure_ option will configure an existing instance of WildFly.

#### Install

The _install_ option will install a new instance of WildFly on the local machine.

#### Show

The _show_ option will display the configuration of the script.

#### Uninstall

The _uninstall_ option will remove an existing instance of WildFly from the local machine.

### Unattended

The _unattended_ switch allows you to run the script in silent mode without any interaction. This relies on all configuration properties having been properly defined, especially the admin user credentials.

## Known issues

### Failure to remove files

When uninstalling the application, it may happen that an access denied error is thrown when trying to remove the files.

This can be due to multiple causes:

1.  A ghost Java process still running that applies a lock on the files. Manually terminating the Java process resolves the issue and the uninstallation can be re-run successfully.
2.  A file opened in an application such as a text editor can apply a lock on the specific file. Closing all relevant applications removes the lock and the uninstallation can be re-run successfully.

## Roadmap

-   [ ] Enable HTTPS configuration
-   [ ] Enable LDAP configuration

## Contact

In case of any issue please contact Florian Carrier: [florian.carrier@wolterskluwer.com](mailto:florian.carrier@wolterskluwer.com)
