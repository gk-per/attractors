defmodule LorenzAttractor do
  @doc """
  Simulate the Lorenz attractor and create an image file showing the attractor.
  """
  @sigma 10
  @rho 28
  @beta 8/3

  def simulate(num_points, dt) do
    initial_state = {1.0, 1.0, 1.0}
    states = Stream.iterate(initial_state, &next_state(&1, dt))
    Enum.take(states, num_points)
  end

  defp next_state({x, y, z}, dt) do
    dx = @sigma * (y - x)
    dy = x * (@rho - z) - y
    dz = x * y - @beta * z

    {
      x + dx * dt,
      y + dy * dt,
      z + dz * dt
    }
  end

  def plot(points) do
    File.write!("lorenz_data.dat", format_points(points))

    gnuplot_commands = """
    set term png
    set output 'lorenz_attractor.png'
    set title 'Lorenz Attractor'
    set xlabel 'X'
    set ylabel 'Y'
    set zlabel 'Z'
    splot 'lorenz_data.dat' with lines notitle
    """

    File.write!("plot_commands.gp", gnuplot_commands)
    System.cmd("gnuplot", ["plot_commands.gp"])
  end

  defp format_points(points) do
    points
    |> Enum.map(fn {x, y, z} -> "#{x} #{y} #{z}\n" end)
    |> Enum.join()
  end
end

# Usage
num_points = 10000
dt = 0.01

LorenzAttractor.simulate(num_points, dt)
|> LorenzAttractor.plot()

IO.puts("Lorenz attractor plot saved as 'lorenz_attractor.png'")
