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
          if Gem.loaded_specs.key?("ffaker")
            require "ffaker"
            FFakerGemAdapter.new
          elsif Gem.loaded_specs.key?("faker")
            require "faker"
            FakerGemAdapter.new
          else
            NoGemAdapter.new
          end
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
