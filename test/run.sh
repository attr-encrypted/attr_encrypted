#!/bin/sh

set -e

export RBENV_VERSION=ree-1.8.7-2012.02
rbenv version

export ACTIVERECORD=2.3.8
bundle
bundle exec rake
export ACTIVERECORD=3.0.0
bundle
bundle exec rake
export ACTIVERECORD=3.1.0
bundle
bundle exec rake
export ACTIVERECORD=3.2.0
bundle
bundle exec rake

export RBENV_VERSION=1.9.3-p484
rbenv version

export ACTIVERECORD=3.0.0
bundle
bundle exec rake
export ACTIVERECORD=3.1.0
bundle
bundle exec rake
export ACTIVERECORD=3.2.0
bundle
bundle exec rake
export ACTIVERECORD=4.0.0
bundle
bundle exec rake

export RBENV_VERSION=2.0.0-p353
rbenv version

export ACTIVERECORD=3.2.0
bundle
bundle exec rake
export ACTIVERECORD=4.0.0
bundle
bundle exec rake

export RBENV_VERSION=2.1.0
rbenv version

export ACTIVERECORD=4.0.0
bundle
bundle exec rake
