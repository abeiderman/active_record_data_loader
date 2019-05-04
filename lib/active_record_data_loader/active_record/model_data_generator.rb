# frozen_string_literal: true

module DataLoader
  module ActiveRecord
    class ModelDataGenerator
      attr_reader :table

      def initialize(model:, column_settings:, polymorphic_settings: [])
        @model_class = model
        @table = model.table_name
        @polymorphic_settings = polymorphic_settings
        @column_settings = column_settings
      end

      def column_list
        columns.keys
      end

      def generate_row(row_number)
        column_list.map { |c| column_data(row_number, c) }
      end

      private

      def column_data(row_number, column)
        column_value = columns[column]
        return column_value unless column_value.respond_to?(:call)

        if column_value.arity == 2
          column_value.call(row_number, column)
        elsif column_value.arity == 1
          column_value.call(row_number)
        else
          column_value.call
        end
      end

      def columns
        @columns ||= [
          own_columns_config,
          belongs_to_config,
          polymorphic_config,
          @column_settings,
        ].reduce(:merge)
      end

      def own_columns_config
        @model_class
          .columns_hash
          .reject { |name| name == @model_class.primary_key }
          .select { |_, c| ColumnConfiguration.supported?(model_class: @model_class, ar_column: c) }
          .map { |_, c| ColumnConfiguration.config_for(model_class: @model_class, ar_column: c) }
          .reduce({}, :merge)
      end

      def belongs_to_config
        @model_class
          .reflect_on_all_associations
          .select(&:belongs_to?)
          .reject(&:polymorphic?)
          .map { |assoc| BelongsToConfiguration.config_for(ar_association: assoc) }
          .reduce({}, :merge)
      end

      def polymorphic_config
        @polymorphic_settings
          .map { |s| PolymorphicBelongsToConfiguration.config_for(polymorphic_settings: s) }
          .reduce({}, :merge)
      end
    end
  end
end
