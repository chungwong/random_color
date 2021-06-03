defmodule RandomColourTest do
  use ExUnit.Case, async: true
  doctest RandomColour
  alias RandomColour.RandomColourException

  test "HSV to HEX" do
    assert RandomColour.hsv_to_hex({231, 27, 58}) == "#6B7193"
  end

  test "HSV to RGB" do
    assert RandomColour.hsv_to_rgb({231, 27, 58}) == {107, 113, 147}
    assert RandomColour.hsv_to_rgb({2231, 27, 58}) == {65280, 65280, 65280}
  end

  test "HEX to HSB" do
    assert RandomColour.hex_to_hsb("#ffffff") == {0, 0, 1}
    assert RandomColour.hex_to_hsb("ffffff") == {0, 0, 1}
    assert RandomColour.hex_to_hsb("FFFFFF") == {0, 0, 1}
    assert RandomColour.hex_to_hsb("FFF") == {0, 0, 1}
    assert RandomColour.hex_to_hsb("#123") == {210.0, 0.6666666666666667, 0.2}
  end

  test "HSV to HSL" do
    assert RandomColour.hsv_to_hsl({231, 27, 58}) == {231, 15.71, 50.169999999999995}
  end

  test "get hue range" do
    assert RandomColour.get_hue_range("#123") == {210, 210}
    assert RandomColour.get_hue_range(123) == {123, 123}
    assert RandomColour.get_hue_range(523) == {0, 360}
    assert RandomColour.get_hue_range("525") == {-60, -60}
  end

  test "string to integer" do
    assert RandomColour.string_to_integer("777") == 165
  end

  test "get real hue range" do
    assert RandomColour.get_real_hue_range("#123") == {178, 257}
    assert RandomColour.get_real_hue_range("green") == {62, 178}
  end

  test "random_within" do
    assert RandomColour.random_within({0, 360}, seed: 3) == 119
    assert RandomColour.random_within({30, 100}, seed: 3) == 45
    assert RandomColour.random_within({87.5, 100}, seed: 3) == 99
  end

  test "get minimum brightness" do
    assert RandomColour.get_minimum_brightness(24, 25) == 96.5
    assert RandomColour.get_minimum_brightness(200, 500) == 0
  end

  test "pick hue" do
    assert RandomColour.pick_hue(seed: 3) == 119
  end

  test "pick saturation" do
    assert RandomColour.pick_saturation(119, seed: 3) == 53
  end

  test "pick brightness" do
    assert RandomColour.pick_brightness(119, 53, seed: 3) == 89
  end

  test "generate colours" do
    assert is_binary(RandomColour.generate())
    assert RandomColour.generate(seed: 1, hue: "green") == "#89D343"
    assert RandomColour.generate(seed: 3) == "#8CFC8A"
    assert RandomColour.generate(seed: 111, hue: "#CCC") == "#F46664"
    assert RandomColour.generate(seed: "111", hue: "green") == "#C1DB3F"

    assert RandomColour.generate(seed: 222, luminosity: "dark") == "#BA4D0E"
    assert RandomColour.generate(seed: 222, luminosity: "light") == "#F7C9AF"
    assert RandomColour.generate(seed: 222, luminosity: "bright") == "#C67241"

    assert RandomColour.generate(seed: 77, format: "hsv") == {101, 35, 99}
    assert RandomColour.generate(seed: 77, format: "hsl") == {101, 94.54, 81.675}
    assert RandomColour.generate(seed: 77, format: "rgb") == {192, 252, 164}
    assert RandomColour.generate(seed: 77, format: "rgba", alpha: 0.7) == {192, 252, 164, 0.7}

    assert_raise RandomColourException, fn ->
      RandomColour.generate(seed: 77, format: "unknown")
    end

    assert_raise RandomColourException, fn ->
      RandomColour.generate(seed: 77, hue: "unknown")
    end
  end

  # test "get ranges" do
  #   count = 4
  #   colour_ranges = List.duplicate(false, count)

  #   assert RandomColour.get_ranges(
  #            seed: 777,
  #            hue: "blue",
  #            count: count,
  #            colour_ranges: colour_ranges
  #          ) == [182, 233, 222, 212]
  # end

  test "generate multiple" do
    assert RandomColour.generate(seed: 777, hue: "red", count: 4) == [
             "#F7B4CE",
             "#E24A3F",
             "#D35658",
             "#F27985"
           ]
  end
end
