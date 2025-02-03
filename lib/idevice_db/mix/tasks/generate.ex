defmodule Mix.Tasks.GenerateDb do
  @moduledoc false
  use Mix.Task

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

        [_, {"section", _, [{"table", _, [{"tbody", _, table_rows}]}]}] =
          content
          |> Floki.children()
          |> Enum.drop(1)
          |> Enum.chunk_every(2)
          |> Enum.find(fn
            [{"h2", _, [{"span", _, _}, {"span", attrs, _}]}, {"section", _, _}] ->
              Enum.any?(attrs, &match?({"id", "iPhone"}, &1))

            _ ->
              false
          end)

        json =
          table_rows
          |> Enum.drop(1)
          |> group_by_generation()
          |> Enum.flat_map(& &1)
          |> Enum.map(&to_map/1)
          |> Jason.encode!(pretty: true)

        File.mkdir_p!("priv")
        File.write!("priv/devices.json", json)
    end
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
      {storage, _},
      {models, _}
    ] = elems

    %{
      generation: generation,
      internal_name: internal_name,
      identifier: identifier,
      finish: finish,
      storage: storage,
      models: String.split(models, ", ", trim: true)
    }
  end

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
    for {"td", attrs, [child | _]} <- cells, do: rowspan(child, attrs)
  end

  defp rowspan({"a", _, [text | _]}, attrs), do: rowspan(text, attrs)

  defp rowspan(text, attrs) when is_binary(text) do
    {
      String.trim(text),
      String.to_integer(elem(List.keyfind(attrs, "rowspan", 0, {"rowspan", "1"}), 1))
    }
  end
end
