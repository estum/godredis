# Godredis: bulk managing multiply Redis instances

Godredis gem provides unified interface for mass managing [Redis](http://redis.io) connections which could be initialized in different modules having each own custom API.

It is useful when you need to close or reset connections on forking, for example, with [puma](http://github.com/puma/puma) server in the `on_restart` block:

    on_restart do
      # Rails.cache.instance_variable_get('@data').quit
      # Redis::Objects.redis.quit
      # Sidekiq.redis(&:quit)
      Godredis.quit_all!  # instead of commented lines above
    end

## Installation

Add this line to your application's Gemfile:

    gem 'godredis'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install godredis

## Usage

There are several ways to call bulk commands with Godredis:

    # Godredis.command_all! -- will output command execution result
    Godredis.reconnect_all! # => Redis [cache_store]: reconnect... [OK]
                            # => Redis [objects]: reconnect... [OK]
                            # => Redis [sidekiq]: reconnect... [OK]
    
    # Godredis.command_all -- silent
    Godredis.quit_all
    
    # Just different syntax
    Godredis.redises(&:quit) 
    Godredis.redises(&:quit!)
    
    # It's also return an enumerator, so you can do something like this:
    Godredis.redises.map(&:connected?)

Subclass `Godredis::Base` class to collect Redis-related objects and use simple DSL to set mapping for the common methods such as `quit` or `reconnect` if they are different from the defaults.

    class CacheStoreGodredis < Godredis::Base
      redis ->{ Rails.cache.instance_variable_get('@data') }
    end
    
    class ObjectsGodredis < Godredis::Base
      redis ->{ Redis::Objects.redis }
    end
    
    class SidekiqGodredis < Godredis::Base
      # define mappings with blocks or lambdas
      redis  ->(&block){ Sidekiq.redis &block }
      client { redis &:client }
      quit   { redis &:quit }
    end

Default mapping:

    redis      { Redis.current }
    client     { redis.client }
    connected? { client.connected? }
    reconnect  { client.reconnect.connected? }
    quit       { redis.quit }

You may also add custom commands:

    class SomeGodredis < Godredis::Base
      del_some_key { redis.del('some_key') }
    end
    
    Godredis.redises(&:del_some_key!)
    # etc...

Every commands (except question-marked) also has a banged wrapper `command!`, which calls an itself command and puts a short message about its execution result.

## Contributing

1. Fork it ( https://github.com/[my-github-username]/godredis/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
