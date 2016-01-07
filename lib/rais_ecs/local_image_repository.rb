# Local docker repository
# @see http://askubuntu.com/questions/477551/how-can-i-use-docker-without-sudo Instructions to allow non-root user access to Docker socket
# @author Brett Haranin

class RaisEcs::LocalImageRepository

  # Constuctor for local image repository (Docker)
  # @param options [Hash]
  # @option options [String] :docker_socket Local docker socket location
  # @option options [String] :repository_name Name of repository in local Docker instance

  def initialize(options)

    @docker_socket = options[:docker_socket]
    @repository_name = options[:repository_name]

    if @docker_socket.nil?
      @docker_socket = '/var/run/docker.sock'
    end

  end

  # Get the raw docker-api object for a given local image_id
  # @param id [String] Local image_id value (e.g., first 12 digits of SHA as displayed on docker image list)
  # @return [Docker::Image]

  def get_raw_image_by_id(id)

    repo_images = self.get_raw_repository_images

    # select images from this repository with matching id
    image = repo_images.select { |image| image.id[0,id.length] == id }

    if image.length == 0
      raise "Image not found"
    elsif image.length > 1
      raise "More than one image matched"
    end

    return image[0]

  end

  # get all raw Docker::Image objects from the local repository for this repository
  # @return [Array<Docker::Image>]

  def get_raw_repository_images
    # Docker image object inspection:
    # Docker::Image { :id => ae0d36c75a1deac924ef426162f4356118a780140c709e16bbb6d4aa435c8d34, :info => {"ParentId"=>"ae9aedc2812918e2f5bc80d17de557de0f9ed18e1f10cc3609b10c0e1c1a24d2", "RepoTags"=>["docker.cucloud.net/rais/pidash-uxwork-zach:e40c5a1"], "RepoDigests"=>[], "Created"=>1438632097, "Size"=>6202783, "VirtualSize"=>486874949, "Labels"=>{}, "id"=>"ae0d36c75a1deac924ef426162f4356118a780140c709e16bbb6d4aa435c8d34"}, :connection => Docker::Connection { :url => unix:///, :options => {:socket=>"/var/run/docker.sock"} } }

    #https://github.com/bkeepers/dotenv
    images = Docker::Image.all

    repo_images = []

    images.each do |image|
      # check to see if this image is tagged with the local repository (can have multiple tags)
      # note - this could probably be improved with some enumerable magic - revisit it
      include_image = false
      image.info["RepoTags"].each do |tag|
        if tag[0..@repository_name.length] == @repository_name + ":"
          include_image = true
        end
      end

      if include_image
        repo_images << image
      end
    end

    return repo_images

  end

  # Get image objects for all images in this local repository
  # @return [Array<ContainerImage>]

  def get_repository_images

    raw_images = self.get_raw_repository_images

    images = []

    raw_images.each do |image|
      images << RaisEcs::ContainerImage.new({
          local_image_id: image.id[0...12],
          primary_image_tag: image.id[0...12],
          local_repository: self,
          local_image_object: image,
          image_created_dt: Time.at(image.info['Created'])
      })
    end

    return images

  end

  # Get the ecs utility library image (wraps the docker-api) for a given id
  # @param id [String] Local image_id value (e.g., first 12 digits of SHA as displayed on docker image list)
  # @return [RaisEcs::ContainerImage] An ecs utility library instance of image for given id

  def get_image_by_id(id)

    image = self.get_raw_image_by_id(id)

    return RaisEcs::ContainerImage.new({
        local_image_id: id,
        local_repository: self,
        local_image_object: image
    })

  end

  # Tag a given image in the local repository for use with it's associated remote repository (injected into image)
  # @param image [ContainerImage] An instance of the image to be tagged for remote repository
  # @return [Boolean] Result of tagging operation

  def tag_image_for_remote(image)

    if image.primary_image_tag.nil?
      raise "No primary tag specified"
    end

    if image.local_image_id.nil?
      raise "No local id set in image"
    end

    if image.remote_repository.nil?
      raise "Image has not remote repository specified"
    end

    raw_image = self.get_raw_image_by_id(image.local_image_id)

    begin
      #https://github.com/bkeepers/dotenv
      raw_image.tag('repo' => image.remote_repository.get_remote_repository_name, 'tag' => image.primary_image_tag, 'force' => true)
    rescue
      return false
    end

    return true

  end

  # push image to associated remote repository - outputs command to stdout
  # @param image [RaisEcs::ContainerImage] An instance of a tagged image to be pushed to remote repository
  # @return [Boolean] Result of push operation

  def push_image_to_remote(image)

    if !image.tagged_for_remote
      raise "Image not yet tagged (use tag_for_remote function)"
    end

    if image.local_image_id.nil?
      raise "No local id set in image"
    end

    if image.remote_repository.nil?
      raise "Image has not remote repository specified"
    end

    # api push command oddly fails silently - not sure what's up
    # also, api appears to give no feedback as image is uploaded - which can take some time

    # raw_image = self.get_raw_image_by_id(image.local_image_id)
    # https://github.com/bkeepers/dotenv
    # result = raw_image.push(nil,repo_tag: image.remote_repository.get_remote_repository_name + ":" + image.primary_image_tag)
    # puts result.inspect


    # drop to command line and issue push via docker-cli for now
    push_command = "docker push #{image.remote_repository.get_remote_repository_name}:#{image.primary_image_tag}"
    system push_command

    if $?.exitstatus == 0
      return true
    else
      return false
    end

  end

end
