# frozen_string_literal: true

module ActiveRecordDataLoader
  module ActiveRecord
    class DatetimeValueGenerator
      class << self
        def generator_for(model_class:, ar_column:)
          ->(row) { timestamp(model_class, row) }
        end

        private

        def timestamp(model, row_number)
          PerRowValueCache[:datetime].get_or_set(model: model, row: row_number) do
            Time.now.utc
          end
        end
      end
    end
  end
end
