module CRDT
  # Vector clocks are a loose synchronization primitive
  #
  # Vector clocks can be used as a building block to create other replicated data types, and tracking operations
  #
  # Formally, a vector clock is equivalent to a GCounter that is only incremented by 1, and the aggregate value is ignored
  class VectorClock
    # Create a new vector clock
    #
    # @param default_node Identity of the current node. Defaults to the current Thread object id
    def initialize(default_node = Thread.current.object_id)
      @default_node = default_node
      @clocks = {}
    end

    attr_accessor :clocks

    # Increment the clock for the given node by 1
    #
    # @param node The node to update the clock for. Defaults to the default node
    def increment_clock(node = nil)
      node ||= @default_node
      @clocks[node] ||= 0
      @clocks[node] += 1
    end

    # Get the current clock value for the given node
    #
    # @param node the node to check for. Defaults to the default node
    def value(node = nil)
      node ||= @default_node
      @clocks[node]
    end 

    # Create a new VectorClock from the provided hash. The hash should follow this syntax:
    #
    # {
    #   "clocks" => {
    #     "1" => 3,
    #     "3" => 2
    #   }
    # }
    def self.from_h(hash)
      clock = VectorClock.new

      hash["clocks"].each do |node, value|
        clock.clocks[node] = value
      end

      return clock
    end

    # Get a hash representation of this vector clock, suitable for serialization to JSON
    def to_h
      return {
        clocks: @clocks,
      }
    end

    # Perform a one-way merge, bringing in clock values from the other clock
    def merge(other)
      other.clocks.each do |node, value|
        current_value = @clocks[node]
        if current_value
          if current_value < value
            @clocks[node] = value
          end
        else
          @clocks[node] = value
        end
      end
    end
  end
end
