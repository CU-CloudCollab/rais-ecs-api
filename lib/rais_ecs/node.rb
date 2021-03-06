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
    @as  = @cloud.get_as_client

    @instance_details = self.get_describe_container_instances_response
    @ec2_description = self.get_describe_instances_response
    @scaling_group_details = self.get_describe_auto_scaling_instances

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

  # Method to return instance status withing scaling group
  # @return [Aws::AutoScaling::Types::AutoScalingInstancesType]

  def get_describe_auto_scaling_instances

    #http://docs.aws.amazon.com/sdkforruby/api/Aws/AutoScaling/Client.html#describe_auto_scaling_instances-instance_method
    auto_scaling_instances = @as.describe_auto_scaling_instances({
      instance_ids: [self.get_node_instance_id],
    })

    return auto_scaling_instances
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

  # is node part of an autoscaling group?
  # @return [Boolean] Is node part of an auto-scaling group?

  def is_in_autoscaling_group

    if @scaling_group_details.auto_scaling_instances.length > 0
      return true
    end

    return false
  end

  # get node auto-scaling group name
  # @return [String]

  def get_autoscaling_group_name
    if self.is_in_autoscaling_group
        return @scaling_group_details.auto_scaling_instances[0].auto_scaling_group_name
    else
      return nil
    end

  end

  # get the auto scale group this node belongs to
  # @return [RaisEcs::AutoScalingGroup]
  def get_autoscaling_group

    return RaisEcs::AutoScalingGroup.new({
      cloud: @cloud,
      auto_scaling_group_name: self.get_autoscaling_group_name
    })

  end

end
