# Class for storing service event logs

class RaisEcs::ServiceEventLog

  # @return [String] Log ID
  attr_reader :id

  # @return [Time] Log date/time
  attr_reader :created_at

  # @return [String] Log message
  attr_reader :message

  # Constructor - ServiceEventLog
  # @param options
  # @option options [String] :id Log ID
  # @option options [Time] :created_at Log date/Time
  # @option options [String] :message Log message

  def initialize(options)
    @id = options[:id]
    @created_at = options[:created_at]
    @message = options[:message]
  end

end
