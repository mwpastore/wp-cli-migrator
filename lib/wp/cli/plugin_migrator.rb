# frozen_string_literal: true
module WP
  module CLI
    class PluginMigrator
      attr_reader :action

      def initialize
        @action = nil
        @reactivate = false
      end

      def activate
        @action = @action == :deactivate ? nil : :activate
      end

      def deactivate
        @action = @action == :activate ? nil : :deactivate
      end

      def reactivate
        @reactivate = true
      end

      def activate?
        @action == :activate
      end

      def deactivate?
        @action == :deactivate
      end

      def reactivate?
        @action.nil? && @reactivate
      end
    end
  end
end
