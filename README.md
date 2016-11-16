# Logger Backends JSON [![Build Status](https://travis-ci.org/driv3r/logger_backends_json.svg?branch=master)](https://travis-ci.org/driv3r/logger_backends_json)

Yet another (but flexible) JSON backend for Logger. Pick whatever json encoder you want (poison, json, exjsx) or provide your own.

## Roadmap

- [x] Basic functionallity, dumb IO usage, configuration and using given parsing lib.
- [ ] Improve documentation on hex docs.
- [ ] Buffered & async sending messages to IO `:user` process.
- [ ] Filtering of messages via configured function in addition to log levels.
- [ ] Adding examples of custom json encoders.
- [ ] Additional switchable IO backends, i.e. TCP, UDP, File

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed as:

  1. Add `logger_backends_json` to your list of dependencies in `mix.exs`:

    ```elixir
    def deps do
      [
        # your json library of choice, otherwise you will need to provide custom module.
        {:poison, "~> 3.0"},
        {:logger_backends_json, "~> 0.1.0"}
      ]
    end
    ```

  2. Update your config

    ```elixir
    # A tuple with module and config name to use
    config :logger, backends: [{Logger.Backends.JSON, :json}]

    config :logger, :json,
      level: :info,
      metadata: %{foo: "bar"},
      encoder: Poison
    ```

## Extra configuration

```elixir
config :logger, :json,
  level: fn() ->
    (System.get_env("LOG_LEVEL") || "info") |> String.to_atom
  end,
  metadata: fn() ->
    [
      application: System.get_env("MY_APP_NAME"),
      env: System.get_env("APP_ENV")
    ]
  end,
  encoder: Poison
```

All possible options:

- `encoder` anything that implements `encode(object) :: map|list => {:ok, json}`, we test against `poison`, `exjsx` and `json` libs.
- `level` represents log level, same as in default `Logger` - `debug, info, warn, error`.
- `metadata` additional info to pass into json, should be `Map` in the end.

In any case you can also specify a function that will get evaluated on initialization.

If you need to pass any extra info on each log, i.e. some stuff from ETS tables or whatever, you can do it by creating custom encoder and adding it there.

## Frequent issues

  1. This backend doesn't install any dependencies - it doesn't come with any default JSON encoder - so when you try to assign `Poison` as encoder, but you didn't installed it you will get a message like

    ```elixir
    iex(1)>
    =INFO REPORT==== 16-Nov-2016::09:57:32 ===
        application: logger
        exited: shutdown
        type: temporary
    ```

    to solve it just install `:poison` (or any other json lib) by following their installation instructions, and everything should be back to good.

## Sources & inspiration

- [user process](http://ferd.ca/repl-a-bit-more-and-less-than-that.html) Erl shell workings and what is user process.
- [elixir#4720](https://github.com/elixir-lang/elixir/pull/4720) performance via calling user process directly.
- [elixir#4728](https://github.com/elixir-lang/elixir/pull/4728) performance via buffering IO and sending stuff async.
- various json loggers (i.e. `json_logger` and `logger_logstash_backend`)
