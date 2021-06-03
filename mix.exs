defmodule RandomColour.MixProject do
  use Mix.Project

  @source_url "https://github.com/chungwong/random_colour"

  def project do
    [
      app: :random_colour,
      version: "0.1.0",
      elixir: "~> 1.6",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      docs: docs(),
      package: package()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:ex_doc, ">= 0.0.0", only: :dev, runtime: false}
    ]
  end

  defp docs do
    [
      extras: [
        "README.md"
      ],
      main: "readme",
      source_url: @source_url
    ]
  end

  defp package do
    [
      description: "A tool for generating random colours",
      maintainers: ["Chung WONG"],
      links: %{
        "GitHub" => @source_url
      },
      licenses: ["MIT"]
    ]
  end
end
