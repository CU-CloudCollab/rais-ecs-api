# Auto Scaling Group
# Group configured to automatically add ec2 instances
# @author Brett Haranin

class RaisEcs::AutoScalingGroup

  # Constructor - AutoScaleGroup
  # @param options [Hash]
  # @option options [RaisEcs::Cloud] :cloud An active cloud object
  # #option options [String] :auto_scaling_group_name

  def initialize(options)
    @cloud = options[:cloud]
    @auto_scaling_group_name = options[:auto_scaling_group_name]

    @as  = @cloud.get_as_client

    # cache the common needs
    @describe_scaling_group = self.get_describe_scaling_group

  end

  # Method to return results of call to aws api describe_scaling_group
  # @return [Aws::AutoScaling::Types::AutoScalingGroupsType]

  def get_describe_scaling_group

    # http://docs.aws.amazon.com/sdkforruby/api/Aws/AutoScaling/Client.html#describe_auto_scaling_groups-instance_method
    auto_scaling_group_response = @as.describe_auto_scaling_groups({
      auto_scaling_group_names: [@auto_scaling_group_name]
    })

    return auto_scaling_group_response

  end

  # Get the name of this auto scaling group
  # @return [String] Auto Scaling Group Name
  def get_scaling_group_name
    return @auto_scaling_group_name
  end

  # Get the launch configuration name associated with this auto-scaling group
  # @return [String] Launch configuration name
  def get_launch_configuration_name
    return @describe_scaling_group.auto_scaling_groups[0].launch_configuration_name
  end

  # Get the current desired capacity (node count) setting
  # @return [Integer] Number of nodes to build out
  def get_desired_nodes
    return @describe_scaling_group.auto_scaling_groups[0].desired_capacity
  end

  # Get the maximum number of nodes
  # @return [Integer] Maximum number of nodes
  def get_max_nodes
    return @describe_scaling_group.auto_scaling_groups[0].max_size
  end

  # Get the minumum number of nodes
  # @return [Integer] Minumum number of nodes
  def get_min_nodes
    return @describe_scaling_group.auto_scaling_groups[0].min_size
  end

  # Set desired node count
  # @return [Boolean] Success/Failure of operation
  def set_desired_nodes(desired_count,honor_cooldown=true)

    begin
      resp = @as.set_desired_capacity({
        auto_scaling_group_name: self.get_scaling_group_name,
        desired_capacity: desired_count,
        honor_cooldown: honor_cooldown
      })
    rescue
      return false
    end

    return true

  end


end
