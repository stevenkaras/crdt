# Convergent/Commutative Replicated Data Types
#
# TODO: document library inclusion
# TODO: document usage example
module CRDT
end

%w{
  pn_counter
  vector_clock
  or_set
  lww_register
}.each do |lib|
  require File.expand_path("crdt/#{lib}", __dir__)
end
