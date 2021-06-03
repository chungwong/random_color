defmodule RandomColour.PredefinedtHue do
  alias RandomColour

  @spec define_colour(nil | RandomColour.hue_range(), list(RandomColour.hue_range())) :: map
  def define_colour(hue_range, lower_bounds) do
    s_min = lower_bounds |> Enum.at(0) |> elem(0)
    s_max = lower_bounds |> Enum.at(length(lower_bounds) - 1) |> elem(0)

    b_min = lower_bounds |> Enum.at(length(lower_bounds) - 1) |> elem(1)
    b_max = lower_bounds |> Enum.at(0) |> elem(1)

    %{
      hue_range: hue_range,
      lower_bounds: lower_bounds,
      saturation_range: {s_min, s_max},
      brightness_range: {b_min, b_max}
    }
  end

  @spec load_colour_bounds() :: map
  def load_colour_bounds() do
    [
      {
        "monochrome",
        nil,
        [{0, 0}, {100, 0}]
      },
      {
        "red",
        {-26, 18},
        [
          {20, 100},
          {30, 92},
          {40, 89},
          {50, 85},
          {60, 78},
          {70, 70},
          {80, 60},
          {90, 55},
          {100, 50}
        ]
      },
      {
        "orange",
        {18, 46},
        [{20, 100}, {30, 93}, {40, 88}, {50, 86}, {60, 85}, {70, 70}, {100, 70}]
      },
      {
        "yellow",
        {46, 62},
        [{25, 100}, {40, 94}, {50, 89}, {60, 86}, {70, 84}, {80, 82}, {90, 80}, {100, 75}]
      },
      {
        "green",
        {62, 178},
        [{30, 100}, {40, 90}, {50, 85}, {60, 81}, {70, 74}, {80, 64}, {90, 50}, {100, 40}]
      },
      {
        "blue",
        {178, 257},
        [
          {20, 100},
          {30, 86},
          {40, 80},
          {50, 74},
          {60, 60},
          {70, 52},
          {80, 44},
          {90, 39},
          {100, 35}
        ]
      },
      {
        "purple",
        {257, 282},
        [
          {20, 100},
          {30, 87},
          {40, 79},
          {50, 70},
          {60, 65},
          {70, 59},
          {80, 52},
          {90, 45},
          {100, 42}
        ]
      },
      {
        "pink",
        {282, 334},
        [{20, 100}, {30, 90}, {40, 86}, {60, 84}, {80, 80}, {90, 75}, {100, 73}]
      }
    ]
    |> List.foldl(%{}, fn {name, hue_range, lower_bounds}, acc ->
      Map.put(acc, name, define_colour(hue_range, lower_bounds))
    end)
  end
end
