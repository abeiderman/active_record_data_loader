# frozen_string_literal: true

require "active_record_data_loader/version"
require "active_record"
require "active_record_data_loader/configuration"
require "active_record_data_loader/data_faker"
require "active_record_data_loader/active_record/integer_value_generator"
require "active_record_data_loader/active_record/text_value_generator"
require "active_record_data_loader/active_record/enum_value_generator"
require "active_record_data_loader/active_record/column_configuration"
require "active_record_data_loader/active_record/belongs_to_configuration"
require "active_record_data_loader/active_record/polymorphic_belongs_to_configuration"
require "active_record_data_loader/active_record/model_data_generator"
require "active_record_data_loader/dsl/belongs_to_association"
require "active_record_data_loader/dsl/polymorphic_association"
require "active_record_data_loader/dsl/model"
require "active_record_data_loader/dsl/definition"
require "active_record_data_loader/copy_strategy"
require "active_record_data_loader/bulk_insert_strategy"
require "active_record_data_loader/loader"

module ActiveRecordDataLoader
  def self.define(config = ActiveRecordDataLoader.configuration, &block)
    LoaderProxy.new(
      configuration,
      ActiveRecordDataLoader::Dsl::Definition.new(config).tap { |l| l.instance_eval(&block) }
    )
  end

  def self.configure(&block)
    @configuration = ActiveRecordDataLoader::Configuration.new.tap { |c| block.call(c) }
  end

  def self.configuration
    @configuration ||= ActiveRecordDataLoader::Configuration.new
  end

  class LoaderProxy
    def initialize(configuration, definition)
      @configuration = configuration
      @definition = definition
    end

    def load_data
      definition.models.map do |m|
        generator = ActiveRecordDataLoader::ActiveRecord::ModelDataGenerator.new(
          model: m.klass,
          column_settings: m.columns,
          polymorphic_settings: m.polymorphic_associations,
          belongs_to_settings: m.belongs_to_associations
        )

        ActiveRecordDataLoader::Loader.load_data(
          data_generator: generator,
          batch_size: m.batch_size,
          total_rows: m.row_count,
          configuration: configuration
        )
      end
    end

    private

    attr_reader :definition, :configuration
  end
end
