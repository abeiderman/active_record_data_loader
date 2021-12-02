# frozen_string_literal: true

module ActiveRecordDataLoader
  class BulkInsertStrategy
    def initialize(data_generator, file_adapter)
      @data_generator = data_generator
      @file_adapter = file_adapter
    end

    def load_batch(row_numbers, connection)
      command = <<~SQL
        INSERT INTO #{quoted_table_name(connection)} (#{column_list(connection)})
        VALUES #{values(row_numbers, connection)}
      SQL
      insert(connection: connection, command: command)
      file_adapter.insert(command)
    end

    def table_name
      data_generator.table
    end

    def name
      "BULK INSERT"
    end

    private

    attr_reader :data_generator, :file_adapter

    def insert(connection:, command:)
      connection.insert(command)
    end

    def quoted_table_name(connection)
      @quoted_table_name ||= connection.quote_table_name(data_generator.table)
    end

    def column_list(connection)
      @column_list ||= data_generator
                       .column_list
                       .map { |c| connection.quote_column_name(c) }
                       .join(",")
    end

    def values(row_numbers, connection)
      row_numbers
        .map { |i| row_values(i, connection) }
        .compact
        .join(",")
    end

    def row_values(row_number, connection)
      row = data_generator.generate_row(row_number)
      return unless row.present?

      "(#{row.map { |v| connection.quote(v) }.join(',')})"
    end
  end
end
