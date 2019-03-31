require_relative 'db_connection'
require 'active_support/inflector'
# NB: the attr_accessor we wrote in phase 0 is NOT used in the rest
# of this project. It was only a warm up.

module Util
  def sanitize(value)
    value.is_a?(String) ? "'#{value}'" : value
  end
end

class SQLObject
  include Util
  
  def self.columns
    @columns ||= DBConnection.execute2("SELECT * FROM #{table_name} LIMIT 1").first.map &:to_sym
  end

  def self.finalize!
    columns.each do |column|
      define_method(column) { attributes[column] }
      define_method("#{column}=") { |v| attributes[column] = v }
    end
  end

  def self.table_name=(table_name)
    @table_name = table_name
  end

  def self.table_name
    @table_name ||= name.tableize
  end

  def self.all
    parse_all execute("SELECT #{table_name}.* FROM #{table_name}")
  end

  def self.parse_all(results)
    results.map { |hash| new(hash) }
  end

  def self.find(id)
    result = execute("SELECT * FROM #{table_name} WHERE id = ?", id)
    return nil if result.empty? || result.length > 1

    new(result.first)
  end

  def initialize(params = {})
    params.each do |k, v|
      k = k.to_sym
      raise "unknown attribute '#{k}'" unless self.class.columns.include?(k)

      send("#{k}=", v)
    end
  end

  def attributes
    @attributes ||= {}
  end

  def attribute_values
    self.class.columns.map { |column| send(column) }
  end

  def insert
    columns = dup_and_remove_id(self.class.columns)
    values = columns.map do |column|
      value = send(column)
      value.is_a?(String) ? "'#{value}'" : value
    end
    execute(<<-SQL)
      INSERT INTO #{self.class.table_name} (#{columns.join(', ')})
      VALUES (#{values.join(', ')})
    SQL
    self.id = DBConnection.last_insert_row_id
  end

  def update
    columns = self.class.columns
    id_idx = columns.index(:id)
    execute(<<-SQL)
      UPDATE #{self.class.table_name}
      SET #{(columns[0...id_idx]+columns[id_idx+1..-1]).map { |c| "#{c} = #{sanitize(send(c))}" }.join(', ') }
      WHERE id = #{self.id}
    SQL
  end

  def save
    id.nil? ? insert : update
  end

  private

  def execute(sql, *args)
    self.class.execute(sql, args)
  end

  def self.execute(sql, *args)
    DBConnection.execute(sql, args)
  end

  def dup_and_remove_id(arr)
    result = arr.dup
    result.delete(:id)
    result
  end
end
