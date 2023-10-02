defmodule OpenApiCodegen do
  @moduledoc """
  Generates Tesla client from OpenAPI specification.
  """
  alias OpenApiCodegen.Ast
  alias OpenApiCodegen.Client.Req
  alias OpenApiCodegen.Client.Tesla
  alias OpenApiCodegen.Components

  @spec generate(Path.t(), binary(), :req | :tesla) :: %{schemas: list(Path.t()), client: Path.t()}
  def generate(path, spec, adapter) when is_binary(spec) do
    name =
      path
      |> Path.split()
      |> Enum.take(-1)
      |> hd()
      |> Macro.camelize()

    spec = Jason.decode!(spec)

    schemas = Components.generate(name, spec)

    client =
      case adapter do
        :req -> Req.generate(name, spec)
        :tesla -> Tesla.generate(name, spec)
      end

    client_file_path = Ast.to_file!(client, name, path)

    schema_file_paths =
      Enum.map(schemas, fn {component_name, ast} ->
        Ast.to_file!(ast, component_name, Path.join(path, "components"))
      end)

    %{schemas: schema_file_paths, client: client_file_path}
  end
end
