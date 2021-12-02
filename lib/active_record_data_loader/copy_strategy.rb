# frozen_string_literal: true

module ActiveRecordDataLoader
  class CopyStrategy
    def initialize(data_generator, file_adapter)
      @data_generator = data_generator
      @file_adapter = file_adapter
    end

    def load_batch(row_numbers, connection)
      data = csv_rows(row_numbers, connection)
      copy(
        connection: connection,
        table: table_name_for_copy(connection),
        columns: columns_for_copy(connection),
        data: data,
        row_numbers: row_numbers
      )
      file_adapter.copy(
        table: table_name_for_copy(connection),
        columns: columns_for_copy(connection),
        data: data,
        row_numbers: row_numbers
      )
    end

    def table_name
      data_generator.table
    end

    def name
      "COPY"
    end

    private

    attr_reader :data_generator, :file_adapter

    def copy(connection:, table:, columns:, data:, row_numbers:)
      raw_connection = connection.raw_connection
      raw_connection.copy_data("COPY #{table} (#{columns}) FROM STDIN WITH (FORMAT CSV)") do
        raw_connection.put_copy_data(data.join("\n"))
      end
    end

    def csv_rows(row_numbers, connection)
      row_numbers.map do |i|
        data_generator.generate_row(i)&.map { |d| quote_data(d, connection) }&.join(",")
      end.compact
    end

    def table_name_for_copy(connection)
      @table_name_for_copy ||= connection.quote_table_name(data_generator.table)
    end

    def columns_for_copy(connection)
      @columns_for_copy ||= data_generator
                            .column_list
                            .map { |c| connection.quote_column_name(c) }
                            .join(", ")
    end

    def quote_data(data, connection)
      return if data.nil?

      "\"#{connection.quote_string(data.to_s)}\""
    end
  end
end
