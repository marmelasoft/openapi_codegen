defmodule TeslaCodegen do
  @moduledoc """
  Generates Tesla client from OpenAPI specification.
  """
  alias TeslaCodegen.Ast
  alias TeslaCodegen.Client
  alias TeslaCodegen.Components

  @spec generate(Path.t(), binary()) :: %{schemas: list(Path.t()), client: Path.t()}
  def generate(path, spec) when is_binary(spec) do
    name =
      path
      |> Path.split()
      |> Enum.take(-1)
      |> hd()
      |> Macro.camelize()

    spec = Jason.decode!(spec)

    schemas = Components.generate(name, spec)
    client = Client.generate(name, spec)

    client_file_path = Ast.ast_to_file!(client, name, path)

    schema_file_paths =
      Enum.map(schemas, fn {component_name, ast} ->
        Ast.ast_to_file!(ast, component_name, Path.join(path, "components"))
      end)

    %{schemas: schema_file_paths, client: client_file_path}
  end
end
