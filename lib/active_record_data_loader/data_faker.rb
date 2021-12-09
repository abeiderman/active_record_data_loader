# frozen_string_literal: true

require "forwardable"

module ActiveRecordDataLoader
  class DataFaker
    class << self
      extend Forwardable

      def_delegators :adapter, :person_name, :first_name, :middle_name, :last_name, :company_name

      private

      def adapter
        @adapter ||=
          if can_use?("ffaker", "2.1.0")
            FFakerGemAdapter.new
          elsif can_use?("faker", "1.9.3")
            FakerGemAdapter.new
          else
            NoGemAdapter.new
          end
      end

      def can_use?(gem, min_version)
        gemspec = Gem.loaded_specs[gem]
        return false unless gemspec.present? && gemspec.version >= Gem::Version.new(min_version)

        require gem
        true
      rescue LoadError
        false
      end
    end

    class FFakerGemAdapter
      extend Forwardable

      def_delegators :ffaker_name, :first_name, :last_name
      def_delegator :ffaker_name, :name, :person_name
      def_delegator :ffaker_name, :first_name, :middle_name

      def company_name
        FFaker::Company.name
      end

      def ffaker_name
        FFaker::Name
      end
    end

    class FakerGemAdapter
      extend Forwardable

      def_delegators :faker_name, :first_name, :middle_name, :last_name
      def_delegator :faker_name, :name, :person_name

      def company_name
        Faker::Company.name
      end

      def faker_name
        Faker::Name
      end
    end

    class NoGemAdapter
      FIRST_NAMES = %w[John Mary].freeze
      MIDDLE_NAMES = %w[Madison Ashley].freeze
      LAST_NAMES = %w[Doe Smith].freeze

      def first_name
        FIRST_NAMES.sample
      end

      def middle_name
        MIDDLE_NAMES.sample
      end

      def last_name
        LAST_NAMES.sample
      end

      def person_name
        "#{first_name} #{middle_name} #{last_name}"
      end

      def company_name
        "Acme"
      end
    end
  end
end
