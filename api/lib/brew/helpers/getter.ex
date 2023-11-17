defprotocol Brew.Helper.Getter do
  def getter(map)
end

defimpl Brew.Helper.Getter, for: Map do
  def getter(map) do
    {
      fn name -> Map.get(map, name) end,
      fn (name, default) -> Map.get(map, name, default) end
    }
  end
end
