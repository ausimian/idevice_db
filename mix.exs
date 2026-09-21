defmodule IDeviceDb.MixProject do
  use Mix.Project

  @version "1.4.0"
  @source_url "https://github.com/ausimian/idevice_db"

  def project do
    [
      app: :idevice_db,
      description: "A database of Apple devices",
      version: System.get_env("VERSION_OVERRIDE", @version),
      elixir: "~> 1.15",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      aliases: aliases(),
      package: package(),
      docs: docs(),
      test_coverage: [ignore_modules: [Mix.Tasks.GenerateDb]]
    ]
  end

  def cli do
    [preferred_envs: [precommit: :test]]
  end

  defp elixirc_paths(:prod), do: ["lib/idevice_db.ex"]
  defp elixirc_paths(_), do: ["lib"]

  # Run "mix help compile.app" to learn about applications.
  def application do
    []
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:req, "~> 0.5", only: [:dev, :test], runtime: false},
      {:floki, "~> 0.37", only: [:dev, :test], runtime: false},
      {:ex_doc, "~> 0.36", only: :dev, runtime: false},
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:publisho, "~> 1.0", only: :dev, runtime: false},
      {:jason, "~> 1.4"}
    ]
  end

  defp aliases do
    [
      compile: ["format --check-formatted", "compile --warnings-as-errors"],
      precommit: [
        "compile --warnings-as-errors",
        "deps.unlock --unused",
        "format",
        "credo --strict",
        "test"
      ]
    ]
  end

  defp docs do
    [
      main: "readme",
      source_url: @source_url,
      source_ref: @version,
      extras: ["LICENSE.md", "CHANGELOG.md", "README.md"]
    ]
  end

  defp package do
    [
      licenses: ["MIT"],
      files: [
        "lib",
        "priv",
        "mix.exs",
        "README.md",
        "LICENSE.md",
        "CHANGELOG.md",
        ".formatter.exs"
      ],
      links: %{
        "GitHub" => "#{@source_url}/tree/#{@version}"
      }
    ]
  end
end
