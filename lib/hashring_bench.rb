require "hashring_bench/version"
require "zlib"

module HashringBench
  class Error < StandardError; end
 
  class Shard

    attr_accessor :dsn
    attr_accessor :sid

    def initialize(dsn, sid)
      @dsn = dsn
      @sid = sid
    end
  end

  def self.get_hash(value)
    Zlib.crc32(value.to_s, nil)
  end

  def self.get_shard_idx(shards, value)
    idx = self.get_hash(value) % shards.length
    idx
  end

  # Performance can be improved with memoization
  def self.get_consistent_shard_idx_bs(shards, value)
    idx = self.get_hash(value) % 360

    # Use modified Binary search to find best fitting shard
    # i.e. minimum shard with id >= value
    middle = shards.length / 2
    i = 0
    j = shards.length - 1
    best = 0

    while i < j

      # If we get an exact match return the id at middle
      if shards[middle].sid == idx
        return middle
      elsif shards[middle].sid < idx
        i = middle + 1
        middle = (i + j) / 2
      # shards[middle] > id we want to track 
      else
        best = middle # Store current middle as best
        j = middle - 1
        middle = (i + j) / 2
      end
    end

    return best
  end

  def self.get_consistent_shard_idx_memo(shards, value, memo)
    idx = self.get_hash(value) % 360

    # Use modified Binary search to find best fitting shard
    # i.e. minimum shard with id >= value
    middle = shards.length / 2
    i = 0
    j = shards.length - 1
    best = 0

    if !memo[idx].nil?
      return memo[idx]
    end

    while i < j

      # If we get an exact match return the id at middle
      if shards[middle].sid == idx
        memo[idx] = middle
        return middle
      elsif shards[middle].sid < idx
        i = middle + 1
        middle = (i + j) / 2
      # shards[middle] > id we want to track 
      else
        best = middle # Store current middle as best
        j = middle - 1
        middle = (i + j) / 2
      end
    end

    memo[idx] = best
    return best
  end

  def self.get_consistent_shard_linear(shards, value, memo)
    idx = self.get_hash(value) % 360

    if !memo[idx].nil?
      return memo[idx]
    end

    i = 0
    shards.each do |shard|
      if shard.sid >= idx
        memo[idx] = i
        return i
      end

      i = i + 1
    end

    memo[idx] = 0
    return 0
  end
end

