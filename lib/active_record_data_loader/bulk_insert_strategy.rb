# frozen_string_literal: true

module ActiveRecordDataLoader
  class BulkInsertStrategy
    def initialize(data_generator)
      @data_generator = data_generator
    end

    def load_batch(row_numbers)
      connection = ::ActiveRecord::Base.connection

      connection.insert(<<~SQL)
        INSERT INTO #{quoted_table_name(connection)} (#{column_list(connection)})
        VALUES #{values(row_numbers, connection)}
      SQL
    end

    def table_name
      data_generator.table
    end

    def name
      "BULK INSERT"
    end

    private

    attr_reader :data_generator

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
        .map { |i| "(#{row_values(i, connection)})" }
        .join(",")
    end

    def row_values(row_number, connection)
      data_generator
        .generate_row(row_number)
        .map { |v| connection.quote(v) }
        .join(",")
    end
  end
end
