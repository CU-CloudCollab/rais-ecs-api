# Container Environment Variable
# Class to contain environment variable settings

# @author Brett Haranin

class RaisEcs::ContainerEnvironmentVar

  # @return [String] Environment Variable Name (key)
  attr_reader :key

  # @return [String] Environment Variable Value (value)
  attr_reader :value

  # Environment Variable Constructor
  # @param key [String] Name of variable
  # @param value [String] Value of variable

  def initialize(key,value)
    @key = key
    @value = value
  end

end
