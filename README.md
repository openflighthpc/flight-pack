# Flight Pack

Manage application content packs.

## Overview

Flight Pack facilitates the installation of application packs suitable
for a number of different HPC verticals.

## Installation

### From source

Flight Pack requires a recent version of Ruby and `bundler`.

The following will install from source using `git`:

```
git clone https://github.com/alces-flight/flight-pack.git
cd flight-pack
bundle install --path=vendor
```

Use the script located at `bin/pack` to execute the tool.

### Installing with Flight Runway

Flight Runway provides a Ruby environment and command-line helpers for
running openflightHPC tools.  Flight Pack integrates with Flight
Runway to provide an easy way for multiple users of an
HPC environment to use the tool.

To install Flight Runway, see the [Flight Runway installation
docs](https://github.com/openflighthpc/flight-runway#installation).

These instructions assume that `flight-runway` has been installed from
the openflightHPC yum repository and that either [system-wide
integration](https://github.com/openflighthpc/flight-runway#system-wide-integration) has been enabled or the
[`flight-starter`](https://github.com/openflighthpc/flight-starter) tool has been
installed and the environment activated with the `flight start` command.

 * Enable the OpenFlightHPC RPM repository:

    ```
    yum install https://repo.openflighthpc.org/openflight/centos/7/x86_64/openflighthpc-release-2-1.noarch.rpm
    ```

 * Rebuild your `yum` cache:

    ```
    yum makecache
    ```
    
 * Install the `flight-pack` RPM:

    ```
    [root@myhost ~]# yum install flight-pack
    ```

Flight Pack is now available via the `flight` tool:

```
[root@myhost ~]# flight pack
  NAME:

    flight pack

  DESCRIPTION:

    Manage content packs.

  COMMANDS:

    avail    Show available packs
    download Download a pack
    help     Display global or [command] help documentation
    info     Show information about a pack
    install  Install a pack
    repoadd  Configure a repo
    <snip>
```

## Configuration

Making changes to the default configuration is optional and can be achieved by creating a `config.yml` file in the `etc/` subdirectory of the tool.  A `config.yml.ex` file is distributed which outlines all the configuration values available:

 * `pack_paths`: Location to store content pack descriptors (defaults to `etc/packs`).
 * `repo_paths`: Location to store repo descriptors (defaults to `etc/repos`).
 * `log_path`: Location for storing log files (defaults to `var/log`).
 * `store_dir`: Cache directory for downloaded content archives (defaults to `var/cache/pack`)

## Operation

Before use a repository should be added to Flight Pack using the `repoadd` command, e.g.:

```
flight pack repoadd https://alces-flight-packs.s3.eu-west-2.amazonaws.com/v1/core.yml
```

See the `help` command for further details and information about commands.

# Contributing

Fork the project. Make your feature addition or bug fix. Send a pull
request. Bonus points for topic branches.

Read [CONTRIBUTING.md](CONTRIBUTING.md) for more details.

# Copyright and License

Eclipse Public License 2.0, see [LICENSE.txt](LICENSE.txt) for details.

Copyright (C) 2019-present Alces Flight Ltd.

This program and the accompanying materials are made available under
the terms of the Eclipse Public License 2.0 which is available at
[https://www.eclipse.org/legal/epl-2.0](https://www.eclipse.org/legal/epl-2.0),
or alternative license terms made available by Alces Flight Ltd -
please direct inquiries about licensing to
[licensing@alces-flight.com](mailto:licensing@alces-flight.com).

Flight Pack is distributed in the hope that it will be
useful, but WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, EITHER
EXPRESS OR IMPLIED INCLUDING, WITHOUT LIMITATION, ANY WARRANTIES OR
CONDITIONS OF TITLE, NON-INFRINGEMENT, MERCHANTABILITY OR FITNESS FOR
A PARTICULAR PURPOSE. See the [Eclipse Public License 2.0](https://opensource.org/licenses/EPL-2.0) for more
details.
