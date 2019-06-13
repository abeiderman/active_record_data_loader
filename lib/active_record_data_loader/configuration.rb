# frozen_string_literal: true

module ActiveRecordDataLoader
  class Configuration
    attr_accessor :default_batch_size, :default_row_count, :logger, :statement_timeout

    def initialize(
      default_batch_size: 100_000,
      default_row_count: 1,
      logger: nil,
      statement_timeout: "2min"
    )
      @default_batch_size = default_batch_size
      @default_row_count = default_row_count
      @logger = logger || default_logger
      @statement_timeout = statement_timeout
    end

    private

    def default_logger
      if defined?(Rails) && Rails.respond_to?(logger)
        Rails.logger
      else
        Logger.new(STDOUT, level: :info)
      end
    end
  end
end
