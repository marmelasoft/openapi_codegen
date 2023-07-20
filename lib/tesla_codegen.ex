defmodule TeslaCodegen do
  @moduledoc """
  Generates Tesla client from OpenAPI specification.
  """

  @doc """
  Generates files from OpenAPI specification and returns the paths for the generated files.
  """
  @spec generate(Path.t(), binary()) :: %{schemas: list(Path.t()), client: Path.t()}
  def generate(path, spec) when is_binary(spec) do
    name = path |> Path.split() |> Enum.take(-1) |> hd() |> Macro.camelize()
    spec = Jason.decode!(spec)
    %{schemas: generate_schemas(name, path, spec), client: generate_client(name, path, spec)}
  end

  # Generate Components
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
      defmodule unquote(String.to_atom("Elixir.#{name}.#{key}")) do
        @moduledoc unquote("Structure for #{key} component")
        defstruct(unquote(properties |> Map.keys() |> Enum.map(&Macro.underscore/1) |> Enum.map(&String.to_atom/1)))
      end
    end
  end

  # Generate Client
  defp generate_client(name, path, %{"paths" => paths, "servers" => [%{"url" => server} | _]}) do
    name
    |> build_client_ast(paths, server)
    |> write_ast_to_file!(name, path)
  end

  defp build_client_ast(name, paths, server) do
    name = String.to_atom("Elixir.#{name}")

    quote do
      defmodule unquote(name) do
        use Tesla

        plug(Tesla.Middleware.BaseUrl, unquote(server))

        unquote_splicing(generate_functions_ast(name, paths))
      end
    end
  end

  defp generate_functions_ast(name, paths), do: Enum.map(paths, &generate_function_ast(name, &1))

  defp generate_function_ast(name, {path, %{"get" => content}}), do: generate_function_ast(name, path, content, :get)

  defp generate_function_ast(name, {path, %{"post" => content}}), do: generate_function_ast(name, path, content, :post)

  defp generate_function_ast(name, {path, %{"put" => content}}), do: generate_function_ast(name, path, content, :put)

  defp generate_function_ast(name, {path, %{"delete" => content}}),
    do: generate_function_ast(name, path, content, :delete)

  defp generate_function_ast(name, path, %{"operationId" => func_name}, method) do
    pattern = ~r/{([^}]*)}/

    arguments =
      pattern
      |> Regex.scan(path)
      |> Enum.map(fn [_, arg] -> arg |> String.to_atom() |> Macro.var(name) end)

    path =
      pattern
      |> Regex.split(path, include_captures: true)
      |> Enum.reject(&(&1 == ""))
      |> Enum.map(fn path ->
        case Regex.run(~r/^{([^}]*)}$/, path) do
          [_, path] -> path |> String.to_atom() |> Macro.var(name)
          _ -> path
        end
      end)
      |> then(&quote do: Enum.join(unquote(&1)))

    quote do
      def unquote(:"#{Macro.underscore(func_name)}")(unquote_splicing(arguments)) do
        unquote(
          case method do
            :get -> quote do: get(unquote(path))
            :post -> quote do: post(unquote(path))
            :put -> quote do: put(unquote(path))
            :delete -> quote do: delete(unquote(path))
          end
        )
      end
    end
  end

  defp write_ast_to_file!(ast, key, path) do
    File.mkdir_p!(path)

    file_path = Path.join(path, "#{key}.ex")

    ast
    |> Macro.to_string()
    |> Code.format_string!()
    |> Enum.join()
    |> then(&Styler.format(&1, []))
    |> then(&File.write!(file_path, &1))

    file_path
  end
end
