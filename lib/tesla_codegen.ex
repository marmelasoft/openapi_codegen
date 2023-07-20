defmodule TeslaCodegen do
  @moduledoc false
  @doc """
  Generates files from OpenAPI specification and returns the paths for the generated files.
  """
  @spec generate(atom(), Path.t(), binary()) :: %{schemas: list(Path.t())}
  def generate(name, path, spec) when is_binary(spec) do
    spec = Jason.decode!(spec)
    %{schemas: generate_schemas(name, path, spec)}
  end

  defp generate_schemas(name, path, %{"components" => %{"schemas" => schemas}}) do
    Enum.map(schemas, &generate_component(name, path, &1))
  end

  defp generate_component(name, path, {key, %{"properties" => properties}}) do
    name
    |> build_component_ast(key, properties)
    |> write_ast_to_file!(key, Path.join(path, "components"))
  end

  defp build_component_ast(name, key, properties) do
    quote do
      defmodule unquote(:"#{name}.#{key}") do
        @moduledoc unquote("Structure for #{key} component")
        defstruct(unquote(properties |> Map.keys() |> Enum.map(&Macro.underscore/1) |> Enum.map(&String.to_atom/1)))
      end
    end
  end

  defp write_ast_to_file!(ast, key, path) do
    File.mkdir_p!(path)

    file_path = Path.join(path, "#{key}.ex")

    ast
    |> Macro.to_string()
    |> Code.format_string!()
    |> then(&File.write!(file_path, &1))

    file_path
  end
end
