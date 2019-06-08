# frozen_string_literal: true

module ActiveRecordDataLoader
  module ActiveRecord
    class PolymorphicBelongsToConfiguration
      def self.config_for(polymorphic_settings:)
        ar_association = polymorphic_settings.model_class.reflect_on_association(
          polymorphic_settings.name
        )
        raise "#{name} only supports polymorphic associations" unless ar_association.polymorphic?

        new(polymorphic_settings, ar_association).polymorphic_config
      end

      def initialize(settings, ar_association)
        @settings = settings
        @ar_association = ar_association
        @model_count = settings.weighted_models.size
      end

      def polymorphic_config
        {
          @ar_association.foreign_type.to_sym => ->(row_number) { foreign_type(row_number) },
          @ar_association.foreign_key.to_sym => ->(row_number) { foreign_key(row_number) },
        }
      end

      private

      def foreign_type(row_number)
        possible_values[row_number % @model_count][0]
      end

      def foreign_key(row_number)
        possible_values[row_number % @model_count][1].sample
      end

      def possible_values
        @possible_values ||= begin
          values = @settings.models.keys.map do |klass|
            [klass.name, klass.all.pluck(klass.primary_key).to_a]
          end.to_h

          @settings.weighted_models.map { |klass| [klass.name, values[klass.name]] }
        end
      end
    end
  end
end
