defmodule OpenApiCodeGen.CLI do
  @moduledoc false

  def usage do
    """
    Usage: openapi_codegen [options] INPUT_FILE

    Available options:

      --output-path    Output directory where the code should be generated.
      --req            To use the :req as HTTP client.
      --tesla          To use the :tesla as HTTP client.

    The --help and --version options can be given instead of a command for usage and versioning information.
    """
  end

  def main([arg]) when arg in ["--help", "-h"], do: display_help()
  def main([arg]) when arg in ["--version", "-v"], do: display_version()

  def main(argv) do
    {opts, [openapi_spec_path | _extra_args]} = args_to_options(argv)

    output_path = opts[:output_path]
    use_req? = opts[:req]

    if use_req? do
      OpenApiCodeGen.generate(output_path, File.read!(openapi_spec_path), :req)
    else
      OpenApiCodeGen.generate(output_path, File.read!(openapi_spec_path), :tesla)
    end
  end

  @switches [
    output_path: :string,
    req: :boolean,
    tesla: :boolean
  ]

  @aliases [
    o: :output_path
  ]

  defp args_to_options(args) do
    {opts, extra_args} = OptionParser.parse!(args, strict: @switches, aliases: @aliases)
    validate_options!(opts)
    validate_extra_args!(extra_args)
    {opts, extra_args}
  end

  defp validate_options!(opts) do
    cond do
      Keyword.has_key?(opts, :tesla) and Keyword.has_key?(opts, :req) ->
        raise "the provided --req and --tesla options are mutually exclusive, please specify only one of them"

      not Keyword.has_key?(opts, :output_path) ->
        raise "--output_path is required"

      true ->
        nil
    end
  end

  defp validate_extra_args!(extra_args) do
    if extra_args == [] do
      raise "open api spec path is required"
    end
  end

  defp display_help do
    IO.puts("OpenApiCodeGen is a Code Generation tool for Elixir\n")
    IO.write(usage())
  end

  defp display_version do
    IO.puts(:erlang.system_info(:system_version))
    IO.puts("Elixir " <> System.build_info()[:build])

    version = Application.spec(:openapi_codegen, :vsn)
    IO.puts("\nOpenApiCodeGen #{version}")
  end
end
