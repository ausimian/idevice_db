defmodule Mix.Tasks.GenerateDb do
  @moduledoc "Regenerate the device database from the Apple Wiki"
  @shortdoc "Regenerate the device database"
  use Mix.Task

  @doc false
  @spec run(any()) :: :ok
  def run(_args) do
    Application.ensure_all_started(:req)

    case Req.get("https://theapplewiki.com/wiki/Models") do
      {:ok, %{status: 200, body: body}} ->
        {:ok, html} = Floki.parse_document(body)

        [content, _footer] =
          html
          |> Floki.find("#mw-content-text")
          |> List.first()
          |> Floki.children()

        json =
          ["iPhone", "iPad", "iPad_Air", "iPad_Pro", "iPad_mini"]
          |> Enum.flat_map(&get_devices(content, &1))
          |> Jason.encode!(pretty: true)

        File.mkdir_p!("priv")
        File.write!("priv/devices.json", json)
    end
  end

  defp get_devices(content, type) do
    get_table_rows(content, type)
    |> Enum.drop(1)
    |> group_by_generation()
    |> Enum.flat_map(& &1)
    |> Enum.map(&to_map/1)
    |> Enum.reject(&match?(%{models: []}, &1))
  end

  defp get_table_rows(content, span_id) do
    [{"table", _, [{"tbody", _, table_rows} | _]} | _] =
      content
      |> Floki.children()
      |> Enum.find(fn
        {"section", _, [heading | _]} ->
          case Floki.find(heading, "h2") do
            [{"h2", attrs, _}] -> Enum.any?(attrs, &match?({"id", ^span_id}, &1))
            _ -> false
          end

        _ ->
          false
      end)
      |> Floki.children()
      |> Enum.filter(&match?({"table", _, _}, &1))

    table_rows
  end

  defp to_map(elems) do
    [
      {generation, _},
      _,
      _,
      _,
      {internal_name, _},
      {identifier, _},
      {finish, _},
      {storage, _} | maybe_models
    ] = elems

    models = List.first(maybe_models, {"", 0}) |> elem(0)

    %{
      generation: first_line(generation),
      internal_name: first_line(internal_name),
      identifier: first_line(identifier),
      finish: tweak_finish(first_line(finish)),
      storage: first_line(storage),
      models: split_models(models)
    }
  end

  # Cells that list several values (e.g. two internal names) keep only the first.
  defp first_line(text), do: text |> String.split("\n") |> List.first() |> String.trim()

  defp split_models(models) do
    models
    |> String.split([",", "\n"], trim: true)
    |> Enum.map(&String.trim/1)
    |> Enum.reject(&(&1 == ""))
  end

  defp tweak_finish("PRODUCT(RED)"), do: "Red"
  defp tweak_finish("(PRODUCT)RED"), do: "Red"
  defp tweak_finish("(PRODUCT)Red"), do: "Red"
  defp tweak_finish(finish), do: finish

  defp group_by_generation(table_rows), do: group_by_generation(table_rows, [])

  defp group_by_generation([], acc), do: Enum.reverse(acc)

  defp group_by_generation([{"tr", _, [{"td", attrs, _} | _]} | _] = rows, acc) do
    rowcount =
      attrs
      |> Enum.find_value("1", fn {k, v} -> if k == "rowspan", do: v end)
      |> String.to_integer()

    {group, rest} = Enum.split(rows, rowcount)
    group_by_generation(rest, [expand_cells(group) | acc])
  end

  defp expand_cells(group) do
    Enum.reduce(group, [], fn
      {"tr", _, cells}, [] ->
        [rowspans(cells)]

      {"tr", _, cells}, [prev | _] = acc ->
        [merge_row(dec_rowspans(prev), rowspans(cells)) | acc]
    end)
    |> Enum.reverse()
  end

  defp merge_row(prev, row) do
    Enum.reduce(row, prev, fn cell, datum ->
      index = Enum.find_index(datum, fn {_, n} -> n == 0 end)
      List.replace_at(datum, index, cell)
    end)
  end

  defp dec_rowspans(row), do: Enum.map(row, fn {k, v} -> {k, v - 1} end)

  defp rowspans(cells) do
    for {"td", attrs, children} <- cells, do: rowspan(children, attrs)
  end

  defp rowspan(children, attrs) do
    {
      children |> Enum.reject(&match?({"sup", _, _}, &1)) |> Floki.text() |> String.trim(),
      String.to_integer(elem(List.keyfind(attrs, "rowspan", 0, {"rowspan", "1"}), 1))
    }
  end
end
