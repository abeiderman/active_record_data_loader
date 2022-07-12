# frozen_string_literal: true

module ActiveRecordDataLoader
  module ActiveRecord
    class ModelDataGenerator
      attr_reader :table

      def initialize(
        model:,
        column_settings:,
        connection_factory:,
        logger:,
        raise_on_duplicates:,
        max_duplicate_retries:,
        polymorphic_settings: [],
        belongs_to_settings: []
      )
        @model_class = model
        @table = model.table_name
        @column_settings = column_settings
        @polymorphic_settings = polymorphic_settings
        @belongs_to_settings = belongs_to_settings.map { |s| [s.name, s.query] }.to_h
        @connection_factory = connection_factory
        @raise_on_duplicates = raise_on_duplicates
        @max_duplicate_retries = max_duplicate_retries
        @logger = logger
        @index_tracker = UniqueIndexTracker.new(model: model, connection_factory: connection_factory)
        @index_tracker.map_indexed_columns(column_list)
      end

      def column_list
        columns.keys
      end

      def generate_row(row_number)
        @index_tracker.capture_unique_values(generate_row_with_retries(row_number))
      end

      private

      def generate_row_with_retries(row_number)
        retries = 0
        while @index_tracker.repeating_unique_values?(row = generate_candidate_row(row_number))
          if (retries += 1) > @max_duplicate_retries
            raise DuplicateKeyError, <<~MSG if @raise_on_duplicates
              Exhausted retries looking for unique values for row #{row_number} for '#{table}'.
              Table '#{table}' has unique indexes that would have prevented inserting this row. If you would
              like to skip non-unique rows instead of raising, configure `raise_on_duplicates` to be `false`.
            MSG

            @logger.warn(
              "[ActiveRecordDataLoader] " \
              "Exhausted retries looking for unique values. Skipping row #{row_number} for '#{table}'."
            )
            return nil
          else
            @logger.info(
              "[ActiveRecordDataLoader] " \
              "Retrying row #{row_number} for '#{table}' looking for unique values compliant with indexes. " \
              "Retry number #{retries}."
            )
          end
        end
        row
      end

      def generate_candidate_row(row_number)
        column_list.map { |c| column_data(row_number, c) }
      end

      def column_data(row_number, column)
        column_value = columns[column]
        return column_value unless column_value.respond_to?(:call)

        if column_value.arity == 2
          column_value.call(row_number, column)
        elsif column_value.arity == 1
          column_value.call(row_number)
        else
          column_value.call
        end
      end

      def columns
        @columns ||= [
          own_columns_config,
          belongs_to_config,
          polymorphic_config,
          @column_settings,
        ].reduce(:merge)
      end

      def own_columns_config
        @model_class
          .columns_hash
          .reject { |name| name == @model_class.primary_key }
          .select { |_, c| ColumnDataProvider.supported?(model_class: @model_class, ar_column: c) }
          .map do |_, c|
            ColumnDataProvider.provider_for(
              model_class: @model_class,
              ar_column: c,
              connection_factory: @connection_factory
            )
          end
          .reduce({}, :merge)
      end

      def belongs_to_config
        @model_class
          .reflect_on_all_associations
          .select(&:belongs_to?)
          .reject(&:polymorphic?)
          .map do |assoc|
            BelongsToDataProvider.provider_for(
              ar_association: assoc,
              query: @belongs_to_settings[assoc.name],
              strategy: column_config_strategy(assoc)
            )
          end
          .reduce({}, :merge)
      end

      def polymorphic_config
        @polymorphic_settings
          .map do |s|
            PolymorphicBelongsToDataProvider.provider_for(
              polymorphic_settings: s,
              strategy: column_config_strategy(s.model_class.reflect_on_association(s.name))
            )
          end
          .reduce({}, :merge)
      end

      def column_config_strategy(column)
        if @index_tracker.contained_in_index?(column)
          :random_cycle
        else
          :random
        end
      end
    end
  end
end
