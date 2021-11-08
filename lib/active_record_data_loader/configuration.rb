# frozen_string_literal: true

module ActiveRecordDataLoader
  class Configuration
    attr_accessor :connection_factory, :default_batch_size, :default_row_count,
                  :logger, :output, :statement_timeout

    def initialize(
      default_batch_size: 100_000,
      default_row_count: 1,
      logger: nil,
      statement_timeout: "2min",
      connection_factory: -> { ::ActiveRecord::Base.connection },
      output: :connection
    )
      @default_batch_size = default_batch_size
      @default_row_count = default_row_count
      @logger = logger || default_logger
      @statement_timeout = statement_timeout
      @connection_factory = connection_factory
      @output = output
    end

    private

    def default_logger
      if defined?(Rails) && Rails.respond_to?(:logger)
        Rails.logger
      else
        Logger.new($stdout, level: :info)
      end
    end
  end
end
