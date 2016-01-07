# Registry Repository - hosting service for container images
# @author Brett Haranin
# @todo add authenticate action - currently relies on local environment authenication state

class RaisEcs::RegistryImageRepository

  # Note - AWS libraries hand back images with this class injected - but do not add username/password.
  #   these values should be set by the outer-most client prior to any registry server action


  attr_writer :repository_username
  attr_writer :repository_password

  # Constructor - Trusted Registry Repository
  # @param options [Hash]
  # @option options [String] :registry_server Registry server address (e.g., docker.cucloud.net)
  # @option options [String] :repository_name The name of the image repository (e.g., user/image)
  # @option options [String] :repository_username Username for this specific repository
  # @option options [String] :repository_password Password for this specific repository

  def initialize(options)
    @registry_server = options[:registry_server]
    @repository_name = options[:repository_name]

    # these are necessary before using any api calls
    @repository_username = options[:repository_username]
    @repository_password = options[:repository_password]
  end

  # get fully scoped repository name (with registry server prefix)
  # @return [String] The fully scoped repository name
  def get_remote_repository_name
    return @registry_server + "/" + @repository_name
  end

  # Get OAuth2 Bearer token from registry for use with other requests
  # @return [String] OAuth2 Bearer Token

  def get_auth_token

    # https://docs.docker.com/registry/spec/auth/jwt/
    auth_response = RestClient.get "https://#{@repository_username}:#{@repository_password}@#{@registry_server}/auth/token?service=#{@registry_server}&scope=repository:#{@repository_name}:pull&account=#{@registry_username}"
    auth_response_json = JSON.parse(auth_response)
    token = auth_response_json['token']
    return token

  end

  # get image tags from remote repository
  # @return [Array<String>] Array of image tags on remote registry
  def get_remote_image_tags

    token = self.get_auth_token

    # https://docs.docker.com/registry/spec/api/#listing-image-tags
    tags_response = RestClient.get "https://#{@registry_server}/v2/#{@repository_name}/tags/list", { 'Authorization' => "Bearer #{token}" }
    tags_response_json = JSON.parse(tags_response)
    tags = tags_response_json['tags']

    return tags

  end

  # get image object from remote repository based on tag
  # @param [String] Image Tag
  # @return [ContainerImage] Requested Image Object

  def get_image_by_tag(tag)
    manifest = self.get_image_manifest_by_tag(tag)
    return self.get_image_from_manifest(manifest)
  end

  # get image object from remote repository based on sha digest
  # @param [String] SHA Digest for image
  # @return [ContainerImage] Requested Image Object

  def get_image_by_digest(digest)
    manifest = self.get_image_manifest_by_digest(digest)
    return self.get_image_from_manifest(manifest)
  end

  # build image object from manifest
  # @param [Json] Image Manifest
  # @return [ContainerImage] Requested Image Object

  def get_image_from_manifest(manifest)
    return RaisEcs::ContainerImage.new({
      primary_image_tag: self.extract_tag_from_manifest(manifest),
      local_image_id: self.extract_local_id_from_manifest(manifest),
      remote_repository: self,
      image_sha_digest: self.extract_digest_from_manifest(manifest),
      image_created_dt: self.extract_created_from_manifest(manifest)
    })
  end

  # get image manifest (json blob) for given image SHA digest
  # @param digest [String] Image digest
  # @return [Json] Image Manifest

  def get_image_manifest_by_digest(digest)

    token = self.get_auth_token

    # https://docs.docker.com/registry/spec/api/#detail
    reg_response = RestClient.get "https://#{@registry_server}/v2/#{@repository_name}/manifests/#{digest}", { 'Authorization' => "Bearer #{token}" }
    respcode = reg_response.code

    if respcode != 200
      raise "Request to registry failed - response code #{respcode}"
    end

    return reg_response

  end

  # get image manifest (json blob) for given image SHA digest
  # @param tag [String] Image Tag
  # @return [Json] Image Manifest

  def get_image_manifest_by_tag(tag)

    token = self.get_auth_token

    # https://docs.docker.com/registry/spec/api/#detail
    reg_response = RestClient.get "https://#{@registry_server}/v2/#{@repository_name}/manifests/#{tag}", { 'Authorization' => "Bearer #{token}" }
    respcode = reg_response.code

    if respcode != 200
      raise "Request to registry failed - response code #{respcode}"
    end

    return reg_response

  end

  # get image digest from manifest JSON
  # @param manifest [Json] Image Manifest
  # @return [String] Image SHA digest

  def extract_digest_from_manifest(manifest)
    # https://docs.docker.com/registry/spec/api/#manifest
    return manifest.headers[:docker_content_digest]
  end

  # get last local image id from manifest JSON
  # @param manifest [Json] Image Manifest
  # @return [String] Local image id for the remote image manifest

  def extract_local_id_from_manifest(manifest)
    # https://docs.docker.com/registry/spec/api/#manifest

    manifest = JSON.parse(manifest)

    # last build in history will be local id (if done on this machine)
    last_image_history_entry = JSON.parse(manifest['history'].first["v1Compatibility"])
    return last_image_history_entry['id'][0...12]

  end


  # get last local image id from manifest JSON
  # @param manifest [Json] Image Manifest
  # @return [String] Image tag

  def extract_tag_from_manifest(manifest)
    # https://docs.docker.com/registry/spec/api/#manifest

    manifest = JSON.parse(manifest)
    return manifest['tag']
  end

  # get the date and time of the last image build (corresponds to local image id)
  # @param manifest [Json] Image Manifest
  # @return [Time] Image Build Datetime

  def extract_created_from_manifest(manifest)
    manifest = JSON.parse(manifest)
    last_image_history_entry = JSON.parse(manifest['history'].first["v1Compatibility"])
    return Time.parse(last_image_history_entry['created'])
  end

  # check if a given image exists on the remote repository
  # @param image [RaisEcs::ContainerImage] Image object
  # @return [Boolean] Image Exists or Not (true/false)

  def image_exists_in_registry(image)

    registry_tags = self.get_remote_image_tags

    tag = registry_tags.select { |tag| tag == image.primary_image_tag }

    if tag.length > 0
      return true
    else
      return false
    end

  end

end
