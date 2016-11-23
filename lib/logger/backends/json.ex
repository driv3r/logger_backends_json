defmodule Logger.Backends.JSON do
  use GenEvent

  defstruct [name: :json, level: :info, metadata: [], encoder: Logger.Backends.JSON.DummyEncoder]

  def init({__MODULE__, name}) do
    {:ok, configure(name, [], %__MODULE__{})}
  end


  def handle_call({:configure, options}, state) do
    {:ok, :ok, configure(state.name, options, state)}
  end

  def handle_event({_level, gl, _event}, state) when node(gl) != node() do
    {:ok, state}
  end

  def handle_event({level, _gl, {Logger, msg, ts, md}}, %{level: min_level} = state) do
    if is_nil(min_level) or Logger.compare_levels(level, min_level) != :lt do
      IO.puts :user, event(level, normalize_message(msg), ts, md, state)
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

  defp event(lvl, txt, timestamp, metadata, %{metadata: extras, encoder: encoder}) do
    message =
      %{msg: txt, level: lvl}
      |> Map.put(:timestamp, normalize_timestamp(timestamp))
      |> Map.merge(extras)
      |> Map.merge(Enum.into(metadata, %{}))
      |> Map.put(:pid, metadata[:pid] |> inspect)

    {:ok, json} = encoder.encode(message)

    json
  end

  defp configure(name, options, state) do
    config =
      Application.get_env(:logger, name, [])
      |> Keyword.merge(options)

    encoder  = get_config config, :encoder, Logger.Backends.JSON.DummyEncoder
    level    = get_config(config, :level, :info) |> normalize_level
    metadata = get_config(config, :metadata, %{}) |> normalize_metadata

    %{state | name: name, level: level, encoder: encoder, metadata: metadata}
  end

  defp get_config(config, key, default) do
    config
    |> Keyword.get(key, default)
    |> ConfigExt.load!
  end

  defp normalize_metadata(md) when is_map(md), do: md
  defp normalize_metadata(md) when is_list(md), do: Enum.into(md, %{})
  defp normalize_metadata(md), do: %{metadata: inspect(md)}

  defp normalize_timestamp({date, {h, min, sec, ms}}) do
    {date, {h, min, sec}}
    |> NaiveDateTime.from_erl!({ms * 1000, 6})
    |> NaiveDateTime.to_iso8601
  end

  defp normalize_message(txt) when is_list(txt), do: inspect(txt)
  defp normalize_message(txt) when is_bitstring(txt), do: txt
  defp normalize_message(_), do: "unsupported message type"

  defp normalize_level(lvl) when is_bitstring(lvl), do: String.to_atom(lvl)
  defp normalize_level(lvl) when is_atom(lvl), do: lvl
  defp normalize_level(_), do: :info
end
