# frozen_string_literal: true

module ActiveRecordDataLoader
  module ActiveRecord
    class ModelDataGenerator
      attr_reader :table

      def initialize(
        model:,
        column_settings:,
        polymorphic_settings: [],
        belongs_to_settings: [],
        connection_factory:
      )
        @model_class = model
        @table = model.table_name
        @column_settings = column_settings
        @polymorphic_settings = polymorphic_settings
        @belongs_to_settings = belongs_to_settings.map { |s| [s.name, s.query] }.to_h
        @connection_factory = connection_factory
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
          .map do |_, c|
            ColumnConfiguration.config_for(
              model_class: @model_class,
              ar_column: c,
              connection_factory: @connection_factory
            )
          end
          .reduce({}, :merge)
      end

      def belongs_to_config
        @model_class
          .reflect_on_all_associations
          .select(&:belongs_to?)
          .reject(&:polymorphic?)
          .map do |assoc|
            BelongsToConfiguration.config_for(ar_association: assoc, query: @belongs_to_settings[assoc.name])
          end
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
