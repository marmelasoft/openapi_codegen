defmodule PetStore.Address do
  @moduledoc "Structure for Address component"
  @derive Jason.Encoder
  defstruct [:city, :state, :street, :zip]
end
