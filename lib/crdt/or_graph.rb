module CRDT
  # Observe Remove Graph (variant of 2P2P Graph)
  #
  # This is a general purpose graph data type. It works by keeping a 2P set for vertices and an OR set for edges
  # This also means that it is left to the user to choose which operations take precedence (removes over adds, etc)
  #
  # Vertices are created uniquely on a node, and are represented with a token. It is left to the user to tie this token to their internal data.
  class ORGraph
    # Create a new graph
    def initialize(node_identity = Thread.current.object_id, token_counter = 0)
      @node_identity = node_identity
      @token_counter = token_counter
      @vertices = {}
      @edges = {}
    end

    attr_accessor :vertices, :edges

    # Test if a given vertex token is in this graph
    def has_vertex?(token)
      vertex = @vertices[token]
      return false unless vertex
      return ! vertex[:removed]
    end

    # Test if an edge exists between the given vertices
    def has_edge?(from, to)
      edge = @edges[edge_token(from, to)]
      return false unless edge
      return ! edge[:observed].empty?
    end

    # Get a list of all the edges that originate at the given vertex
    def outgoing_edges(from)
      @vertices[from][:outgoing_edges].map { |to| [from, to] }
    end

    # Get a list of all the edges that terminate at the given vertex
    def incoming_edges(to)
      @vertices[to][:incoming_edges].map { |from| [from, to] }
    end

    # Add a new vertex to the graph
    #
    # @return token representing the newly created vertex
    def create_vertex
      token = issue_token
      # the edge arrays are a performance optimization to provide O(1) lookup for edges by vertex
      @vertices[token] = { incoming_edges: [], outgoing_edges: [], removed: false }
      return token
    end

    # add an edge leading from the given vertex to the given vertex
    #
    # @return token representing the created edge
    def add_edge(from, to)
      @vertices[from][:outgoing_edges] << to
      @vertices[to][:incoming_edges] << from
      token = edge_token(from, to)
      @edges[token] ||= { observed: [], removed: [] }
      @edges[token][:observed] << issue_token

      return token
    end

    # remove a vertex from this graph, and any edges that involve it
    def remove_vertex(vertex)
      @vertices[vertex][:removed] = true
      (incoming_edges(vertex) + outgoing_edges(vertex)).each do |from, to|
        remove_edge(from, to)
      end
    end

    # remove an edge from this graph
    def remove_edge(from, to)
      edge = @edges[edge_token(from, to)]
      edge[:removed] += edge[:observed]
      edge[:observed] = []
      @vertices[from][:outgoing_edges] -= [to]
      @vertices[to][:outgoing_edges] -= [from]
    end

    # Get a hash representation of this graph, suitable for serialization to JSON
    def to_h
      return {
        node_identity: @node_identity,
        token_counter: @token_counter,
        vertices: @vertices,
        edges: @edges,
      }
    end

    # Create a new Graph from a hash, such as that deserialized from JSON
    def self.from_h(hash)
      graph = ORGraph.new(hash["node_identity"], hash["token_counter"])

      hash["vertices"].each do |token, vertex|
        graph.vertices[token] ||= {
          incoming_edges: vertex[:incoming_edges].dup,
          outgoing_edges: vertex[:outgoing_edges].dup,
          removed: vertex[:removed],
        }
      end
      hash["edges"].each do |token, edge|
        graph.edges[token] = {
          observed: edge[:observed].dup,
          reomved: edge[:removed].dup,
        }
      end

      return graph
    end

    # Perform a one-way merge, bringing in changes from another graph
    def merge(other)
      other.vertices.each do |token, vertex|
        @vertices[token] ||= {
          incoming_edges: [],
          outgoing_edges: [],
          removed: false,
        }
        # cleaning out removed edges is taken care of while merging edges
        @vertices[token][:incoming_edges] |= vertex[:incoming_edges]
        @vertices[token][:outgoing_edges] |= vertex[:outgoing_edges]
        @vertices[token][:removed] |= vertex[:removed]
      end
      other.edges.each do |edge_token, edge|
        from, to = from_edge_token(edge_token)
        @edges[edge_token] ||= {
          observed: [],
          removed: [],
        }
        @edges[edge_token][:observed] |= edge[:observed]
        @edges[edge_token][:removed] |= edge[:removed]
        @edges[edge_token][:observed] -= @edges[edge_token][:removed]
        if @edges[edge_token][:observed].empty?
          @vertices[to][:incoming_edges].delete(from)
          @vertices[from][:outgoing_edges].delete(to)
        end
      end
    end

    private
    # issue a token unique to this node
    def issue_token
      @token_counter += 1
      token = "#{@node_identity}:#{@token_counter}"
    end

    def edge_token(from, to)
      "#{from}->#{to}"
    end

    def from_edge_token(token)
      token.split("->")
    end
  end
end
