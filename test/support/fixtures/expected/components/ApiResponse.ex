defmodule PetStore.ApiResponse do
  @moduledoc "Structure for ApiResponse component"
  @derive Jason.Encoder
  defstruct [:code, :message, :type]
end
