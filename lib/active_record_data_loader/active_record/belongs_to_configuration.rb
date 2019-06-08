# frozen_string_literal: true

module ActiveRecordDataLoader
  module ActiveRecord
    class BelongsToConfiguration
      def self.config_for(ar_association:)
        raise "#{name} does not support polymorphic associations" if ar_association.polymorphic?

        { ar_association.join_foreign_key.to_sym => new(ar_association).foreign_key_func }
      end

      def initialize(ar_association)
        @ar_association = ar_association
      end

      def foreign_key_func
        -> { possible_values.sample }
      end

      private

      def possible_values
        @possible_values ||= @ar_association.klass.all.pluck(@ar_association.join_primary_key).to_a
      end
    end
  end
end
