# frozen_string_literal: true

module ActiveRecordDataLoader
  class Configuration
    attr_accessor :default_batch_size, :default_row_count, :logger, :statement_timeout, :connection_factory

    def initialize(
      default_batch_size: 100_000,
      default_row_count: 1,
      logger: nil,
      statement_timeout: "2min",
      connection_factory: -> { ::ActiveRecord::Base.connection }
    )
      @default_batch_size = default_batch_size
      @default_row_count = default_row_count
      @logger = logger || default_logger
      @statement_timeout = statement_timeout
      @connection_factory = connection_factory
    end

    private

    def default_logger
      if defined?(Rails) && Rails.respond_to?(:logger)
        Rails.logger
      else
        Logger.new(STDOUT, level: :info)
      end
    end
  end
end
