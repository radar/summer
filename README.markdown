# Summer

Summer is an IRC Bot "framework" "inspired" by [http://github.com/RISCFuture/autumn](Autumn). Its goal is to be tiny.

## Installation

You need to have gemcutter.org in your sources.

Installation is as simple as:

    sudo gem install summer
    
Or you could clone the project and run `rake install`

## Usage

To use summer, create a file like this:

    require 'rubygems'
    require 'summer'
    
    class Bot < Summer::Connection
    
    end
    
    Bot.new("localhost")
    
And in the same directory create a directory called _config_ and in that put _summer.yml_ which can have the following keys:

* nick: The nickname of the bot.
* channel: A channel to join on startup.
* channels: Channels to join on startup. 