# frozen_string_literal: true

module ActiveRecordDataLoader
  module ActiveRecord
    class EnumValueGenerator
      class << self
        def generator_for(model_class:, ar_column:, connection_factory:)
          values = enum_values_for(model_class, ar_column.sql_type, connection_factory)
          -> { values.sample }
        end

        private

        def enum_values_for(model_class, enum_type, connection_factory)
          connection = connection_factory.call

          if connection.adapter_name.downcase.to_sym == :postgresql
            postgres_enum_values_for(model_class, enum_type)
          elsif connection.adapter_name.downcase.to_s.start_with?("mysql")
            mysql_enum_values_for(model_class, enum_type)
          else
            []
          end
        end

        def postgres_enum_values_for(model_class, enum_type)
          model_class
            .connection
            .execute("SELECT unnest(enum_range(NULL::#{enum_type}))::text")
            .map(&:values)
            .flatten
            .compact
        end

        def mysql_enum_values_for(_model_class, enum_type)
          enum_type
            .to_s
            .downcase
            .gsub(/\Aenum\(|\)\Z/, "")
            .split(",")
            .map(&:strip)
            .map { |s| s.gsub(/\A'|'\Z/, "") }
        end
      end
    end
  end
end
