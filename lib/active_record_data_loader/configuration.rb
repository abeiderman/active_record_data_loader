# frozen_string_literal: true

module ActiveRecordDataLoader
  class Configuration
    attr_accessor :connection_factory, :default_batch_size, :default_row_count,
                  :logger, :max_duplicate_retries, :raise_on_duplicates, :statement_timeout
    attr_reader :output

    def initialize(
      default_batch_size: 100_000,
      default_row_count: 1,
      logger: nil,
      statement_timeout: "2min",
      connection_factory: -> { ::ActiveRecord::Base.connection },
      raise_on_duplicates: false,
      max_duplicate_retries: 5,
      output: nil
    )
      @default_batch_size = default_batch_size
      @default_row_count = default_row_count
      @logger = logger || default_logger
      @statement_timeout = statement_timeout
      @connection_factory = connection_factory
      @raise_on_duplicates = raise_on_duplicates
      @max_duplicate_retries = max_duplicate_retries
      self.output = output
    end

    def output=(output)
      @output = validate_output(output)
    end

    private

    def validate_output(output)
      if output.to_s.blank?
        nil
      elsif output.is_a?(String)
        output
      else
        raise "The output configuration parameter must be a filename meant to be the " \
              "target for the SQL script"
      end
    end

    def default_logger
      if defined?(Rails) && Rails.respond_to?(:logger)
        Rails.logger
      else
        Logger.new($stdout, level: :info)
      end
    end
  end
end
