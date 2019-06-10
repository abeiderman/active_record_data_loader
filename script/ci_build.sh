#! /bin/bash
bundle exec appraisal
bundle exec appraisal activerecord-5 rake
bundle exec appraisal faker rake
bundle exec appraisal ffaker rake
bundle exec rake
