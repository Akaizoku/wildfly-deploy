# WildFly deployment utlity

`wildfly-deploy` is a small PowerShell utility that offers an automation framework to quickly and easily setup a web-server on a local machine.

## Table of contents

<!-- TOC depthFrom:2 depthTo:6 withLinks:1 updateOnSave:1 orderedList:1 -->

1.  [Table of contents](#table-of-contents)
2.  [Usage](#usage)
3.  [Pre-requisites](#pre-requisites)
    1.  [Permissions](#permissions)
    2.  [PowerShell version](#powershell-version)
    3.  [PowerShell Tool Kit](#powershell-tool-kit)
    4.  [WildFly PowerShell Module](#wildfly-powershell-module)
    5.  [Java](#java)
4.  [Configuration](#configuration)
    1.  [Script configuration](#script-configuration)
    2.  [Service configuration](#service-configuration)
    3.  [Java Virtual Machine configuration](#java-virtual-machine-configuration)
    4.  [Security](#security)
5.  [Parameters](#parameters)
    1.  [Action](#action)
        1.  [Configure](#configure)
        2.  [Install](#install)
        3.  [Reload](#reload)
        4.  [Restart](#restart)
        5.  [Show](#show)
        6.  [Start](#start)
        7.  [Stop](#stop)
        8.  [Uninstall](#uninstall)
    2.  [Version](#version)
    3.  [Unattended](#unattended)
6.  [Logs](#logs)
7.  [Known issues](#known-issues)
    1.  [Failure to remove files](#failure-to-remove-files)
8.  [Roadmap](#roadmap)

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
+---powershell
\---res
```

### WildFly PowerShell Module

This script requires the [WildFly PowerShell Module (PSWF)](https://www.powershellgallery.com/packages/PSWF) module. It must be installed on the local machine or copied in a `lib` folder at the root of the directory.

```
.wildfly-deploy
+---conf
+---lib
|   +---PSTK
|   \---PSWF
+---powershell
\---res
```

### Java

WildFly requires [Java Platform, Standard Edition (Java SE)](https://www.oracle.com/java/). For version requirement, please refer to the corresponding WildFly documentation.

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

#### Reload

The _reload_ option will reload the application server.

#### Restart

The _restart_ option will restart the WildFly service.

#### Show

The _show_ option will display the configuration of the script.

#### Start

The _start_ option will start the WildFly service.

#### Stop

The _stop_ option will stop the WildFly service.

#### Uninstall

The _uninstall_ option will remove an existing instance of WildFly from the local machine.

### Version

The optional _version_ parameter allows you to specify the version of WildFly to deploy dynamically without having to edit the configuration file. It takes precedence over the values defined in `custom.ini` and `default.ini`.

### Unattended

The _unattended_ switch allows you to run the script in silent mode without any interaction. This relies on all configuration properties having been properly defined, especially the admin user credentials.

## Logs

Transcript log files are generated in the `log` directory of the script.

-   The naming convention is as follows: `<Action>-WildFly_<Timestamp>.log`.
-   The format of the log is: `<Timestamp>     <Message type>     <Message>`

Below is an example of a successful installation log:

```text
2020-02-10 14:19:07     INFO    Installation of WildFly 11.0.0.Final
2020-02-10 14:19:07     INFO    Checking distribution source files
2020-02-10 14:19:08     CHECK   Distribution file integrity check successful
2020-02-10 14:19:08     INFO    Extracting WildFly to "C:\WKFS\WildFly"
2020-02-10 14:19:47     INFO    Configuring "" environment variable
2020-02-10 14:19:47     INFO    Configuring Java options
2020-02-10 14:19:47     CHECK   Java options configured successfully
2020-02-10 14:19:47     INFO    Configuring interfaces
2020-02-10 14:19:47     INFO    Configuring addresses for management interface
2020-02-10 14:19:47     INFO    Configuring addresses for public interface
2020-02-10 14:19:47     CHECK   Interfaces configured successfully
2020-02-10 14:19:47     INFO    Configuring ports
2020-02-10 14:19:47     INFO    Configuring standard socket port offset
2020-02-10 14:19:47     INFO    Configuring ajp socket
2020-02-10 14:19:47     INFO    Configuring http socket
2020-02-10 14:19:47     INFO    Configuring https socket
2020-02-10 14:19:47     INFO    Configuring management-http socket
2020-02-10 14:19:47     INFO    Configuring management-https socket
2020-02-10 14:19:47     INFO    Configuring txn-recovery-environment socket
2020-02-10 14:19:47     INFO    Configuring txn-status-manager socket
2020-02-10 14:19:47     CHECK   Port numbers configured successfully
2020-02-10 14:19:47     INFO    Configuring WildFly service
2020-02-10 14:19:48     INFO    Installing WildFly service
2020-02-10 14:19:48     INFO    Starting WildFly service (WildFly11)
2020-02-10 14:19:58     INFO    Creating Administrator role
2020-02-10 14:20:02     CHECK   Administrator security role has been successfully created
2020-02-10 14:20:02     INFO    Add user admin to management realm
2020-02-10 14:20:03     CHECK   User admin successfully added
2020-02-10 14:20:03     INFO    Grant role Administrator to user group Administrators
2020-02-10 14:20:06     CHECK   Administrator security role has been successfully granted
2020-02-10 14:20:06     INFO    Enabling role-based access control security model
2020-02-10 14:20:09     CHECK   RBAC security model has been successfully enabled
2020-02-10 14:20:09     INFO    Reloading WildFly
2020-02-10 14:20:12     CHECK   WildFly 11.0.0.Final installation complete
```

## Known issues

### Failure to remove files

When uninstalling the application, it may happen that an access denied error is thrown when trying to remove the files.

This can be due to multiple causes:

1.  A ghost Java process still running that applies a lock on the files. Manually terminating the Java process resolves the issue and the uninstallation can be re-run successfully.
2.  A file opened in an application such as a text editor can apply a lock on the specific file. Closing all relevant applications removes the lock and the uninstallation can be re-run successfully.

## Roadmap

-   [ ] Enable HTTPS configuration
-   [ ] Enable LDAP configuration
