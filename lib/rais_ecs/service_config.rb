# Service Configuration Class
# All defintions necessary to update a service (service def)

# @author Brett Haranin
# @todo add support for deployment options hash

class RaisEcs::ServiceConfig

  # @return [RaisEcs::Cluster] Cluster Object
  attr_reader :cluster

  # @return [RaisEcs::Service] Service Object
  attr_reader :service

  # @return [Integer] How many instances of services should run
  attr_accessor :desired_count

  # @return [RaisEcs::ContainerConfig] Container configuration to run (use update function)
  attr_reader :container_config

  # Constructor ServiceConfig
  # @param options [Hash]
  # @option options [RaisEcs::Cluster] :cluster Cluster Object
  # @option options [RaisEcs::Service] :service Service Object
  # @option options [Integer] :desired_count How many instances of service should run
  # @option options [RaisEcs::ContainerConfig] :container_config What container configuration should be run

  def initialize(options)
    @service_instance_id = options[:service_instance_id]
    @cluster = options[:cluster]
    @service = options[:service]
    @desired_count = options[:desired_count]
    @container_config = options[:container_config]
  end

  # update service config with new container config
  # @param container_config [RaisEcs::ContainerConfig] Container configuration object
  # @return [RaisEcs::ContainerConfig] Container configuration updated with new container config

  def update_container_config(container_config)

    if container_config.container_config_id.nil?
      raise "Container config ID not found"
    end

    @container_config = container_config

    return self

  end

end
