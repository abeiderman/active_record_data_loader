# frozen_string_literal: true

module ActiveRecordDataLoader
  class Configuration
    attr_accessor :default_batch_size, :default_row_count, :logger

    def initialize(
      default_batch_size: 100_000,
      default_row_count: 1,
      logger: Logger.new(STDOUT, level: :info)
    )
      @default_batch_size = default_batch_size
      @default_row_count = default_row_count
      @logger = logger
    end
  end
end
