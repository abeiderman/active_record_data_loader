# frozen_string_literal: true

module ActiveRecordDataLoader
  class CopyStrategy
    def initialize(data_generator, output_adapter)
      @data_generator = data_generator
      @output_adapter = output_adapter
    end

    def load_batch(row_numbers, connection)
      output_adapter.copy(
        connection: connection,
        table: table_name_for_copy(connection),
        columns: columns_for_copy(connection),
        data: csv_rows(row_numbers, connection)
      )
    end

    def table_name
      data_generator.table
    end

    def name
      "COPY"
    end

    private

    attr_reader :data_generator, :output_adapter

    def csv_rows(row_numbers, connection)
      row_numbers.map do |i|
        data_generator.generate_row(i).map { |d| quote_data(d, connection) }.join(",")
      end
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
