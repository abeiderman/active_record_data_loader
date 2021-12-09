# frozen_string_literal: true

module ActiveRecordDataLoader
  module Dsl
    class Model
      attr_reader :klass, :columns, :row_count, :polymorphic_associations, :belongs_to_associations,
                  :raise_on_duplicates_flag

      def initialize(klass:, configuration:)
        @klass = klass
        @columns = {}
        @row_count = configuration.default_row_count
        @batch_size = configuration.default_batch_size
        @raise_on_duplicates_flag = configuration.raise_on_duplicates
        @max_duplicate_retries = configuration.max_duplicate_retries
        @polymorphic_associations = []
        @belongs_to_associations = []
      end

      def count(count)
        @row_count = count
      end

      def batch_size(size = nil)
        @batch_size = (size || @batch_size)
      end

      def raise_on_duplicates
        @raise_on_duplicates_flag = true
      end

      def do_not_raise_on_duplicates
        @raise_on_duplicates_flag = false
      end

      def max_duplicate_retries(retries = nil)
        return @max_duplicate_retries if retries.nil?

        @max_duplicate_retries = retries
      end

      def column(name, func)
        @columns[name.to_sym] = func
      end

      def polymorphic(assoc_name, &block)
        @polymorphic_associations << PolymorphicAssociation.new(
          @klass, assoc_name
        ).tap { |a| block.call(a) }
      end

      def belongs_to(assoc_name, eligible_set: nil)
        @belongs_to_associations << BelongsToAssociation.new(@klass, assoc_name, eligible_set)
      end
    end
  end
end
