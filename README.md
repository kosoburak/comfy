# COMFY - ClOud iMage FactorY
COMFY is a tool for building virtual machine images from scratch and their upload to OpenNebula data stores.

[![Build Status](https://secure.travis-ci.org/Misenko/comfy.png)](http://travis-ci.org/Misenko/comfy)
[![Dependency Status](https://gemnasium.com/Misenko/comfy.png)](https://gemnasium.com/Misenko/comfy)
[![Gem Version](https://fury-badge.herokuapp.com/rb/comfy.png)](https://badge.fury.io/rb/comfy)
[![Code Climate](https://codeclimate.com/github/Misenko/comfy.png)](https://codeclimate.com/github/Misenko/comfy)

##Requirements
* Ruby >= 1.9.3
* Rubygems

## Installation
**Unfortunately, neither gem nor packages are available for COMFY right now. To try COMFY, please use the [From source](#from-source-dev) guide below.**

###From source (dev)
**Installation from source should never be your first choice! Especially, if you are not
familiar with RVM, Bundler, Rake and other dev tools for Ruby!**

**However, if you wish to contribute to our project, this is the right way to start.**

To build and install the bleeding edge version from master

```bash
git clone git://github.com/Misenko/comfy.git
cd comfy
gem install bundler
bundle install
bundle exec rake spec
```

##Configuration
###Create a configuration file for COMFY
Configuration file can be read by COMFY from these
three locations:

* `~/.comfy/conf.yml`
* `/etc/comfy/conf.yml`
* `PATH_TO_GEM_DIR/config/conf.yml`

The example configuration file can be found at the last location
`PATH_TO_GEM_DIR/config/conf.yml`. When editing a configuration
file you have to follow the division into three environments: `production`,
`development` and `test`. All the configuration options are described
in the example configuration file.

##Usage
COMFY is run with executable `comfy`. For a list of all
available options run `comfy -h`:
```bash
$ comfy -h

Usage of COMFY tool: comfy [options] DISTRIBUTION

    -V, --distribution-version VERSION         Version of distribution to build. Defaults to the newest version.
    -f, --formats FORMAT1[,FORMAT2,...]        Select the output format of the virtual machine image (qemu - qcow2, virtualbox - ova). Defaults to qemu.
    -s, --size NUMBER                          Specify disk size for created virtual machines (in MB). Defaults to 5000MB (5GB)
    -l, --list                                 Lists all the available distributions and their versions
        --export DESTINATION                   Exports files for building virtual machines to directory DESTINATION. Helps with the customization of the build process.
        --[no-]debug                           Run in debug mode
    -h, --help                                 Shows this message
    -v, --version                              Shows version of COMFY
```
COMFY currently supports building of these distributions:
* CentOS 7.1.1503
* Debian 7.8.0
* ScientificLinux 7.1
* Ubuntu 12.04
* Ubuntu 14.04

##Example
To start a building process for example for ubuntu simply run:
```bash
$ comfy ubuntu
```
When not specified, COMFY will build the newest version of selected distribution. If you want to select a specific version run:
```bash
$ comfy -v 12.04 ubuntu
```
COMFY uses by default a QEMU supervisor for image creation. If you want to use VirtualBox you can do it with:
```bash
$ comfy -f virtualbox ubuntu
```
Or if you want to use both:
```bash
$ comfy -f qemu,virtualbox ubuntu
```
This will create virtual machine images in both `qcow2` and `ova` formats. Since QEMU and VirtualBox can't run simultaneously, images are created in two sequential runs.

##Continuous integration
[Continuous integration for COMFY by Travis-CI](http://travis-ci.org/Misenko/comfy/)

## Contributing
1. Fork it ( https://github.com/Misenko/comfy/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

