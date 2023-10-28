defmodule PetStore.ApiResponse do
  @moduledoc "Structure for ApiResponse component"
  @derive Jason.Encoder
  @enforce_keys []
  defstruct [:code, :message, :type]
end
