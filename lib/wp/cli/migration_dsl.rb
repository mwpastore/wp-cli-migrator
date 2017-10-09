# frozen_string_literal: true
module WP
  module CLI
    module MigrationDSL
      private

      def build(file)
        @state_stack = nil
        # TODO: replace this with something safer and more robust, a la Sequel::Migrator?
        instance_eval File.read(file)
      end

      def mask(previous_states, current_state = :end, &block)
        fail "invalid state: expected outer #{[*previous_states].join('|')}" \
          unless [*previous_states].include?(@state_stack.last)

        @state_stack << current_state
        yield.tap { @state_stack.pop }
      end

      def migration(&block)
        fail 'only one migration allowed per file' \
          if @state_stack

        mask(@state_stack = [:start], :migration, &block)
      end

      def up(&block)
        mask(:migration, :up, &block)
      end

      def down(&block)
        mask(:migration, :down, &block)
      end

      def change(&block)
        mask(:migration, :up, &block)
        mask(:migration, :reverse) do
          mask(:reverse, :down, &block)
        end
      end

      def plugins(&block)
        mask([:up, :down], :plugins, &block)
      end

      def activate(plugin, keyword=:activate)
        mask(:plugins) do
          @migrations[direction][:plugins][plugin.to_sym].send \
            lookup.fetch(reverse?).fetch(keyword)
        end
      end

      # Look up the keyword based on whether or not we're currently computing a
      # reverse migration and the given keyword argument.
      def lookup
        @lookup ||= {
          false=>{
            :activate=>:activate,
            :deactivate=>:deactivate
          },
          true=>{
            :activate=>:deactivate,
            :deactivate=>:activate
          }
        }
      end

      def deactivate(plugin)
        activate(plugin, :deactivate)
      end

      def reactivate(plugin)
        mask(:plugins) do
          @migrations[direction][:plugins][plugin.to_sym].reactivate
        end
      end

      def direction
        @state_stack.detect { |s| s == :up || s == :down }
      end

      def up?
        direction == :up
      end

      def down?
        direction == :down
      end

      def reverse?
        @state_stack.include?(:reverse)
      end
    end
  end
end
