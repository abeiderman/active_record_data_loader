# frozen_string_literal: true

require "benchmark"

module ActiveRecordDataLoader
  class Loader
    class << self
      def load_data(
        data_generator:,
        total_rows:,
        batch_size:,
        logger:
      )
        new(
          logger: logger,
          strategy: strategy_class.new(data_generator)
        ).load_data(batch_size, total_rows)
      end

      private

      def strategy_class
        if ::ActiveRecord::Base.connection.raw_connection.respond_to?(:copy_data)
          ActiveRecordDataLoader::CopyStrategy
        else
          ActiveRecordDataLoader::BulkInsertStrategy
        end
      end
    end

    def initialize(logger:, strategy:)
      @logger = logger
      @strategy = strategy
    end

    def load_data(batch_size, total_rows)
      batch_count = (total_rows / batch_size.to_f).ceil

      logger.info(
        "Loading #{total_rows} row(s) into '#{strategy.table_name}' via #{strategy.name}. "\
        "#{batch_size} row(s) per batch, #{batch_count} batch(es)."
      )
      total_time = Benchmark.realtime do
        load_in_batches(batch_size, total_rows, batch_count)
      end
      logger.info(
        "Completed loading #{total_rows} row(s) into '#{strategy.table_name}' "\
        "in #{total_time} seconds."
      )
    end

    private

    attr_reader :strategy, :logger

    def load_in_batches(batch_size, total_rows, batch_count)
      total_rows.times.each_slice(batch_size).with_index do |row_numbers, i|
        time = Benchmark.realtime { strategy.load_batch(row_numbers) }

        logger.debug(
          "Completed batch #{i + 1}/#{batch_count}, #{row_numbers.count} row(s) in #{time} seconds"
        )
      end
    end
  end
end
