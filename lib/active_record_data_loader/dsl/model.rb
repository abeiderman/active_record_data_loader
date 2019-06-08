# frozen_string_literal: true

module ActiveRecordDataLoader
  module Dsl
    class Model
      attr_reader :klass, :columns, :row_count, :polymorphic_associations

      def initialize(klass:, configuration:)
        @klass = klass
        @columns = {}
        @row_count = configuration.default_row_count
        @batch_size = configuration.default_batch_size
        @polymorphic_associations = []
      end

      def count(count)
        @row_count = count
      end

      def batch_size(size = nil)
        @batch_size = (size || @batch_size)
      end

      def column(name, func)
        @columns[name.to_sym] = func
      end

      def polymorphic(assoc_name, &block)
        @polymorphic_associations << PolymorphicAssociation.new(
          @klass, assoc_name
        ).tap { |a| block.call(a) }
      end
    end
  end
end
