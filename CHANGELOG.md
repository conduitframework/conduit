# Changelog

## Unreleased

## 0.12.10 (2019-03-25)

### Fixed

- Deprecation warning for `System.convert_time_unit/3` `:microsecond` instead of `:microseconds`
- Retry on nack would raise exception

## 0.12.9 (2018-11-16)

### Fixed

- Conduit.Plug.DeadLetter was using the deprecated form of publish.

## 0.12.8 (2018-10-27)

### Added

- Conduit.Plug.Wrap and Conduit.Plug.Unwrap. Useful for brokers without native support for headers.

## 0.12.7 (2018-10-23)

### Added

- Conduit.Util - commonly used functions for adapters

### Changed

- Adapters can now set the source of a message

## 0.12.6 (2018-09-09)

### Deprecates

- Broker.publish(:route, message) was changed to Broker.publish(message, :route) to help with pipelining. The old form is dreprecated.

### Fixes

- Various bugs in generator instructions
- Functions for dynamic to and from are no longer run at compile time (regression)

## 0.12.5 (2018-08-05)

### Fixes

- Error message said subscribe instead of publish.
- Raises error when duplicate routes are defined.

## 0.12.4 (2018-07-27)

### Fixes

- Fix Elixir 1.7.0 warnings

## 0.12.3 (2018-07-14)

### Changed

- Switched from uuid, to elixir_uuid to prevent conflict with uuid_erl, which uses also used uuid as it's app name and is commonly used in erlang packages.

## 0.12.2 (2018-06-25)

### Fixes

- Regression where plugs were executed in reverse order.

## 0.12.1 (2018-06-02)

### Fixes

- Regression where `Conduit.Plug.MessageActions` were no longer available in `Broker` for plugs.

## 0.12.0 (2018-05-28)

### Added

- Message ID plug
- Improved error message when publishing to a route that doesn't exist
- Improved error message when receiving from a route that doesn't exist

### Changed

- Stop generating modules namespaced under broker for pipelines, config, subscribers, and publishers.
- Test helpers now expect a route name

## 0.11.0 (2018-04-11)

### Added

- Added child specs to suport `Supervisor.init/1`

### Fixed

- Subscriber gets passed opts specified in broker

### Changed

- Adapter publish callback now accepts broker. Necessary for adapters to namespace processes to allow multiple instances of an adapter to run. Upgrading to this version requires an upgrade to the adapter.

## 0.10.8 (2018-03-05)

- No notable changes

## 0.10.7 (2018-02-28)

### Added

- Formatter exports for Broker DSL and test macros. (Add `import_deps: [:conduit]` to your `.formatter.exs` file)

## 0.10.6 (2018-02-28)

- No notable changes

## 0.10.5 (2018-02-20)

### Changed

- Switched from Poison to Jason for `application/json` content type

## 0.10.4 (2018-02-02)

### Fixed

- Subscriber generator no longer generates wrong method name @doughsay
- Fixed fallback for generator config @doughsay

## 0.10.3 (2018-01-16)

### Fixed

- Extra opts passed to content type `application/x-erlang-binary` are ignored

## 0.10.2 (2018-01-01)

### Added

- Allow function to be passed for name of queue and exchange (useful for per app instance queues)

## 0.10.1 (2018-01-01)

### Added

- `application/x-erlang-binary` content type

## 0.10.0 (2017-12-31)

### Changed

- Support 0.9.0 feature, with API for new content types and encodings from pre-0.9.0

## 0.9.0 (2017-12-31)

### Added

- Allow content type and encoding to be stored in other parts of message. Useful for multiple encodings (e.g. encrypted and compressed)

## 0.8.3 (2017-11-08)

### Added

- Generators for Brokers and Subscribers

## 0.8.2 (2017-08-27)

### Added

- Support for dynamic destination for messages

## 0.8.1 (2017-03-02)

### Added

- Improved logging when errors occur

## 0.8.0 (2017-02-21)

### Changed

- Adapter callback accepts new config argument

## 0.7.2 (2017-01-12)

### Changed

- Fixed all elixir deprecations
- Added more docs

## 0.7.1 (2017-01-03)

### Added

- Support short hand functions for options argument for all plugs (e.g. `&foo(&1)`)

## 0.7.0 (2017-01-01)

### Added

- Support function for the options argument of all plugs
- AckException and NackException plugs
- Test assertions and test adapter

## 0.6.2 (2016-12-14)

### Changed

- Loosened Poison version dependency

## 0.6.1 (2016-12-14)

### Changed

- Improved docs

## 0.6.0 (2016-12-12)

### Changed

- Improved errors
- Dead letter plug adds exception as header
- Small improvements for message action plugs

## 0.5.0 (2016-12-05)

### Added

- Lots of functions for working with message attributes
- Added dead letter plug
- Added message action plugs for most of the operations available to modify message attributes
- Added retry plug

### Changed

- Plug system changed from `Enum.reduce(plugs, message, fn plug, message -> plug.(message))` to being passed the next plug to control if it's called and handle any errors
- Changed callbacks for Subscribers to work with plug system changes

## 0.4.0 (2016-11-27)

### Added

- Functions for working with headers

### Changed

- Message headers became map with string keys

## 0.3.0 (2016-11-27)

### Added

- Added parse and format plugs with system to extend with custom content types
- Added encode and decode plugs with system to extend with custom encodings
- Added created_at plug to add timestamp to message
- Added created_by plug to annotate message with application
- Added a lot of docs around new plugs

### Changed

- Conduit.Message top level attributes

## 0.2.1 (2016-11-20)

- No notable changes

## 0.2.0 (2016-11-20)

- No notable changes

## 0.1.1 (2016-11-20)

- No notable changes

## 0.1.0 (2016-11-20)

- Initial version
