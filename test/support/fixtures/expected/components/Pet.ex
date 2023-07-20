defmodule PetStore.Pet do
  @moduledoc "Structure for Pet component"
  defstruct [:category, :id, :name, :photo_urls, :status, :tags]
end