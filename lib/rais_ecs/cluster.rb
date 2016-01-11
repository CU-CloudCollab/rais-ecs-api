# Cluster - generic compute space in which to launch container tasks and services
# @author Brett Haranin

class RaisEcs::Cluster

  # @return [String] Cluster name
  attr_reader :name

  # @return [RaisEcs::Cloud] Cloud object
  attr_reader :cloud

  # Constructor for AWS cluster class
  # @param [Hash] options
  # @option options [RaisEcs::Cloud] :cloud An active cloud object
  # @option options [String] :cluster_name AWS cluster name (http://docs.aws.amazon.com/AmazonECS/latest/developerguide/create_cluster.html)

  def initialize(options)
    @name = options[:cluster_name]
    @cloud = options[:cloud]

    # cache the common needs

    @ecs = @cloud.get_ecs_client
    @describe_clusters = self.get_describe_clusters_results
    @instances = self.get_list_container_instances_response

  end

  # Method to return results of call to aws api describe_clusters
  # @return [Aws::ECS::Types::DescribeClustersResponse] describe_clusters api response

  def get_describe_clusters_results

    # http://docs.aws.amazon.com/sdkforruby/api/Aws/ECS/Client.html#describe_clusters-instance_method
    describe_clusters = @ecs.describe_clusters({
      clusters: [@name]
    })

    return describe_clusters
  end

  # Method to return results of call to aws api list_container_instances
  # @return [Aws::ECS::Types::ListContainerInstancesResponse]

  def get_list_container_instances_response

    # http://docs.aws.amazon.com/sdkforruby/api/Aws/ECS/Client.html#list_container_instances-instance_method
    instances = @ecs.list_container_instances({
      cluster: @name
    })

    return instances
  end


  # Get cluster status
  # @return [String] AWS cluster status (active/inactive)

  def status
    return @describe_clusters.clusters[0].status
  end

  # get cluster size
  # @return [Integer] Number of nodes in cluster

  def size
    return @describe_clusters.clusters[0].registered_container_instances_count
  end

  # Get cluster nodes
  # @return [Array<RaisEcs::Node>] An array of node objects

  def nodes

    node_array = []
    @instances.container_instance_arns.each do |instance_arn|
      node_array << RaisEcs::Node.new({cloud: @cloud, cluster: self, node_identifier: instance_arn})
    end

    return node_array

  end

  # get an instance of service config based on service name
  # @param service_name [String] AWS service name (http://docs.aws.amazon.com/AmazonECS/latest/developerguide/service_definition_paramters.html)
  # @return [RaisEcs::Service] Service requested
  def get_service_by_name(service_name)
    return RaisEcs::Service.new({
      cloud: @cloud,
      cluster: self,
      service_name: service_name
    })
  end


end
