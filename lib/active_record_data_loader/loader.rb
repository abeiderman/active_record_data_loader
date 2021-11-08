# frozen_string_literal: true

require "benchmark"

module ActiveRecordDataLoader
  class Loader
    class << self
      def load_data(
        data_generator:,
        total_rows:,
        batch_size:,
        configuration:
      )
        new(
          logger: configuration.logger,
          statement_timeout: configuration.statement_timeout,
          strategy: strategy_class(configuration.connection_factory).new(
            data_generator,
            output_adapter(configuration.output)
          ),
          connection_factory: configuration.connection_factory
        ).load_data(batch_size, total_rows)
      end

      private

      def strategy_class(connection_factory)
        if connection_factory.call.raw_connection.respond_to?(:copy_data)
          ActiveRecordDataLoader::CopyStrategy
        else
          ActiveRecordDataLoader::BulkInsertStrategy
        end
      end

      def output_adapter(output)
        if output == :connection || !output.respond_to?(:write)
          ActiveRecordDataLoader::ConnectionOutputAdapter.new
        else
          ActiveRecordDataLoader::IOStreamOutputAdapter.new(output)
        end
      end
    end

    def initialize(logger:, statement_timeout:, strategy:, connection_factory:)
      @logger = logger
      @strategy = strategy
      @statement_timeout = statement_timeout
      @connection_factory = connection_factory
    end

    def load_data(batch_size, total_rows)
      batch_count = (total_rows / batch_size.to_f).ceil

      logger.info(
        "[ActiveRecordDataLoader] "\
        "Loading #{total_rows} row(s) into '#{strategy.table_name}' via #{strategy.name}. "\
        "#{batch_size} row(s) per batch, #{batch_count} batch(es)."
      )
      total_time = Benchmark.realtime do
        load_in_batches(batch_size, total_rows, batch_count)
      end
      logger.info(
        "[ActiveRecordDataLoader] "\
        "Completed loading #{total_rows} row(s) into '#{strategy.table_name}' "\
        "in #{total_time} seconds."
      )
    end

    private

    attr_reader :strategy, :statement_timeout, :logger, :connection_factory

    def load_in_batches(batch_size, total_rows, batch_count)
      with_connection do |connection|
        total_rows.times.each_slice(batch_size).with_index do |row_numbers, i|
          time = Benchmark.realtime { strategy.load_batch(row_numbers, connection) }

          logger.debug(
            "[ActiveRecordDataLoader] "\
            "Completed batch #{i + 1}/#{batch_count}, #{row_numbers.count} row(s) in #{time} seconds"
          )
        end
      end
    end

    def with_connection
      connection = open_connection
      if connection.adapter_name.downcase.to_sym == :postgresql
        original_timeout = retrieve_statement_timeout(connection)
        update_statement_timeout(connection, statement_timeout)
        yield connection
        update_statement_timeout(connection, original_timeout)
      else
        yield connection
      end
    ensure
      connection&.close
    end

    def retrieve_statement_timeout(connection)
      connection.execute("SHOW statement_timeout").first["statement_timeout"]
    end

    def update_statement_timeout(connection, timeout)
      connection.execute("SET statement_timeout = \"#{timeout}\"")
    end

    def open_connection
      connection_factory.call
    end
  end
end
