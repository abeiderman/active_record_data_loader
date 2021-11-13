# frozen_string_literal: true

require "bundler/gem_tasks"
require "rspec/core/rake_task"
require "rubocop/rake_task"

RSpec::Core::RakeTask.new(:spec)
RuboCop::RakeTask.new(:rubocop)

task default: [:spec, :rubocop]

task :wait_for_test_db do
  require "active_record_data_loader"
  require "./spec/active_record_helper"

  ActiveRecordHelper.wait_for_mysql
  ActiveRecordHelper.wait_for_postgres
end
