# frozen_string_literal: true

require "csv"
require "benchmark"

module ActiveRecordDataLoader
  class CopyStrategy
    def initialize(data_generator)
      @data_generator = data_generator
    end

    def load_batch(row_numbers)
      csv_data = csv_data_batch(row_numbers)

      connection = ::ActiveRecord::Base.connection.raw_connection
      connection.copy_data(copy_command) { connection.put_copy_data(csv_data) }
    end

    def table_name
      data_generator.table
    end

    def name
      "COPY"
    end

    private

    attr_reader :data_generator

    def csv_data_batch(row_numbers)
      row_numbers.map do |i|
        data_generator.generate_row(i).map { |d| quote_data(d) }.join(",")
      end.join("\n")
    end

    def copy_command
      @copy_command ||= begin
        quoted_table_name = ::ActiveRecord::Base.connection.quote_table_name(data_generator.table)
        columns = data_generator
                  .column_list
                  .map { |c| ::ActiveRecord::Base.connection.quote_column_name(c) }
                  .join(", ")

        <<~SQL
          COPY #{quoted_table_name} (#{columns})
            FROM STDIN WITH (FORMAT CSV)
        SQL
      end
    end

    def quote_data(data)
      return if data.nil?

      "\"#{::ActiveRecord::Base.connection.quote_string(data.to_s)}\""
    end
  end
end
