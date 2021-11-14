# frozen_string_literal: true

module ActiveRecordDataLoader
  class Configuration
    attr_accessor :connection_factory, :default_batch_size, :default_row_count,
                  :logger, :statement_timeout
    attr_reader :output

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
      self.output = output
    end

    def output=(output)
      @output = validate_output(output || { type: :connection })
    end

    def output_adapter
      if output.fetch(:type) == :file
        ActiveRecordDataLoader::FileOutputAdapter.new(output)
      else
        ActiveRecordDataLoader::ConnectionOutputAdapter.new
      end
    end

    def connection_handler
      ActiveRecordDataLoader::ConnectionHandler.new(
        connection_factory: connection_factory,
        statement_timeout: statement_timeout,
        output_adapter: output_adapter
      )
    end

    private

    OUTPUT_OPTIONS_BY_TYPE = { connection: %i[type], file: %i[type filename] }.freeze

    def validate_output(output)
      if %i[file connection].include?(output)
        { type: output }
      elsif output.is_a?(Hash)
        raise "The output hash must contain a :type key with either :connection or :file" \
          unless %i[file connection].include?(output[:type])

        output.slice(*OUTPUT_OPTIONS_BY_TYPE[output[:type]])
      else
        raise "The output configuration parameter must be either a symbol for :connection or :file, "\
              "or a hash with more detailed output options."
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
