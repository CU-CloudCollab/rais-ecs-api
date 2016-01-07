# RAIS - ECS Utility API


#### Table of Contents
1. [About](#about)
2. [Installation] (#installation)
3. [Documentation] (#documentation)
4. [Examples] (#examples)

## About

When building the platform for our PI Dashboard product (hosted in Elastic Container Services), RAIS developed this api to allow object-oriented interaction with the ECS infrastructure as well as local and remote Docker registries.  This library is used by a set of cli tools that we use to build, push and deploy images to specific services in ECS -- this CLI will also being posted to the CU-CloudCollab repository.

Currently, the library focuses on services that already exist in AWS (that is, they have been set up using the GUI, or through other scripts) -- it allows monitoring those services, as well as updating them with new parameters (new task configurations, new images, and scaling).

Future enhancements will add the ability to setup new services (create the service, assign role, assign ELB).


**Important Notes:**

* This library currently (at v 0.3.0) has minimum viable implementation of ECS task definitions for RAIS.  This includes: Image, Environment Variables, Log driver, Port Mappings, Memory, and CPU.  It does not yet include support for linked containers or mounted volumes.  Future enhancements will include additional definition elements.

* The library assumes that the user environment is configured with the desired AWS credentials.  Future enhancements will include ability to inject other credentials.


## Installation

To use this library, you can either include the gem via github reference:

    Add to Gemfile: 
    gem 'rais_ecs', :git => 'git://github.com/CU-CloudCollab/rais-ecs-api.git'
    
    $ bundle
    

Or, clone the repository and build the Gem

    $ cd rais-ecs-api
    $ gem build ./rais_ecs.gemspec
    $ gem install ./rais_ecs-0.3.0.gem
    

## Documentation

The library is documented with YARD syntax (http://www.yardoc.org/guides/index.html).  You can generate helpful documentation for the library as follows:

    $ gem install yard
    $ cd rais-ecs-api
    $ yard
    
This will generate a doc folder which contains html documentation in the typical yard format.

## Examples

Get details about a given cluster and related nodes:

    aws = Cloud.new
    ecs_manager = EcsManager.new(cloud: aws)
    
    # get cluster by name
    cluster = ecs_manager.get_cluster_by_name('EXAMPLE-CLUSTER')

    # output details about the cluster (name, status, size)
    puts cluster.name
    puts cluster.status
    puts cluster.size

    # get nodes belonging to this cluster and output details
    cluster.nodes.each do |node|
        puts node.get_node_instance_id + ' ' + node.get_node_instance_type
    end
    

Get current task revision and image running for service

    aws = Cloud.new
    ecs_manager = EcsManager.new(cloud: aws)
    
    # get cluster by name
    cluster = ecs_manager.get_cluster_by_name('EXAMPLE-CLUSTER')
    
    # get service by name
    service = cluster.get_service_by_name('EXAMPLE-SERVICE')
    
    # get current container config
    container_config = service.get_primary_container_config
	
	# output cpu and memory allocation
	puts container_config.memory
	puts container_config.cpu
	
	# get image
	image = container_config.image
	
	# output image tag as deployed to AWS
	puts image.primary_image_tag
	
	# output image remote repository
	puts image.remote_repository.get_remote_repository_name
	

**See the rais-service-cli project for additional implementation examples**
    