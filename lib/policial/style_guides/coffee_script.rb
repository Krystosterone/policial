require 'coffeelint'

module Policial
  module StyleGuides
    class CoffeeScript < Base
      DEFAULT_CONFIG_FILENAME = '.coffeescript.yml'

      class << self
        attr_writer :config_file

        def config_file
          @config_file || DEFAULT_CONFIG_FILENAME
        end
      end

      def violations_in_file(file)
        Coffeelint.lint(file.content, config).each_with_object({}) do |offense, violations|
          line_number = offense['lineNumber']
          message = offense['message']

          if violations[line_number]
            violations[line_number].add_messages([message])
          else
            violations[line_number] = Violation.new(file, line_number, message)
          end
        end.values
      end

      private

      def config
        @config ||= @repo_config.for(self.class)
      end
    end
  end
end
