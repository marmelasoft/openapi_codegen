defmodule TeslaCodegen.FunctionAST do
  @moduledoc false

  @path_elements_pattern ~r/{([^}]*)}/

  def generate(name, {path, %{"get" => content}}), do: generate(name, path, content, :get)

  def generate(name, {path, %{"post" => content}}), do: generate(name, path, content, :post)

  def generate(name, {path, %{"put" => content}}), do: generate(name, path, content, :put)

  def generate(name, {path, %{"delete" => content}}), do: generate(name, path, content, :delete)

  def generate(name, path, %{"operationId" => func_name} = schema, method) do
    arguments =
      @path_elements_pattern
      |> Regex.scan(path)
      |> Enum.map(fn [_, arg] -> arg |> String.to_atom() |> Macro.var(name) end)

    request_body = generate_request_body_argument(name, schema)
    url_parameters = generate_url_parameters(name, schema)

    arguments =
      case request_body do
        nil -> arguments
        {_, ast} -> arguments ++ [ast]
      end

    arguments =
      case url_parameters do
        [] -> arguments
        url_parameters -> arguments ++ Enum.map(url_parameters, &elem(&1, 0))
      end

    path =
      case url_parameters do
        [] ->
          generate_path_interpolation(name, path)

        url_parameters ->
          path_params = Enum.flat_map(url_parameters, &elem(&1, 1))
          quote do: Tesla.build_url(unquote(generate_path_interpolation(name, path)), unquote(path_params))
      end

    build_request_function_ast(func_name, method, path, arguments, request_body)
  end

  defp build_request_function_ast(func_name, method, path, arguments, request_body) do
    quote do
      def unquote(:"#{Macro.underscore(func_name)}")(unquote_splicing(arguments)) do
        unquote(
          cond do
            method == :get ->
              quote do: get(unquote(path))

            method == :post and is_nil(request_body) ->
              quote do: post(unquote(path))

            method == :post ->
              quote do: post(unquote(path), unquote(elem(request_body, 0)))

            method == :put ->
              quote do: put(unquote(path))

            method == :delete ->
              quote do: delete(unquote(path))

            true ->
              raise "Unknown method #{method}"
          end
        )
      end
    end
  end

  defp generate_request_body_argument(name, %{
         "requestBody" => %{"content" => %{"application/json" => %{"schema" => %{"$ref" => ref}}}}
       }) do
    ref_to_var_ast(name, ref, :single)
  end

  defp generate_request_body_argument(name, %{
         "requestBody" => %{"content" => %{"application/json" => %{"schema" => %{"items" => %{"$ref" => ref}}}}}
       }) do
    ref_to_var_ast(name, ref, :array)
  end

  defp generate_request_body_argument(name, %{"requestBody" => _}) do
    var = Macro.var(:body, name)
    {var, quote(do: unquote(var))}
  end

  defp generate_request_body_argument(_, _), do: nil

  defp ref_to_var_ast(name, ref, type) do
    ref
    |> String.split("/")
    |> Enum.take(-1)
    |> hd()
    |> then(&String.to_atom("#{name}.#{&1}"))
    |> then(fn module ->
      var =
        module
        |> Atom.to_string()
        |> String.split(".")
        |> Enum.take(-1)
        |> hd()
        |> then(
          &case type do
            :array -> "#{&1}s"
            _ -> &1
          end
        )
        |> String.downcase()
        |> String.to_atom()
        |> Macro.var(name)

      ast =
        case type do
          :single -> quote do: %unquote(module){} = unquote(var)
          _ -> quote do: unquote(var)
        end

      {var, ast}
    end)
  end

  defp generate_url_parameters(name, %{"parameters" => parameters}) do
    Enum.flat_map(parameters, &generate_url_parameter(name, &1))
  end

  defp generate_url_parameters(_, _), do: []

  defp generate_url_parameter(name, %{"in" => "query"} = parameter), do: parameter_to_ast(name, parameter)

  defp generate_url_parameter(_, _), do: []

  defp parameter_to_ast(name, parameter) do
    var_name =
      parameter
      |> Map.get("name")
      |> Macro.underscore()
      |> String.to_atom()

    var = Macro.var(var_name, name)

    [{var, quote(do: [{unquote(var_name), unquote(var)}])}]
  end

  defp generate_path_interpolation(name, path) do
    @path_elements_pattern
    |> Regex.split(path, include_captures: true)
    |> Enum.reject(&(&1 == ""))
    |> Enum.map(fn path ->
      case Regex.run(@path_elements_pattern, path) do
        [_, path] ->
          path
          |> String.to_atom()
          |> Macro.var(name)
          |> then(&quote(do: :"Elixir.Kernel".to_string(unquote(&1)) :: binary))

        _ ->
          quote(do: unquote(path))
      end
    end)
    |> then(&{:<<>>, [], &1})
  end
end
