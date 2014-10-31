require 'active_support/core_ext/class/subclasses'

# = Godredis: bulk managing multiply Redis instances
# 
# Godredis provides unified interface for mass managing Redis connections which
# could be initialized in different modules having each own custom API. 
# 
# It is useful when you need to close or reset connections on forking, for 
# example, with puma server in the <tt>on_restart</tt> block: 
# 
#   on_restart do
#     # Rails.cache.instance_variable_get('@data').quit
#     # Redis::Objects.redis.quit
#     # Sidekiq.redis(&:quit)
#     Godredis.quit_all!  # instead of commented lines above
#   end
# 
# There are several ways to call bulk commands with Godredis:
#   
#   # Godredis.command_all! -- will output command execution result
#   Godredis.reconnect_all! # => Redis [cache_store]: reconnect... [OK]
#                           # => Redis [objects]: reconnect... [OK]
#                           # => Redis [sidekiq]: reconnect... [OK]
#   
#   # Godredis.command_all -- silent
#   Godredis.quit_all
#   
#   # Just different syntax
#   Godredis.redises(&:quit) 
#   Godredis.redises(&:quit!)
# 
#   # It's also return an enumerator, so you can do something like this:
#   Godredis.redises.map(&:connected?)
# 
# See Godredis::Base documentation for collecting your Redis-related objects.
module Godredis
  # :nodoc:
  def self.redises(&block)
    Base.subclasses.map(&:new).each(&block)
  end
  
  def self.method_missing(method, *args, &blk)
    if /^(?<action>.+)_all(?<bang>!)?$/ =~ method.to_s
      redises &:"#{action}#{bang}"
    else
      super
    end
  end
  
  # Subclass Godredis base class to collect Redis-related objects and use
  # simple DSL to set mapping for the common methods such as <tt>quit</tt> or
  # <tt>reconnect</tt> if they are different from the defaults.
  # 
  #   class CacheStoreGodredis < Godredis::Base
  #     redis ->{ Rails.cache.instance_variable_get('@data') }
  #   end
  # 
  #   class ObjectsGodredis < Godredis::Base
  #     redis ->{ Redis::Objects.redis }
  #   end
  #   
  #   class SidekiqGodredis < Godredis::Base
  #     # define mappings with blocks or lambdas
  #     redis  ->(&block){ Sidekiq.redis &block }
  #     client { redis &:client }
  #     quit   { redis &:quit }
  #   end
  # 
  # Default mapping:
  # 
  #   redis      { Redis.current }
  #   client     { redis.client }
  #   connected? { client.connected? }
  #   reconnect  { client.reconnect.connected? }
  #   quit       { redis.quit }
  # 
  # You may also add custom commands:
  # 
  #   class SomeGodredis < Godredis::Base
  #     del_some_key { redis.del('some_key') }
  #   end
  #   
  #   Godredis.redises(&:del_some_key!)
  #   # etc...
  # 
  # Every commands (except question-marked) also has a banged wrapper
  # <tt>command!</tt>, which calls an itself command and puts a short message
  # about its execution result
  class Base
    class << self
      def tag
        @tag ||= name.demodulize[/^(.+?)((?:god)?redis)?$/i, 1].underscore
      end
      
      protected
      def method_missing(method, proc = nil, *args, &block)
        if block_given? || proc.respond_to?(:to_proc)
          define_method method, &(block || proc)
        else
          super
        end
      end
    end
    
    # Default command mapping
    redis      { Redis.current }
    client     { redis.client }
    connected? { client.connected? }
    reconnect  { client.reconnect.connected? }
    quit       { redis.quit }
    
    def method_missing(method, *args, &block)
      if /^(?<action>.+[^\?])!$/ =~ method.to_s && respond_to?(action)
        say(action) { send action }
      else
        super
      end
    end
    
    delegate :tag, to: :class
    
    private
    def say(action, &block)
      result = _get_short_status_calling(&block)
      puts "Redis [#{tag}]: #{action}... #{result}"
    end
    
    def _get_short_status_calling(&block)
      result = begin; block.call rescue nil; end
      result == true ? '[OK]' : result || '[FAIL]'
    end
  end
end