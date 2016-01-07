# Service class
# A service is a long-running container
# @author Brett Haranin

class RaisEcs::Service

  # @return [String] Service Name
  attr_reader :service_name

  # @return [RaisEcs::Cluster] Cluster object
  attr_reader :cluster

  # @return [RaisEcs::Cloud] Cloud object
  attr_reader :cloud


  # Constructor - Service
  # @param options [Hash]
  # @option options [RaisEcs::Cloud] :cloud Active cloud instance
  # @option options [RaisEcs::Cluster] :cluster Active cluster instance
  # @option options [String] :service_name AWS name of this service

  def initialize(options)
    @cloud = options[:cloud]
    @cluster = options[:cluster]
    @service_name = options[:service_name]

    # cache the common needs
    @ecs = @cloud.get_ecs_client
    @describe_service = self.get_describe_service_result

  end

  # Method to get the results of the ecs api call to descibe_service
  # @return [Aws::ECS::Types::DescribeServicesResponse]

  def get_describe_service_result

    # http://docs.aws.amazon.com/sdkforruby/api/Aws/ECS/Client.html#describe_services-instance_method
    describe_service = @ecs.describe_services({
      cluster: @cluster.name,
      services: [@service_name], # required
    })

    return describe_service
  end

  # get current container definition (task definition in AWS vocabulary)
  # @return [RaisEcs::ContainerConfig] Current container configuration object

  def get_primary_container_config
    task_arn = @describe_service.services[0].task_definition
    return self.get_container_config_by_task_arn(task_arn)
  end


  # get a container config (task definition) for a given task arn
  # @param task_arn [String] AWS Task Definition ARN
  # @return [RaisEcs::ContainerConfig]

  def get_container_config_by_task_arn(task_arn)

    # example: arn:aws:ecs:us-east-1:601654722933:task-definition/pidash_auth_test:44
    task_parts = task_arn.split(':')
    task_revision = task_parts[-1]
    task_definition_name = task_parts[-2]
    task_name = task_definition_name.split('/')[1]

    # use ecs manage lib to build the container config
    ecs_manager = RaisEcs::EcsManager.new({cloud: @cloud })

    return ecs_manager.get_container_config_by_name(task_name,task_revision)

  end

  # Get instance of ServiceConfig for current running service (used for updates)
  # @return [RaisEcs::ServiceConfig] Instance of ServiceConfig matching current service instance

  def get_current_service_config
    return RaisEcs::ServiceConfig.new({
        service_instance_id: self.get_service_arn,
        cluster: @cluster,
        service: self,
        desired_count: self.get_desired_count,
        container_config: self.get_primary_container_config
      })
  end

  # Update service with new config (i.e., change container or desired count)
  # @param service_config [RaisEcs::ServiceConfig] New service configuration
  # @return [RaisEcs::Service] Updated service

  def update_current_service_config(service_config)

    # http://docs.aws.amazon.com/sdkforruby/api/Aws/ECS/Client.html#update_service-instance_method

    service_update_response = @ecs.update_service({
      cluster: service_config.cluster.name,
      service: service_config.service.service_name,
      desired_count: service_config.desired_count,
      task_definition: service_config.container_config.container_config_id
    })

    return RaisEcs::Service.new({
        cloud: @cloud,
        cluster: @cluster,
        service_name: @service_name
    })

  end

  # AWS arn for this service
  # @return [String] AWS Arn
  def get_service_arn
    return @describe_service.services[0].service_arn
  end

  # get desired count value for current service instance
  # @return [Integer] Number of desired service instances
  def get_desired_count
    return @describe_service.services[0].desired_count
  end

  # get pending count value for current service instance
  # @return [Integer] Number of pending service instances
  def get_pending_count
    return @describe_service.services[0].pending_count
  end

  # get running count value for current service instance
  # @return [Integer] Number of running service instances
  def get_running_count
    return @describe_service.services[0].running_count
  end

  # get the running container instances
  # @return [RaisEcs::Container] Running container instances

  def get_running_containers

    containers = []
    running_tasks = get_list_tasks_result
    running_tasks.task_arns.each do |task_arn|
        containers << RaisEcs::Container.new({
          cloud: @cloud,
          cluster: @cluster,
          service: self,
          task_arn: task_arn
        })
    end

    return containers

  end

  def get_list_tasks_result

    # http://docs.aws.amazon.com/sdkforruby/api/Aws/ECS/Client.html#list_tasks-instance_method
    list_tasks = @ecs.list_tasks({
        cluster: @cluster.name,
        service_name: self.service_name
    })

    return list_tasks
  end

  # get curent deployments
  # @return [Array<ServiceDeployment>]
  def get_deployments

    deployments = []

    @describe_service.services[0].deployments.each do |deployment|
      deployments << RaisEcs::ServiceDeployment.new({
          id: deployment.id,
          status: deployment.status,
          container_config: self.get_container_config_by_task_arn(deployment.task_definition),
          desired_count: deployment.desired_count,
          running_count: deployment.running_count,
          pending_count: deployment.pending_count,
          created_at: deployment.created_at,
          updated_at: deployment.updated_at
      })
    end

    return deployments

  end

  # get nodes that this service is running on
  # @return [Array<Node>]
  def get_nodes
    nodes = []

    self.get_running_containers.each do |container|
      nodes << container.get_node
    end

    return nodes

  end

  # get service event log messages
  def get_event_logs(last_n=5)

    service_logs = []

    logrow = 0

    if last_n > @describe_service.services[0].events.length
      loop_to = @describe_service.services[0].events.length
    else
      loop_to = last_n
    end

    while logrow < loop_to
      log = RaisEcs::ServiceEventLog.new({
        id: @describe_service.services[0].events[logrow].id,
        created_at: @describe_service.services[0].events[logrow].created_at,
        message: @describe_service.services[0].events[logrow].message
      })

      service_logs << log
      logrow += 1
    end

    return service_logs

  end

end
