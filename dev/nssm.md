# NSSM — Non-Sucking Service Manager

NSSM provides a command-line interface for installing, configuring and managing Windows services.

## Quick commands

### Install a service

```powershell
nssm install <servicename>
nssm install <servicename> <program>
nssm install <servicename> <program> [<arguments>]
```

By default the service's startup directory is set to the directory containing the program. To override it after installation:

```powershell
nssm set <servicename> AppDirectory <path>
```

### Remove a service

```powershell
nssm remove
nssm remove <servicename>
nssm remove <servicename> confirm
```

### Start / stop / restart

```powershell
nssm start <servicename>
nssm stop <servicename>
nssm restart <servicename>
```

### Query status

```powershell
nssm status <servicename>
```

### Send controls

```powershell
nssm pause <servicename>
nssm continue <servicename>
nssm rotate <servicename>
```

`nssm rotate` triggers on-demand rotation for services with I/O redirection and online rotation enabled. nssm also accepts user-defined control 128 as a cue to begin output file rotation.

## Editing service parameters

All parameters supported by nssm can be queried or configured on the command line.

Basic syntax:

```powershell
nssm get <servicename> <parameter>
nssm get <servicename> <parameter> <subparameter>

nssm set <servicename> <parameter> <value>
nssm set <servicename> <parameter> <subparameter> <value>

nssm reset <servicename> <parameter>
nssm reset <servicename> <parameter> <subparameter>
```

nssm will accept additional arguments beyond the value required and concatenate them separated by single spaces. Example (equivalent invocations):

```powershell
nssm set <servicename> AppParameters "-classpath C:\Classes"
nssm set <servicename> AppParameters -classpath C:\Classes
```

### Environment variables

`AppEnvironment` and `AppEnvironmentExtra` accept an optional subparameter when used with `nssm get`. Without a subparameter, all configured variables are printed one per line as `KEY=VALUE`.

Example:

```powershell
nssm get <servicename> AppEnvironmentExtra
# prints:
# CLASSPATH=C:\Classes
# TEMP=C:\Temp

nssm get <servicename> AppEnvironmentExtra CLASSPATH
# prints: C:\Classes
```

To set multiple variables, pass each as a separate `KEY=VALUE` argument:

```powershell
nssm set <servicename> AppEnvironmentExtra CLASSPATH=C:\Classes TEMP=C:\Temp
```

### Exit actions

`AppExit` requires a subparameter specifying the exit code. Use the string `Default` to query the default action.

```powershell
nssm get <servicename> AppExit Default
nssm get <servicename> AppExit 2
nssm set <servicename> AppExit 2 Exit
```

### Priority

`AppPriority` accepts the priority class constants used by `SetPriorityClass()`:

- `REALTIME_PRIORITY_CLASS`
- `HIGH_PRIORITY_CLASS`
- `ABOVE_NORMAL_PRIORITY_CLASS`
- `NORMAL_PRIORITY_CLASS`
- `BELOW_NORMAL_PRIORITY_CLASS`
- `IDLE_PRIORITY_CLASS`

## Native parameters

These map directly to service registry values:

- `DependOnGroup` — load order groups that must start first
- `DependOnService` — services that must start first
- `Description` — service description
- `DisplayName` — display name shown in services.msc
- `ImagePath` — path to the service executable (for nssm services this is nssm.exe)
- `ObjectName` — account the service runs under (default: `LOCALSYSTEM`)
- `Name` — service key name (immutable)
- `Start` — startup type (see below)
- `Type` — service type (nssm can edit `SERVICE_WIN32_OWN_PROCESS`)

When setting `ObjectName` you must provide the password as an additional argument:

```powershell
nssm set <servicename> ObjectName <username> <password>
```

To set a blank password use `""`.

## Start types

- `SERVICE_AUTO_START` — Automatic startup at boot
- `SERVICE_DELAYED_AUTO_START` — Delayed automatic startup (not available prior to Vista)
- `SERVICE_DEMAND_START` — Manual
- `SERVICE_DISABLED` — Disabled

If delayed start is not supported, nssm will fall back to automatic startup.

## Service types

nssm recognises many service types but will only allow setting:

- `SERVICE_WIN32_OWN_PROCESS` — standalone service (default)
- `SERVICE_INTERACTIVE_PROCESS` — interactive service (requires `LOCALSYSTEM`)

To configure an interactive service safely:

```powershell
nssm reset <servicename> ObjectName
nssm set <servicename> Type SERVICE_INTERACTIVE_PROCESS
```

## Windows 10, Server 2016 and newer

2017-04-26: Users of Windows 10 Creators Update or newer should use prelease build 2.24-101 or any newer build to avoid an issue with services failing to start. If for some reason you cannot use that build you can alternatively set AppNoConsole=1 in the registry, noting that applications which expect a console window may behave unexpectedly.

Thanks to Sebasian Krause for the initial diagnosis.

## Download

nssm should work under Windows 2000 or later. Specifically, Windows 7, Windows 8 and Windows 10 are supported. 32-bit and 64-bit binaries are included in the download. Most of the time it should be safe to run the 32-bit version on 64-bit Windows but in some circumstances you may find that it doesn't work and you must use the 64-bit version. Both versions are compiled from the same source code. If one works for you, use that one. If it doesn't, try the other.

## Licence

nssm is public domain. You may unconditionally use it and/or its source code for any purpose you wish.

## Latest release

nssm 2.24 (2014-08-31)
[be7b3577c6e3a280e5106a9e9db5b3775931cefc]

## Featured pre-release

nssm 2.24-101-g897c7ad (2017-04-26)
[ca2f6782a05af85facf9b620e047b01271edd11d]

nssm is built with the Jenkins continuous integration server. You can download any available build if you are feeling brave.

## Source code

Source code is included in the download or you can browse gitweb and view the Changelog

You can also clone the repo from git://git.nssm.cc/nssm/nssm.git or http://git.nssm.cc/nssm/nssm.git with git.

## Chocolatey package

nssm can be installed with Chocolatey. The Chocolatey package is built and maintained by a third party and may not correspond to the latest build available here.
