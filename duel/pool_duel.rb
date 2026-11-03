require_relative "duel_helper"

# ConnectionPool#with, which every Sidekiq job and most Redis and
# memcached calls in a Rails app go through, often several times a
# request. These are uncontended: one thread, a connection free.

duel "with: check out and in" do
  once { @pool = build_pool }
  @pool.with { |conn| conn }
end

duel "with: check out and in with a timeout" do
  once { @pool = build_pool }
  @pool.with(timeout: 1) { |conn| conn }
end

duel "with: nested three deep on one thread" do
  once { @pool = build_pool }
  @pool.with { @pool.with { @pool.with { |conn| conn } } }
end

duel "with: from a pool of 1" do
  once { @pool = build_pool(size: 1) }
  @pool.with { |conn| conn }
end

duel "with: from a pool of 100" do
  once { @pool = build_pool(size: 100) }
  @pool.with { |conn| conn }
end

duel "checkout: check out and in by hand" do
  once { @pool = build_pool }
  @pool.checkout
  @pool.checkin
end

duel "checkout: nested on one thread" do
  once { @pool = build_pool }
  @pool.checkout
  @pool.checkout
  @pool.checkin
  @pool.checkin
end

# Every connection of the pool checked out at once, from a fiber each,
# and then all checked back in.
duel "with: hold all 5 connections from 5 fibers" do
  once { @fibers = holders(build_pool(size: 5), 5) }
  @fibers.each(&:resume)
  @fibers.each(&:resume)
end

duel "with: hold all 25 connections from 25 fibers" do
  once { @fibers = holders(build_pool(size: 25), 25) }
  @fibers.each(&:resume)
  @fibers.each(&:resume)
end

# A bad connection is thrown away, and the next checkout makes another.
duel "with: discard the connection and make a new one" do
  once { @pool = build_pool }
  @pool.with { @pool.discard_current_connection(&:close) }
end

# With every connection out and no time to wait, the checkout times out
# at once, without sleeping.
duel "with: time out on an exhausted pool" do
  once do
    @pool = build_pool(size: 1)
    Fiber.new { @pool.checkout }.resume # held for good, by a fiber that's done
  end
  @pool.with(timeout: 0) { |conn| conn }
rescue ConnectionPool::TimeoutError
  nil
end

duel "pool: read available and idle" do
  once { @pool = build_pool }
  @pool.available
  @pool.idle
end

# reap runs every so often, in apps that close idle connections. This
# finds none idle for long enough.
duel "reap: look over 5 connections, none idle too long" do
  once do
    @pool = build_pool
    @fibers = holders(@pool, 5)
    2.times { @fibers.each(&:resume) }
  end
  @pool.reap(idle_seconds: 3600) { |conn| conn.close }
end

# What a forked child does with each pool (ConnectionPool.after_fork
# calls reload), and then the checkouts that make new connections.
duel "reload: close 5 connections and make 5 again" do
  once do
    @pool = build_pool
    @fibers = holders(@pool, 5)
  end
  @fibers.each(&:resume)
  @fibers.each(&:resume)
  @pool.reload(&:close)
end

duel "shutdown: build a pool, use 5 connections, shut it down" do
  pool = build_pool
  fibers = holders(pool, 5)
  fibers.each(&:resume)
  fibers.each(&:resume)
  pool.shutdown(&:close)
end
