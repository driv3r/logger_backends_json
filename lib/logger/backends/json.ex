defmodule Logger.Backends.JSON do
  use GenEvent

  defstruct [
    name: :json, level: :info, metadata: %{}, encoder: Logger.Backends.JSON.DummyEncoder,
    event: Logger.Backends.JSON.Event
  ]

  alias Logger.Backends.JSON.Event

  def init({__MODULE__, name}) do
    {:ok, configure(name, [], %__MODULE__{})}
  end


  def handle_call({:configure, options}, state) do
    {:ok, :ok, configure(state.name, options, state)}
  end

  def handle_event({_level, gl, _event}, state) when node(gl) != node() do
    {:ok, state}
  end

  def handle_event({level, _gl, {Logger, msg, ts, ctx}}, %__MODULE__{} = state) do
    %{level: min_level, event: event, metadata: metadata} = state

    if enabled?(level, min_level)  do
      message = %Event{
        message:   msg,
        level:     level,
        timestamp: ts,
        metadata:  metadata,
        context:   ctx
      }

      if event.allow?(message) do
        IO.puts :user, encode(message, state)
      end
    end

    {:ok, state}
  end

  def handle_event(_, state) do
    {:ok, state}
  end

  def handle_info(_, state) do
    {:ok, state}
  end

  ### Helpers

  defp enabled?(level, min_level) do
    Logger.compare_levels(level, min_level) != :lt
  end

  defp encode(message, %__MODULE__{encoder: encoder, event: event}) do
    {:ok, json} =
      message
      |> event.build
      |> encoder.encode

    json
  end

  defp configure(name, options, state) do
    config =
      Application.get_env(:logger, name, [])
      |> Keyword.merge(options)

    encoder  = get_config config, :encoder, Logger.Backends.JSON.DummyEncoder
    event    = get_config config, :event, Event
    level    = get_config(config, :level, :info) |> normalize_level
    metadata = get_config(config, :metadata, %{}) |> normalize_metadata

    %{state | name: name, level: level, encoder: encoder, event: event, metadata: metadata}
  end

  defp get_config(config, key, default) do
    config
    |> Keyword.get(key, default)
    |> ConfigExt.load!(default)
  end

  defp normalize_metadata(md) when is_map(md), do: md
  defp normalize_metadata(md) when is_list(md), do: Enum.into(md, %{})
  defp normalize_metadata(md), do: %{metadata: inspect(md)}

  defp normalize_level(lvl) when is_bitstring(lvl), do: String.to_atom(lvl)
  defp normalize_level(lvl) when is_atom(lvl), do: lvl
  defp normalize_level(_), do: :info
end
