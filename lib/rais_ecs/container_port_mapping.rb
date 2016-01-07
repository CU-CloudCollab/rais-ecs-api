# Container Port Mapping - Node to Container Port Map
# Class to contain port mappings for containers (node port to container port)

# @author Brett Haranin

class RaisEcs::ContainerPortMapping

  # @return [Integer] Port on node (available to ELB)
  attr_reader :node_port

  # @return [Integer] Port on container (port the container exposes)
  attr_reader :container_port

  # @return [String] The protocol for this map
  attr_reader :protocol

  # Constructor Container Port Map
  # @param node_port [Integer] Port on node (available to ELB)
  # @param container_port [Integer] Port on container (port the container exposes)
  # @param protocol [String] The protocol for this map

  def initialize(node_port,container_port,protocol)
      @node_port = node_port
      @container_port = container_port
      @protocol = protocol
  end

end
