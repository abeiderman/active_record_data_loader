# frozen_string_literal: true

module ActiveRecordDataLoader
  module Dsl
    class BelongsToAssociation
      attr_reader :model_class, :name, :query

      def initialize(model_class, name, query = nil)
        @model_class = model_class
        @name = name
        @query = query
      end
    end
  end
end
