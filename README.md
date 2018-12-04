# ElixirBlinkt

`ElixirBlinkt` lets you control a Pimoroni Blinkt! RGB LEDs
(https://shop.pimoroni.com/products/blinkt) with Elixir!

Modeled after the official Python library (https://github.com/pimoroni/blinkt)

Stores the LED array state in an Agent, which allows for updating single LEDs,
but always sets all LED colours and brightnesses at once.

## NOTE

I had to manually turn both pins 23 and 24 to output mode by running
```
$ echo "out" > /sys/class/gpio/gpio24/direction
$ echo "out" > /sys/class/gpio/gpio23/direction
```

Otherwise I kept getting Access Denied -errors from Elixir Circuits' GPIO-library

### Examples

```elixir

iex(1)> ElixirBlinkt.start_link
{:ok, #PID<0.181.0>}

iex(2)> ElixirBlinkt.dump 
%{
  1 => {0, 0, 0, 0},
  2 => {0, 0, 0, 0},
  3 => {0, 0, 0, 0},
  4 => {0, 0, 0, 0},
  5 => {0, 0, 0, 0},
  6 => {0, 0, 0, 0},
  7 => {0, 0, 0, 0},
  8 => {0, 0, 0, 0}
}

iex(3)> ElixirBlinkt.set_led(1, 255, 0, 0, 0.5)
:ok
iex(4)> ElixirBlinkt.set_led(3, 0, 100, 0, 0.2)
:ok
iex(5)> ElixirBlinkt.set_led(4, 15, 100, 200, 0.7)
:ok
iex(6)> ElixirBlinkt.dump                         
%{
  1 => {255, 0, 0, 0.5},
  2 => {0, 0, 0, 0},
  3 => {0, 100, 0, 0.2},
  4 => {15, 100, 200, 0.7},
  5 => {0, 0, 0, 0},
  6 => {0, 0, 0, 0},
  7 => {0, 0, 0, 0},
  8 => {0, 0, 0, 0}
}
iex(7)> ElixirBlinkt.show
:ok
```


## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `elixir_blinkt` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:elixir_blinkt, "~> 0.1.0"}
  ]
end
``` 