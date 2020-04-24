# AWS Rakes

Rake tasks for simplified command line interaction with AWS using published AWS Ruby SDKs.  This was developed out of my own need to see what's going on with my AWS resources, without having to navigate through the console and aggregate things on the fly.

## Prerequisites

This project has been written, tested, and run exclusively on MacOS. The instructions below follow accordingly.  It should run well on other *nix OSes, and on Windows too, with some adjustments.

* Recommended: Homebrew, if you are on MacOs.  See https://brew.sh/
* awscli installed and configured, e.g. `brew install awscli`
* AWS programatic access via key and secret, normally saved in ~/.aws/credentials
* IAM permissions for the specific services you wish to query
* ruby installed, with gems rake and bundler (these are pre-installed with current ruby versions)
* Optional: a ruby version manager, e.g. chruby or rbenv
  * chruby install directions below in Installation
  * RVM is not recommended

## Installation

### Install

* clone the repo into your desired directory `git clone <repo_url>  ./aws_rakes`
* install chruby - see docs at https://github.com/postmodern/chruby
  * `brew install chruby ruby-build ruby-install wget`
  * add to your shell.rc: 
  
```
 source /usr/local/share/chruby/chruby.sh
 source /usr/local/share/chruby/auto.sh
```

* (re-)source your shell.rc, e.g. `source ~/.bashrc` or `source ~/.zshrc`

* Install specified ruby version: 

```
ruby-install ruby `cat .aws_rakes/.ruby-version`
```
* Optional: install other rubies according to preference
* `cd aws_rakes`
* confirm ruby version: `ruby -v`
* run `bundle install` (if you are using system ruby, `sudo bundle install`)

## Usage

### Rake tasks

Note: Follow the installation instuctions above, and you should not need to prefix `bundle exec` to your `rake` commands, since the gems will be installed in a common location for the ruby, not in an application-specific location, e.g vendor/bundle.

If you do need `bundle exec` it is helpful to create an alias in your shell.rc e.g. `alias be="bundle exec "`.  This done, you can substitute 'be' for 'bundle exec' in your rake commands.

* Display all available rake tasks: `rake -T`
* to filter for specific AWS resources, add argument, e.g. `rake -T ec2`

#### Multifactor authentication

If your AWS account requires MFA for CLI access, you will be prompted to set up an MFA session interactively, to set a new session token.  You will need your AWS username, and the 6 digit rotating token from your MFA device.

### Caching

* To improve performance results are cached for 30 minutes locally.  
* The expiration time can be changed by updating cache\_expire\_minutes in config/config.yaml
* To force no caching for any rake task, append 'cache=no', e.g. `rake ec2s:new cache=no`

### Audit

* Display all audit tasks: `rake -T audit`

### Lambda scripts

The 'lambda' directory contains a few helpful scripts which can run on AWS Lambda

## Development and Testing

* Run `bundle exec rake spec` to run the tests
* You can also run `bin/console` for an interactive prompt that will allow you to experiment with objects

## Acknowledgements

* Thanks to Jason Davila for the original bash scripts which inspired this project.

## Todo

* add some intelligent tests, maybe?

## Contributing

Please do.   Create a fork.  Follow the general structure, and create some new tasks, and/or improve what is already here.  Then submit a pull request.  Thanks!
