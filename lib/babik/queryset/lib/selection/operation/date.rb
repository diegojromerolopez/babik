# frozen_string_literal: true

require 'babik/queryset/lib/selection/operation/base'

module Babik
  module Selection
    # SQL operation module
    module Operation

      # Check the DBMS is one of the supported ones
      module ValidDBMS
        SUPPORTED_DBMS = [:mariadb, :mysql, :postgresql, :sqlite3]
        def assert_dbms
          dbms = db_engine.to_sym
          raise "Invalid dbms #{db_engine}. Only mysql, postgresql, and sqlite3 are accepted" unless SUPPORTED_DBMS.include?(dbms)
        end
      end

      # Each one of the operations over date fields (date, year, month, day, etc.)
      class DateOperation < Base
        include ValidDBMS

        HAS_OPERATOR = true
        def initialize(field, operator, value)
          assert_dbms
          operator ||= 'equal'
          @operator = operator
          main_operation = Base.factory(sql_function, operator, value)
          super(field, main_operation.sql_operation, value)
        end

        def sql_function
          raise NotImplementedError
        end
      end

      # Year date operation
      class Year < DateOperation
        def sql_function
          dbms_adapter = db_engine
          return 'EXTRACT(YEAR FROM ?field)' if %w[mysql postgresql].include?(dbms_adapter)
          return 'strftime(\'%Y\', ?field)' if dbms_adapter == 'sqlite3'
        end
      end

      # Month date operation
      class Month < DateOperation
        def initialize(field, operator, value)
          value = format('%02d', value) if db_engine == 'sqlite3'
          super(field, operator, value)
        end

        def sql_function
          dbms_adapter = db_engine
          return 'EXTRACT(MONTH FROM ?field)' if %w[mysql postgresql].include?(dbms_adapter)
          return 'strftime(\'%m\', ?field)' if dbms_adapter == 'sqlite3'
        end
      end

      # Day date operation
      class Day < DateOperation
        def initialize(field, operator, value)
          value = format('%02d', value) if db_engine == 'sqlite3'
          super(field, operator, value)
        end

        def sql_function
          dbms_adapter = db_engine
          return 'EXTRACT(DAY FROM ?field)' if %w[mysql postgresql].include?(dbms_adapter)
          return 'strftime(\'%d\', ?field)' if dbms_adapter == 'sqlite3'
        end
      end

      # WeekDay (1-7, sunday to monday) date operation
      class WeekDay < DateOperation

        def initialize(field, operator, value)
          value = format('%d', value) if db_engine == 'sqlite3'
          super(field, operator, value)
        end

        def sql_function
          dbms_adapter = db_engine
          return 'EXTRACT(DOW FROM ?field)' if %w[mysql postgresql].include?(dbms_adapter)
          return 'strftime(\'%w\', ?field)' if dbms_adapter == 'sqlite3'
        end
      end

      # Week of year (00-53) from date operation
      class Week < DateOperation
        def initialize(field, operator, value)
          value = format('%02d', value) if db_engine == 'sqlite3'
          super(field, operator, value)
        end

        def sql_function
          dbms_adapter = db_engine
          return 'EXTRACT(WEEK FROM ?field)' if %w[mysql postgresql].include?(dbms_adapter)
          return 'strftime(\'%W\', ?field)' if dbms_adapter == 'sqlite3'
        end
      end

      # Hour date operation
      class Hour < DateOperation
        def initialize(field, operator, value)
          value = format('%02d', value) if db_engine == 'sqlite3'
          super(field, operator, value)
        end

        def sql_function
          dbms_adapter = db_engine
          return 'EXTRACT(HOUR FROM ?field)' if %w[mysql postgresql].include?(dbms_adapter)
          return 'strftime(\'%H\', ?field)' if dbms_adapter == 'sqlite3'
        end
      end

      # Minute date operation
      class Minute < DateOperation
        def initialize(field, operator, value)
          value = format('%02d', value) if db_engine == 'sqlite3'
          super(field, operator, value)
        end

        def sql_function
          dbms_adapter = db_engine
          return 'EXTRACT(MINUTE FROM ?field)' if %w[mysql postgresql].include?(dbms_adapter)
          return 'strftime(\'%M\', ?field)' if dbms_adapter == 'sqlite3'
        end
      end

      # Minute date operation
      class Second < DateOperation
        def initialize(field, operator, value)
          value = format('%02d', value) if db_engine == 'sqlite3'
          super(field, operator, value)
        end

        def sql_function
          dbms_adapter = db_engine
          return 'FLOOR(EXTRACT(SECOND FROM ?field))' if %w[mysql postgresql].include?(dbms_adapter)
          return 'strftime(\'%s\', ?field)' if dbms_adapter == 'sqlite3'
        end
      end

      # Time date operation
      class Time < DateOperation
        def sql_function
          dbms_adapter = db_engine
          return 'date_trunc(\'second\', ?field::time)' if dbms_adapter == 'postgresql'
          return 'DATE_FORMAT(colName,\'%H:%i:%s\')' if %w[mysql postgresql].include?(dbms_adapter)
          return 'strftime(\'%H:%M:%S\', ?field)' if dbms_adapter == 'sqlite3'
        end
      end

    end
  end
end