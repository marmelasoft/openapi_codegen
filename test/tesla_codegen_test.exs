defmodule TeslaCodegenTest do
  use ExUnit.Case

  doctest TeslaCodegen

  setup do
    spec = "test/support/fixtures/openapi_petstore.json"
    output_path = "tmp/lib/pet_store"

    on_exit(fn -> File.rm_rf!(output_path) end)
    %{spec: spec, output_path: output_path}
  end

  describe "generate/1" do
    test "generates components", %{spec: spec, output_path: output_path} do
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

      %{schemas: result} = TeslaCodegen.generate(output_path, spec)

      assert result == Enum.map(components, &Path.join(output_path <> "/components", "#{&1}.ex"))

      for component <- components do
        output_file = Path.join([output_path, "/components", "#{component}.ex"])
        assert File.exists?(output_file)
        assert File.read!(output_file) == File.read!("test/support/fixtures/expected/components/#{component}.ex")
      end
    end

    test "generates client", %{spec: spec, output_path: output_path} do
      %{client: output_file} = TeslaCodegen.generate(output_path, spec)
      assert File.exists?(output_file)
      assert File.read!(output_file) == File.read!("test/support/fixtures/expected/PetStore.ex")
    end
  end
end
