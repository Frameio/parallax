defmodule Parallax.MixProject do
  use Mix.Project

  @version "1.0.0"

  def project do
    [
      app: :parallax,
      version: @version,
      elixir: "~> 1.7",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      package: package(),
      description: description()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:ex_doc, ">= 0.0.0", only: :dev}
    ]
  end

  defp description do
    """
    Simple parallel task orchestration for elixir
    """
  end

  defp package do
    [
      licenses: ["MIT"],
      maintainers: ["Michael Guarino"],
      links: %{"GitHub" => "https://github.com/Frameio/parallax"}
    ]
  end
end
