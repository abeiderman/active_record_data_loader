# frozen_string_literal: true

module ActiveRecordDataLoader
  module Dsl
    class Definition
      attr_reader :models

      def initialize(config = ActiveRecordDataLoader.configuration)
        @models = []
        @config = config
      end

      def model(klass, &block)
        t = Model.new(klass: klass, configuration: config)
        block&.call(t)
        models << t
        t
      end

      private

      attr_reader :config
    end
  end
end
