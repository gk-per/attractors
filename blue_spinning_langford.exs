defmodule LorenzAttractor do
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

  def plot_rotating_frames(points, num_frames) do
    File.write!("lorenz_data.dat", format_points(points))

    1..num_frames
    |> Enum.each(fn frame ->
      angle = 360 * frame / num_frames
      gnuplot_commands = """
      set term pngcairo size 1920,1080 font "Arial,12" enhanced background rgb 'black'
      set output 'frames/lorenz_frame_#{String.pad_leading(Integer.to_string(frame), 3, "0")}.png'
      set encoding utf8
      unset border
      unset tics
      unset xlabel
      unset ylabel
      unset zlabel
      unset title
      set view 60, #{angle}, 1.2, 1.2
      set style line 1 lc rgb '#00FFFF' lw 1.5
      set samples 10000
      set isosamples 100
      set hidden3d
      splot 'lorenz_data.dat' with lines ls 1 notitle
      """

      File.write!("plot_commands.gp", gnuplot_commands)
      System.cmd("gnuplot", ["plot_commands.gp"])
      IO.puts("Generated frame #{frame}/#{num_frames}")
    end)
  end

  defp format_points(points) do
    points
    |> Enum.map(fn {x, y, z} -> "#{x} #{y} #{z}\n" end)
    |> Enum.join()
  end
end

# Usage
num_points = 30000  # Increased number of points for smoother curve
dt = 0.005  # Smaller time step for more detailed simulation
num_frames = 360  # Increased number of frames for smoother rotation

points = LorenzAttractor.simulate(num_points, dt)
LorenzAttractor.plot_rotating_frames(points, num_frames)

IO.puts("Generated #{num_frames} high-quality frames for rotating Lorenz attractor animation.")
IO.puts("Use FFmpeg to create a high-quality MP4 with:")
IO.puts("ffmpeg -framerate 30 -i lorenz_frame_%03d.png -c:v libx264 -preset slow -crf 17 -pix_fmt yuv420p lorenz_rotating_hq.mp4")
