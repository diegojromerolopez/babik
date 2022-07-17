# frozen_string_literal: true

require 'babik/queryset/lib/selection/operation/base'

module Babik
  module Selection
    # SQL operation module
    module Operation

      # Check the DBMS is one of the supported ones
      module ValidDBMS
        SUPPORTED_DB_ADAPTERS = %i[mariadb mysql2 postgresql sqlite3].freeze
        def assert_dbms
          dbms = db_engine.to_sym
          raise "Invalid dbms #{db_engine}. Only mysql, postgresql, and sqlite3 are accepted" unless SUPPORTED_DB_ADAPTERS.include?(dbms)
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
          # In the left-hand of the main operator lies the sql_function
          # that will extract the desired part of the datetime
          # This function represents the field as #field, not as ?field
          # to avoid having replacement issues
          code_for_sql_function = sql_function
          main_operation = Base.factory(code_for_sql_function, operator, value)
          # Replacement mechanism only understand ?field and not #field,
          # so replace #field for ?field and let it work
          main_operation_sql_code = main_operation.sql_operation.sub('#field', '?field')
          super(field, main_operation_sql_code, value)
        end

        def sql_function
          raise NotImplementedError
        end
      end

      # Year date operation
      class Year < DateOperation
        def sql_function
          dbms_adapter = db_engine
          return 'YEAR(#field)' if dbms_adapter == 'mysql2'
          return 'EXTRACT(YEAR FROM #field)' if dbms_adapter == 'postgresql'
          return 'strftime(\'%Y\', #field)' if dbms_adapter == 'sqlite3'
          raise NotImplementedError, "#{self.class} lookup not implemented for #{dbms_adapter}"
        end
      end

      # Quarter where the date is operation
      class Quarter < DateOperation
        def sql_function
          dbms_adapter = db_engine
          return 'QUARTER(#field)' if dbms_adapter == 'mysql2'
          return 'EXTRACT(QUARTER FROM #field)' if dbms_adapter == 'postgresql'
          return '(CAST(strftime(\'%m\', #field) AS INTEGER) + 2) / 3' if dbms_adapter == 'sqlite3'
          raise NotImplementedError, "#{self.class} lookup not implemented for #{dbms_adapter}"
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
          return 'MONTH(#field)' if dbms_adapter == 'mysql2'
          return 'EXTRACT(MONTH FROM #field)' if dbms_adapter == 'postgresql'
          return 'strftime(\'%m\', #field)' if dbms_adapter == 'sqlite3'
          raise NotImplementedError, "#{self.class} lookup not implemented for #{dbms_adapter}"
        end
      end

      # Day of month date operation
      class Day < DateOperation
        def initialize(field, operator, value)
          value = format('%02d', value) if db_engine == 'sqlite3'
          super(field, operator, value)
        end

        def sql_function
          dbms_adapter = db_engine
          return 'DAYOFMONTH(#field)' if dbms_adapter == 'mysql2'
          return 'EXTRACT(DAY FROM #field)' if dbms_adapter == 'postgresql'
          return 'strftime(\'%d\', #field)' if dbms_adapter == 'sqlite3'
          raise NotImplementedError, "#{self.class} lookup not implemented for #{dbms_adapter}"
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
          return 'DAYOFWEEK(#field) -  1' if dbms_adapter == 'mysql2'
          return 'EXTRACT(DOW FROM #field)' if dbms_adapter == 'postgresql'
          return 'strftime(\'%w\', #field)' if dbms_adapter == 'sqlite3'
          raise NotImplementedError, "#{self.class} lookup not implemented for #{dbms_adapter}"
        end
      end

      # ISO Week of year (1-52/53) from date operation
      #
      class Week < DateOperation

        def sql_function
          dbms_adapter = db_engine
          return 'WEEK(#field, 3)' if dbms_adapter == 'mysql2'
          return 'EXTRACT(WEEK FROM #field)' if dbms_adapter == 'postgresql'
          return '(strftime(\'%j\', date(#field, \'-3 days\', \'weekday 4\')) - 1) / 7 + 1' if dbms_adapter == 'sqlite3'
          raise NotImplementedError, "#{self.class} lookup not implemented for #{dbms_adapter}"
        end
      end

      # Hour date operation
      class Hour < DateOperation

        def sql_function
          dbms_adapter = db_engine
          return 'HOUR(#field)' if dbms_adapter == 'mysql2'
          return 'EXTRACT(HOUR FROM #field)' if dbms_adapter == 'postgresql'
          return 'CAST(strftime(\'%H\', #field) AS INTEGER)' if dbms_adapter == 'sqlite3'
          raise NotImplementedError, "#{self.class} lookup not implemented for #{dbms_adapter}"
        end
      end

      # Minute date operation
      class Minute < DateOperation

        def sql_function
          dbms_adapter = db_engine
          return 'MINUTE(#field)' if dbms_adapter == 'mysql2'
          return 'EXTRACT(MINUTE FROM #field)' if dbms_adapter == 'postgresql'
          return 'CAST(strftime(\'%M\', #field) AS INTEGER)' if dbms_adapter == 'sqlite3'
          raise NotImplementedError, "#{self.class} lookup not implemented for #{dbms_adapter}"
        end
      end

      # Second date operation
      class Second < DateOperation

        def sql_function
          dbms_adapter = db_engine
          return 'SECOND(#field)' if dbms_adapter == 'mysql2'
          return 'FLOOR(EXTRACT(SECOND FROM #field))' if dbms_adapter == 'postgresql'
          return 'CAST(strftime(\'%S\', #field) AS INTEGER)' if dbms_adapter == 'sqlite3'
          raise NotImplementedError, "#{self.class} lookup not implemented for #{dbms_adapter}"
        end
      end

      # Time date operation
      class Time < DateOperation
        def sql_function
          dbms_adapter = db_engine
          return 'DATE_FORMAT(#field, \'%H:%i:%s\')' if dbms_adapter == 'mysql2'
          return 'date_trunc(\'second\', #field::time)' if dbms_adapter == 'postgresql'
          return 'strftime(\'%H:%M:%S\', #field)' if dbms_adapter == 'sqlite3'
          raise NotImplementedError, "#{self.class} lookup not implemented for #{dbms_adapter}"
        end
      end

    end
  end
end
