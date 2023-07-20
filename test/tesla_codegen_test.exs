defmodule TeslaCodegenTest do
  use ExUnit.Case

  doctest TeslaCodegen

  setup do
    on_exit(fn -> File.rm_rf!("tmp") end)
  end

  describe "generate/1" do
    test "generates components" do
      content = File.read!("test/support/fixtures/openapi_petstore.json")
      output_path = "tmp"

      components = [
        "Address",
        "ApiResponse",
        "Category",
        "Customer",
        "Order",
        "Pet",
        "Tag",
        "User"
      ]

      %{schemas: result} = TeslaCodegen.generate(PetStore, output_path, content)

      assert result == Enum.map(components, &Path.join(output_path <> "/components", "#{&1}.ex"))

      for component <- components do
        output_file = Path.join(output_path <> "/components", "#{component}.ex")
        assert File.exists?(output_file)
        assert File.read!(output_file) == File.read!("test/support/fixtures/expected/components/#{component}.ex")
      end
    end
  end
end
