# frozen_string_literal: true

require 'minitest/autorun'
require_relative '../../../../test/test_helper'

# Class for testing regex lookups
class RegexLookupTest < Minitest::Test
  def test_regex_operator
    sql_by_db_adapter = {
      mysql2: { operator: 'REGEXP', operation: 'my_field REGEXP \'my_value\'' },
      postgresql: { operator: '~', operation: 'my_field ~ \'my_value\'' },
      sqlite3: { operator: 'REGEXP', operation: 'my_field REGEXP \'my_value\'' }
    }
    _test_regex('Regex', sql_by_db_adapter)
  end

  def test_iregex_operator
    sql_by_db_adapter = {
      mysql2: { operator: 'REGEXP', operation: 'LOWER(my_field) REGEXP \'my_value\'' },
      postgresql: { operator: '~*', operation: 'my_field ~* \'my_value\'' },
      sqlite3: { operator: 'REGEXP', operation: 'my_field REGEXP \'(?i)my_value\'' }
    }
    _test_regex('IRegex', sql_by_db_adapter)
  end

  def _test_regex(regex_operation_name, sql_by_adapter, unimplemented_db_adapters = %w[mssql oracle])
    regex_class = Object.const_get("Babik::Selection::Operation::#{regex_operation_name.camelize}")
    _test_regex_sql(regex_class, sql_by_adapter)
    _test_regex_not_implemented(regex_class, unimplemented_db_adapters)
  end

  def _test_regex_sql(klass, sql_by_db_adapter)
    sql_by_db_adapter.each do |db_adapter, sql|
      Babik::Database.config[:adapter] = db_adapter.to_s
      regex_operation = klass.new('my_field', 'my_value')
      assert_equal db_adapter.to_s, regex_operation.db_engine
      assert_equal sql[:operator], regex_operation.operator, "Failed on checking #{klass} operator on #{db_adapter}"
      assert_equal sql[:operation], regex_operation.sql_operation,
                   "Failed on checking #{klass} operation on #{db_adapter}"
    end
  end

  def _test_regex_not_implemented(klass, unimplemented_db_adapters)
    date_operation = klass.new('my_field', 'my_value')
    unimplemented_db_adapters.each do |unimplemented_db_adapter|
      date_operation.stub :db_engine, -> { unimplemented_db_adapter.to_s } do
        assert_raises NotImplementedError do
          date_operation.operator
        end
      end
    end
  end
end
