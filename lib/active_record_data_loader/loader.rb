# frozen_string_literal: true

module ActiveRecordDataLoader
  class Loader
    def initialize(configuration, definition)
      @configuration = configuration
      @definition = definition
    end

    def load_data
      ActiveRecordDataLoader::ActiveRecord::PerRowValueCache.clear

      output_adapter_class.with_output_options(output_adapter_options) do |output_adapter|
        definition.models.map { |m| load_model(m, output_adapter) }
      end
    end

    private

    attr_reader :definition, :configuration

    def load_model(model, output_adapter)
      generator = ActiveRecordDataLoader::ActiveRecord::ModelDataGenerator.new(
        model: model.klass,
        column_settings: model.columns,
        polymorphic_settings: model.polymorphic_associations,
        belongs_to_settings: model.belongs_to_associations,
        connection_factory: configuration.connection_factory
      )

      ActiveRecordDataLoader::TableLoader.load_data(
        batch_size: model.batch_size,
        total_rows: model.row_count,
        connection_handler: connection_handler,
        strategy: strategy_class.new(generator, output_adapter),
        logger: configuration.logger
      )
    end

    def output_adapter_class
      if configuration.output.fetch(:type) == :file
        ActiveRecordDataLoader::FileOutputAdapter
      else
        ActiveRecordDataLoader::ConnectionOutputAdapter
      end
    end

    def output_adapter_options
      timeout_commands =
        if connection_handler.supports_timeout?
          {
            pre_command: connection_handler.timeout_set_command(configuration.statement_timeout),
            post_command: connection_handler.reset_timeout_command,
          }
        else
          {}
        end

      configuration.output.merge(timeout_commands)
    end

    def strategy_class
      @strategy_class ||= if configuration.connection_factory.call.raw_connection.respond_to?(:copy_data)
                            ActiveRecordDataLoader::CopyStrategy
                          else
                            ActiveRecordDataLoader::BulkInsertStrategy
                          end
    end

    def connection_handler
      @connection_handler ||= ActiveRecordDataLoader::ConnectionHandler.new(
        connection_factory: configuration.connection_factory,
        statement_timeout: configuration.statement_timeout
      )
    end
  end
end
