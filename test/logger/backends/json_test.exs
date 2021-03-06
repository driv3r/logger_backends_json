defmodule Logger.Backends.JSONTest do
  use ExUnit.Case, async: false
  import ExUnit.CaptureIO
  require Logger
  require Poison
  require JSX

  doctest Logger.Backends.JSON

  @backend {Logger.Backends.JSON, :test_logger_backends_json}
  @dummy Logger.Backends.JSON.DummyEncoder

  setup do
    Logger.remove_backend :console
    Logger.add_backend(@backend)
    :ok
  end

  test "basic test" do
    assert capture_log(fn ->
      Logger.info("foo")
    end) =~ "message: \"foo\""
  end

  test "check poison" do
    Logger.configure_backend @backend, encoder: Poison

    capture_log(fn -> Logger.info("foo") end)
    |> Poison.decode
    |> assert_correct_json(28, "poison")
  after
    Logger.configure_backend @backend, encoder: @dummy
  end

  test "check exjsx" do
    Logger.configure_backend @backend, encoder: JSX

    capture_log(fn -> Logger.info("foo") end)
    |> JSX.decode
    |> assert_correct_json(38, "exjsx")
  after
    Logger.configure_backend @backend, encoder: @dummy
  end

  test "check json" do
    Logger.configure_backend @backend, encoder: JSON

    capture_log(fn -> Logger.info("foo") end)
    |> JSON.decode
    |> assert_correct_json(48, "json")
  after
    Logger.configure_backend @backend, encoder: @dummy
  end

  test "correct log level" do
    Logger.configure_backend @backend, level: :warn
    assert capture_log(fn -> Logger.info("foo") end) == ""
  after
    Logger.configure_backend @backend, level: :info
  end

  test "additional metadata: map" do
    Logger.configure_backend @backend, metadata: %{bar: :baz}, encoder: Poison
    {:ok, msg} = capture_log(fn -> Logger.info("foo") end) |> Poison.decode
    assert msg["bar"] == "baz"
  after
    Logger.configure_backend @backend, metadata: nil, encoder: @dummy
  end

  test "additional metadata: keyword list" do
    Logger.configure_backend @backend, metadata: [bar: :baz], encoder: Poison
    {:ok, msg} = capture_log(fn -> Logger.info("foo") end) |> Poison.decode
    assert msg["bar"] == "baz"
  after
    Logger.configure_backend @backend, metadata: nil, encoder: @dummy
  end

  test "additional metadata: other" do
    Logger.configure_backend @backend, metadata: Process.whereis(:user), encoder: Poison
    {:ok, msg} = capture_log(fn -> Logger.info("foo") end) |> Poison.decode
    assert msg["metadata"] =~ ~r{#PID<\d+\.\d+\.\d+>}
  after
    Logger.configure_backend @backend, metadata: nil, encoder: @dummy
  end

  def metadata, do: %{bar: :baz}
  def encoder, do: Poison
  def level, do: "debug"

  test "dynamic config" do
    Logger.configure_backend @backend,
      metadata: {:function, Logger.Backends.JSONTest, :metadata},
      encoder: {:function, Logger.Backends.JSONTest, :encoder},
      level: {:function, Logger.Backends.JSONTest, :level}

    {:ok, msg} = capture_log(fn -> Logger.debug("foo") end) |> Poison.decode
    assert msg["bar"] == "baz"
  after
    Logger.configure_backend @backend, metadata: nil, encoder: @dummy, level: :info
  end

  test "logger metadata" do
    Logger.configure_backend @backend, encoder: Poison
    {:ok, msg} = capture_log(fn -> Logger.info("foo", baz: :bar) end) |> Poison.decode
    assert msg["baz"] == "bar"
  after
    Logger.configure_backend @backend, metadata: nil, encoder: @dummy
  end

  test "logger sasl reports" do
    Logger.App.stop
    Application.put_env :logger, :handle_sasl_reports, true
    Application.put_env :logger, :test_logger_backends_json, level: :debug, encoder: Poison

    [msg | rest] =
      capture_log(fn ->
        Logger.App.start;
        :proc_lib.spawn fn -> raise RuntimeError, "Oops" end
        :timer.sleep 150
      end)
      |> String.split("\n")
      |> Enum.filter(fn(m) -> String.length(m) > 0 end)
      |> Enum.map(fn(m) ->
        {:ok, msg} = m |> String.trim |> Poison.decode
        msg
      end)

    assert msg["error_logger"] == "progress"
    assert msg["level"] == "info"
    assert msg["message"] =~ "Child Logger.ErrorHandler of Supervisor Logger.Supervisor started"

    [msg | rest] = rest

    assert msg["error_logger"] == "progress"
    assert msg["level"] == "info"
    assert msg["message"] =~ "Application logger started at "

    [msg] = rest

    assert msg["error_logger"] == "crash_report"
    assert msg["level"] == "error"
    assert msg["message"] =~ "** (RuntimeError) Oops"
  after
    Logger.App.stop
    Application.put_env :logger, :handle_sasl_reports, false
    Application.put_env :logger, :test_logger_backends_json, level: :info, encoder: Logger.Backends.JSON.DummyEncoder
    Logger.App.start
  end

  defp capture_log(fun) do
    capture_io(:user, fn ->
      fun.()
      Logger.flush()
    end)
  end

  defp assert_correct_json({:ok, json}, line, funk) do
    assert json["message"] == "foo"
    assert json["file"] =~ "test/logger/backends/json_test.exs"
    assert json["level"] == "info"
    assert json["function"] == "test check #{funk}/1"
    assert json["line"] == line
    assert json["module"] == "Elixir.Logger.Backends.JSONTest"
    assert json["pid"] =~ ~r{#PID<\d+\.\d+\.\d+>}
    date = DateTime.utc_now |> DateTime.to_date |> Date.to_iso8601
    assert json["timestamp"] =~ "#{date}"
  end

  defp assert_correct_json(_, _, _) do
    assert false
  end
end
