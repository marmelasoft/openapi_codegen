defmodule TeslaCodegen.Ast do
  @moduledoc """
  AST operations.
  """

  @doc """
  Converts the AST into a string, formats it, styles it and writes it to a file and returns the path to the file.
  """
  @spec to_file!(Macro.t(), String.t(), Path.t()) :: Path.t()
  def to_file!(ast, key, path) do
    File.mkdir_p!(path)

    file_path = path |> Path.join("#{key}.ex") |> String.replace("-", "_")

    ast
    |> Macro.to_string()
    |> tap(&File.write!(file_path, &1))
    |> Code.format_string!()
    |> Enum.join()
    |> then(&Styler.format(&1, []))
    |> then(&File.write!(file_path, &1))

    file_path
  end

  @reserved_words ~w(do end else catch rescue after alias and or not when fn quote unquote unquote_splicing)
  @doc """
  Converts a string or atom into a variable.

  ## Examples

      iex> to_var(:my_var, __MODULE__)
      {:my_var, [], __MODULE__}

      iex> to_var("my_var", __MODULE__)
      {:my_var, [], __MODULE__}

      iex> to_var("myVar", __MODULE__)
      {:my_var, [], __MODULE__}
  """
  @spec to_var(binary() | atom(), atom()) :: Macro.t()
  def to_var(name, context) when is_atom(name) do
    name
    |> Atom.to_string()
    |> to_var(context)
  end

  def to_var(name, context) when is_binary(name) do
    name
    |> sanitize_name()
    |> Macro.var(context)
  end

  @doc """
  Converts a string or atom into a variable. It also checks for reserved words and appends `_param` to the variable name if it is a reserved word.
  """
  @spec sanitize_name(binary, :camelize | :underscore) :: atom
  def sanitize_name(name, transform \\ :underscore) do
    name =
      name
      |> String.replace(~r/\W/, "_")
      |> then(&String.replace(&1, ~r/^\d/, "Component\\0"))
      |> then(
        &case transform do
          :camelize -> Macro.camelize(&1)
          :underscore -> Macro.underscore(&1)
        end
      )

    @reserved_words
    |> Enum.find(&(&1 == name))
    |> then(fn
      nil ->
        name

      _ ->
        case transform do
          :camelize -> Macro.camelize("#{name}Param")
          :underscore -> Macro.underscore("#{name}_param")
        end
    end)
    |> String.to_atom()
  end
end
