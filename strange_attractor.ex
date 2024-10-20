defmodule StrangeAttractor do
  # Define your attractor parameters here
  @a 1.0
  @b 1.0
  @c 1.0
  # Add more parameters as needed

  def simulate(num_points, dt) do
    initial_state = {1.0, 1.0, 1.0}
    states = Stream.iterate(initial_state, &next_state(&1, dt))
    Enum.take(states, num_points)
  end

  defp next_state({x, y, z}, dt) do
    # Define your attractor equations here
    dx = 0 # Replace with your dx equation
    dy = 0 # Replace with your dy equation
    dz = 0 # Replace with your dz equation

    {
      x + dx * dt,
      y + dy * dt,
      z + dz * dt
    }
  end

  def plot_rotating_frames(points, num_frames) do
    File.write!("attractor_data.dat", format_points(points))

    1..num_frames
    |> Task.async_stream(
      fn frame ->
        angle = 360 * frame / num_frames
        gnuplot_commands = """
        set term pngcairo size 1920,1080 font "Arial,12" enhanced background rgb 'black'
        set output 'frames/attractor_frame_#{String.pad_leading(Integer.to_string(frame), 3, "0")}.png'
        set encoding utf8
        unset border
        unset tics
        unset xlabel
        unset ylabel
        unset zlabel
        unset title
        set view #{angle}, 0, 1.2, 1.2
        set samples 10000
        set isosamples 100
        set hidden3d
        splot 'attractor_data.dat' with lines lc rgb '#f1c232' lw 1.5 notitle
        """

        File.write!("plot_commands_#{frame}.gp", gnuplot_commands)
        System.cmd("gnuplot", ["plot_commands_#{frame}.gp"])
        File.rm("plot_commands_#{frame}.gp")
        IO.puts("Generated frame #{frame}/#{num_frames}")
      end,
      max_concurrency: System.schedulers_online()
    )
    |> Stream.run()
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
num_frames = 360

points = StrangeAttractor.simulate(num_points, dt)
StrangeAttractor.plot_rotating_frames(points, num_frames)

IO.puts("Generated #{num_frames} frames for the strange attractor animation.")
IO.puts("Use FFmpeg to create a high-quality MP4 with:")
IO.puts("ffmpeg -framerate 30 -i frames/attractor_frame_%03d.png -c:v libx264 -preset slow -crf 17 -pix_fmt yuv420p strange_attractor.mp4")
