# Conduit

[![CircleCI](https://img.shields.io/circleci/project/github/conduitframework/conduit.svg?style=flat-square)](https://circleci.com/gh/conduitframework/conduit)
[![Coveralls](https://img.shields.io/coveralls/conduitframework/conduit.svg?style=flat-square)](https://coveralls.io/github/conduitframework/conduit)
[![Hex.pm](https://img.shields.io/hexpm/v/conduit.svg?style=flat-square)](https://hex.pm/packages/conduit)
[![Hex.pm](https://img.shields.io/hexpm/l/conduit.svg?style=flat-square)](https://github.com/conduitframework/conduit/blob/master/LICENSE.md)
[![Hex.pm](https://img.shields.io/hexpm/dt/conduit.svg?style=flat-square)](https://hex.pm/packages/conduit)

A message queue framework, with support for middleware and multiple adapters.

Check out [this slide deck](http://slides.com/blatyo/deck-12#/) for more info.

## Installation

The package can be installed as:

  1. Add `conduit` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [{:conduit, "~> 0.12"}]
end
```

  2. If you are explicitly stating which applications to start, ensure `conduit`
     is started before your application:

```elixir
def application do
  [applications: [:conduit]]
end
```

## Getting Started

Once conduit is added to your project, you can generate a broker. For example:

``` bash
mix conduit.gen.broker --adapter amqp
mix conduit.gen.broker --adapter sqs
```

The Broker is responsible for describing how to setup your
message queue routing, defining subscribers, publishers, and
pipelines for subscribers and publishers.

See `mix help conduit.gen.broker` for all the options that are available. For
example, specifying the adapter to use.

## Officially Supported Adapters

  * AMQP 0-9-1 - [ConduitAMQP](https://hexdocs.pm/conduit_amqp/readme.html#configuring-the-adapter)
  * SQS - [ConduitSQS](https://hexdocs.pm/conduit_sqs/readme.html#configuring-the-adapter)

In the future more adapters will be supported.

## Configuring the Broker Topology

MQ's have queues which need to be setup and may involve other
concepts as well, including exchanges and bindings. Conduit
attemps to stay out of the way when you need to define these
things because each MQ has a different opinion on what you need.

Because of that, you'll need to looks at the specific adapter
for what options are available.

  * AMQP 0-9-1 - [Exchanges](https://hexdocs.pm/conduit_amqp/readme.html#configuring-exchanges) & [Queues](https://hexdocs.pm/conduit_amqp/readme.html#configuring-queues)
  * SQS - [Queues](https://hexdocs.pm/conduit_sqs/readme.html#configuring-queues)

## Configuring a Subscriber

A subscriber is responsible for processing messages from a message queue.
Typically, you'll have one subscriber per queue. You can generate a subscriber
by doing:

``` bash
mix conduit.gen.subscriber user_created
```

See `mix help conduit.gen.subscriber` for all the options that are available.

You can find more information about configuring your subscriber in the adapter
specific docs here:

  * AMQP 0-9-1 - [Subscribers](https://hexdocs.pm/conduit_amqp/readme.html#configuring-a-subscriber)
  * SQS - [Subscribers](https://hexdocs.pm/conduit_sqs/readme.html#configuring-a-subscriber)

## Configuring a Publisher

A publisher is responsible for sending messages. You can find more information
abount configuring publishers in the adapter specific docs here:

  * AMQP 0-9-1 - [Publishers](https://hexdocs.pm/conduit_amqp/readme.html#configuring-a-publisher)
  * SQS - [Publishers](https://hexdocs.pm/conduit_sqs/readme.html#configuring-a-publisher)
