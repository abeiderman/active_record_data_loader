# frozen_string_literal: true

module ActiveRecordDataLoader
  class CopyStrategy
    def initialize(data_generator)
      @data_generator = data_generator
    end

    def load_batch(row_numbers, connection)
      csv_data = csv_data_batch(row_numbers, connection)

      raw_connection = connection.raw_connection
      raw_connection.copy_data(copy_command(connection)) { raw_connection.put_copy_data(csv_data) }
    end

    def table_name
      data_generator.table
    end

    def name
      "COPY"
    end

    private

    attr_reader :data_generator

    def csv_data_batch(row_numbers, connection)
      row_numbers.map do |i|
        data_generator.generate_row(i).map { |d| quote_data(d, connection) }.join(",")
      end.join("\n")
    end

    def copy_command(connection)
      @copy_command ||= begin
        quoted_table_name = connection.quote_table_name(data_generator.table)
        columns = data_generator
                  .column_list
                  .map { |c| connection.quote_column_name(c) }
                  .join(", ")

        <<~SQL
          COPY #{quoted_table_name} (#{columns})
            FROM STDIN WITH (FORMAT CSV)
        SQL
      end
    end

    def quote_data(data, connection)
      return if data.nil?

      "\"#{connection.quote_string(data.to_s)}\""
    end
  end
end
