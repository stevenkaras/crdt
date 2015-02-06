module CRDT
  # Observed-Removed Set
  #
  # This CRDT allows items to be added, and removed. The idea being that when an item is added, it is added along with a token. When removing an element, all tokens for that item are marked as removed.
  # This implementation of an ORSet keeps a unified record for each item, where removed tokens are moved from an "observed" set to a "removed" set.
  #
  # Efficiency:
  # Number of items: n, Number of nodes: m, Number of operations: k
  # Space efficiency: O(k)
  # Space efficiency with garbage collection: O(n)
  # Adding an item: O(1)
  # Removing an item: O(k) in the degenerate case, typically closer to O(1)
  # Testing if an item is in the set: O(1)
  class ORSet
    # Create a new, empty set
    def initialize(node_identity = Thread.current.object_id, token_counter = 0)
      @node_identity = node_identity
      @token_counter = token_counter
      @items = {}
    end

    attr_accessor :items, :token_counter

    # Check if this item is in the set
    def has?(item)
      tokens = @items[item]
      return false unless tokens
      return ! tokens[:observed].empty?
    end

    def each
      if block_given?
        @items.each do |item, record|
          next if record[:observed].empty?
          yield item
        end
      else
        return to_enum
      end
    end
    include Enumerable

    # Add an item to this set
    def add(item)
      # the token in this implementation is "better", since it's easier for us to parse/garbage collect
      token = "#{@node_identity}:#{@token_counter}"
      @token_counter += 1

      @items[item] ||= { observed: [], removed: []}
      @items[item][:observed] << token
    end

    # Mark an item as removed from the set
    def remove(item)
      @items[item][:removed] += @items[item][:observed]
      @items[item][:observed] = []
    end

    # Get a hash representation of this set, suitable for serialization to JSON
    def to_h
      return {
        node_identity: @node_identity,
        token_counter: @token_counter,
        items: @items,
      }
    end

    # Create a ORSet from a hash, such as that deserialized from JSON
    def self.from_h(hash)
      set = ORSet.new(hash["node_identity"], hash["token_counter"])

      hash["items"].each do |item, record|
        set.items[item] = {observed: [], removed: []}
        set.items[item][:observed] += record[:observed]
        set.items[item][:removed] += record[:removed]
      end

      return set
    end

    # Perform a one-way merge, bringing changes from the other ORSet provided
    #
    # @param other (ORSet)
    def merge(other)
      other.items.each do |item, record|
        @items[item] ||= {observed: [], removed: []}
        @items[item][:observed] |= record[:observed]
        @items[item][:removed] |= record[:removed]
        @items[item][:observed] -= @items[item][:removed]
      end
    end

    # garbage collect all tokens originating from the given node that are smaller than the given counter
    #
    # This should be called only when partial consensus can be ascertained for the system
    def gc(node_to_collect, until_counter)
      match_proc = proc do |token|
        node, counter = token.split(":")
        node == node_to_collect && counter.to_i <= until_counter
      end

      @items.each do |item, record|
        # remove any removal records, since the system has reached consensus up to this node's counter
        record[:removed].reject!(&:match_proc)

        # squash all the observed tokens into one
        # This is potentially unnecessary so long as at most one active observed token is recorded per node
        tokens = record[:observed].select(&:match_proc).map do |token|
          node, counter = token.split(":")
          [node, counter.to_i]
        end.sort_by(&:last)
        surviving_token = tokens.pop
        record[:observed] -= tokens
        record[:observed] << surviving_token
      end
    end
  end
end
