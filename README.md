```
    ___        ______    _   _ _   _ _
   / \ \      / / ___|  | | | | |_(_) |___
  / _ \ \ /\ / /\___ \  | | | | __| | / __|
 / ___ \ V  V /  ___) | | |_| | |_| | \__ \
/_/   \_\_/\_/  |____/   \___/ \__|_|_|___/
```
# AWS Utils

The project is a means for getting more familiar with the AWS Ruby SDKs in practice.  It sets up rake tasks for querying AWS resources using the published APIs.  The intention is to enable viewing AWS resources, aggregated, sliced and diced, without having to piece things together in the AWS console.

The rake tasks are non-destructive by design, i.e. informational only.  Actually manipulation of resources should probably be done some IaC tool like [Terraform](https://www.terraform.io/ "Terraform by HashiCorp").

## Setup

This project has been written, tested, and run exclusively with Ruby 3 on MacOS, and the Prerequisites below follow accordingly.  **AWS Rakes** should run on other *nix OSes, and on Windows too, with some adjustments.

* clone the repo into your desired directory `git clone git@github.com:avonderluft/aws_utils.git`
* `cd aws_utils`
* Running `./bin/setup` should be all you need to get going.

`./bin/setup` assumes you have [Homebrew](https://brew.sh/ "The Missing Package Manager for macOS (or Linux) — Homebrew") installed, and will use [rbenv](https://github.com/rbenv/rbenv "GitHub - rbenv/rbenv: Manage your app&#39;s Ruby environment") as your Ruby Version Manager.  If you want to do things differently, you can use the `./bin/setup` script as general guide.

## Prerequisites

* Homebrew, if you are on MacOs.  See https://brew.sh/
* awscli installed and configured, e.g. `brew install awscli`
* AWS configuration set up in ~/.aws/config with at least a 'default' profile
* AWS programatic access via key and secret, normally saved in ~/.aws/credentials
* IAM permissions for the specific services you wish to query
* ruby installed, with gems rake and bundler (these are pre-installed with current ruby versions)
* Optional: a ruby version manager, e.g. rbenv or chruby (RVM is not recommended)
  * e.g. rbenv - see docs at https://github.com/rbenv/rbenv
  * After updating it, (re-)source your shell.rc, e.g. `source ~/.bashrc` or `source ~/.zshrc`
* Optional: install other rubies according to preference

## Caching

* To improve performance results are cached for 30 minutes locally by default, except for regions which are cached for a day
* cache expiration time can be changed by editing `./config/config.yaml` (see Config below)
* To force clear caches on any rake task, append 'cache=no', e.g. `rake ec2s:new cache=no`

## YAML Config

in `./config/config.yaml`

### Cache expiration 

Change the integers for minutes cached: `regions_cache_expire_minutes` for regions, and `cache_expire_minutes` for everything else.

### What is considered a 'stale' key

Default is one year (365 days) - adjust according to your standards

### Limiting queried regions to speed up queries

You can speed up your queries by limiting the regions searched in `./config/config.yaml`, adding strings which will be matched with region names.  For example, if you wanted to limit regions to Europe and USA, you could update the YAML config like so:

```
---
cache_expire_minutes: 30
regions_cache_expire_minutes: 1440 # 1 day
stale_key_days: 365
region_filters:
  - 'eu-'
  - 'us-'
```

To search in all regions accessible to you, just leave the `regions_filter` element empty:

```
---
stale_key_days: 365
region_filters:
```

After you change region_filters `config.yaml`, run `rake regions cache=no` to apply the changes


## Usage

### Rake tasks

Note: Follow the installation instuctions above, and you should not need to prefix `bundle exec` to your `rake` commands, since the gems will be installed in a common location for the ruby, not in an application-specific location, e.g vendor/bundle.

If you do need `bundle exec` it is helpful to create an alias in your shell.rc e.g. `alias be="bundle exec "`.  This done, you can substitute 'be' for 'bundle exec' in your rake commands, if needed

* Display all available rake tasks: `rake -T`
* To filter for specific AWS services, add argument, e.g. `rake -T ec2`

### Multifactor authentication

If your AWS account requires MFA for CLI access, you will be prompted to set up an MFA session interactively, to set a new session token.  You will need your AWS username, and the 6 digit rotating token from your MFA device.

## Examples

* Show EC2 instances, grouped by region: `rake ec2s`
* Show all volumes, grouped by region: `rake vols`
* Show all unencrypted volumes, grouped by region: `rake vols:unencrypted`
* Show all unencrypted snapshots: `rake snaps:unencrypted`
* Show all S3 buckets without logging enabled: `rake s3s:no_logging`
* Show all KMS keys which include 'EKS' in their description: `rake keys:desc[EKS]`

### Audit

Audit reports are created in ./audit_reports/ directory for each service with date stamp in the filename.  Each subsequent run creates a diff file to show changes since the last run.

* Display all audit tasks: `rake -T audit`

### Lambda scripts

The 'lambda' directory contains a few example scripts

## Development and Testing

* Run `rake` to run the tests.  You might need to prefix `bundle exec`
* You can view current at `./coverage/index.html` in a web browser
* You can also run `bin/console` for an interactive prompt that will allow you to experiment with objects

## Acknowledgements

* to Jason Davila for the original bash scripts which inspired this project
* to my employer [Excella](https://www.excella.com/) for time on the bench to work on it
* to all the contributors to [Ruby](https://www.ruby-lang.org/) which make it such a marvelous language

## Todos

* code for more AWS services, e.g. ECS, and expanding EKS
* write tests for all the services covered

## Contributing

The basic structure is in place, to which you can add tasks to slice and dice according to taste. Follow the general structure, and create some new tasks, and/or improve what is already here.  Then submit a pull request.  Thanks!
