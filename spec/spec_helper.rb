# frozen_string_literal: true

require "bundler/setup"
require "rspec/collection_matchers"
require "timecop"
require "pry"
require "rails" if Gem.loaded_specs.key?("rails")
require "active_record_data_loader"
require "simplecov"
require "simplecov-lcov"
require File.join(__dir__, "active_record_helper")

SimpleCov.start do
  SimpleCov::Formatter::LcovFormatter.config do |c|
    c.report_with_single_file = true
    c.single_report_path = "coverage/lcov.info"
  end

  formatter SimpleCov::Formatter::LcovFormatter
  add_filter %w[version.rb]
end

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  config.before(:each) do |example|
    if example.metadata[:connects_to_db]
      if example.metadata[:sqlite3]
        ActiveRecordHelper.connect_to_sqlite3
      elsif example.metadata[:mysql]
        ActiveRecordHelper.connect_to_mysql
      else
        ActiveRecordHelper.connect_to_postgres
      end

      ActiveRecordHelper.define_schema
    end
  end

  logger = ActiveSupport::Logger.new(File.join(__dir__, "../log/test.log"), level: :debug)

  ActiveRecord::Base.logger = logger
  ActiveRecord::Migration.verbose = false

  ActiveRecordDataLoader.configure do |c|
    c.logger = logger
    c.statement_timeout = "5min"
  end
end
