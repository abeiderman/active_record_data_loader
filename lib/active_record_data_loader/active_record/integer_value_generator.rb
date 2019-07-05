# frozen_string_literal: true

module ActiveRecordDataLoader
  module ActiveRecord
    class IntegerValueGenerator
      class << self
        def generator_for(model_class:, ar_column:, connection_factory: nil)
          range_limit = [(256**number_of_bytes(ar_column)) / 2 - 1, 1_000_000_000].min

          -> { rand(0..range_limit) }
        end

        private

        def number_of_bytes(ar_column)
          ar_column.limit || 8
        end
      end
    end
  end
end
