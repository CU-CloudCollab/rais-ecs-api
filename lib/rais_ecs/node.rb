# Cluster Node
# A node is a unit of compute within a cluster (EC2 instance in AWS)
# @author Brett Haranin
# @todo break apart ec2-specific functionality into ec2 class - node can extend that

class RaisEcs::Node

  # Node Constructor
  # @param [Hash] options
  # @option options [RaisEcs::Cloud] :cloud An active cloud object
  # @option options [String] :cluster The AWS cluster name
  # @option options [String] :identifier The node identifier (EC2 ARN)

  def initialize(options)

    @cluster = options[:cluster]
    @identifier = options[:node_identifier] #arn
    @cloud = options[:cloud]

    # cache the common needs

    @ecs = @cloud.get_ecs_client
    @ec2 = @cloud.get_ec2_client
    @cw  = @cloud.get_cw_client

    @instance_details = self.get_describe_container_instances_response
    @ec2_description = self.get_describe_instances_response

  end

  # Method to return results of call to aws api describe_container_instances
  # @return [Aws::ECS::Types::DescribeContainerInstancesResponse]

  def get_describe_container_instances_response

    # http://docs.aws.amazon.com/sdkforruby/api/Aws/ECS/Client.html#describe_container_instances-instance_method
    instance_details = @ecs.describe_container_instances({
      cluster: @cluster.name,
      container_instances: [@identifier]
    })

    return instance_details
  end

  # Method to return results of call to aws api describe_instances
  # @return [Aws::EC2::Types::DescribeInstancesResult]

  def get_describe_instances_response

    # http://docs.aws.amazon.com/sdkforruby/api/Aws/EC2/Client.html#describe_instances-instance_method
    ec2_description = @ec2.describe_instances({
      instance_ids: [self.get_node_instance_id]
    })

    return ec2_description

  end

  # get the node Identifier
  # @return [String] The node ARN
  def get_node_arn
    return @identifier
  end

  # get the node instance id
  # @return [String] The node EC2 ID (e.g., i-343234b)
  def get_node_instance_id
    return @instance_details.container_instances[0].ec2_instance_id
  end

  # get the node instance type
  # @return [String] The node instance type (e.g., t2.medium)
  def get_node_instance_type
    return @ec2_description.reservations[0].instances[0].instance_type
  end

  # get the node private dns name
  # @return [String] Private dns name for instance
  def get_node_private_dns_name
    return @ec2_description.reservations[0].instances[0].private_dns_name
  end

  # get the node state name
  # @return [String] State of instance (pending, running, etc)
  def get_node_state_name
    return @ec2_description.reservations[0].instances[0].state.name
  end

  # get node launch date
  # @return [Time] Date/time that the instance was launched
  def get_node_launch_dt
    return @ec2_description.reservations[0].instances[0].launch_time
  end

  # get node availability zone
  # @return [String] Node placement availability zone
  def get_node_availability_zone
    return @ec2_description.reservations[0].instances[0].placement.availability_zone
  end

end
