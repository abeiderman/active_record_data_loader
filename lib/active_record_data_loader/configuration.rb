# frozen_string_literal: true

module ActiveRecordDataLoader
  class Configuration
    attr_accessor :default_batch_size, :default_row_count, :logger, :statement_timeout

    def initialize(
      default_batch_size: 100_000,
      default_row_count: 1,
      logger: Logger.new(STDOUT, level: :info),
      statement_timeout: "2min"
    )
      @default_batch_size = default_batch_size
      @default_row_count = default_row_count
      @logger = logger
      @statement_timeout = statement_timeout
    end
  end
end
