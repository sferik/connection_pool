# A stand-in for a client such as Redis or Dalli: cheap to make and to
# call, so the pool's own work is what's timed.
class FakeConnection
  def get(key)
    key
  end

  def set(key, value, ex: nil)
    value
  end

  def pipelined
    yield self
  end

  def close
  end
end

# A pool that's never reloaded after fork, for benchmarks that build
# pools as they go (they'd otherwise pile up in ConnectionPool's list of
# pools to reload).
def build_pool(size: 5, timeout: 5)
  ConnectionPool.new(size:, timeout:, auto_reload_after_fork: false) { FakeConnection.new }
end

# One fiber per connection, each holding its own checkout (checkouts are
# fiber-local), as fiber servers like Falcon use a pool. The first resume
# of each checks a connection out, and the next checks it back in.
def holders(pool, count)
  Array.new(count) do
    Fiber.new do
      loop do
        pool.with { Fiber.yield }
        Fiber.yield
      end
    end
  end
end

# Threads that share the pool for n checkouts in all, each passing the
# GVL while it holds a connection, the way a thread waiting on a socket
# would. With more threads than connections, they wait for each other.
def contend(pool, threads, n)
  per_thread = n.fdiv(threads).ceil
  Array.new(threads) { Thread.new { per_thread.times { pool.with { Thread.pass } } } }.each(&:join)
end
