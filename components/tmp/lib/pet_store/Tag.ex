defmodule PetStore.Tag do
  @moduledoc "Structure for Tag component"
  @derive Jason.Encoder
  defstruct [:id, :name]
end
