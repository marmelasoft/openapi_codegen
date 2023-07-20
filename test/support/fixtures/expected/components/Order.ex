defmodule PetStore.Order do
  @moduledoc "Structure for Order component"
  defstruct [:complete, :id, :pet_id, :quantity, :ship_date, :status]
end
