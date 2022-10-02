#!/usr/bin/env bash

set -e

for RUBY in 2.7.6 3.0.4
do
  for ACTIVERECORD in 6.1 7.0
  do
    echo ">>> Testing with Ruby ${RUBY} and ActiveRecord ${ACTIVERECORD}."
    export RBENV_VERSION=$RUBY
    export ACTIVERECORD=$ACTIVERECORD

    rbenv install $RUBY --skip-existing
    bundle install
    bundle check
    bundle exec rake test
    rm Gemfile.lock
    echo ">>> Finished testing with Ruby ${RUBY} and ActiveRecord ${ACTIVERECORD}."
  done
done
  