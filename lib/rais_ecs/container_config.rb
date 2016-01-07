# Container Configuration Class
# All defintions necessary to run a container (task def)

# @author Brett Haranin

class RaisEcs::ContainerConfig

  # @return [String] Container name
  attr_accessor :container_name

  # @return [String] Container Config ID (set by AWS)
  attr_accessor :container_config_id

  # @return [Integer] Memory to assign to this container (mb)
  attr_accessor :memory

  # @return [Integer] CPU units to assign to this container
  attr_accessor :cpu

  # @return [Array<RaisEcs::ContainerPortMapping>] What ports to map for this container
  attr_accessor :port_mappings

  # @return [Array<RaisEcs::ContainerEnvironmentVar>] What environment variables to set when launched
  attr_accessor :environment_vars

  # @return [String] Container Image (use update function to set)
  attr_reader :image

  # @return [String] Log driver
  attr_accessor :log_driver

  # @return [Hash] Log driver options (specific to driver, so simple hash)
  attr_accessor :log_settings


  # Constructor - ContainerConfig - minimum viable for RAIS application
  # @param options [Hash]
  # @option options [String] :container_config_id Task arn for current revision
  # @option options [String] :container_name Task name/family (equivalent for simplicity)
  # @option options [Integer] :memory Memory to assign to this container (mb)
  # @option options [Integer] :cpu CPU units to assign to this container
  # @option options [Array<RaisEcs::ContainerPortMapping>] :port_mappings What ports to map for this container
  # @option options [Array<RaisEcs::ContainerEnvironmentVar>] :environment_vars What environment variables to set when launched
  # @option options [RaisEcs::ContainerImage] :image Image object for this image
  # @option options [String] :log_driver Log driver (default: syslog)
  # @option options [String] :log_options Log option hash (default: container name logging)

  def initialize(options)
    @container_config_id = options[:container_config_id]
    @container_name = options[:container_name]
    @memory = options[:memory]
    @cpu = options[:cpu]
    @port_mappings = options[:port_mappings]
    @environment_vars = options[:environment_vars]
    @image = options[:image]
    @log_driver = options[:log_driver]
    @log_settings = options[:log_options]

    if @log_driver.nil?
      @log_driver = 'syslog'
    end

    if @log_settings.nil?
      @log_settings = {":syslog-tag" => @container_name}
    end

  end

  # Update container image
  # @param image [RaisEcs::ContainerImage] The new image object
  # @return [RaisEcs::ContainerConfig] New ContainerConfig instance with given image image

  def update_container_image(image)

    # image must have primary tag
    if image.primary_image_tag.nil?
      raise "Image must have primary tag"
    end

    # image must have remote repository
    if image.remote_repository.nil?
      raise "Image must have remote repository assigned to assign it to a container config"
    end

    # validate image is on remote repo
    remote_repository = image.remote_repository

    if !remote_repository.image_exists_in_registry(image)
      raise "Image not found in remote registry"
    end

    @image = image

    return self

  end

end
