defmodule IDeviceDbTest do
  use ExUnit.Case
  doctest IDeviceDb

  test "can fetch all the devices" do
    [_ | _] = IDeviceDb.all_devices()
  end

  test "can fetch a specific model" do
    assert %{} = IDeviceDb.find_by_model("MX132")
  end

  test "can fetch a specific identifier" do
    assert "iPhone 12 mini" = IDeviceDb.id_to_generation("iPhone13,1")
  end

  test "Can sort by generation" do
    gens = IDeviceDb.all_devices() |> Enum.map(& &1.generation) |> Enum.uniq()
    assert Enum.sort(Enum.shuffle(gens), &IDeviceDb.generation_less_than?/2) == gens
  end

  test "Can sort by identifier" do
    ids = IDeviceDb.all_devices() |> Enum.map(& &1.identifier) |> Enum.uniq()
    assert Enum.sort(Enum.shuffle(ids), &IDeviceDb.identifier_less_than?/2) == ids
  end

  test "Can sort by model" do
    models = IDeviceDb.all_devices() |> Enum.map(& &1.models) |> List.flatten()
    _ = Enum.sort(Enum.shuffle(models), &IDeviceDb.model_less_than?/2)
  end
end
