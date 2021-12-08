# frozen_string_literal: true

module ActiveRecordDataLoader
  module ActiveRecord
    class List
      def self.for(enumerable, strategy: :random)
        if strategy == :cycle
          Cycle.new(enumerable)
        else
          Random.new(enumerable)
        end
      end

      class Random
        def initialize(enumerable)
          @list = enumerable
        end

        def next
          @list.sample
        end
      end

      class Cycle
        def initialize(enumerable)
          @list = enumerable.cycle
        end

        def next
          @list.next
        end
      end
    end
  end
end
