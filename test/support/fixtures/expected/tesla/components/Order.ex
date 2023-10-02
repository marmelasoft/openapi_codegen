defmodule PetStore.Order do
  @moduledoc "Structure for Order component"
  @derive Jason.Encoder
  defstruct [:complete, :id, :pet_id, :quantity, :ship_date, :status]
end
