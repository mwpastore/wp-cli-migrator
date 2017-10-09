# frozen_string_literal: true
module WP
  module CLI
    class Migrator
      include MigrationDSL

      OPTION_KEY = 'wp_cli_migrator_state'.freeze
      WP_CLI = ENV.fetch('WP_CLI', 'wp').split(/\s+/).freeze # TODO: arbitrary command execution
      WP_CLI_OPTIONS = %w{--skip-themes --skip-packages}

      def initialize(path, stage, target=nil, options={})
        @path = Dir.new(path || 'migrations')

        fail 'unknown stage (try :pre or :post)' \
          unless [:pre, :post].include?(stage)

        @stage = stage
        @migrations = {
          :up=>{
            :plugins=>Hash.new { |h, k| h[k] = PluginMigrator.new }
          },
          :down=>{
            :plugins=>Hash.new { |h, k| h[k] = PluginMigrator.new }
          }
        }
        @options = options

        fail 'no migrations found!' \
          if available.empty?

        fail 'migrator in invalid state (database ahead of available migrations)!' \
          if current > available[-1][0]

        @target =
          if target == 0 then 0
          elsif target.nil? then available[-1][0]
          elsif available.transpose.first.include?(target) then target
          else fail 'target migration not found!'
          end

        return if current?

        candidate_range, @direction =
          if ahead? # database is ahead of target, so migrate down
            [@target.succ .. current, :down]
          elsif behind? # database is behind target, so migrate up
            [current.succ .. @target, :up]
          end

        available.each do |i, file|
          build File.expand_path(file, @path.path) if candidate_range.include?(i)
        end
      end

      def run
        if current?
          puts "#{@stage}-migrator is already current"
        else
          puts "#{@stage}-migrating #{@direction}"
          run_plugins
          self.current = @target
        end
      end

      def run_plugins
        # only perform certain actions depending on the stage
        filter_action = { :pre=>:deactivate, :post=>:activate }[@stage]
        plugins = @migrations[@direction][:plugins].select do |_, m|
          m.action == filter_action || m.reactivate?
        end

        plugin_names = plugins.map(&:first)
        missing = plugin_names - (plugin_names & installed_plugin_names)

        fail "unable to #{filter_action} plugins that are not installed (#{missing.join(', ')})" \
          unless missing.empty? || @options[:force]

        plugins.each do |plugin, _migrator|
          system(*WP_CLI.dup.push('plugin', filter_action.to_s, plugin.to_s).concat(WP_CLI_OPTIONS))

          fail "unable to #{filter_action} plugin #{plugin}" \
            unless $?.success?
        end
      end

      def current?
        status == :current
      end

      def behind?
        status == :behind
      end

      def ahead?
        status == :ahead
      end

      private

      def status
        @status ||= [:current, :behind, :ahead][@target <=> current]
      end

      def option_key
        "#{OPTION_KEY}_#{@stage}"
      end

      def current=(new_value)
        system(*WP_CLI.dup.push('option', 'update', option_key, new_value.to_s).concat(WP_CLI_OPTIONS))

        fail 'unable to set current migration state in `wp_options`' \
          unless $?.success?
      end

      def current
        @current ||= begin
          value = %x{#{WP_CLI.join(' ')} option get #{option_key} #{WP_CLI_OPTIONS.join(' ')}}.chomp

          return -1 if value.empty? && $?.exitstatus == 1

          fail 'unable to retrieve current migration state from `wp_options`' \
            unless $?.success?

          fail "invalid current migration state in `wp_options` at #{option_key}" \
            if value[/\D/]

          value.to_i
        end
      end

      def installed_plugin_names
        %x{#{WP_CLI.join(' ')} plugin list --field=name #{WP_CLI_OPTIONS.join(' ')}}
          .split("\n")
          .map(&:to_sym)
      end

      def available
        @path.each.map do |file|
          if pos = file[/\A(\d+).*?\.rb\z/, 1]
            [pos.to_i, file]
          end
        end.compact.sort { |a, b| a[0] <=> b[0] }
      end
    end
  end
end
