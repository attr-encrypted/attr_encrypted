#!/usr/bin/env bash

set -e

for RUBY in 3.0.6
do
  for ACTIVERECORD in 7.0.2
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
