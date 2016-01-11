# Class to wrap all service interaction with AWS.  Methods wrap multiple API
# calls and aggregate returns into hashes - mostly focused on enabling quicker
# access to this information via command line tools (project-cli)

# @author Brett Haranin

class RaisEcs::Cloud

  # Constructor for AWS provider factory
  # @param region [String] AWS region
  # @todo add parameters for credentials - currently just uses environment default (http://docs.aws.amazon.com/sdkforruby/api/index.html)

  def initialize(region="us-east-1")
    @region = region

    # cache common needs
    @ecs = Aws::ECS::Client.new(region: @region)
    @ec2 = Aws::EC2::Client.new(region: @region)
    @cw  = Aws::CloudWatch::Client.new(region: @region)
    @as  = Aws::AutoScaling::Client.new(region: @region)
  end

  # get an instance of an AWS ECS API client
  # @return [Aws::ECS::Client] Authenticated instance of ECS API client

  def get_ecs_client
    return @ecs
  end

  # get an instance of an AWS EC2 API client
  # @return [Aws::EC2::Client] Authenticated instance of EC2 API client

  def get_ec2_client
    return @ec2
  end

  # get an instance of an AWS CloudWatch API client
  # @return [Aws::CloudWatch::Client] Authenticated instance of CloudWatch API client

  def get_cw_client
    return @cw
  end

  # get an instance of an AWS AutoScaling API client
  # @return [Aws::AutoScaling::Client] Authenticated instance of AutoScaling API client

  def get_as_client
    return @as
  end

end
