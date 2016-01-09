Gem::Specification.new do |s|
  s.name        = 'rais_ecs'
  s.version     = '0.3.1'
  s.date        = '2015-01-09'
  s.summary     = "RAIS ECS utility library"
  s.description = "RAIS ECS utility library"
  s.authors     = ["Brett Haranin"]
  s.email       = 'bmh67@cornell.edu'
  s.files       = ["lib/rais_ecs.rb","lib/rais_ecs/cloud.rb","lib/rais_ecs/cluster.rb","lib/rais_ecs/container_config.rb","lib/rais_ecs/container_environment_var.rb","lib/rais_ecs/container_image.rb","lib/rais_ecs/container_port_mapping.rb","lib/rais_ecs/container.rb","lib/rais_ecs/ecs_manager.rb","lib/rais_ecs/local_image_repository.rb","lib/rais_ecs/node.rb","lib/rais_ecs/registry_image_repository.rb","lib/rais_ecs/service_config.rb","lib/rais_ecs/service_deployment.rb","lib/rais_ecs/service_event_log.rb","lib/rais_ecs/service.rb"]
  s.require_paths = %w{lib}
  s.add_dependency 'aws-sdk', '~> 2'
  s.add_dependency 'docker-api'
  s.add_dependency 'json'
  s.add_dependency 'rest-client'
  s.homepage    =
    'http://rais.cucloud.net'
  s.license       = 'MIT'
end
