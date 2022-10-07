#!/usr/bin/env bash

set -e

for RUBY in 2.5.9 2.6.10 2.7.6 3.0.4 3.1.2
do
  for ACTIVERECORD in 5.2.8 6.0.6 6.1.7
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
