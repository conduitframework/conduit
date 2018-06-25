# Overview

Conduit is a message queue development framework written in Elixir which makes many of the [Enterprise Integration patterns](http://www.enterpriseintegrationpatterns.com/) simple to implement. Many of its components and concepts will seem familiar to those of us with experience with Phoenix's router, Plug, and Ecto's adapters.

Conduit encapsulates a lot of the complexity in dealing with message queues, allowing focus on sending and receiving messages. It provides tools to make it simple to
guarantee reliability, extend for your use case, and scale to processing millions of messages.

If you are already familiar with Elixir, great! If not, there are a number of places to learn. The [Elixir guides](https://elixir-lang.org/getting-started/introduction.html) and the [Elixir learning resources page](https://elixir-lang.org/learning.html) are two great places to start.

The aim of this introductory guide is to present a brief, high-level overview of Conduit, the parts that make it up, and the layers underneath that support it.

## Conduit

Conduit is made up of a number of distinct parts, each with its own purpose and role to play in building a messaging application. We will cover them all in depth throughout these guides, but here's a quick breakdown.

- [Broker](broker.html)
  - the place to configure your queues and other aspects of your message queue broker
  - define all outgoing messages
  - define all incoming messages and which subscriber to route them to
  - define pipelines to process messages on their way in and out
- [Subscribers](subscribers.html)
  - typically, the final step in processing a message
  - acks or nacks the message
- [Plugs](plugs.html)
  - a processing step for incoming or outgoing messages
  - for example:
    - logging
    - add metadata
    - format/parse body
    - error handling
- [Adapters](adapters.html)
  - sets up queues and other aspects of your message queue broker
  - responsible for sending and receiving messages
  - manages resources and connections to your message queue
- [Content Types & Encodings](content-types-and-encodings.html)
  - serialize and deserialize message bodies

## A Note about these guides

If you find an issue with the guides or would like to help improve these guides please checkout the [Conduit Guides](https://github.com/conduitframework/conduit/tree/master/guides/) on github. Issues and Pull Requests are happily accepted!
