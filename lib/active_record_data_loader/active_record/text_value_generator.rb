# frozen_string_literal: true

module DataLoader
  module ActiveRecord
    class TextValueGenerator
      GENERATORS = {
        likely_a_person_full_name?: -> { Faker::Name.name },
        likely_a_first_name?: -> { Faker::Name.first_name },
        likely_a_middle_name?: -> { Faker::Name.middle_name },
        likely_a_last_name?: -> { Faker::Name.last_name },
        likely_an_organization_name?: -> { Faker::Company.name },
      }.freeze

      class << self
        def generator_for(model_class:, ar_column:)
          scenario = GENERATORS.keys.find { |m| send(m, model_class, ar_column) }
          generator = GENERATORS.fetch(scenario, -> { SecureRandom.uuid })

          -> { truncate_if_needed(generator.call, ar_column.limit) }
        end

        private

        def truncate_if_needed(value, limit)
          return value if limit.nil?

          value[0...limit]
        end

        def likely_a_person_full_name?(model_class, ar_column)
          ar_column.name.downcase == "name" && likely_a_person?(model_class)
        end

        def likely_a_first_name?(_, ar_column)
          ar_column.name.downcase == "first_name" || ar_column.name.downcase == "firstname"
        end

        def likely_a_middle_name?(_, ar_column)
          ar_column.name.downcase == "middle_name" || ar_column.name.downcase == "middlename"
        end

        def likely_a_last_name?(_, ar_column)
          ar_column.name.downcase == "last_name" || ar_column.name.downcase == "lastname"
        end

        def likely_an_organization_name?(model_class, ar_column)
          ar_column.name.downcase == "company_name" ||
            ar_column.name.downcase == "companyname" ||
            ar_column.name.downcase == "business_name" ||
            ar_column.name.downcase == "businessname" ||
            (ar_column.name.downcase == "name" && likely_an_organization?(model_class))
        end

        def likely_a_person?(model_class)
          %w[
            customer human employee person user
          ].any? do |word|
            model_class.name.downcase.start_with?(word) || model_class.name.downcase.end_with?(word)
          end
        end

        def likely_an_organization?(model_class)
          %w[
            business company enterprise legalentity organization
          ].any? do |word|
            model_class.name.downcase.start_with?(word) || model_class.name.downcase.end_with?(word)
          end
        end
      end
    end
  end
end
