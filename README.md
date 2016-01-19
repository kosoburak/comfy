# COMFY - ClOud iMage FactorY
COMFY is a tool for building virtual machine images from scratch.

[![Build Status](https://secure.travis-ci.org/CESNET/comfy.png)](http://travis-ci.org/CESNET/comfy)
[![Dependency Status](https://gemnasium.com/CESNET/comfy.png)](https://gemnasium.com/CESNET/comfy)
[![Gem Version](https://fury-badge.herokuapp.com/rb/comfy.png)](https://badge.fury.io/rb/comfy)
[![Code Climate](https://codeclimate.com/github/CESNET/comfy.png)](https://codeclimate.com/github/CESNET/comfy)

##Requirements
* Ruby >= 1.9.3
* Rubygems
* [Packer] >= 0.8.6 (https://www.packer.io/) (used for the image creation process)
* VirtualBox (if you want to create `ova` images)
* QEMU/KVM (if you want to create `qcow2` images)

## Installation
**Unfortunately, neither gem nor packages are available for COMFY right now. To try COMFY, please use the [From source](#from-source-dev) guide below.**

###From source (dev)
**Installation from source should never be your first choice! Especially, if you are not
familiar with RVM, Bundler, Rake and other dev tools for Ruby!**

**However, if you wish to contribute to our project, this is the right way to start.**

To build and install the bleeding edge version from master

```bash
git clone git://github.com/CESNET/comfy.git
cd comfy
gem install bundler
bundle install
bundle exec rake spec
```

##Configuration
###Create a configuration file for COMFY
Configuration file can be read by COMFY from these
three locations:

* `~/.comfy/comfy.yml`
* `/etc/comfy/comfy.yml`
* `PATH_TO_GEM_DIR/config/comfy.yml`

The example configuration file can be found at the last location
`PATH_TO_GEM_DIR/config/comfy.yml`. When editing a configuration
file you have to follow the division into three environments: `production`,
`development` and `test`. All the configuration options are described
in the example configuration file.

##Usage
COMFY is run with executable `comfy`. For further assistance run `comfy help`:
```bash
$ comfy help

Commands:
  comfy DISTRIBUTION                            # Builds VM with selected distribution
  comfy <DISTRIBUTION>-versions                 # Lists available versions for selected destribution
  comfy clean-cache -c, --cache-dir=CACHE-DIR   # Cleans packer's cache containing distributions' installation media
  comfy distributions                           # Lists all available distributions and their versions
  comfy export -d, --destination=DESTINATION    # Exports files for building virtual machines. Helps with the customization of the build process.
  comfy help [COMMAND]                          # Describe available commands or one specific command
  comfy version                                 # Prints COMFY's version

Options:
  --logging-level=LOGGING-LEVEL
                                 # Possible values: DEBUG, INFO, WARN, ERROR, FATAL, UNKNOWN
  [--logging-file=LOGGING-FILE]  # File to write log to
  [--debug], [--no-debug]        # Runs COMFY in debug mode
```

Building process of selected VM can be customized. To list all the options for one of the distributions run `comfy help DISTRIBUTION`:
```bash
$ comfy help ubuntu

Usage:
  comfy ubuntu -c, --cache-dir=CACHE-DIR -f, --formats=one two three -o, --output-dir=OUTPUT-DIR -s, --size=N -v, --version=VERSION

Options:
  -v, --version=VERSION                    # Version of distribution to build
  -f, --formats=one two three              # Output format of the virtual machine image (qemu - qcow2, virtualbox - ova)
                                           # Possible values: qemu, virtualbox
  -s, --size=N                             # Disk size for created virtual machines (in MB)
  -o, --output-dir=OUTPUT-DIR              # Directory to which COMFY will produce virtual machine files
  -c, --cache-dir=CACHE-DIR                # Directory for packer's cache e.g. distribution installation images
  -g, [--groups=one two three]             # Groups VM belongs to. For automatic processing purposes
  -i, [--identifier=IDENTIFIER]            # VM identifier. For automatic processing purposes
  -d, [--description], [--no-description]  # Generates VM description file. For automatic processing purposes
  -t, [--template-dir=TEMPLATE-DIR]        # Directory COMFY uses templates from to build a VM
      --logging-level=LOGGING-LEVEL
                                           # Possible values: DEBUG, INFO, WARN, ERROR, FATAL, UNKNOWN
      [--logging-file=LOGGING-FILE]        # File to write log to
      [--debug], [--no-debug]              # Runs COMFY in debug mode

Builds VM with distribution Ubuntu
```

COMFY currently supports building of these distributions:
* CentOS 7.2.1511
* Debian 7.9.0
* Debian 8.2.0
* ScientificLinux 7.1
* Ubuntu 14.04

##Example
To start a building process for example for debian simply run:
```bash
$ comfy debian
```
When not specified, COMFY will build the newest version of selected distribution. If you want to select a specific version run:
```bash
$ comfy debian -v 7.9.0
```
COMFY uses by default a QEMU supervisor for image creation. If you want to use VirtualBox you can do it with:
```bash
$ comfy debian -f virtualbox
```
Or if you want to use both:
```bash
$ comfy debian -f qemu virtualbox
```
This will create virtual machine images in both `qcow2` and `ovf` formats. Since QEMU and VirtualBox can't run simultaneously, images are created in two sequential runs.

##Continuous integration
[Continuous integration for COMFY by Travis-CI](http://travis-ci.org/CESNET/comfy/)

## Contributing
1. Fork it ( https://github.com/CESNET/comfy/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
