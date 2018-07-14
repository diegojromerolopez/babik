# frozen_string_literal: true

require 'erb'

module Babik
  module QuerySet
    # SQL renderer
    class SQLRenderer

      attr_reader :queryset

      TEMPLATE_PATH = "#{__dir__}/../templates"

      def initialize(queryset)
        @queryset = queryset
      end

      def select
        self._render('select/main.sql.erb')
      end

      def update
        @queryset.project(['id'])
        sql = self._render('update/main.sql.erb')
        @queryset.unproject
        sql
      end

      def delete
        @queryset.project(['id'])
        sql = self._render('delete/main.sql.erb')
        @queryset.unproject
        sql
      end

      def left_joins
        # Join all left joins and return a string with the SQL code
        @queryset.left_joins_by_alias.values.map(&:sql).join("\n")
      end

      def _render(template_path)
        render = lambda do |partial_template_path, replacements|
          _base_render(partial_template_path, **replacements)
        end
        _base_render(template_path, queryset: @queryset, render: render)
      end

      def _base_render(template_path, replacements)
        dbms_adapter = _dbms_adapter
        dbms_adapter_template_path = "#{TEMPLATE_PATH}/#{dbms_adapter}#{template_path}"
        template_path = if File.exist?(dbms_adapter_template_path)
                          dbms_adapter_template_path
                        else
                          "#{TEMPLATE_PATH}/default/#{template_path}"
                        end
        template_content = File.read(template_path)
        ::ERB.new(template_content).result_with_hash(**replacements)
      end

      def _dbms_adapter
        ActiveRecord::Base.connection_config[:adapter]
      end

    end
  end
end