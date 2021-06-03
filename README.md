# RandomColour

[![Hex Docs](https://img.shields.io/badge/hex-docs-lightgreen.svg)](https://hexdocs.pm/random_colour)

`RandomColour` is a tool for generating attractive random colours.

It is an `Elixir` port of [David Merfield's randomColor](https://github.com/davidmerfield/randomColor)

## Usage

```elixir
# Returns a hex code for an attractive colour
RandomColour.generate()

# Returns an array of ten green colours
RandomColour.generate(
   count: 10,
   hue: "green"
)

# Returns a hex code for a light blue
RandomColour.generate(
  luminosity: "light",
  hue: "blue"
)

# Returns a bright colour in RGB
RandomColour.generate(
  luminosity: "bright",
  format: "rgb"
)

# Returns a dark RGB colour with random alpha
RandomColour.generate(
  luminosity: "dark",
  format: "rgba"
)

# Returns a dark RGB colour with specified alpha
RandomColour.generate(
  luminosity: "dark",
  format: "rgba",
  alpha: 0.5
)

# Returns a light HSL colour with random alpha
RandomColour.generate(
  luminosity: "light",
  format: "hsla"
)

# Returns the same colour based on a given seed
RandomColour.generate(
  seed: 11,
  luminosity: "light",
)
# "#707EE5"

# Returns a list of predefined hues
RandomColour.get_predefined_hues
# ["blue", "green", "monochrome", "orange", "pink", "purple", "red", "yellow"]

```

## Options

You can pass an options object to influence the type of colour it produces. The options object accepts the following properties:

```hue``` – Controls the hue of the generated colour. You can pass a string representing a colour name: ```red```, ```orange```, ```yellow```, ```green```, ```blue```, ```purple```, ```pink``` and ```monochrome``` are currently supported. If you pass a  hexidecimal colour string such as ```#00FFFF```, randomColour will extract its hue value and use that to generate colours.

```luminosity``` – Controls the luminosity of the generated colour. You can specify a string containing ```bright```, ```light``` or ```dark```. Defaults to ```nil```.

```count``` – An integer which specifies the number of colours to generate. Defaults to ```1```.

```seed``` - An integer or a string which when passed will cause randomColour to return the same colour each time.

```format``` – A string which specifies the format of the generated colour. Possible values are ```rgb```, ```rgba```, ```hsl```, ```hsla```, ```hsv``` and ```hex``` (default).

```alpha``` – A decimal between 0 and 1. Only relevant when using a format with an alpha channel (```rgba``` and ```hsla```). Defaults to a random value.


## Installation
```elixir
def deps do
  [
    {:random_colour, "~> 0.1.0"}
  ]
end
