defmodule IDeviceDb do
  @moduledoc """
  A database of Apple devices.

  This module provides a simple API for querying a database of Apple devices.
  The database is generated from the Apple Wiki and is stored in the priv directory.

  When the module is loaded, the database is read from the priv directory and stored in
  persistent terms. This means that the database is only read from disk once and is then
  available in memory for the lifetime of the application.
  """

  @on_load :init

  @doc false
  @spec init() :: :ok
  def init do

    all_devices =
      :idevice_db
      |> :code.priv_dir()
      |> Path.join("iphones.json")
      |> File.read!()
      |> Jason.decode!(keys: :atoms)
    :persistent_term.put({__MODULE__, :all_devices}, all_devices)

    devices_by_model =
      :persistent_term.get({__MODULE__, :all_devices})
      |> Enum.reduce(%{}, fn %{models: models} = device, acc ->
         Enum.reduce(models, acc, fn model, acc ->
           Map.put(acc, model, device)
         end)
      end)
    :persistent_term.put({__MODULE__, :devices_by_model}, devices_by_model)

    identifiers =
      :persistent_term.get({__MODULE__, :all_devices})
      |> Enum.reduce(%{}, fn device, acc ->
        Map.put_new(acc, device.identifier, Map.take(device, [:generation, :internal_name]))
      end)
    :persistent_term.put({__MODULE__, :identifiers}, identifiers)
  end

  @doc """
  Returns a list of all devices in the database.
  """
  @spec all_devices() :: [map()]
  def all_devices, do: :persistent_term.get({__MODULE__, :all_devices})

  @doc """
  Finds a device by its model name e.g. `MX132`
  """
  @spec find_by_model(String.t()) :: map() | nil
  def find_by_model(model), do: devices_by_model()[model]

  @doc """
  Finds a device name by its identifier e.g. `iPhone13,1`
  """
  @spec find_by_identifier(String.t()) :: map() | nil
  def find_by_identifier(identifier), do: identifiers()[identifier]

  defp devices_by_model, do: :persistent_term.get({__MODULE__, :devices_by_model})
  defp identifiers, do: :persistent_term.get({__MODULE__, :identifiers})

end
