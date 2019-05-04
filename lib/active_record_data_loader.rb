# frozen_string_literal: true

require "active_record_data_loader/version"
require "active_record"
require "faker"
require "active_record_data_loader/configuration"
require "active_record_data_loader/active_record/integer_value_generator"
require "active_record_data_loader/active_record/text_value_generator"
require "active_record_data_loader/active_record/enum_value_generator"
require "active_record_data_loader/active_record/column_configuration"
require "active_record_data_loader/active_record/belongs_to_configuration"
require "active_record_data_loader/active_record/polymorphic_belongs_to_configuration"
require "active_record_data_loader/active_record/model_data_generator"
require "active_record_data_loader/dsl/polymorphic_association"
require "active_record_data_loader/dsl/model"
require "active_record_data_loader/dsl/definition"
require "active_record_data_loader/copy_strategy"
require "active_record_data_loader/bulk_insert_strategy"
require "active_record_data_loader/loader"

module DataLoader
  def self.define(config = DataLoader.configuration, &block)
    LoaderProxy.new(
      configuration,
      DataLoader::Dsl::Definition.new(config).tap { |l| l.instance_eval(&block) }
    )
  end

  def self.configure(&block)
    @configuration = DataLoader::Configuration.new.tap { |c| block.call(c) }
  end

  def self.configuration
    @configuration ||= DataLoader::Configuration.new
  end

  class LoaderProxy
    def initialize(configuration, definition)
      @configuration = configuration
      @definition = definition
    end

    def load_data
      definition.models.map do |m|
        generator = DataLoader::ActiveRecord::ModelDataGenerator.new(
          model: m.klass,
          column_settings: m.columns,
          polymorphic_settings: m.polymorphic_associations
        )

        DataLoader::Loader.load_data(
          data_generator: generator,
          batch_size: m.batch_size,
          total_rows: m.row_count,
          logger: configuration.logger
        )
      end
    end

    private

    attr_reader :definition, :configuration
  end
end
