defmodule TeslaCodegen.Components do
  @moduledoc """
  Component generation operations
  """

  @doc """
  Generates components AST from OpenAPI spec using the `schemas` key

  Returns the name of the component and the AST for said component
  """
  @spec generate(String.t(), map()) :: list({String.t(), Macro.t()})
  def generate(name, %{"components" => %{"schemas" => schemas}}), do: Enum.map(schemas, &generate_component(name, &1))

  defp generate_component(name, {key, %{"properties" => properties}}) do
    {key, build_component_ast(name, key, properties)}
  end

  defp build_component_ast(name, key, properties) do
    quote do
      defmodule unquote(String.to_atom("Elixir.#{name}.#{key}")) do
        @moduledoc unquote("Structure for #{key} component")
        @derive Jason.Encoder
        defstruct(
          unquote(
            properties
            |> Map.keys()
            |> Enum.map(&Macro.underscore/1)
            |> Enum.map(&String.to_atom/1)
          )
        )
      end
    end
  end
end
