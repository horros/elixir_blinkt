defmodule ElixirBlinkt do
  @moduledoc """
  `ElixirBlinkt` lets you control a Pimoroni Blinkt! RGB LEDs
  (https://shop.pimoroni.com/products/blinkt) with Elixir!

  Modeled after the official Python library (https://github.com/pimoroni/blinkt)

  Stores the LED array state in an Agent, which allows for updating single LEDs,
  but always sets all LED colours and brightnesses at once.
  """
  use Agent
  use Bitwise
  alias Circuits.GPIO

  # The DAT-pin is pin 23
  @dat 23
  # The CLK-pin is pin 24
  @clk 24

  @type led_num :: integer()
  @type red :: byte()
  @type green :: byte()
  @type blue :: byte()
  @type brightness :: float()
  @type colours :: tuple()
  @type led_array :: map()

  @doc """
  Start the agent and initialize all leds as off

  The map is structured as follows:

  ```elixir
  %{
    1 => {_red, _green, _blue, _brightness},
    2 => {_red, _green, _blue, _brightness},
    3 => {_red, _green, _blue, _brightness},
    4 => {_red, _green, _blue, _brightness},
    ...
  }
  ```

  where the key is the led number on the Blinkt.

  Brightness must be set between 0.0 and 1.0.
  """
  def start_link(_opts \\ %{}) do
    Agent.start_link(fn ->
      %{
        # led_number: {red, green, blue, brightness (between 0.0 and 1.0)}
        1 => {0, 0, 0, 0},
        2 => {0, 0, 0, 0},
        3 => {0, 0, 0, 0},
        4 => {0, 0, 0, 0},
        5 => {0, 0, 0, 0},
        6 => {0, 0, 0, 0},
        7 => {0, 0, 0, 0},
        8 => {0, 0, 0, 0}
      }
    end, name: __MODULE__)
  end

  @doc """
  Set a led colour and brightness

  Index is the LED number, between 1 and 8

  Red, green and blue are between 0 and 255

  Brightness is between 0.0 and 1.0

  After setting one or more LEDs, call ```show/0```

  ### Examples

    iex> ElixirBlinkit.set_led(1, 100, 200, 0, 0.3)
    :ok

  """
  @spec set_led(led_num(), red(), green(), blue(), brightness()) :: :ok
  def set_led(idx, r, g, b, l)
    when is_float(l) and l >= 0.0 and l <= 1.0 and
         is_integer(r) and r >= 0 and r <= 255 and
         is_integer(g) and g >= 0 and g <= 255 and
         is_integer(b) and b >= 0 and b <= 255 and
         is_integer(idx) and idx > 0 and idx <= 8 do
    Agent.update(__MODULE__, fn state ->
      Map.put(state, idx, {r, g, b, l})
    end)
  end

  def set_led(led_num, r, g, b, l) do
    raise "Values for LED #{led_num} out of range:" <>
          " red: #{r}, green: #{g}, blue: #{b}, brightness: #{l}"
  end

  @doc """
  Get the RGBL-tuple for the specific LED

  ### Examples
      iex> ElixirBlinkt.get_led(1)
      {100, 200, 0, 0.3}
  """
  @spec get_led(led_num()) :: colours()
  def get_led(idx) do
    Agent.get(__MODULE__,  fn state ->
      Map.get(state, idx)
    end)
  end

  @doc """
  Dump the LED-array

  ### Examples
      iex> ElixirBlinkt.dump
      %{
        0 => {0, 100, 100, 0.1},
        1 => {100, 200, 0, 0.3},
        2 => {0, 0, 0, 0},
        3 => {0, 150, 10, 0.1},
        4 => {0, 0, 0, 0},
        5 => {0, 0, 0, 0},
        6 => {244, 150, 10, 0.1},
        7 => {0, 0, 0, 0},
        8 => {0, 0, 0, 0}
      }

  """
  @spec dump() :: led_array()
  def dump do
    Agent.get(__MODULE__, fn state -> state end)
  end

  @doc """
  Turn off all LEDs
  """
  @spec clear() :: :ok
  def clear do
    Agent.update(__MODULE__, fn _state ->
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
    end)
    show()
  end

  @doc """
  Write the led information to the Blinkt and turn
  on the wanted LEDs with the specified colours and
  brightnesses
  """
  @spec show() :: :ok
  def show do
    # Loops through every LED stored in the agent
    # LED-array and write the bytes

    # Brightness is peculiar and involves multiplying
    # the wanted brightness (0.0 - 1.0) with 31.0, truncating
    # it to an integer, and bitwise ANDing it with 0b11111
    # and bitwise ORing 0b11100000 with THAT and
    # writing the result to the GPIO pin

    # For colours, simply write the byte value (0-255)
    # to the pin

    # First we need to signal the Blinkt we're going
    # to write some LED data to it
    start_of_write()
    for led <- 1..8 do
      {r, g, b, l} = get_led(led)

      # This brightness value is really strange, but it's
      # nicked straight from the official Python library
      brightness = Kernel.trunc(31.0 * l) &&& 0b11111
      _write_byte(0b11100000 ||| brightness)

      _write_byte(b)
      _write_byte(g)
      _write_byte(r)
    end

    end_of_write()
    :ok
  end

  defp start_of_write do
    # Open both the DAT and CLK pins
    # and set them to write-mode
    {:ok, dat_pin} = GPIO.open(@dat, :output)
    {:ok, clk_pin} = GPIO.open(@clk, :output)
    # Write a 0 to the DAT-pin
    GPIO.write(dat_pin, 0)
    # Pulse the CLK-pin 32 times, this is required
    # by the LEDs
    for _ <- 1..32, do: _pulse_gpio_pin(clk_pin)
    :ok
  end

  defp end_of_write do
    # Open both the DAT and CLK pins
    # and set them to write-mode
    {:ok, dat_pin} = GPIO.open(@dat, :output)
    {:ok, clk_pin} = GPIO.open(@clk, :output)
    GPIO.write(dat_pin, 0)
    # Pulse the CLK-pin 36 times, this is required
    # by the LEDs
    for _ <- 1..36, do: _pulse_gpio_pin(clk_pin)
    :ok
  end

  # Write a byte to the pin
  #
  # First we convert the byte to a binary
  # representation that we can loop over,
  # and we write those bits one by one to the
  # GPIO-pin
  #
  # eg. the integer 124 is 01111100 in binary,
  # so we write a 0, then 1, then 1, then 1 and so on
  defp _write_byte(byte) do
    # Open both the DAT and CLK pins
    # and set them to write-mode
    {:ok, dat_pin} = GPIO.open(@dat, :output)
    {:ok, clk_pin} = GPIO.open(@clk, :output)

    # Loop over the bits in the byte one by one
    for <<bit::size(1) <- <<byte>> >> do
      _write_bit(bit, dat_pin, clk_pin)
    end
  end

  # Write a single bit to a GPIO-pin
  defp _write_bit(bit, dat_pin, clk_pin) do
    GPIO.write(dat_pin, bit)

    # Sleep for 1ms before pulsing the CLK-pin,
    # and sleep for 1ms after pulsing the CLK-pin.
    # This is needed because in some cases the GPIO
    # hasn't had time to change from low to high or
    # vice versa
    :timer.sleep(1)
    _pulse_gpio_pin(clk_pin)
    :timer.sleep(1)
  end

  # Pulse the pin (turn it on, then off)
  defp _pulse_gpio_pin(p) do
    GPIO.write(p, 1)
    GPIO.write(p, 0)
    :ok
  end

end
