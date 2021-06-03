defmodule RandomColour do
  alias RandomColour.{
    PredefinedtHue,
    RandomColourException
  }

  @type hue_range() :: {integer, integer}

  @type hsv() :: {integer, integer, integer}

  @type rgb() :: {integer, integer, integer}

  @type options() :: [
          alpha: float,
          count: non_neg_integer,
          hue: String.t(),
          format: String.t(),
          seed: integer | String.t(),
          luminosity: String.t()
        ]

  @predefined_hues PredefinedtHue.load_colour_bounds()

  @spec get_predefined_hues() :: list(String.t())
  def get_predefined_hues(), do: Map.keys(@predefined_hues)

  @spec generate(options()) :: String.t() | tuple | list(tuple)
  def generate(opts \\ []) do
    opts =
      Keyword.update(opts, :seed, nil, fn
        s when is_binary(s) ->
          string_to_integer(s)

        s when is_integer(s) ->
          s

        s ->
          raise RandomColourException,
            message: "expected seed value to be an integer or a string, got #{s}"
      end)

    count = Keyword.get(opts, :count, 1)

    if !is_integer(count) do
      raise RandomColourException, message: "expected count value to be an integer, got #{count}"
    end

    opts =
      opts
      # default format
      |> Keyword.put_new(:format, "hex")

    result =
      if count == 1 do
        gen(opts)
      else
        opts =
          opts
          |> Keyword.put(:colour_ranges, List.duplicate(nil, count))

        get_ranges(opts)
        |> Enum.map(fn hue_range ->
          opts = Keyword.put(opts, :hue_range, hue_range)

          gen(opts)
        end)
      end

    # FIXME: clean up them mess from `random_within/2`
    Process.delete("_random_colour_seed")
    result
  end

  @spec gen(options()) :: String.t() | tuple | list(tuple)
  defp gen(opts) do
    # First we pick a hue (H)
    h = pick_hue(opts)

    # Then use H to determine saturation (S)
    s = pick_saturation(h, opts)

    # Then use S and H to determine brightness (B).
    b = pick_brightness(h, s, opts)

    # Then we return the HSB colour in the desired format
    set_format({h, s, b}, opts)
  end

  @spec get_ranges(options()) :: list(integer)
  defp get_ranges(opts) do
    colour_ranges = Keyword.get(opts, :colour_ranges, [])
    opt_hue = Keyword.get(opts, :hue)
    hue_range = get_real_hue_range(opt_hue)

    Enum.reduce(colour_ranges, {colour_ranges, []}, fn _, {colour_ranges, m} ->
      hue = random_within(hue_range, opts)
      # Each of colour_ranges.length ranges has a length equal approximatelly one step
      step = (elem(hue_range, 1) - elem(hue_range, 0)) / length(colour_ranges)

      j = trunc((hue - elem(hue_range, 0)) / step)
      # Check if the range j is taken
      {colour_ranges, j} =
        if Enum.at(colour_ranges, j) == true do
          {colour_ranges, rem(j + 2, length(colour_ranges))}
        else
          {List.replace_at(colour_ranges, j, true), j}
        end

      min = :math.fmod(elem(hue_range, 0) + j * step, 359)
      max = :math.fmod(elem(hue_range, 0) + (j + 1) * step, 359)

      {colour_ranges,
       m ++
         [
           random_within({min, max}, opts)
         ]}
    end)
    |> elem(1)
  end

  @spec pick_hue(options()) :: integer
  def pick_hue(opts \\ []) do
    colour_range = Keyword.get(opts, :hue_range)

    if colour_range do
      colour_range
    else
      Keyword.get(opts, :hue)
      |> get_hue_range()
      |> random_within(opts)
    end
    |> case do
      # Instead of storing red as two seperate ranges,
      # we group them, using negative numbers
      hue when hue < 0 ->
        360 + hue

      hue ->
        hue
    end
  end

  @spec pick_saturation(integer, options()) :: integer
  def pick_saturation(hue, opts) do
    if Keyword.get(opts, :hue) == "monochrome" do
      throw({:exit, 0})
    end

    if Keyword.get(opts, :luminosity) == "random" do
      throw({:exit, random_within({0, 100}, opts)})
    end

    {s_min, s_max} = get_saturation_range(hue)

    {s_min, s_max} =
      Keyword.get(opts, :luminosity)
      |> case do
        "bright" ->
          {55, s_max}

        "dark" ->
          {s_max - 10, s_max}

        "light" ->
          {s_min, 55}

        _ ->
          {s_min, s_max}
      end

    random_within({s_min, s_max}, opts)
  catch
    {:exit, sat} -> sat
  end

  @spec pick_brightness(integer, integer, options()) :: integer
  def pick_brightness(h, s, opts) do
    b_min = get_minimum_brightness(h, s)
    b_max = 100

    {b_min, b_max} =
      Keyword.get(opts, :luminosity)
      |> case do
        "dark" ->
          {b_min, b_min + 20}

        "light" ->
          {(b_max + b_min) / 2, b_max}

        "random" ->
          {0, 100}

        _ ->
          {b_min, b_max}
      end

    random_within({b_min, b_max}, opts)
  end

  @spec set_format(hsv(), options()) :: String.t() | tuple
  def set_format(hsv, opts \\ []) when is_tuple(hsv) do
    alpha = Keyword.get(opts, :alpha)

    Keyword.get(opts, :format)
    |> case do
      "hex" ->
        hsv_to_hex(hsv)

      "hsv" ->
        hsv

      "hsl" ->
        hsv_to_hsl(hsv)

      "hsla" ->
        {h, s, l} = hsv_to_hsl(hsv)
        alpha = if alpha, do: alpha, else: :rand.uniform()
        {h, s, l, alpha}

      "rgb" ->
        hsv_to_rgb(hsv)

      "rgba" ->
        {r, g, b} = hsv_to_rgb(hsv)
        alpha = if alpha, do: alpha, else: :rand.uniform()
        {r, g, b, alpha}

      f ->
        raise RandomColourException, message: "unknown format #{f}"
    end
  end

  @spec get_minimum_brightness(integer, integer) :: integer
  def get_minimum_brightness(h, s) do
    lower_bounds = get_colour_info(h).lower_bounds

    0..(length(lower_bounds) - 2)
    |> Enum.find_value(fn i ->
      s1 = lower_bounds |> Enum.at(i) |> elem(0)
      v1 = lower_bounds |> Enum.at(i) |> elem(1)

      s2 = lower_bounds |> Enum.at(i + 1) |> elem(0)
      v2 = lower_bounds |> Enum.at(i + 1) |> elem(1)

      if s >= s1 && s <= s2 do
        m = (v2 - v1) / (s2 - s1)
        b = v1 - m * s1

        m * s + b
      end
    end)
    |> case do
      nil -> 0
      b -> b
    end
  end

  @spec get_hue_range(integer) :: hue_range()
  def get_hue_range(colour_input) when colour_input < 360 and colour_input > 0 do
    {colour_input, colour_input}
  end

  @spec get_hue_range(String.t()) :: hue_range()
  def get_hue_range(colour_input) when is_binary(colour_input) do
    colour = get_colour_info(colour_input)

    cond do
      colour == nil && is_hex_binary?(colour_input) ->
        hue = elem(hex_to_hsb(colour_input), 0)
        {hue, hue}

      colour == nil ->
        raise RandomColourException, message: "hue `#{colour_input}` not found"

      colour && colour.hue_range ->
        colour.hue_range

      true ->
        get_hue_range()
    end
  end

  @spec get_hue_range(any) :: hue_range()
  def get_hue_range(_), do: get_hue_range()

  @spec get_hue_range() :: hue_range()
  def get_hue_range(), do: {0, 360}

  @spec get_saturation_range(integer) :: hue_range()
  def get_saturation_range(hue), do: get_colour_info(hue).saturation_range

  @spec get_colour_info() :: map
  def get_colour_info() do
    @predefined_hues
  end

  @spec get_colour_info(String.t()) :: map
  def get_colour_info(hue) when is_binary(hue) do
    Map.get(get_colour_info(), hue)
  end

  @spec get_colour_info(integer) :: map
  def get_colour_info(hue) when hue >= 334 and hue <= 360 do
    # Maps red colours to make picking hue easier
    get_colour_info(hue - 360)
  end

  @spec get_colour_info(integer) :: map
  def get_colour_info(hue) when is_number(hue) do
    colour =
      get_colour_info()
      |> Enum.find_value(fn {_, colour} ->
        if colour.hue_range && hue >= elem(colour.hue_range, 0) && hue <= elem(colour.hue_range, 1) do
          colour
        end
      end)

    colour || raise RandomColourException, message: "Colour not found"
  end

  @spec random_within(hue_range(), options()) :: integer
  def random_within(range, opts) when is_tuple(range) do
    seed = Keyword.get(opts, :seed)

    if seed == nil do
      # generate random evenly destinct number from : https://martin.ankerl.com/2009/12/09/how-to-create-random-colours-programmatically/
      golden_ratio = 0.618033988749895
      r = :rand.uniform()
      r = r + golden_ratio
      r = :math.fmod(r, 1)
      trunc(elem(range, 0) + r * (elem(range, 1) + 1 - elem(range, 0)))
    else
      # Seeded random algorithm from http://indiegamr.com/generate-repeatable-random-numbers-in-js/
      max = elem(range, 1) || 1
      min = elem(range, 0) || 0

      # FIXME
      # The original source code requires `seed` to be a global variable.
      # Using process dictionary here as a quick hack `:rand.seed/2`
      # was considered as a replacement, however, it will deviate the `randomness` from the JS version
      prev_seed = Process.get("_random_colour_seed")
      seed = prev_seed || seed
      seed = :math.fmod(seed * 9301 + 49297, 233_280)
      Process.put("_random_colour_seed", seed)

      rnd = seed / 233_280.0
      trunc(min + rnd * (max - min))
    end
  end

  @spec component_to_hex(integer) :: String.t()
  def component_to_hex(c) when is_integer(c) do
    c
    |> trunc()
    |> Integer.to_string(16)
    |> String.pad_leading(2, "0")
  end

  @spec hsv_to_hex(hsv()) :: String.t()
  def hsv_to_hex(hsv) do
    {r, g, b} = hsv_to_rgb(hsv)
    "##{component_to_hex(r)}#{component_to_hex(g)}#{component_to_hex(b)}"
  end

  @spec hsv_to_rgb(hsv()) :: rgb()
  def hsv_to_rgb(hsv) do
    {h, s, v} = hsv
    # this doesn't work for the values of 0 and 360
    # here's the hacky fix
    h =
      case h do
        0 -> 1
        360 -> 359
        h -> h
      end

    # Rebase the h,s,v values
    h = h / 360
    s = s / 100
    v = v / 100

    h_i = trunc(h * 6)
    f = h * 6 - h_i
    p = v * (1 - s)
    q = v * (1 - f * s)
    t = v * (1 - (1 - f) * s)

    {r, g, b} =
      case h_i do
        0 ->
          {v, t, p}

        1 ->
          {q, v, p}

        2 ->
          {p, v, t}

        3 ->
          {p, q, v}

        4 ->
          {t, p, v}

        5 ->
          {v, p, q}

        _ ->
          {256, 256, 256}
      end

    {trunc(r * 255), trunc(g * 255), trunc(b * 255)}
  end

  @spec hex_to_hsb(String.t()) :: {number, number, number}
  def hex_to_hsb(hex) when is_binary(hex) do
    hex = String.trim_leading(hex, "#")
    hex = if String.length(hex) == 3, do: String.replace(hex, ~r/(.)/, "\\1\\g{1}"), else: hex

    [red, green, blue] = for <<x::binary-2 <- hex>>, do: String.to_integer(x, 16) / 255

    c_max = Enum.max([red, green, blue])
    delta = c_max - Enum.min([red, green, blue])
    saturation = if c_max, do: delta / c_max, else: 0

    case c_max do
      ^red ->
        hue_val =
          if green - blue == 0 && delta == 0 do
            0
          else
            :math.fmod((green - blue) / delta, 6)
          end

        {60 * hue_val, saturation, c_max}

      ^green ->
        {60 * ((blue - red) / delta + 2) || 0, saturation, c_max}

      ^blue ->
        {60 * ((red - green) / delta + 4) || 0, saturation, c_max}
    end
  end

  @spec hsv_to_hsl(hsv()) :: tuple
  def hsv_to_hsl(hsv) do
    {h, s, v} = hsv
    s = s / 100
    v = v / 100
    k = (2 - s) * v

    {
      h,
      round(s * v / if(k < 1, do: k, else: 2 - k) * 10000) / 100,
      k / 2 * 100
    }
  end

  @spec string_to_integer(String.t()) :: integer
  def string_to_integer(string) do
    String.to_charlist(string)
    |> Enum.reduce(0, &(&1 + &2))
  end

  @doc """
  Get The range of given hue when options.count!=0
  """
  @spec get_real_hue_range(integer) :: map
  def get_real_hue_range(hue) when hue < 360 and hue > 0 do
    get_colour_info(hue).hue_range
  end

  @spec get_real_hue_range(String.t()) :: map
  def get_real_hue_range(colour_hue) when is_binary(colour_hue) do
    colour = get_colour_info(colour_hue)

    if colour && colour.hue_range do
      colour.hue_range
    else
      is_hex_binary?(colour_hue)
      hue = hex_to_hsb(colour_hue) |> elem(0)
      get_colour_info(hue).hue_range
    end
  end

  def is_hex_binary?(string), do: Regex.match?(~r/^#?([0-9A-F]{3}|[0-9A-F]{6})$/i, string)
end
