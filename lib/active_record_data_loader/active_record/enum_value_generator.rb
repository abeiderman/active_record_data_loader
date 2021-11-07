# frozen_string_literal: true

module ActiveRecordDataLoader
  module ActiveRecord
    class EnumValueGenerator
      class << self
        def generator_for(model_class:, ar_column:, connection_factory:)
          values = enum_values_for(ar_column.sql_type, connection_factory)
          -> { values.sample }
        end

        private

        def enum_values_for(enum_type, connection_factory)
          connection = connection_factory.call

          if connection.adapter_name.downcase.to_sym == :postgresql
            postgres_enum_values_for(connection, enum_type)
          elsif connection.adapter_name.downcase.to_s.start_with?("mysql")
            mysql_enum_values_for(enum_type)
          else
            []
          end
        ensure
          connection&.close
        end

        def postgres_enum_values_for(connection, enum_type)
          connection
            .execute("SELECT unnest(enum_range(NULL::#{enum_type}))::text")
            .map(&:values)
            .flatten
            .compact
        end

        def mysql_enum_values_for(enum_type)
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
