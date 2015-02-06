module CRDT
  # A positive negative counter
  #
  # This counter can be incremented up or down. Each node should only adjust it's up and down counters.
  # The current value of the counter is calculated by taking the sum of all the positive counters and subtracting the sum of all the negative counters
  #
  # # Efficiency:
  # value in counter: n, number of nodes: m, number of changes: k
  # Local changes (+/-) are O(1)
  # Merging changes are O(m)
  # The space cost is O(m)
  # The space cost of synchronization is O(m)
  #
  # # Implementation notes:
  # This implementation is a CvRDT. That means it sends a full copy of the entire structure, rather than messages
  class PNCounter
    # @param hash [Hash] a serialized PNCounter, conforming to the format here
    # 
    # Expects a Hash in the following format:
    # {
    #   "positive" => {
    #     "1" => 15,
    #     "3" => 4
    #   },
    #   "negative" => {
    #   }
    # }
    def self.from_h(hash)
      counter = PNCounter.new(hash["node_identity"], hash["base_value"])

      hash["positive"].each do |source, amount|
        counter.increase(amount, source)
      end
      hash["negative"].each do |source, amount|
        counter.decrease(amount, source)
      end

      return counter
    end

    # Get a hash representation of this object, which is suitable for serialization to JSON
    def to_h
      return {
        node_identity: @node_identity,
        base_value: @base_value,
        cached_value: @cached_value,
        positive: @positive_counters,
        negative: @negative_counters,
      }
    end

    # Create a new counter
    #
    # @param node_identity Identifier for this node, used for tracking changes to the counter. Defaults to the current Thread's object ID
    def initialize(node_identity = Thread.current.object_id, base_value = 0)
      @base_value = base_value
      @cached_value = base_value
      @positive_counters = {}
      @negative_counters = {}
      @node_identity = node_identity
    end

    attr_accessor :positive_counters, :negative_counters

    # Increase this counter by the given amount
    #
    # @param amount [Number] a non-negative amount to decrease this counter by
    def increase(amount, source = nil)
      source ||= @node_identity
      positive_counters[source] ||= 0
      positive_counters[source] += amount
      @cached_value += amount

      return self
    end

    # Decrease this counter by the given amount
    #
    # @param amount [Number] a non-negative amount to decrease this counter by
    def decrease(amount, source = nil)
      source ||= @node_identity
      negative_counters[source] ||= 0
      negative_counters[source] += amount
      @cached_value -= amount

      return self
    end

    # Add something to this counter
    #
    # @param other [Number] the amount to add to this counter
    def +(other)
      if other > 0
        increase(other)
      else
        decrease(- other)
      end
      self
    end

    # Subtract something from this counter
    #
    # @param other [Number] the amount to subtract from this counter
    def -(other)
      if other > 0
        decrease(other)
      else
        increase(- other)
      end
      self
    end

    def value
      @cached_value
    end

    def to_i
      @cached_value.to_i
    end

    # Merge the counters from the other PNCounter into this one
    def merge(other)
      other.positive_counters.each do |source, amount|
        current_amount = @positive_counters[source]
        if current_amount
          if current_amount < amount
            @positive_counters[source] = amount
          end
        else
          @positive_counters[source] = amount
        end
      end
      other.negative_counters.each do |source, amount|
        current_amount = @negative_counters[source]
        if current_amount
          if current_amount < amount
            @negative_counters[source] = amount
          end
        else
          @negative_counters[source] = amount
        end
      end

      return self
    end

    # Garbage collect a node, removing its counters and folding them into the new base value.
    #
    # This should only be called if your cluster management has indicated that a node has left the cluster permanently.
    def gc(node)
      @base_value += @positive_counters[node]
      @base_value -= @negative_counters[node]
      @positive_counters.delete(node)
      @negative_counters.delete(node)
    end
  end
end