# frozen_string_literal: true

module ActiveRecordDataLoader
  module Dsl
    class PolymorphicAssociation
      attr_reader :model_class, :name, :models, :queries

      def initialize(model_class, name)
        @model_class = model_class
        @name = name
        @models = {}
        @queries = {}
      end

      def model(klass, weight: 1, eligible_set: nil)
        @models[klass] = weight.to_i
        @queries[klass] = eligible_set if eligible_set
      end

      def weighted_models
        gcd = models.values.reduce(:gcd)

        models.map { |m, w| [m] * (w / gcd) }.flatten
      end
    end
  end
end
