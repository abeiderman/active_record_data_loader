# frozen_string_literal: true

module ActiveRecordDataLoader
  module ActiveRecord
    class BelongsToConfiguration
      def self.config_for(ar_association:, query: nil)
        raise "#{name} does not support polymorphic associations" if ar_association.polymorphic?

        { ar_association.join_foreign_key.to_sym => new(ar_association, query).foreign_key_func }
      end

      def initialize(ar_association, query)
        @ar_association = ar_association
        @query = query
      end

      def foreign_key_func
        -> { possible_values.sample }
      end

      private

      def possible_values
        @possible_values ||= base_query.pluck(@ar_association.join_primary_key).to_a
      end

      def base_query
        if @query&.respond_to?(:call)
          @query.call.all
        else
          @ar_association.klass.all
        end
      end
    end
  end
end
