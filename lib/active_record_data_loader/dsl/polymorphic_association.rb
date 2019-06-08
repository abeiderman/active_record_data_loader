# frozen_string_literal: true

module ActiveRecordDataLoader
  module Dsl
    class PolymorphicAssociation
      attr_reader :model_class, :name, :models

      def initialize(model_class, name)
        @model_class = model_class
        @name = name
        @models = {}
      end

      def model(klass, weight: 1)
        @models[klass] = weight.to_i
      end

      def weighted_models
        gcd = models.values.reduce(:gcd)

        models.map { |m, w| [m] * (w / gcd) }.flatten
      end
    end
  end
end
