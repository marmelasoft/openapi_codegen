defmodule OpenApiCodeGenTest do
  use ExUnit.Case

  doctest OpenApiCodeGen

  setup do
    content = File.read!("test/support/fixtures/openapi_petstore.json")
    output_path = "tmp/lib/pet_store"

    on_exit(fn -> File.rm_rf!(output_path) end)
    %{content: content, output_path: output_path}
  end

  describe "generate/1" do
    test "generates components", %{content: content, output_path: output_path} do
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

      %{schemas: result} = OpenApiCodeGen.generate(output_path, content, :tesla)

      assert result == Enum.map(components, &Path.join(output_path <> "/components", "#{&1}.ex"))

      for component <- components do
        output_file = Path.join([output_path, "/components", "#{component}.ex"])
        assert File.exists?(output_file)
        assert File.read!(output_file) == File.read!("test/support/fixtures/expected/tesla/components/#{component}.ex")
      end
    end

    test "generates tesla client", %{content: content, output_path: output_path} do
      %{client: output_file} = OpenApiCodeGen.generate(output_path, content, :tesla)
      assert File.exists?(output_file)
      assert File.read!(output_file) == File.read!("test/support/fixtures/expected/tesla/PetStore.ex")
    end

    test "generates req client", %{content: content, output_path: output_path} do
      %{client: output_file} = OpenApiCodeGen.generate(output_path, content, :req)
      assert File.exists?(output_file)
      assert File.read!(output_file) == File.read!("test/support/fixtures/expected/req/PetStore.ex")
    end
  end
end
