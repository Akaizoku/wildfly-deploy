# WildFly deployment process

This document will present the step-by-step process to deploy a WildFly application server.

This document will display extracts of the logs for each step as a reference.

## Table of contents

<!-- TOC depthFrom:2 depthTo:6 withLinks:1 updateOnSave:1 orderedList:1 -->

1.  [Table of contents](#table-of-contents)
2.  [Installation](#installation)
3.  [Configuration](#configuration)
4.  [Windows Service](#windows-service)
5.  [Security](#security)

<!-- /TOC -->

## Installation

In this section, we will go through the steps to _install_ WildFly.

1.  Download the distribution file from the official WildFly website (and file hash if applicable).
2.  Check file integrity using file hash.
    ```
    2020-02-10 15:26:04	INFO	Checking distribution source files
    DEBUG: No reference file found in C:\WKFS\Scripts\wildfly-deploy\res\checksum
    DEBUG: C:\WKFS\Sources\wildfly-17.0.1.Final.zip.sha1
    DEBUG: Reference checksum:    6d3dd603eb3e177c6e7e06c649997ec182445789
    DEBUG: Distribution checksum: 6D3DD603EB3E177C6E7E06C649997EC182445789
    2020-02-10 15:26:04	CHECK	Distribution file integrity check successful
    ```
3.  Expand archive to target location.
    ```
    2020-02-10 15:26:04	INFO	Extracting WildFly to "C:\WKFS\WildFly"
    DEBUG: Using native PowerShell v5.0 Expand-Archive function
    DEBUG: Expand archive to "C:\WKFS\WildFly"
    ```
4.  Set `JBOSS_HOME` environment variable.
    ```
    2020-02-10 15:32:08	INFO	Configuring "JBOSS_HOME" environment variable
    DEBUG: Machine	JBOSS_HOME=C:\WKFS\WildFly\wildfly-17.0.1.Final
    ```

WildFly application server is now _installed_ and ready to use. However, it has not been configured and is thus using the default parametrisation.

## Configuration

In this section, we will go through the steps to configure WildFly.

1.  Configure Java Virtual Machine.
    ```
    2020-02-10 15:32:08	INFO	Configuring Java options
    DEBUG: set "JAVA_OPTS=-Xms8G -Xmx14G -XX:MetaspaceSize=1G -XX:MaxMetaspaceSize=8G"
    2020-02-10 15:32:08	CHECK	Java options configured successfully
    ```
2.  Configure application server interfaces.
    ```
    2020-02-10 15:32:08	INFO	Configuring interfaces
    2020-02-10 15:32:08	INFO	Configuring addresses for management interface
    DEBUG: + <any-address xmlns="urn:jboss:domain:10.0" />
    DEBUG: - <inet-address value="${jboss.bind.address.management:127.0.0.1}" xmlns="urn:jboss:domain:10.0" />
    2020-02-10 15:32:08	INFO	Configuring addresses for public interface
    DEBUG: + <any-address xmlns="urn:jboss:domain:10.0" />
    DEBUG: - <inet-address value="${jboss.bind.address:127.0.0.1}" xmlns="urn:jboss:domain:10.0" />
    2020-02-10 15:32:08	CHECK	Interfaces configured successfully
    ```
3.  Configure application server port numbers.
    ```
    2020-02-10 15:32:08	INFO	Configuring ports
    2020-02-10 15:32:08	INFO	Configuring standard socket port offset
    DEBUG: ${jboss.socket.binding.port-offset:1}
    2020-02-10 15:32:08	INFO	Configuring ajp socket
    DEBUG: ${jboss.ajp.port:8009}
    2020-02-10 15:32:08	INFO	Configuring http socket
    DEBUG: ${jboss.http.port:8080}
    2020-02-10 15:32:08	INFO	Configuring https socket
    DEBUG: ${jboss.https.port:8443}
    2020-02-10 15:32:08	INFO	Configuring management-http socket
    DEBUG: ${jboss.management.http.port:9990}
    2020-02-10 15:32:08	INFO	Configuring management-https socket
    DEBUG: ${jboss.management.https.port:9990}
    2020-02-10 15:32:08	INFO	Configuring txn-recovery-environment socket
    DEBUG: 4712
    2020-02-10 15:32:08	INFO	Configuring txn-status-manager socket
    DEBUG: 4713
    2020-02-10 15:32:08	CHECK	Port numbers configured successfully
    ```

## Windows Service

In this section, we will go through the steps to install WildFly as a Windows service.

1.  Copy the _service_ files to the binaries directory
    ```
    2020-02-10 15:32:08	INFO	Configuring WildFly service
    DEBUG: "17.0.1" -lt "10.0.0"
    DEBUG: Copy files from C:\WKFS\WildFly\wildfly-17.0.1.Final\docs\contrib\scripts\service to C:\WKFS\WildFly\wildfly-17.0.1.Final\bin
    ```
2.  Configure service parameters (`service.bat`)
    ```
    DEBUG: 114	set SHORTNAME=WildFly17
    DEBUG: 115	rem NO quotes around the display name here !
    DEBUG: 116	set DISPLAYNAME=WildFly17
    DEBUG: 117	rem NO quotes around the description here !
    DEBUG: 118	set DESCRIPTION=WildFly Application Server (17.0.0.Final)
    DEBUG: 119	set CONTROLLER=UKWS04282-01:9991
    DEBUG: 120	set DC_HOST=master
    DEBUG: 121	set IS_DOMAIN=false
    DEBUG: 122	set LOGLEVEL=INFO
    DEBUG: 123	set LOGPATH=
    DEBUG: 124	set PROPSPATH=
    DEBUG: 125	set ENV_VARS=
    DEBUG: 126	set JBOSSUSER=
    DEBUG: 127	set JBOSSPASS=
    DEBUG: 128	set SERVICE_USER=
    DEBUG: 129	set SERVICE_PASS=
    DEBUG: 130	set STARTUP_MODE=true
    DEBUG: 131	set ISDEBUG=
    DEBUG: 132	set CONFIG=
    DEBUG: 133	set HOSTCONFIG=host.xml
    DEBUG: 134	set BASE=
    DEBUG: 135
    ```
3.  Install Windows service.
    ```
    2020-02-10 15:32:09	INFO	Installing WildFly service
    DEBUG: cmd.exe /c "C:\WKFS\WildFly\wildfly-17.0.1.Final\bin\service\service.bat" install /startup
    DEBUG: Using the X86-64bit version of prunsrv

    "C:\WKFS\WildFly\wildfly-17.0.1.Final\bin\service\amd64\wildfly-service" install WildFly17  --DisplayName="WildFly17" --Description="WildFly Application Server (17.0.0.Final)" --LogLevel=INFO --LogPath="C:\WKFS\WildFly\wildfly-17.0.1.Final\standalone\log" --LogPrefix=service --StdOutput=auto --StdError=auto --StartMode=exe --Startup=auto --StartImage=cmd.exe --StartPath="C:\WKFS\WildFly\wildfly-17.0.1.Final\bin" ++StartParams="/c#set#NOPAUSE=Y#&&#standalone.bat#-Djboss.server.base.dir=C:\WKFS\WildFly\wildfly-17.0.1.Final\standalone#--server-config=standalone.xml" --StopMode=exe --StopImage=cmd.exe --StopPath="C:\WKFS\WildFly\wildfly-17.0.1.Final\bin"  ++StopParams="/c jboss-cli.bat --controller=UKWS04282-01:9991 --connect  --command=:shutdown" ++Environment=
    Service WildFly17 installed
    ```
4.  Start Windows service.
    ```
    2020-02-10 15:32:09	INFO	Starting WildFly service (WildFly17)
    DEBUG: & "C:\WKFS\WildFly\wildfly-17.0.1.Final\bin\jboss-cli.ps1" --connect --controller='UKWS04282-01:9991' --command=':read-attribute(name=server-state)'
    DEBUG: Failed to connect to the controller: The controller is not available at UKWS04282-01:9991: java.net.ConnectException: WFLYPRT0053: Could not connect to remote+http://UKWS04282-01:9991. The connection failed: WFLYPRT0053: Could not connect to remote+http://UKWS04282-01:9991. The connection failed: Connection refused: no further information
    DEBUG: & "C:\WKFS\WildFly\wildfly-17.0.1.Final\bin\jboss-cli.ps1" --connect --controller='UKWS04282-01:9991' --command=':read-attribute(name=server-state)'
    DEBUG: {
        "outcome" => "success",
        "result" => "running"
    }
    ```

WildFly is now installed as a Windows service that can be easily managed.

## Security

In this section, we will go through the steps to manage the security settings of WildFly.

1.  Create administration role.
    ```
    2020-02-10 15:32:22	INFO	Creating Administrator role
    DEBUG: & "C:\WKFS\WildFly\wildfly-17.0.1.Final\bin\jboss-cli.ps1" --connect --controller='UKWS04282-01:9991' --command='/core-service=management/access=authorization/role-mapping=Administrator:add()'
    DEBUG: {"outcome" => "success"}
    2020-02-10 15:32:25	CHECK	Administrator security role has been successfully created
    ```
2.  Create administration user.
    ```
    2020-02-10 15:32:25	INFO	Add user admin to management realm
    DEBUG: & "C:\WKFS\WildFly\wildfly-17.0.1.Final\bin\add-user.ps1" --user "admin" --password "*******" --realm "ManagementRealm" --group "Administrators"
    DEBUG: Updated user 'admin' to file 'C:\WKFS\WildFly\wildfly-17.0.1.Final\standalone\configuration\mgmt-users.properties'
    Updated user 'admin' to file 'C:\WKFS\WildFly\wildfly-17.0.1.Final\domain\configuration\mgmt-users.properties'
    Updated user 'admin' with groups Administrators to file 'C:\WKFS\WildFly\wildfly-17.0.1.Final\standalone\configuration\mgmt-groups.properties'
    Updated user 'admin' with groups Administrators to file 'C:\WKFS\WildFly\wildfly-17.0.1.Final\domain\configuration\mgmt-groups.properties'
    2020-02-10 15:32:27	CHECK	User admin successfully added
    ```
3.  Grant standard security role "Administrator" to the administration user group.
    ```
    2020-02-10 15:32:27	INFO	Grant role Administrator to user group Administrators
    DEBUG: & "C:\WKFS\WildFly\wildfly-17.0.1.Final\bin\jboss-cli.ps1" --connect --controller='UKWS04282-01:9991' --command='/core-service=management/access=authorization/role-mapping=Administrator/include=group-Administrators:add(name=Administrators,type=GROUP)'
    DEBUG: {"outcome" => "success"}
    2020-02-10 15:32:30	CHECK	Administrator security role has been successfully granted
    ```
4.  Enable role-based access control security model (RBAC).
    ```
    2020-02-10 15:32:30	INFO	Enabling role-based access control security model
    DEBUG: & "C:\WKFS\WildFly\wildfly-17.0.1.Final\bin\jboss-cli.ps1" --connect --controller='UKWS04282-01:9991' --user='admin' --password='*******' --command='/core-service=management/access=authorization:write-attribute(name=provider,value=rbac)'
    DEBUG: {
        "outcome" => "success",
        "response-headers" => {
            "operation-requires-reload" => true,
            "process-state" => "reload-required"
        }
    }
    2020-02-10 15:32:35	CHECK	RBAC security model has been successfully enabled
    ```

WildFly security model is now configured and you can access the management console using the administration account.
