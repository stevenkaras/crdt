module CRDT
  # Last Write Wins Register
  #
  # This is a LWWRegister, useful for storing arbitrary data. However, it assumes that your nodes' clocks are synchronized.
  #
  # In practice, this is problematic if you expect changes to take place more often than the clock drift.
  # In my personal experience, clock drift is usually only a few seconds between servers, but can be upwards of several minutes between personal devices such as mobile phones/tablets (especially those on different cellular networks)
  class LWWRegister
    def initialize(tiebreaker = Thread.current.object_id.to_i)
      @tiebreaker = tiebreaker
      @value = nil
      @timestamp = nil
    end

    attr_accessor :value, :timestamp, :timestamp_nsec, :timestamp_tiebreaker

    # Set the value of this register, throwing out any previous value
    def set(value)
      @value = value
      time = Time.now
      @timestamp = time.to_i
      @timestamp_nsec = time.nsec
      @timestamp_tiebreaker = @tiebreaker
    end

    # Get the value in this register
    def get
      @value
    end

    # Perform a one way merge, potentially bringing in the value from another register
    def merge(other)
      return unless other.timestamp
      return unless other.timestamp >= @timestamp
      return unless other.timestamp_nsec >= @timestamp_nsec
      return unless other.timestamp_tiebreaker >= @timestamp_tiebreaker
      @value = other.value
      @timestamp = other.timestamp
      @timestamp_nsec = other.timestamp_nsec
      @timestamp_tiebreaker = other.timestamp_tiebreaker
    end

    # Get a hash representation of this register, suitable for serialization to JSON
    def to_h
      return {
        value: @value,
        timestamp: @timestamp,
        timestamp_nsec: @timestamp_nsec,
        timestamp_tiebreaker: @timestamp_tiebreaker,
        tiebreaker: @tiebreaker,
      }
    end

    # Build a new register from the given hash
    def self.from_h(hash)
      register = LWWRegister.new(hash["tiebreaker"])

      register.value = hash["value"]
      register.timestamp = hash["timestamp"]
      register.timestamp_nsec = hash["timestamp_nsec"]
      register.timestamp_tiebreaker = hash["timestamp_tiebreaker"]

      return register
    end
  end
end
