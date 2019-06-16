# frozen_string_literal: true

module ActiveRecordDataLoader
  module ActiveRecord
    class ColumnConfiguration
      class << self
        VALUE_GENERATORS = {
          enum: EnumValueGenerator,
          integer: IntegerValueGenerator,
          string: TextValueGenerator,
          text: TextValueGenerator,
          datetime: DatetimeValueGenerator,
        }.freeze

        def config_for(model_class:, ar_column:)
          raise_error_if_not_supported(model_class, ar_column)

          {
            ar_column.name.to_sym => VALUE_GENERATORS[ar_column.type].generator_for(
              model_class: model_class,
              ar_column: ar_column
            ),
          }
        end

        def supported?(model_class:, ar_column:)
          return false if model_class.reflect_on_association(ar_column.name)

          VALUE_GENERATORS.keys.include?(ar_column.type)
        end

        private

        def raise_error_if_not_supported(model_class, ar_column)
          return if supported?(model_class: model_class, ar_column: ar_column)

          raise <<~ERROR
            Column '#{ar_column.name}' of type '#{ar_column.type}' in model '#{model_class.name}' not supported"
          ERROR
        end
      end
    end
  end
end
