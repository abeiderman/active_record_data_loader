# frozen_string_literal: true

module ActiveRecordDataLoader
  module ActiveRecord
    class ColumnDataProvider
      class << self
        VALUE_GENERATORS = {
          enum: EnumValueGenerator,
          integer: IntegerValueGenerator,
          string: TextValueGenerator,
          text: TextValueGenerator,
          datetime: DatetimeValueGenerator,
        }.freeze

        def provider_for(model_class:, ar_column:, connection_factory:)
          raise_error_if_not_supported(model_class, ar_column)

          {
            ar_column.name.to_sym => VALUE_GENERATORS[column_type(ar_column)].generator_for(
              model_class: model_class,
              ar_column: ar_column,
              connection_factory: connection_factory
            ),
          }
        end

        def supported?(model_class:, ar_column:)
          return false if model_class.reflect_on_association(ar_column.name)

          VALUE_GENERATORS.keys.include?(column_type(ar_column))
        end

        private

        def raise_error_if_not_supported(model_class, ar_column)
          return if supported?(model_class: model_class, ar_column: ar_column)

          raise <<~ERROR
            Column '#{ar_column.name}' of type '#{ar_column.type}' in model '#{model_class.name}' not supported"
          ERROR
        end

        def column_type(ar_column)
          if ar_column.type == :string && ar_column.sql_type.to_s.downcase.start_with?("enum")
            :enum
          else
            ar_column.type
          end
        end
      end
    end
  end
end
