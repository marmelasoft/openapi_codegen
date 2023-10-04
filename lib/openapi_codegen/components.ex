defmodule OpenApiCodeGen.Components do
  @moduledoc """
  Component generation operations.
  """
  alias OpenApiCodeGen.Ast

  @doc """
  Generates components AST from OpenAPI spec using the `schemas` key.

  Returns the name of the component and the AST for said component.
  """
  @spec generate(String.t(), map()) :: list({String.t(), Macro.t()})
  def generate(client_module_name, %{"components" => %{"schemas" => schemas}}),
    do: schemas |> Enum.map(&generate_component(client_module_name, &1)) |> Enum.reject(&is_nil/1)

  defp generate_component(client_module_name, {key, %{"properties" => properties}}) do
    {key, build_component_ast(client_module_name, key, properties)}
  end

  defp generate_component(client_module_name, {key, %{"type" => _}}) do
    {key, build_component_ast(client_module_name, key, %{key => ""})}
  end

  defp generate_component(_, _), do: nil

  defp build_component_ast(client_module_name, key, properties) do
    component_module_name =
      key
      |> Ast.sanitize_name(:camelize)
      |> then(&String.to_atom("Elixir.#{client_module_name}.#{&1}"))

    quote do
      defmodule unquote(component_module_name) do
        @moduledoc unquote("Structure for #{key} component")
        @derive Jason.Encoder
        defstruct(
          unquote(
            properties
            |> Map.keys()
            |> Enum.map(&Ast.sanitize_name/1)
          )
        )
      end
    end
  end
end
