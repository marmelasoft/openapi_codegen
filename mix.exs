defmodule TeslaCodegen.MixProject do
  use Mix.Project

  @app :openapi_codegen
  @version "0.1.0-pre"
  @description "OpenApiCodeGen is a Code Generation tool for Elixir"

  def project do
    [
      app: @app,
      version: @version,
      description: @description,
      elixir: "~> 1.15",
      start_permanent: Mix.env() == :prod,
      consolidate_protocols: Mix.env() != :test,
      escript: escript(),
      package: package(),
      docs: docs(),
      deps: deps(),
      aliases: aliases(),
      dialyzer: [plt_add_apps: [:ex_unit]],
      preferred_cli_env: [
        check: :test
      ]
    ]
  end

  def application do
    [extra_applications: [:logger]]
  end

  defp escript do
    [main_module: OpenApiCodeGen.CLI]
  end

  defp docs do
    [
      main: "readme",
      extras: [{:"README.md", [title: "Overview"]}],
      source_ref: "v#{@version}"
    ]
  end

  defp package do
    [
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/marmelasoft/openapi_codegen"}
    ]
  end

  defp deps do
    [
      {:tesla, "~> 1.7"},
      {:req, "~> 0.4.0"},
      # parsers
      {:jason, "~> 1.4"},

      # tools
      {:styler, "~> 0.8"},
      {:credo, "~> 1.7"},
      {:dialyxir, "~> 1.3", only: [:dev, :test], runtime: false},
      {:ex_doc, "~> 0.30", only: :dev, runtime: false}
    ]
  end

  defp aliases do
    [
      setup: ["deps.get"],
      "lint.credo": ["credo --strict --all"],
      "lint.dialyzer": ["dialyzer --format dialyxir"],
      lint: ["lint.dialyzer", "lint.credo"],
      check: [
        "clean",
        "deps.unlock --check-unused",
        "compile --warnings-as-errors",
        "format --check-formatted",
        "deps.unlock --check-unused",
        "test --warnings-as-errors",
        "lint"
      ]
    ]
  end
end
