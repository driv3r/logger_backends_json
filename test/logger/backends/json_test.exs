defmodule Logger.Backends.JSONTest do
  use ExUnit.Case
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
    end) =~ "msg: \"foo\""
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

  test "dynamic config" do
    Logger.configure_backend @backend,
      metadata: fn -> %{bar: :baz} end,
      encoder:  fn -> Poison end,
      level:    fn -> :debug end

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


  defp capture_log(fun) do
    capture_io(:user, fn ->
      fun.()
      Logger.flush()
    end)
  end

  defp assert_correct_json({:ok, json}, line, funk) do
    assert json["msg"] == "foo"
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
