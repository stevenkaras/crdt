# Convergent/Commutative Replicated Data Types
#
# TODO: document library inclusion
# TODO: document usage example
module CRDT
end

%w{
  vector_clock
}.each do |lib|
  require File.expand_path("crdt/#{lib}", __DIR__)
end
