require_relative 'db_connection'
require_relative '01_sql_object'

module Searchable
  include Util
  def where(params)
    where_line = params.to_a.map { |k, v| "#{k} = #{sanitize(v)}" }.join(" AND ")
    DBConnection.execute(<<-SQL)
      SELECT * FROM #{table_name}
      WHERE #{where_line}
    SQL
    .map { |hash| new(hash)}
  end
end

class SQLObject
  extend Searchable
end
