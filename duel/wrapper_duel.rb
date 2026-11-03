require_relative "duel_helper"

# ConnectionPool.wrap, a drop-in for a global client: every method call
# goes through method_missing, which checks a connection out for it.

setup { @client = ConnectionPool.wrap(size: 5, auto_reload_after_fork: false) { FakeConnection.new } }

duel("wrapper: call a method") { @client.get("key") }

duel("wrapper: call a method with keywords") { @client.set("key", "value", ex: 60) }

duel("wrapper: call a method with a block") { @client.pipelined { |conn| conn } }

duel("wrapper: with") { @client.with { |conn| conn } }

duel("wrapper: respond_to?") { @client.respond_to?(:get) }
