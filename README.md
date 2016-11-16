# Logger Backends JSON

Yet another (but flexible) JSON backend for Logger. Pick whatever json encoder you want (poison, json, exjsx) or provide your own.

## Roadmap

- [x] Basic functionallity, dumb IO usage, configuration and using given parsing lib.
- [ ] Improve documentation on hex docs.
- [ ] Buffered & async sending messages to IO `[:user](http://ferd.ca/repl-a-bit-more-and-less-than-that.html)` process.
- [ ] Filtering of messages via configured function in addition to log levels.
- [ ] Adding examples of custom json encoders.

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed as:

  1. Add `logger_backends_json` to your list of dependencies in `mix.exs`:

    ```elixir
    def deps do
      [{:logger_backends_json, "~> 0.1.0"}]
    end
    ```

  2. Ensure `logger_backends_json` is started before your application:

    ```elixir
    def application do
      [applications: [:logger_backends_json]]
    end
    ```

## Configuration

```elixir
# A tuple with module and config name to use
config :logger, backends: [{Logger.Backends.JSON, :json}]

config :logger, :json,
  level: :info,
  metadata: %{application: "YourApp", env: "staging"},
  encoder: Poison
```

Or a bit more dynamic like

```elixir
config :logger, :json,
  level: fn() ->
    System.get_env("LOG_LEVEL") || "info"
  end,
  metadata: fn() -> [
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
