# frozen_string_literal: true

module ActiveRecordDataLoader
  module ActiveRecord
    class BelongsToDataProvider
      def self.provider_for(ar_association:, query: nil, strategy: :random)
        raise "#{name} does not support polymorphic associations" if ar_association.polymorphic?

        { ar_association.join_foreign_key.to_sym => new(ar_association, query, strategy).foreign_key_func }
      end

      def initialize(ar_association, query, strategy)
        @ar_association = ar_association
        @query = query
        @strategy = strategy
      end

      def foreign_key_func
        -> { possible_values.next }
      end

      private

      def possible_values
        @possible_values ||= List.for(base_query.pluck(@ar_association.join_primary_key), strategy: @strategy)
      end

      def base_query
        if @query.respond_to?(:call)
          @query.call.all
        else
          @ar_association.klass.all
        end
      end
    end
  end
end
