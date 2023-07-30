defmodule TeslaCodegen.Client do
  @moduledoc """
  Client generation operations
  """
  alias TeslaCodegen.Client.Path
  alias TeslaCodegen.Client.QueryParam
  alias TeslaCodegen.Client.RequestBody

  @path_elements_pattern ~r/{([^}]*)}/

  @doc """
  Generates client AST from OpenAPI spec using:
  * `servers` to generate Tesla middleware for the base URL
  * `operationId` for the name of the functions
  * `paths` keys to determine method for the function
  * `requestBody` to generate the request body argument
  * `path` to generate the request path with string interpolation
  * `parameters` to generate the URL parameters (if they are of type `query`)
  """
  @spec generate(String.t(), map()) :: Macro.t()
  def generate(name, %{"paths" => paths, "servers" => [%{"url" => server} | _]}),
    do: build_client_ast(name, paths, server)

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

  defp generate_functions_ast(name, paths), do: Enum.map(paths, &generate_function(name, &1))

  defp generate_function(name, {path, %{"get" => content}}), do: generate_function(name, path, content, :get)
  defp generate_function(name, {path, %{"post" => content}}), do: generate_function(name, path, content, :post)
  defp generate_function(name, {path, %{"put" => content}}), do: generate_function(name, path, content, :put)
  defp generate_function(name, {path, %{"delete" => content}}), do: generate_function(name, path, content, :delete)

  defp generate_function(name, path, %{"operationId" => func_name} = schema, method) do
    request_body_arguments = RequestBody.generate(name, schema)
    url_parameters = QueryParam.generate(name, schema)
    function_arguments = generate_function_arguments(name, path, request_body_arguments, url_parameters)
    request_path = Path.generate(name, path, url_parameters)

    build_request_function_ast(func_name, method, request_path, function_arguments, request_body_arguments)
  end

  defp generate_function_arguments(name, path, request_body_arguments, url_parameters) do
    @path_elements_pattern
    |> Regex.scan(path)
    |> Enum.map(fn [_, arg] -> arg |> String.to_atom() |> Macro.var(name) end)
    |> then(fn function_arguments ->
      case request_body_arguments do
        nil -> function_arguments
        {_, ast} -> function_arguments ++ [ast]
      end
    end)
    |> then(fn function_arguments ->
      case url_parameters do
        [] -> function_arguments
        url_parameters -> function_arguments ++ Enum.map(url_parameters, &elem(&1, 0))
      end
    end)
  end

  defp build_request_function_ast(func_name, method, request_path, function_arguments, request_body_arguments) do
    quote do
      def unquote(:"#{Macro.underscore(func_name)}")(unquote_splicing(function_arguments)) do
        url = unquote(request_path)

        unquote(
          cond do
            method == :get -> quote do: get(url)
            method == :post and is_nil(request_body_arguments) -> quote do: post(url)
            method == :post -> quote do: post(url, unquote(elem(request_body_arguments, 0)))
            method == :put -> quote do: put(url)
            method == :delete -> quote do: delete(url)
            true -> raise "Unknown method #{method}"
          end
        )
      end
    end
  end
end
