defmodule IDeviceDb.MixProject do
  use Mix.Project

  def project do
    [
      app: :idevice_db,
      descriptios: "A database of Apple devices",
      version: version(),
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
      {:jason, "~> 1.4"}
    ]
  end

  defp aliases do
    [
      compile: ["format --check-formatted", "compile --warnings-as-errors"]
    ]
  end

  defp docs do
    [
      main: "readme",
      source_url: "https://github.com/ausimian/idevice_db",
      source_ref: "#{version()}",
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
        "GitHub" => "https://github.com/ausimian/idevice_db/tree/#{version()}"
      }
    ]
  end

  defp version do
    version_from_pkg() || version_from_github() || version_from_git() || "0.0.0"
  end

  defp version_from_github do
    if System.get_env("GITHUB_REF_TYPE") == "tag" do
      System.get_env("GITHUB_REF_NAME")
    end
  end

  defp version_from_pkg do
    if File.exists?("./hex_metadata.config") do
      {:ok, info} = :file.consult("./hex_metadata.config")
      Map.new(info)["version"]
    end
  end

  defp version_from_git do
    case System.cmd("git", ["describe", "--dirty"], stderr_to_stdout: true) do
      {version, 0} -> String.trim(version)
      _ -> nil
    end
  end
end
