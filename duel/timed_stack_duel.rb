require_relative "duel_helper"

# ConnectionPool::TimedStack, under every checkout and checkin, and which
# subclasses build on.

duel "timed_stack: pop and push" do
  once { @stack = ConnectionPool::TimedStack.new(size: 5) { FakeConnection.new } }
  @stack.push(@stack.pop)
end

duel "timed_stack: pop with a timeout and push" do
  once { @stack = ConnectionPool::TimedStack.new(size: 5) { FakeConnection.new } }
  @stack.push(@stack.pop(timeout: 1))
end

duel "timed_stack: pop and push all 5" do
  once { @stack = ConnectionPool::TimedStack.new(size: 5) { FakeConnection.new } }
  conns = Array.new(5) { @stack.pop }
  conns.each { |conn| @stack.push(conn) }
end

duel "timed_stack: pop and push all 50" do
  once { @stack = ConnectionPool::TimedStack.new(size: 50) { FakeConnection.new } }
  conns = Array.new(50) { @stack.pop }
  conns.each { |conn| @stack.push(conn) }
end

# Empty, with no time to wait: nil at once, without sleeping.
duel "timed_stack: pop from an empty stack without raising" do
  once do
    @stack = ConnectionPool::TimedStack.new(size: 1) { FakeConnection.new }
    @stack.pop
  end
  @stack.pop(timeout: 0, exception: false)
end
