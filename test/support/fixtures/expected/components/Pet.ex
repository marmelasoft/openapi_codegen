defmodule PetStore.Pet do
  @moduledoc "Structure for Pet component"
  defstruct [:category, :id, :name, :photoUrls, :status, :tags]
end