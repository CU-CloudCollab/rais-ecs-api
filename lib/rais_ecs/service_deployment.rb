# Service Deployment - Class for status of active and pending deployments
# @author Brett Haranin

class RaisEcs::ServiceDeployment

  # @return [String] ID of deployment
  attr_reader :id

  # @return [String] Status of deployment
  attr_reader :status

  # @return [RaisEcs::ContainerConfig] Container Configuration Deployed
  attr_reader :container_config

  # @return [Integer] Target number of instances
  attr_reader :desired_count

  # @return [Integer] Number of running instances
  attr_reader :running_count

  # @return [Integer] Number of pending instances
  attr_reader :pending_count

  # @return [Time] Deployment created DateTime
  attr_reader :created_at

  # @return [Time] Deployment last updated DateTime
  attr_reader :updated_dt

  # Constructor - Service Deployment
  # @param options [Hash] Options Hash
  # @option options [String] :id  ID of deployment
  # @option options [String] :status Status of deployment
  # @option options [RaisEcs::ContainerConfig] :container_config Container configuration
  # @option options [Integer] :desired_Count Target number of instances
  # @option options [Integer] :running_count Number of running instances
  # @option options [Integer] :pending_count Number of pending instances
  # @option options [Time] Deployment created DateTime
  # @option options [Time] Deployment last updated DateTime

  def initialize(options)
    @id = options[:id]
    @status = options[:status]
    @container_config = options[:container_config]
    @desired_count = options[:desired_count]
    @running_count = options[:running_count]
    @pending_count = options[:pending_count]
    @created_at = options[:created_at]
    @updated_at = options[:updated_at]
  end

end
