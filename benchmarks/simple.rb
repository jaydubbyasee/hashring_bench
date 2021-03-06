require 'benchmark/ips'
require 'hashring_bench'
require 'securerandom'

Benchmark.ips do |x|
  # Configure the number of seconds used during
  # the warmup phase (default 2) and calculation phase (default 5)
  x.config(:time => 60, :warmup => 2)

  # Populate shards
  shards = []
  for i in 0..9 do
    shards.push(HashringBench::Shard.new("shard-#{i}", 360.div(10) * i))
  end

  x.report("Simple modulo assignment") do |times|
    i = 0
    while i < times
      HashringBench::get_shard_idx(shards, "test-#{i}")
      i += 1
    end
  end

  x.report("Consistent Hashring w/ Binary Search") do |times|
    i = 0
    while i < times
      HashringBench::get_consistent_shard_idx_bs(shards, "test-#{i}")
      i += 1
    end
  end

  memo1 = {}
  x.report("Consistent Hashring w/ Memoized Binary Search") do |times|
    i = 0
    while i < times
      HashringBench::get_consistent_shard_idx_memo(shards, "test-#{i}", memo1)
      i += 1
    end
  end

  memo2 = {}
  x.report("Consistent Hashring w/ Linear Memoized Search") do |times|
    i = 0
    while i < times
      HashringBench::get_consistent_shard_idx_memo(shards, "test-#{i}", memo2)
      i += 1
    end
  end

  # Compare the iterations per second of the various reports!
  x.compare!
end
