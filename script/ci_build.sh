#! /bin/bash
bundle exec appraisal
bundle exec appraisal rake
bundle exec rake
bundle exec rake coveralls:push
