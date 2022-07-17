# frozen_string_literal: true

require 'minitest/autorun'
require_relative '../../../../test/test_helper'

# Class for testing date lookups
class DateLookupTest < Minitest::Test
  def test_abstract_date_operation
    assert_raises NotImplementedError do
      Babik::Selection::Operation::DateOperation.new('my_field', 'equal', 'my_value')
    end
  end

  def test_year_date_operation
    sql_by_db_adapter = {
      mysql2: 'YEAR(#field)',
      postgresql: 'EXTRACT(YEAR FROM #field)',
      sqlite3: 'strftime(\'%Y\', #field)'
    }
    _test_date_operation('Year', sql_by_db_adapter)
  end

  def test_quarter_date_operation
    sql_by_db_adapter = {
      mysql2: 'QUARTER(#field)',
      postgresql: 'EXTRACT(QUARTER FROM #field)',
      sqlite3: '(CAST(strftime(\'%m\', #field) AS INTEGER) + 2) / 3'
    }
    _test_date_operation('Quarter', sql_by_db_adapter)
  end

  def test_month_date_operation
    sql_by_db_adapter = {
      mysql2: 'MONTH(#field)',
      postgresql: 'EXTRACT(MONTH FROM #field)',
      sqlite3: 'strftime(\'%m\', #field)'
    }
    _test_date_operation('Month', sql_by_db_adapter)
  end

  def test_day_date_operation
    sql_by_db_adapter = {
      mysql2: 'DAYOFMONTH(#field)',
      postgresql: 'EXTRACT(DAY FROM #field)',
      sqlite3: 'strftime(\'%d\', #field)'
    }
    _test_date_operation('Day', sql_by_db_adapter)
  end

  def test_weekday_date_operation
    sql_by_db_adapter = {
      mysql2: 'DAYOFWEEK(#field) -  1',
      postgresql: 'EXTRACT(DOW FROM #field)',
      sqlite3: 'strftime(\'%w\', #field)'
    }
    _test_date_operation('WeekDay', sql_by_db_adapter)
  end

  def test_week_date_operation
    sql_by_db_adapter = {
      mysql2: 'WEEK(#field, 3)',
      postgresql: 'EXTRACT(WEEK FROM #field)',
      sqlite3: '(strftime(\'%j\', date(#field, \'-3 days\', \'weekday 4\')) - 1) / 7 + 1'
    }
    _test_date_operation('Week', sql_by_db_adapter)
  end

  def test_hour_date_operation
    sql_by_db_adapter = {
      mysql2: 'HOUR(#field)',
      postgresql: 'EXTRACT(HOUR FROM #field)',
      sqlite3: 'CAST(strftime(\'%H\', #field) AS INTEGER)'
    }
    _test_date_operation('Hour', sql_by_db_adapter)
  end

  def test_minute_date_operation
    sql_by_db_adapter = {
      mysql2: 'MINUTE(#field)',
      postgresql: 'EXTRACT(MINUTE FROM #field)',
      sqlite3: 'CAST(strftime(\'%M\', #field) AS INTEGER)'
    }
    _test_date_operation('Minute', sql_by_db_adapter)
  end

  def test_second_date_operation
    sql_by_db_adapter = {
      mysql2: 'SECOND(#field)',
      postgresql: 'FLOOR(EXTRACT(SECOND FROM #field))',
      sqlite3: 'CAST(strftime(\'%S\', #field) AS INTEGER)'
    }
    _test_date_operation('Second', sql_by_db_adapter)
  end

  def test_time_date_operation
    sql_by_db_adapter = {
      mysql2: 'DATE_FORMAT(#field, \'%H:%i:%s\')',
      postgresql: 'date_trunc(\'second\', #field::time)',
      sqlite3: 'strftime(\'%H:%M:%S\', #field)'
    }
    _test_date_operation('Time', sql_by_db_adapter)
  end

  def _test_date_operation(date_operation_name, sql_by_adapter, unimplemented_db_adapters = %w[mssql oracle])
    date_operation_class = Object.const_get("Babik::Selection::Operation::#{date_operation_name.camelize}")
    _test_date_operation_sql(date_operation_class, sql_by_adapter)
    _test_date_operation_not_implemented(date_operation_class, unimplemented_db_adapters)
  end

  def _test_date_operation_sql(klass, date_operation_sql_by_db_adapter)
    date_operation = klass.new('my_field', 'equal', 6)
    date_operation_sql_by_db_adapter.each do |db_adapter, date_operation_sql|
      date_operation.stub :db_engine, -> { db_adapter.to_s } do
        assert_equal date_operation_sql, date_operation.sql_function
      end
    end
  end

  def _test_date_operation_not_implemented(klass, unimplemented_db_adapters)
    date_operation = klass.new('my_field', 'equal', 6)
    unimplemented_db_adapters.each do |unimplemented_db_adapter|
      date_operation.stub :db_engine, -> { unimplemented_db_adapter.to_s } do
        assert_raises NotImplementedError do
          date_operation.sql_function
        end
      end
    end
  end
end
