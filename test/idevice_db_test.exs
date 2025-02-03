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
    assert %{} = IDeviceDb.find_by_identifier("iPhone13,1")
  end
end
