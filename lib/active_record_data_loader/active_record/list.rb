# frozen_string_literal: true

module ActiveRecordDataLoader
  module ActiveRecord
    class List
      def self.for(enumerable, strategy: :random)
        if strategy == :random_cycle
          RandomCycle.new(enumerable)
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

      class RandomCycle
        def initialize(enumerable)
          @enumerable = enumerable
          @count = enumerable.count
          reset_list
        end

        def next
          value = @list.next
          reset_list if (@index += 1) >= @count
          value
        end

        private

        def reset_list
          @index = 0
          @enumerable = @enumerable.shuffle
          @list = @enumerable.cycle
        end
      end
    end
  end
end
