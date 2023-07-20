defmodule PetStore.Order do
  @moduledoc "Structure for Order component"
  defstruct [:complete, :id, :petId, :quantity, :shipDate, :status]
end