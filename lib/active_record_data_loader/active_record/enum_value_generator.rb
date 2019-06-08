# frozen_string_literal: true

module ActiveRecordDataLoader
  module ActiveRecord
    class EnumValueGenerator
      class << self
        def generator_for(model_class:, ar_column:)
          values = enum_values_for(model_class, ar_column.sql_type)
          -> { values.sample }
        end

        private

        def enum_values_for(model_class, enum_type)
          model_class
            .connection
            .execute("SELECT unnest(enum_range(NULL::#{enum_type}))::text")
            .map(&:values)
            .flatten
            .compact
        end
      end
    end
  end
end
