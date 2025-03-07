defmodule IDeviceDb do
  @moduledoc """
  A database of Apple devices.

  This module provides a simple API for querying a database of Apple devices.
  The database is generated from the Apple Wiki and is stored in the priv directory.

  When the module is loaded, the database is read from the priv directory and stored in
  persistent terms. This means that the database is only read from disk once and is then
  available in memory for the lifetime of the application.

  The module provides two functions, `generation_less_than?/2` and `model_less_than?/2`,
  which may be used as 'sorters' in the `Enum.sort/2` function. These functions order by
  the age of the device, with the oldest devices first.
  """

  @on_load :init

  @all_devices {__MODULE__, :all_devices}
  @ranked_generations {__MODULE__, :ranked_generations}
  @ranked_identifiers {__MODULE__, :ranked_identifiers}
  @ranked_models {__MODULE__, :ranked_models}
  @devices_by_model {__MODULE__, :devices_by_model}
  @identifiers {__MODULE__, :identifiers}

  @doc false
  @spec init() :: :ok
  def init do
    all_devices =
      :idevice_db
      |> :code.priv_dir()
      |> Path.join("devices.json")
      |> File.read!()
      |> Jason.decode!(keys: :atoms)
      |> Enum.map(fn
        %{generation: "iPhone" <> _} = device ->
          Map.put(device, :family, :iPhone)

        %{generation: "iPad Air" <> _} = device ->
          Map.put(device, :family, :iPadAir)

        %{generation: "iPad Pro" <> _} = device ->
          Map.put(device, :family, :iPadPro)

        %{generation: "iPad mini" <> _} = device ->
          Map.put(device, :family, :iPadMini)

        %{generation: "iPad" <> _} = device ->
          Map.put(device, :family, :iPad)
      end)

    :persistent_term.put(@all_devices, all_devices)

    ranked_generations =
      :persistent_term.get(@all_devices)
      |> Enum.map(& &1.generation)
      |> Enum.uniq()
      |> Enum.with_index()
      |> Map.new()

    :persistent_term.put(@ranked_generations, ranked_generations)

    ranked_identifiers =
      :persistent_term.get(@all_devices)
      |> Enum.map(& &1.identifier)
      |> Enum.uniq()
      |> Enum.with_index()
      |> Map.new()

    :persistent_term.put(@ranked_identifiers, ranked_identifiers)

    ranked_models =
      :persistent_term.get(@all_devices)
      |> Enum.map(& &1.models)
      |> Enum.with_index()
      |> Enum.reduce(%{}, fn {models, index}, acc ->
        Enum.reduce(models, acc, fn model, acc ->
          Map.put(acc, model, index)
        end)
      end)

    :persistent_term.put(@ranked_models, ranked_models)

    devices_by_model =
      :persistent_term.get(@all_devices)
      |> Enum.reduce(%{}, fn %{models: models} = device, acc ->
        Enum.reduce(models, acc, fn model, acc ->
          Map.put(acc, model, device)
        end)
      end)

    :persistent_term.put(@devices_by_model, devices_by_model)

    identifiers =
      :persistent_term.get(@all_devices)
      |> Enum.reduce(%{}, fn device, acc ->
        Map.put_new(acc, device.identifier, device.generation)
      end)

    :persistent_term.put(@identifiers, identifiers)
  end

  @doc """
  Returns a list of all devices in the database.

  ## Example

      iex> IDeviceDb.all_devices |> Enum.take(1)
      [
        %{
          finish: "Black",
          identifier: "iPhone1,1",
          generation: "iPhone",
          models: ["MA501"],
          internal_name: "M68AP",
          storage: "4 GB",
          family: :iPhone
        }
      ]
  """
  @spec all_devices() :: [map()]
  def all_devices, do: :persistent_term.get(@all_devices)

  @doc """
  Finds a device by its model name e.g. `MX132`

  ## Example

      iex> IDeviceDb.find_by_model("MX132")
      %{
        finish: "Space Gray",
        identifier: "iPhone10,1",
        generation: "iPhone 8",
        models: ["MX132"],
        internal_name: "D20AP",
        storage: "128 GB",
        family: :iPhone
      }
  """
  @spec find_by_model(String.t()) :: map() | nil
  def find_by_model(model), do: :persistent_term.get(@devices_by_model)[model]

  @doc """
  Returns the generation of a device given its identifier e.g. `iPhone13,1`

  ## Example

      iex> IDeviceDb.id_to_generation("iPhone13,1")
      "iPhone 12 mini"
  """
  @spec id_to_generation(String.t()) :: String.t() | nil
  def id_to_generation(identifier), do: :persistent_term.get(@identifiers)[identifier]

  @doc """
  Returns true if `g1` is older than `g2`, false otherwise.

  Intended to be used as a sorter in `Enum.sort/2`.

  ## Example

      iex> Enum.sort(["iPhone X", "iPhone 13 Pro Max", "iPhone 5c"], &IDeviceDb.generation_less_than?/2)
      ["iPhone 5c", "iPhone X", "iPhone 13 Pro Max"]
  """
  @spec generation_less_than?(String.t(), String.t()) :: boolean()
  def generation_less_than?(g1, g2) when is_binary(g1) and is_binary(g2) do
    ranked_generations = :persistent_term.get(@ranked_generations)
    ranked_generations[g1] < ranked_generations[g2]
  end

  @doc """
  Returns true if `i1` is older than `i2`, false otherwise

  Intended to be used as a sorter in `Enum.sort/2`.

  ## Example

      iex> Enum.sort(["iPhone14,5", "iPhone12,8", "iPhone10,2"], &IDeviceDb.identifier_less_than?/2)
      ["iPhone10,2", "iPhone12,8", "iPhone14,5"]
  """
  @spec identifier_less_than?(String.t(), String.t()) :: boolean()
  def identifier_less_than?(g1, g2) when is_binary(g1) and is_binary(g2) do
    ranked_identifiers = :persistent_term.get(@ranked_identifiers)
    ranked_identifiers[g1] < ranked_identifiers[g2]
  end

  @doc """
  Returns true if `m1` is older than `m2`, false otherwise

  Intended to be used as a sorter in `Enum.sort/2`. Note that more than
  one model can map to a specific device. When comparing such models,
  this function will return false regardless of the order of the arguments.

  ## Example

      iex> Enum.sort(["MU163", "MYD13", "MQ9X3"], &IDeviceDb.model_less_than?/2)
      ["MQ9X3", "MU163", "MYD13"]
  """
  @spec model_less_than?(String.t(), String.t()) :: boolean()
  def model_less_than?(m1, m2) when is_binary(m1) and is_binary(m2) do
    ranked_models = :persistent_term.get(@ranked_models)
    ranked_models[m1] < ranked_models[m2]
  end
end
