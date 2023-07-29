defmodule PetStore.Category do
  @moduledoc "Structure for Category component"
  @derive Jason.Encoder
  defstruct [:id, :name]
end
