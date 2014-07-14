# Summer

Summer is an IRC Bot "framework" "inspired" by [http://github.com/RISCFuture/autumn](Autumn). Its goal is to be tiny.

## Installation

The project is currently in "preview" state 'cause that's all the rage nowadays. No there's no invites, BUT everybody gets access to it.
Sorry to inform you that you'll have to clone it and then run `rake install` if you want to use it.

## Usage

To use summer, create a file like this:

    require 'rubygems'
    require 'summer'

    class Bot < Summer::Connection

    end

    Bot.new("localhost")

Running it will make your bot attempt to connect to the server on localhost. For those of you who do not have an IRC server running locally, I would suggest trying irc.freenode.net instead. 
    
## Configuration

In the same directory create a directory called _config_ and in that put _summer.yml_ which can have the following keys:

* nick: The nickname of the bot.
* channel: A channel to join on startup.
* channels: Channels to join on startup.
* auto_rejoin: Set this to true if you want the bot to re-join any channel it's kicked from.
* nickserv_password: Password to send to nickserv after connection but before joining any channels

## `did_start_up`

Called when the bot has received the final MOTD line (376 or 422) and has finished joining all the channels.

## `channel_message(sender, channel, message)`

Called when the bot receives a channel message.

* sender (`Hash`): Contains `nick` and `hostname`
* channel (`String`): The channel name: e.g. "#logga"
* message (`String`): The message that was received

## `private_message(sender, bot, message)`

Called when the bot receives a private message.

* sender (`Hash`): Contains `nick` and `hostname`
* bot (`String`): The bot's name.
* message (`String`): The message that was received

## `join(sender, channel)`

Called when the bot sees someone join a channel.

* sender (`Hash`): Contains `nick` and `hostname`
* channel (`String`): The channel name: e.g. "#logga"

## `part(sender, channel, message)`

Called when someone parts a channel.

* sender (`Hash`): Contains `nick` and `hostname`
* channel (`String`): The channel name: e.g. "#logga"
* message (`String`): The message that was received

## `quit(sender, message)`

Called when someone quits the server.

* sender (`Hash`): Contains `nick` and `hostname`
* message (`String`): The message that was received.

## `kick(kicker, channel, victim, message)`

Called when someone is kicked from a channel.

* kicker (`Hash`): Contains `nick` and `hostname`
* channel (`String`): The channel name: e.g. "#logga"
* victim (`String`): Just the nick of whoever was kicked.
* message (`String`): The message that was received.


## Handling raw messages

If you wish to handle raw messages that come into your bot you can define a `handle_xxx` method for that where `xxx` is the three-digit representation of the raw you wish to handle.

