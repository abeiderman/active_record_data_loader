# frozen_string_literal: true

require "active_record_data_loader/version"
require "active_record"
require "active_record_data_loader/errors"
require "active_record_data_loader/configuration"
require "active_record_data_loader/connection_handler"
require "active_record_data_loader/data_faker"
require "active_record_data_loader/active_record/list"
require "active_record_data_loader/active_record/per_row_value_cache"
require "active_record_data_loader/active_record/integer_value_generator"
require "active_record_data_loader/active_record/text_value_generator"
require "active_record_data_loader/active_record/enum_value_generator"
require "active_record_data_loader/active_record/datetime_value_generator"
require "active_record_data_loader/active_record/column_data_provider"
require "active_record_data_loader/active_record/belongs_to_data_provider"
require "active_record_data_loader/active_record/polymorphic_belongs_to_data_provider"
require "active_record_data_loader/active_record/unique_index_tracker"
require "active_record_data_loader/active_record/model_data_generator"
require "active_record_data_loader/dsl/belongs_to_association"
require "active_record_data_loader/dsl/polymorphic_association"
require "active_record_data_loader/dsl/model"
require "active_record_data_loader/dsl/definition"
require "active_record_data_loader/file_output_adapter"
require "active_record_data_loader/null_output_adapter"
require "active_record_data_loader/copy_strategy"
require "active_record_data_loader/bulk_insert_strategy"
require "active_record_data_loader/table_loader"
require "active_record_data_loader/loader"

module ActiveRecordDataLoader
  def self.define(config = ActiveRecordDataLoader.configuration, &block)
    ActiveRecordDataLoader::Loader.new(
      config,
      ActiveRecordDataLoader::Dsl::Definition.new(config).tap { |l| l.instance_eval(&block) }
    )
  end

  def self.configure(&block)
    @configuration = ActiveRecordDataLoader::Configuration.new.tap { |c| block.call(c) }
  end

  def self.configuration
    @configuration ||= ActiveRecordDataLoader::Configuration.new
  end
end
