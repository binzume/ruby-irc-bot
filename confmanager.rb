require 'json'

class ConfManager

  def get(key)
  end

  def set(key,value)
  end

  def list_get(key)
    []
  end

  def list_add(key, value)
  end

  def map_get(key)
    {}
  end

  def map_field_get(key, field)
  end

  def map_field_set(key, field, value)
  end

  def close
  end

  def clear!
  end

  def save!
  end

end

class Confrapper < ConfManager
  attr_reader :prefix, :config
  def initialize(config, prefix)
    @prefix = prefix
    @config = config
  end

  def get(key)
    @config.get(@prefix + key)
  end

  def set(key,value)
    @config.set(@prefix + key, value)
  end

end

class FileConfig < ConfManager

  def initialize(path)
    @path = path
    @data = if @path && File.exist?(@path)
      open(@path) {|f| JSON.parse(f.read.force_encoding('utf-8'))}
    else
      {}
    end
  end

  def get(key)
    @data[key]
  end

  def set(key ,value)
    @data[key] = value
  end

  def list_get(key)
    @data[key] || []
  end

  def list_add(key, value)
    @data[key] = [] unless @data[key]
    @data[key] << value
  end

  def map_get(key)
    @data[key] || {}
  end

  def map_field_get(key, field)
    @data[key] && @data[key][field]
  end

  def map_field_set(key, field, value)
    @data[key] = {} unless @data[key]
    @data[key][field] = value
  end

  def map_field_del(key, field)
    @data[key].delete(field) if @data[key]
  end

  def save!
    open(@path, 'w') {|f| f.write(JSON.pretty_generate(@data))} if @path
  end

  def close
    save!
  end

  def clear!
    @data = {}
  end

end

