# `deb-harden-ssh`

Automated OpenSSH daemon hardening package based on Lynis security recommendations.

## Overview

This package deploys hardening settings through drop-in configuration snippets in `/etc/ssh/sshd_config.d/` and
`/etc/fail2ban/jail.d/`. It also adds an `ssh-users` system group.

## Requires

* fail2ban
* openssh-server

## Hardening Applied

* **Access Control:** Restricts logins to members of the `ssh-users` adn `sudo` system groups.
* **Authentication:** Blocks root password login, disables empty passwords, and caps authentication retries.
* **Session Management:** Enforces client idle timeouts to drop inactive connections.
* **Lifecycle Automation:** Adds the `ssh-users` group, validates syntax with `sshd -t`, and reloads `ssh`
  via `deb-systemd-invoke`.

## Directory Structure

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
│   │       └── 50-sshd.conf                   # Auditd usage tracking rules
│   ├── fail2ban/
│   │   └── jail.d/
│   │       └── sshd.conf                      # Fail2ban SSH jail configuration
│   └── ssh/
|       ├── sshd_config.d/
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

Grant SSH access by adding target users to the ssh-users group:

```bash
sudo usermod -aG ssh-users <username>
```

## Verification

Check configuration syntax and settings:

```bash
# Validate OpenSSH config syntax
sudo sshd -t

# Verify fail2ban SSH jail status
sudo fail2ban-client status sshd

# Validate auditd rules
augenrules --check

# Validate AIDE rules
aide -c /etc/aide/aide.conf --config-check
```

## Build Debian Package

### Get Package Building Requirements

```bash
apt update && apt install devscripts
```

### `.deb` ackaging

Build the package using the included build script or using debuild directly:

```bash
./build.sh

# Or by using debuild directly
cd package && debuild -us -uc -b
```
