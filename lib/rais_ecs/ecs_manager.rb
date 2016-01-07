# Class for root ECS functions and glue to images/docker/repository

# @author Brett Haranin

class RaisEcs::EcsManager

  # Constructor - for EcsManager
  # @param options [Hash]
  # @option options [RaisEcs::Cloud] :cloud Authenticated cloud (aws) api instance

  def initialize(options)
    @cloud = options[:cloud]
  end

  # Get instance of cluster
  # @param cluster_name [String] AWS cluster name (http://docs.aws.amazon.com/AmazonECS/latest/developerguide/create_cluster.html)
  # @return [RaisEcs::Cluster]

  def get_cluster_by_name(cluster_name)

    options = {}
    options[:cluster_name] = cluster_name
    options[:cloud] = @cloud

    return RaisEcs::Cluster.new(options)

  end

  # get an instance of container config based on task name and revision (limited to last 100 revisions)
  # @param task_name [String] AWS task definition family name
  # @param revision [String] Specific revision
  # @return [RaisEcs::ContainerConfig] Container configuration requested

  def get_container_config_by_name(task_name,revision='latest')
    # tasks are not cluster-specific - consolidating logic for this task here

    if task_name.nil? || task_name.length == 0
      raise "Task name is required"
    end

    if revision.nil? || revision.length == 0
      raise "Task revision is required"
    end

    ecs = @cloud.get_ecs_client

    # http://docs.aws.amazon.com/sdkforruby/api/Aws/ECS/Client.html#list_task_definitions-instance_method
    definitions = ecs.list_task_definitions({
      family_prefix: task_name,
      sort: "DESC"
    })

    if revision == 'latest'
      task_arn = [definitions.task_definition_arns[0]]
    else
      task_arn = definitions.task_definition_arns.select{|arn| arn.rpartition(':').last == revision}
    end

    # if for some reason 0 or 2+ are found, bail
    if task_arn.length == 0
      raise "Config not found"
    elsif task_arn.length > 1
      raise "Multiple tasks match specified criteria"
    end

    # http://docs.aws.amazon.com/sdkforruby/api/Aws/ECS/Client.html#describe_task_definition-instance_method
    definition_detail = ecs.describe_task_definition({
      task_definition: task_arn[0]
    })

    if definition_detail.task_definition.container_definitions.length == 0
      raise "Config found, but detail could not be retrieved"
    elsif definition_detail.task_definition.container_definitions.length > 1
      raise "Config found, but multiple containers defined.  At this time, the library assumes single container tasks"
    end

    # build port mappings
    port_mappings = []
    definition_detail.task_definition.container_definitions[0].port_mappings.each do |mapping|
      port_mappings << RaisEcs::ContainerPortMapping.new(mapping.container_port,mapping.host_port,mapping.protocol)
    end

    # build environment variables
    environment_vars = []
    definition_detail.task_definition.container_definitions[0].environment.each do |env_var|
      environment_vars << RaisEcs::ContainerEnvironmentVar.new(env_var.name,env_var.value)
    end

    # build image object

    image_registry_address = definition_detail.task_definition.container_definitions[0].image
    address_partitions = image_registry_address.partition('/')
    repository_partitions = address_partitions.last.rpartition(':')

    registry_server = address_partitions[0]
    registry_repository = repository_partitions[0]
    repository_tag = repository_partitions.last

    # might be better to inject the registry service object - especially in light of upcoming changes to DTR
    image = RaisEcs::ContainerImage.new({
        primary_image_tag: repository_tag,
        remote_repository: RaisEcs::RegistryImageRepository.new({registry_server: registry_server, repository_name: registry_repository})
    })

    return RaisEcs::ContainerConfig.new({
      container_config_id: task_arn[0],
      container_name: task_name,
      memory: definition_detail.task_definition.container_definitions[0].memory,
      cpu: definition_detail.task_definition.container_definitions[0].cpu,
      port_mappings: port_mappings,
      environment_vars: environment_vars,
      image: image
    })

  end

  # Register a new container configuration (Task Definition) with ECS
  # @param config [RaisEcs::ContainerConfig] Container configuration to be registered
  # @return [RaisEcs::ContainerConfig] New registered instance of container config (updated arn)

  def register_new_container_config(config)

    # http://docs.aws.amazon.com/sdkforruby/api/Aws/ECS/Client.html#register_task_definition-instance_method

    request_hash = {}

    request_hash[:family] = config.container_name

    request_hash_container = {}

      request_hash_container[:name] = config.container_name
      request_hash_container[:cpu] = config.cpu
      request_hash_container[:memory] = config.memory
      request_hash_container[:image] = config.image.remote_repository.get_remote_repository_name + ":" + config.image.primary_image_tag

      request_hash_portmaps = []
      config.port_mappings.each do |mapping|
        request_hash_portmaps << {
          container_port: mapping.container_port,
          host_port: mapping.node_port,
          protocol: mapping.protocol
        }
      end
      request_hash_container[:port_mappings] = request_hash_portmaps

      request_hash_environment = []
      config.environment_vars.each do |env_var|
        request_hash_environment << {
          name: env_var.key,
          value: env_var.value
        }
      end
      request_hash_container[:environment] = request_hash_environment

      request_hash_container[:log_configuration] = {
        log_driver: config.log_driver,
        options: config.log_settings
      }

    request_hash[:container_definitions] = [request_hash_container]

    ecs = @cloud.get_ecs_client

    response = ecs.register_task_definition(request_hash)

    config.container_config_id = response.task_definition.task_definition_arn

    return config

  end

end
