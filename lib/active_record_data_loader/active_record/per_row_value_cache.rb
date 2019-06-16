# frozen_string_literal: true

module ActiveRecordDataLoader
  module ActiveRecord
    class PerRowValueCache
      class << self
        def [](key)
          caches[key] ||= new
        end

        def clear
          @caches = {}
        end

        private

        def caches
          @caches ||= clear
        end
      end

      def initialize
        @row_caches = Hash.new { |hash, key| hash[key] = {} }
      end

      def get_or_set(model:, row:)
        @row_caches[model.name].shift if @row_caches[model.name].size > 1

        @row_caches[model.name][row] ||= yield
      end
    end
  end
end
