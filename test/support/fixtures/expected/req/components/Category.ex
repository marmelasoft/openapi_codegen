defmodule PetStore.Category do
  @moduledoc "Structure for Category component"
  @derive Jason.Encoder
  @enforce_keys []
  defstruct [:id, :name]
end
