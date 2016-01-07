# Container - a running container instance - could be short- or long-running
# @author Brett Haranin

class RaisEcs::Container

  def initialize(options)
    @cloud = options[:cloud]
    @cluster = options[:cluster]
    @service = options[:service]
    @task_arn = options[:task_arn]

    # cache the common needs
    @ecs = @cloud.get_ecs_client
    @describe_task = self.get_describe_task_result

  end

  def get_describe_task_result

    # http://docs.aws.amazon.com/sdkforruby/api/Aws/ECS/Client.html#describe_tasks-instance_method
    describe_tasks = @ecs.describe_tasks({
      cluster: @cluster.name,
      tasks: [@task_arn]
    })

    return describe_tasks

  end

  # get running task identifier (ARN)
  # @return [String] AWS ARN for running task
  def get_identifier
    return @task_arn
  end

  # get node this container is running on
  def get_node
    return RaisEcs::Node.new({
        cloud: @cloud,
        cluster: @cluster,
        node_identifier: @describe_task.tasks[0].container_instance_arn
    })
  end

  # get definition for this container
  def get_definition

  end

end
