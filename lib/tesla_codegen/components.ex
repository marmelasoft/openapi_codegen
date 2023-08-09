defmodule TeslaCodegen.Components do
  @moduledoc """
  Component generation operations.
  """
  alias TeslaCodegen.Ast

  @doc """
  Generates components AST from OpenAPI spec using the `schemas` key.

  Returns the name of the component and the AST for said component.
  """
  @spec generate(String.t(), map()) ::
          list(%{component_module_name: String.t(), ast: Macro.t(), struct_elements: list(Atom.t())})
  def generate(client_module_name, %{"components" => %{"schemas" => schemas}}) do
    singular_components =
      schemas
      |> Enum.map(&generate_component(client_module_name, &1))
      |> Enum.reject(&is_nil/1)

    schemas
    |> Enum.map(&generate_item_component(client_module_name, &1, singular_components))
    |> Enum.reject(&is_nil/1)

    singular_components
  end

  defp generate_component(client_module_name, schema) do
    case schema do
      {key, %{"properties" => properties}} -> build_component_ast(client_module_name, key, properties)
      {key, %{"type" => _}} -> build_component_ast(client_module_name, key, %{key => ""})
      _ -> nil
    end
  end

  defp generate_item_component(_client_module_name, schema, _singular_components) do
    case schema do
      {_key, %{"allOf" => allOf}} -> IO.inspect(allOf, label: :all_of)
      {_key, %{"oneOf" => oneOf}} -> IO.inspect(oneOf, label: :one_of)
      {_key, %{"anyOf " => anyOf}} -> IO.inspect(anyOf, label: :any_of)
      _ -> nil
    end
  end

  defp build_component_ast(client_module_name, key, properties) do
    component_module_name =
      key
      |> Ast.sanitize_name(:camelize)
      |> then(&String.to_atom("Elixir.#{client_module_name}.#{&1}"))

    struct_elements =
      properties
      |> Map.keys()
      |> Enum.map(&Ast.sanitize_name/1)

    ast =
      quote do
        defmodule unquote(component_module_name) do
          @moduledoc unquote("Structure for #{key} component")
          @derive Jason.Encoder
          defstruct(unquote(struct_elements))
        end
      end

    %{ast: ast, component_module_name: component_module_name, struct_elements: struct_elements}
  end
end
