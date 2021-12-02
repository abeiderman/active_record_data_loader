# frozen_string_literal: true

module ActiveRecordDataLoader
  class Loader
    def initialize(configuration, definition)
      @configuration = configuration
      @definition = definition
    end

    def load_data
      ActiveRecordDataLoader::ActiveRecord::PerRowValueCache.clear

      file_adapter_class.with_output_options(file_adapter_options) do |file_adapter|
        definition.models.map { |m| load_model(m, file_adapter) }
      end
    end

    private

    attr_reader :definition, :configuration

    def load_model(model, file_adapter)
      generator = ActiveRecordDataLoader::ActiveRecord::ModelDataGenerator.new(
        model: model.klass,
        column_settings: model.columns,
        polymorphic_settings: model.polymorphic_associations,
        belongs_to_settings: model.belongs_to_associations,
        connection_factory: configuration.connection_factory,
        raise_on_duplicates: configuration.raise_on_duplicates,
        logger: configuration.logger
      )

      ActiveRecordDataLoader::TableLoader.load_data(
        batch_size: model.batch_size,
        total_rows: model.row_count,
        connection_handler: connection_handler,
        strategy: strategy_class.new(generator, file_adapter),
        logger: configuration.logger
      )
    end

    def file_adapter_class
      if configuration.output.present?
        ActiveRecordDataLoader::FileOutputAdapter
      else
        ActiveRecordDataLoader::NullOutputAdapter
      end
    end

    def file_adapter_options
      timeout_commands =
        if connection_handler.supports_timeout?
          {
            pre_command: connection_handler.timeout_set_command,
            post_command: connection_handler.reset_timeout_command,
          }
        else
          {}
        end

      timeout_commands.merge(filename: configuration.output)
    end

    def strategy_class
      @strategy_class ||= if connection_handler.supports_copy?
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
