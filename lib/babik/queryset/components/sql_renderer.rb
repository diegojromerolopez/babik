# frozen_string_literal: true

require 'erb'
require 'babik/database'

module Babik
  module QuerySet
    # SQL renderer
    class SQLRenderer
      attr_reader :queryset

      # Where the SQL templates are
      TEMPLATE_PATH = "#{__dir__}/../templates".freeze

      # Construct a new SQL rendered for a QuerySet
      # @param queryset [QuerySet] QuerySet to be rendered.
      def initialize(queryset)
        @queryset = queryset
      end

      # Render the SELECT statement
      # @return [String] SQL SELECT statement for this QuerySet.
      def select
        _render('select/main.sql.erb')
      end

      # Render the UPDATE statement
      # @param update_command [Hash{field: value}] Runs the update query.
      # @return [String] SQL UPDATE statement for this QuerySet.
      def update(update_command)
        @queryset.project!(['id'])
        sql = _render('update/main.sql.erb', { update_command: update_command })
        @queryset.unproject!
        sql
      end

      # Render the DELETE statement
      # @return [String] SQL DELETE statement for this QuerySet.
      def delete
        @queryset.project(['id'])
        sql = _render('delete/main.sql.erb')
        @queryset.unproject
        sql
      end

      # Return the SQL representation of all joins of the QuerySet
      # @return [String] A String with all LEFT JOIN statements required for this QuerySet.
      def left_joins
        # Join all left joins and return a string with the SQL code
        @queryset.left_joins_by_alias.values.map(&:sql).join("\n")
      end

      private

      # Render a file in a path
      # @api private
      # @param template_path [String] Relative (to {SQLRenderer::TEMPLATE_PATH}) path of the template file.
      # @param extra_replacements [Hash] Hash with the replacements. By default is an empty hash.
      # @return [String] Rendered SQL with QuerySet replacements completed
      def _render(template_path, extra_replacements = {})
        render = lambda do |partial_template_path, replacements|
          replacements[:render] = render
          _base_render(partial_template_path, **replacements)
        end
        replacements = extra_replacements.clone
        replacements[:queryset] = @queryset
        replacements[:render] = render
        _base_render(template_path, **replacements)
      end

      # Render a file
      # It first search in the dbms_adapter directory and if the file exists, uses that as template.
      # Otherwise, load the one placed in the default directory.
      # @api private
      # @param template_path [String] Relative (to {SQLRenderer::TEMPLATE_PATH}) path of the template file.
      # @param replacements [Hash] Hash with the replacements.
      # @return [String] Rendered SQL with QuerySet replacements completed
      def _base_render(template_path, replacements)
        dbms_adapter = _dbms_adapter
        dbms_adapter_template_path = "#{TEMPLATE_PATH}/#{dbms_adapter}/#{template_path}"
        template_path = if File.exist?(dbms_adapter_template_path)
                          dbms_adapter_template_path
                        else
                          "#{TEMPLATE_PATH}/default/#{template_path}"
                        end
        template_content = File.read(template_path)
        ::ERB.new(template_content).result_with_hash(**replacements).gsub(/ +/, ' ').gsub(/[\n ]{2,}/, "\n")
      end

      # Return the DBMS adapter.
      # @return [String] DBMS adapter (sqlite3, postgre, mysql, mariadb, oracle or mssql).
      def _dbms_adapter
        Babik::Database.config[:adapter]
      end
    end
  end
end
