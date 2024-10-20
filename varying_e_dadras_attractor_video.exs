defmodule VaryingDadrasAttractor do
  @a 3
  @b 2.7
  @c 1.7
  @d 2
  # @e 9

  def simulate(num_points, dt, e) do
    initial_state = {1.0, 1.0, 1.0}
    states = Stream.iterate(initial_state, &next_state(&1, dt, e))
    Enum.take(states, num_points)
  end

  defp next_state({x, y, z}, dt, e) do
    dx = y - @a * x + @b * y * z
    dy = @c * y - x * z + z
    dz = @d * x * y - e * z

    {
      x + dx * dt,
      y + dy * dt,
      z + dz * dt
    }
  end

  # def plot_varying_c(num_points, dt) do
  #   c_values = generate_complex_c_sequence()

  #   c_values
  #   |> Enum.with_index(1)
  #   |> Enum.each(fn {c, frame} ->
  #     points = simulate(num_points, dt, c)
  #     plot_frame(points, frame, c, length(c_values))
  #   end)
  # end

  def plot_varying_c(num_points, dt) do
    c_values = generate_complex_c_sequence()

    c_values
    |> Enum.with_index(1)
    |> Task.async_stream(
      fn {c, frame} ->
        points = simulate(num_points, dt, c) ++ simulate(num_points, dt, 0.3)
        plot_frame(points, frame, c, length(c_values))
      end,
      ordered: false,
      max_concurrency: System.schedulers_online()
    )
    |> Stream.run()
  end

  def nround(num), do: Float.round(num, 5)

  def generate_complex_c_sequence do
    up = generate_sequence(17.50, 17.55, 0.01)
    # up_to_097 = generate_sequence(0.881, 0.97, 0.001)
    # down_to_088 = generate_sequence(0.969, 0.88, -0.001)
    # down = generate_sequence(0.2482, 0.240, -1.0e-5)

    # up ++ down
    up
  end

  defp generate_sequence(start, stop, step) do
    Stream.iterate(start, &(&1 + step))
    |> Stream.take_while(fn x ->
      if step > 0, do: x <= stop, else: x >= stop
    end)
    |> Enum.map(&nround(&1))
  end

  def plot_frame(points, frame, c, total_frames) do
    File.write!("/tmp/lorenz_data_#{frame}.dat", format_points(points))

    # Calculate the current rotation angle
    # rot_x = 360 * (frame - 1) / (total_frames - 1)
    rot_x = 180.0
    # rot_z = 360 * (frame - 1) / (total_frames - 1)
    rot_z = 180.0

    # zoom out 0.5
    # zoom_factor = 1.0 - (0.5 * (frame - 1) / (total_frames - 1))

    # zoom in 5x
    # zoom_factor = 1.0 + (5.0 * (frame - 1)) / (total_frames - 1)

    # sine wave zoom
    # Maximum zoom factor
    # max_zoom = 5.0
    # progress = (frame - 1) / (total_frames - 1)
    # zoom_factor = 1.0 + (max_zoom - 1) * :math.sin(:math.pi() * progress)

    zoom_factor = 1.0

    gnuplot_commands = """
    set term pngcairo size 1920,1080 font "Arial,12" enhanced background rgb 'black'
    set output 'frames/test_#{String.pad_leading(Integer.to_string(frame), 3, "0")}.png'
    set encoding utf8
    unset border
    unset tics
    unset xlabel
    unset ylabel
    unset zlabel
    unset title
    set title 'd = #{c}' textcolor rgb 'white' font 'Arial,20'
    set view #{rot_x}, #{rot_z}, #{zoom_factor}, #{zoom_factor}
    set samples 10000
    set isosamples 100
    set hidden3d
    splot '/tmp/lorenz_data_#{frame}.dat' every ::950::#{-length(points)} with lines lc rgb '#FF5733' lw 2.5 notitle
    """

    File.write!("/tmp/plot_commands_#{frame}.gp", gnuplot_commands)
    System.cmd("gnuplot", ["/tmp/plot_commands_#{frame}.gp"])
    File.rm("/tmp/lorenz_data_#{frame}.dat")
    File.rm("/tmp/plot_commands_#{frame}.gp")

    IO.puts(
      "Generated frame #{frame}/#{total_frames} (c = #{nround(c)}, rot_x = #{nround(rot_x)})"
    )
  end

  defp format_points(points) do
    points
    |> Enum.map(fn {x, y, z} -> "#{x} #{y} #{z}\n" end)
    |> Enum.join()
  end
end

# Usage
num_points = 1000
dt = 0.005

VaryingDadrasAttractor.plot_varying_c(num_points, dt)

total_frames = length(VaryingDadrasAttractor.generate_complex_c_sequence())
IO.puts("Generated #{total_frames} high-quality frames for rotating Dadras attractor animation.")
IO.puts("Use FFmpeg to create a high-quality MP4 with:")

IO.puts(
  "ffmpeg -framerate 30 -i dadras_frame_%03d.png -c:v libx264 -preset slow -crf 17 -pix_fmt yuv420p lorenz_rotating_hq.mp4"
)
