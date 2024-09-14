defmodule LangfordAttractor do
  @a 0.95
  @b 0.7
  @c 0.6
  @d 3.5
  @e 0.25
  @f 0.1

  def simulate(num_points, dt) do
    initial_state = {1.0, 1.0, 1.0}
    states = Stream.iterate(initial_state, &next_state(&1, dt))
    Enum.take(states, num_points)
  end

  defp next_state({x, y, z}, dt) do
    dx = (z - @b) * x - @d * y
    dy = @d * x + (z - @b) * y
    dz = @c + @a * z - z ** 3 / 3 - (x ** 2 + y ** 2) * (1 + @e * z) + @f * z * x ** 3

    {
      x + dx * dt,
      y + dy * dt,
      z + dz * dt
    }
  end

  def plot_tracing_particle(points, num_frames) do
    File.write!("lorenz_data.dat", format_points(points))

    1..num_frames
    |> Task.async_stream(
      fn frame ->
        points_to_plot = div(length(points) * frame, num_frames)

        gnuplot_commands = """
        set term pngcairo size 1920,1080 font "Arial,12" enhanced background rgb 'black'
        set output 'frames/langford_frame_exp_#{String.pad_leading(Integer.to_string(frame), 3, "0")}.png'
        set encoding utf8
        unset border
        unset tics
        unset xlabel
        unset ylabel
        unset zlabel
        unset title
        unset colorbox
        set view 90, 30, 1.2, 1.2
        set samples 10000
        set isosamples 100
        set hidden3d
        set palette defined (0 'grey', 1 'white')
        splot 'lorenz_data.dat' every ::1::#{points_to_plot} with lines lc palette z notitle
        """

        File.write!("plot_commands_#{frame}.gp", gnuplot_commands)
        System.cmd("gnuplot", ["plot_commands_#{frame}.gp"])
        File.rm("plot_commands_#{frame}.gp")
        IO.puts("Generated frame #{frame}/#{num_frames}")
      end,
      max_concurrency: System.schedulers_online() * 2
    )
    |> Stream.run()
  end

  # def plot_tracing_particle(points, num_frames) do
  #   File.write!("lorenz_data.dat", format_points(points))

  #   1..num_frames
  #   |> Enum.each(fn frame ->
  #     points_to_plot = div(length(points) * frame, num_frames)

  #     gnuplot_commands = """
  #     set term pngcairo size 1920,1080 font "Arial,12" enhanced background rgb 'black'
  #     set output 'frames/langford_frame_exp_#{String.pad_leading(Integer.to_string(frame), 3, "0")}.png'
  #     set encoding utf8
  #     unset border
  #     unset tics
  #     unset xlabel
  #     unset ylabel
  #     unset zlabel
  #     unset title
  #     unset colorbox
  #     set view 90, 30, 1.2, 1.2
  #     set samples 10000
  #     set isosamples 100
  #     set hidden3d
  #     set palette defined (0 'grey', 1 'white')
  #     splot 'lorenz_data.dat' every ::1::#{points_to_plot} with lines lc palette z notitle
  #     """

  #     File.write!("plot_commands.gp", gnuplot_commands)
  #     System.cmd("gnuplot", ["plot_commands.gp"])
  #     IO.puts("Generated frame #{frame}/#{num_frames}")
  #   end)
  # end

  defp format_points(points) do
    points
    |> Enum.map(fn {x, y, z} -> "#{x} #{y} #{z}\n" end)
    |> Enum.join()
  end
end

# Usage
# Increased number of points for smoother curve
num_points = 30000
# Smaller time step for more detailed simulation
dt = 0.005
# Increased number of frames for smoother rotation
num_frames = 7200

points = LangfordAttractor.simulate(num_points, dt)
LangfordAttractor.plot_tracing_particle(points, num_frames)

IO.puts("Generated #{num_frames} high-quality frames for rotating Langford attractor animation.")
IO.puts("Use FFmpeg to create a high-quality MP4 with:")

IO.puts(
  "ffmpeg -framerate 30 -i langford_frame_%03d.png -c:v libx264 -preset slow -crf 17 -pix_fmt yuv420p lorenz_rotating_hq.mp4"
)
