require_relative "duel_helper"

# Threads sharing one pool, as Sidekiq's or Puma's do. The threads make
# allocations vary from run to run, so these are judged on timings, and
# with duel-gvl, on how long the threads waited for the GVL too. The
# pools wait a minute for a connection, not 5 seconds, so a thread that
# a busy machine leaves unscheduled doesn't fail the run.

duel "contended: 4 threads, a pool of 4", only: :timing do |n|
  once { @pool = build_pool(size: 4, timeout: 60) }
  contend(@pool, 4, n)
end

duel "contended: 4 threads, a pool of 2", only: :timing do |n|
  once { @pool = build_pool(size: 2, timeout: 60) }
  contend(@pool, 4, n)
end

duel "contended: 10 threads, a pool of 5", only: :timing do |n|
  once { @pool = build_pool(size: 5, timeout: 60) }
  contend(@pool, 10, n)
end

duel "contended: 4 threads, a pool of 1", only: :timing do |n|
  once { @pool = build_pool(size: 1, timeout: 60) }
  contend(@pool, 4, n)
end
