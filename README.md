# `deb-harden-ssh`

Automated OpenSSH hardening package for Debian and Ubuntu, based on Lynis guidance and secure defaults for remote administration.

## Overview

This package stages hardened configuration snippets under the Debian source tree in `package/etc/` and installs them
into the system locations used by OpenSSH, fail2ban, auditd, and AIDE. It creates a dedicated `ssh-users` system group,
applies restrictive ownership and mode overrides for SSH config paths, and validates or reloads the relevant services
when they are present and active.

## Requirements

* **Required:** `openssh-server`
* _Recommended:_ `fail2ban`
* Suggested: `auditd`, `aide`

## Hardening Applied

* **Access Control:** Restricts SSH logins to members of the `ssh-users` group via `AllowGroups ssh-users`.
* **Authentication:** Disables password authentication, blocks root password login, rejects empty passwords, and caps
  `MaxAuthTries` at 3.
* **Session Security:** Disables dangerous forwarding, enforces idle timeouts, limits concurrent sessions, and reduces
  the exposure of SSH service state.
* **Cryptography:** Sets hardened `KexAlgorithms`, `Ciphers`, `MACs`, `HostKeyAlgorithms`, and `RequiredRSASize` for
  both SSH server and client configuration.
* **Monitoring:** Adds AIDE checks for SSH config and auditd watch rules for SSH binaries and configuration files.
* **Lifecycle Automation:** Creates the `ssh-users` group during install, validates configuration with `sshd -t`, checks
  fail2ban/audit rules when present, and reloads services through `deb-systemd-invoke` when active.

## Repository / Package Layout

```text
deb-harden-ssh/
├── debian/
|   ├── changelog                              # Changelog
├   ├── control                                # Package metadata and dependencies
│   ├── copyright                              # Copyright information
│   ├── install                                # Installs drop-in configs
│   ├── postinst                               # Post-installation hooks
│   ├── postrm                                 # Post-removal hooks
│   └── rules                                  # Debhelper build targets
├── etc/
│   ├── aide/
│   │   └── aide.conf.d/
│   │       └── 90_deb-harden-ssh_sshd.conf    # AIDE file integrity rules
│   ├── audit/
│   │   └── rules.d/
│   │       └── 50-sshd.rules                  # Auditd usage tracking rules
│   ├── fail2ban/
│   │   └── jail.d/
│   │       └── sshd.conf                      # Fail2ban SSH jail configuration
│   └── ssh/
|       ├── ssh_config.d/
|       |   └── 95-harden-ssh_crypto.conf      # OpenSSH client cryptography hardening options
│       └── sshd_config.d/
│           ├── 10-harden-sshd_base.conf       # OpenSSH server baseline hardening options
│           └── 95-harden-sshd_crypto.conf     # OpenSSH server cryptography hardening options
└── usr/
    └── lib/
        └── systemd/
            └── system/
                ├── ssh.service.d/
                │   └── 50-deb-harden-ssh.conf  # SSH systemd service override
                └── ssh@.service.d/
                    └── 50-deb-harden-ssh.conf  # SSH template systemd service override
```

## User Management

Grant SSH access by adding target users to the `ssh-users` group:

```bash
sudo usermod -aG ssh-users <username>
```

## Verification

Check configuration syntax and settings after installation:

```bash
# Validate OpenSSH config syntax
sudo sshd -t

# Verify fail2ban SSH jail status
sudo fail2ban-client status sshd

# Validate auditd rules
sudo augenrules --check

# Validate AIDE rules
sudo aide -c /etc/aide/aide.conf --config-check
```

## Build Debian Package

Build the package using the included build script or using debuild directly.

### Install build requirements

```bash
apt update && apt install devscripts
```

### Build with help script

```bash
./build.sh
```

### Build directly with debuild

```bash
cd package && debuild -us -uc -b
```
