# frozen_string_literal: true

require "benchmark"

module ActiveRecordDataLoader
  class TableLoader
    def self.load_data(
      total_rows:,
      batch_size:,
      logger:,
      connection_handler:,
      strategy:
    )
      new(logger: logger, connection_handler: connection_handler, strategy: strategy)
        .load_data(batch_size, total_rows)
    end

    def initialize(logger:, connection_handler:, strategy:)
      @logger = logger
      @connection_handler = connection_handler
      @strategy = strategy
    end

    def load_data(batch_size, total_rows)
      batch_count = (total_rows / batch_size.to_f).ceil

      logger.info(
        "[ActiveRecordDataLoader] " \
        "Loading #{total_rows} row(s) into '#{strategy.table_name}' via #{strategy.name}. " \
        "#{batch_size} row(s) per batch, #{batch_count} batch(es)."
      )
      total_time = Benchmark.realtime do
        load_in_batches(batch_size, total_rows, batch_count)
      end
      logger.info(
        "[ActiveRecordDataLoader] " \
        "Completed loading #{total_rows} row(s) into '#{strategy.table_name}' " \
        "in #{total_time} seconds."
      )
    end

    private

    attr_reader :strategy, :connection_handler, :logger

    def load_in_batches(batch_size, total_rows, batch_count)
      connection_handler.with_connection do |connection|
        total_rows.times.each_slice(batch_size).with_index do |row_numbers, i|
          time = Benchmark.realtime { strategy.load_batch(row_numbers, connection) }

          logger.debug(
            "[ActiveRecordDataLoader] " \
            "Completed batch #{i + 1}/#{batch_count}, #{row_numbers.count} row(s) in #{time} seconds"
          )
        end
      end
    end
  end
end
