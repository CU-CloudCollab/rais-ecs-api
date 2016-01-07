# ContainerImage - Docker image
# Local and remote repository contexts are injected to allow flexibility for remote registry types

# @author Brett Haranin

class RaisEcs::ContainerImage

  # @return [String] Image tag
  attr_accessor :primary_image_tag

  # @return [String] Image SHA Digest
  attr_accessor :image_sha_digest

  # @return [Time] Date/Time that the image was build
  attr_accessor :image_created_dt

  # @return [Docker::Image] Local Image Object
  attr_accessor :local_image_object

  # @return [String] Local Image ID
  attr_accessor :local_image_id

  # @return [RaisEcs::LocalImageRepository] Repository object for local image instance (Docker Socket)
  attr_accessor :local_repository

  # @return [RaisEcs::RegistryImageRepository] Repository object for docker registry - necessary for deploy to AWS
  attr_accessor :remote_repository

  # @return [Boolean] Image has been tagged for remote (required for push command)
  attr_reader :tagged_for_remote


  # Container Image Construtor
  # @param options [Hash]
  # @option options [String] :primary_image_tag Primary image tag
  # @option options [String] :image_sha_digest SHA digest for image (available from remote)
  # @option options [Time] :image_created_dt Date/time that the image was built
  # @option options [String] :local_image_id Image ID on local machine
  # @option options [Docker::Image] :local_image_object
  # @option options [RaisEcs::LocalImageRepository] :local_repository Repository object for local image instance (Docker)
  # @option options [RaisEcs::RegistryImageRepository] :remote_repository Repository object for docker registry - necessary for deploy to AWS

  def initialize(options)
    @primary_image_tag = options[:primary_image_tag]
    @image_sha_digest = options[:image_sha_digest]
    @image_created_dt = options[:image_created_dt]
    @local_image_id = options[:local_image_id]
    @local_image_object = options[:local_image_object]
    @local_repository = options[:local_repository]
    @remote_repository = options[:remote_repository]

    @tagged_for_remote = false

  end

  # tag image for remote repository
  # @return [RaisEcs::ContainerImage] An instance of self tagged for remote registry

  def tag_for_remote

    if @primary_image_tag.nil?
      raise "Primary image tag not set"
    end

    if @remote_repository.nil?
      raise "Remote repository not set"
    end

    if @local_repository.nil?
      raise "Local repository not set"
    end

    if @local_image_id.nil?
      raise "Local image ID not set"
    end

    tag_result = @local_repository.tag_image_for_remote(self)

    if !tag_result
      raise "Image tag command failed"
    end

    @tagged_for_remote = true

    return self

  end

  # Push image to associated remote registry
  # @return [RaisEcs::ContainerImage] Self

  def push_to_remote!

    if @primary_image_tag.nil?
      raise "Primary image tag not set"
    end

    if @remote_repository.nil?
      raise "Remote repository not set"
    end

    if @local_repository.nil?
      raise "Local repository not set"
    end

    if @local_image_id.nil?
      raise "Local image ID not set"
    end

    if !@tagged_for_remote
      raise "Image not yet tagged for remote repository"
    end

    # Assumption: local repository will always be the entity "pushing" the image - this might change, though and
    # could be refactored such that an image pusher class is needed

    @local_repository.push_image_to_remote(self)

    return self

  end


end
