# frozen_string_literal: true

module ActiveRecordDataLoader
  class Configuration
    attr_accessor :connection_factory, :default_batch_size, :default_row_count,
                  :logger, :raise_on_duplicates, :statement_timeout
    attr_writer :max_duplicate_retries
    attr_reader :output

    def initialize(
      default_batch_size: 100_000,
      default_row_count: 1,
      logger: nil,
      statement_timeout: "2min",
      connection_factory: -> { ::ActiveRecord::Base.connection },
      raise_on_duplicates: false,
      max_duplicate_retries: 20,
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

    def max_duplicate_retries(model = nil)
      return @max_duplicate_retries unless @max_duplicate_retries.respond_to?(:call)

      if @max_duplicate_retries.arity == 1
        @max_duplicate_retries.call(model)
      else
        @max_duplicate_retries.call
      end
    end

    private

    def validate_output(output)
      if output.to_s.blank?
        nil
      elsif output.is_a?(String)
        output
      else
        raise "The output configuration parameter must be a filename meant to be the "\
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
