defmodule VaryingDadrasAttractor do
  # @a 3
  @b 2.7
  @c 1.7
  @d 2
  @e 9

  def simulate(num_points, dt, a) do
    initial_state = {1.0, 1.0, 1.0}
    states = Stream.iterate(initial_state, &next_state(&1, dt, a))
    Enum.take(states, num_points)
  end

  defp next_state({x, y, z}, dt, a) do
    dx = y - a * x + @b * y * z
    dy = @c * y - x * z + z
    dz = @d * x * y - @e * z

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
    |> Task.async_stream(fn {c, frame} ->
      points = simulate(num_points, dt, c)
      plot_frame(points, frame, c, length(c_values))
    end, ordered: false, max_concurrency: System.schedulers_online())
    |> Stream.run()
  end

  def nround(num), do: Float.round(num, 5)

  def generate_complex_c_sequence do
    up = generate_sequence(0.240, 0.2482, 1.0e-5)
    # up_to_097 = generate_sequence(0.881, 0.97, 0.001)
    # down_to_088 = generate_sequence(0.969, 0.88, -0.001)
    down = generate_sequence(0.2482, 0.240, -1.0e-5)

    up ++ down
  end

  defp generate_sequence(start, stop, step) do
    Stream.iterate(start, &(&1 + step))
    |> Stream.take_while(fn x ->
      if step > 0, do: x <= stop, else: x >= stop
    end)
    |> Enum.map(&nround(&1))
  end

  def plot_frame(points, frame, c, total_frames) do
    File.write!("lorenz_data_#{frame}.dat", format_points(points))

      gnuplot_commands = """
      set term pngcairo size 1920,1080 font "Arial,12" enhanced background rgb 'black'
      set output 'frames/test_#{String.pad_leading(Integer.to_string(frame), 3, "0")}.png'
      set encoding utf8
      unset border
      unset tics
      unset xlabel
      unset ylabel
      unset zlabel
      set title "Dadras Attractor (a = #{nround(c)})" textcolor rgb 'white'
      set view 22, 0, 1.2, 1.2
      set samples 10000
      set isosamples 100
      set hidden3d
      splot 'lorenz_data_#{frame}.dat' every ::1000 with lines lc rgb '#cd1c18' lw 2.5 notitle
      """

      File.write!("plot_commands_#{frame}.gp", gnuplot_commands)
      System.cmd("gnuplot", ["plot_commands_#{frame}.gp"])
      File.rm("lorenz_data_#{frame}.dat")
      File.rm("plot_commands_#{frame}.gp")
      IO.puts("Generated frame #{frame}/#{total_frames} (c = #{nround(c)})")
    end

  defp format_points(points) do
    points
    |> Enum.map(fn {x, y, z} -> "#{x} #{y} #{z}\n" end)
    |> Enum.join()
  end
end

# Usage
num_points = 30000
dt = 0.005

VaryingDadrasAttractor.plot_varying_c(num_points, dt)

total_frames = length(VaryingDadrasAttractor.generate_complex_c_sequence())
IO.puts("Generated #{total_frames} high-quality frames for rotating Dadras attractor animation.")
IO.puts("Use FFmpeg to create a high-quality MP4 with:")
IO.puts("ffmpeg -framerate 30 -i dadras_frame_%03d.png -c:v libx264 -preset slow -crf 17 -pix_fmt yuv420p lorenz_rotating_hq.mp4")
