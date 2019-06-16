# frozen_string_literal: true

module ActiveRecordDataLoader
  module ActiveRecord
    class DatetimeValueGenerator
      class << self
        def generator_for(model_class:, ar_column:)
          ->(row) { timestamp(model_class, row) }
        end

        def clear_cache
          @timestamps = Hash.new([])
        end

        private

        def timestamp(model, row_number)
          timestamps[model.name].shift if timestamps[model.name].size > 1

          timestamps[model.name][row_number] ||= Time.now.utc
        end

        def timestamps
          @timestamps ||= Hash.new([])
        end
      end
    end
  end
end
