defmodule Logger.Backends.JSON.Mixfile do
  use Mix.Project

  def project do
    [app: :logger_backends_json,
     version: "0.3.2",
     elixir: "~> 1.3",
     description: description(),
     package: package(),
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps()]
  end

  # Configuration for the OTP application
  #
  # Type "mix help compile.app" for more information
  def application do
    [applications: [:logger]]
  end

  # Dependencies can be Hex packages:
  #
  #   {:mydep, "~> 0.3.0"}
  #
  # Or git/path repositories:
  #
  #   {:mydep, git: "https://github.com/elixir-lang/mydep.git", tag: "0.1.0"}
  #
  # Type "mix help deps" for more examples and options
  defp deps do
    [
      {:config_ext, "~> 0.3.0"},
      {:poison, "~> 3.0", only: :test},
      {:json, "~> 1.0", only: :test},
      {:exjsx, "~> 3.2.1", only: :test},
      {:ex_doc, ">= 0.0.0", only: :dev}
    ]
  end

  defp description do
    """
    Yet another (but flexible) JSON backend for Logger. Pick whatever json encoder you want (poison, json, exjsx) or provide your own.
    """
  end

  defp package do
    [
      name: :logger_backends_json,
      files: ["lib", "mix.exs", "README.md", "LICENSE.md", "CHANGELOG.md"],
      maintainers: ["Leszek Zalewski"],
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/driv3r/logger_backends_json"}
    ]
  end
end
