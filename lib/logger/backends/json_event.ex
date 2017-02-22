defmodule Logger.Backends.JSON.Event do
  @moduledoc """
  Event is responsible for allowing and building given messages. It's a separate module so it's easy to switch it with your custom one.
  """

  defstruct [:level, :message, :timestamp, :metadata, :context]

  @doc """
  Builds map from the `event` message, it's later on used as input for json.

  `event` is a struct of `Logger.Backends.JSON.Event`.

  Returns a builded `map`.
  """
  def build(%__MODULE__{} = event) do
    %{level: event.level}
    |> Map.put(:message, normalize_message(event.message))
    |> Map.put(:timestamp, normalize_timestamp(event.timestamp))
    |> Map.merge(event.metadata)
    |> Map.merge(Enum.into(event.context, %{}))
    |> Map.put(:pid, event.context[:pid] |> inspect)
  end

  @doc """
  Decides whenever we should proceed with evaluating the log entry. One more layer besides regular log level option.

  `_event` is a struct of `Logger.Backends.JSON.Event`.

  Returns `true|false`.
  """
  def allow?(%__MODULE__{} = _event) do
    true
  end

  defp normalize_timestamp({date, {h, min, sec, ms}}) do
    {date, {h, min, sec}}
    |> NaiveDateTime.from_erl!({ms * 1000, 6})
    |> NaiveDateTime.to_iso8601
  end

  defp normalize_message(txt) when is_list(txt), do: to_string(txt)
  defp normalize_message(txt) when is_bitstring(txt), do: txt
  defp normalize_message(_), do: "unsupported message type"
end
