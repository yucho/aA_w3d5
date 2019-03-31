require_relative '02_searchable'
require 'active_support/inflector'

# Phase IIIa
class AssocOptions
  attr_accessor(
    :foreign_key,
    :class_name,
    :primary_key
  )

  def model_class
    @class_name.constantize
  end

  def table_name
    model_class.table_name
  end
end

class BelongsToOptions < AssocOptions
  def initialize(name, options = {})
    @foreign_key = (options[:foreign_key].nil? ? :"#{name.to_s.underscore}_id" : options[:foreign_key])
    @primary_key = (options[:primary_key].nil? ? :id : options[:primary_key])
    @class_name = (options[:class_name].nil? ? name.to_s.camelcase : options[:class_name])
  end
end

class HasManyOptions < AssocOptions
  def initialize(name, self_class_name, options = {})
    @foreign_key = (options[:foreign_key].nil? ? :"#{self_class_name.to_s.underscore}_id" : options[:foreign_key])
    @primary_key = (options[:primary_key].nil? ? :id : options[:primary_key])
    @class_name = (options[:class_name].nil? ? name.to_s.camelcase.singularize : options[:class_name])
  end
end

module Associatable
  # Phase IIIb
  def belongs_to(name, options = {})
    owner = BelongsToOptions.new(name, options).model_class
  end

  def has_many(name, options = {})
    # ...
  end

  def assoc_options
    # Wait to implement this in Phase IVa. Modify `belongs_to`, too.
  end
end

class SQLObject
  extend Associatable
end
