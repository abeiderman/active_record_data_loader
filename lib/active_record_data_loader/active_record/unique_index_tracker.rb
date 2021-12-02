# frozen_string_literal: true

module ActiveRecordDataLoader
  module ActiveRecord
    class UniqueIndexTracker
      Index = Struct.new(:name, :columns, :column_indexes, keyword_init: true)

      def initialize(model:, connection_factory:)
        @model = model
        @table = model.table_name
        @unique_indexes = []
        @unique_values_used = {}
        find_unique_indexes(connection_factory)
      end

      def map_indexed_columns(column_list)
        @unique_indexes = @raw_unique_indexes.map do |index|
          @unique_values_used[index.name] = Set.new
          columns = index.columns.map(&:to_sym)
          Index.new(
            name: index.name,
            columns: columns,
            column_indexes: columns.map { |c| column_list.find_index(c) }
          )
        end
      end

      def repeating_unique_values?(row)
        @unique_indexes.map do |index|
          values = index.column_indexes.map { |i| row[i] }
          @unique_values_used.fetch(index.name).include?(values)
        end.any?
      end

      def capture_unique_values(row)
        return unless row.present?

        @unique_indexes.each do |index|
          values = index.column_indexes.map { |i| row[i] }
          @unique_values_used.fetch(index.name) << values
        end
        row
      end

      def contained_in_index?(ar_column)
        target_column = if @model.reflect_on_association(ar_column.name)&.belongs_to?
                          ar_column.join_foreign_key.to_sym
                        else
                          ar_column.name.to_sym
                        end

        @raw_unique_indexes.flat_map { |i| i.columns.map(&:to_sym) }.include?(target_column)
      end

      private

      attr_reader :table

      def find_unique_indexes(connection_factory)
        connection = connection_factory.call
        @raw_unique_indexes = connection.indexes(table).select(&:unique)
      ensure
        connection&.close
      end
    end
  end
end
