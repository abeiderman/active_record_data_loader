# frozen_string_literal: true

require "bundler/setup"
require "rspec/collection_matchers"
require "active_record_data_loader"
require "pry"
require File.join(__dir__, "active_record_helper")
require "coveralls"
Coveralls.wear!

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
      else
        ActiveRecordHelper.connect_to_postgres
      end

      ActiveRecordHelper.define_schema
    end
  end

  logger = ActiveSupport::Logger.new(File.join(__dir__, "../log/test.log"), level: :debug)

  ActiveRecord::Base.logger = logger
  ActiveRecord::Migration.verbose = false

  DataLoader.configure do |c|
    c.logger = logger
  end
end
