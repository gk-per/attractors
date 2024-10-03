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

    # Define transitions as {frame, interval} tuples
    transitions = [
      {1, 24},
      {769, 96},
      {2305, 24},
      {2689, 96},
      {3073, 12},
      {3265, 96},
      {4417, 24},
      {4801, 96}
      # Add more transitions here as needed, e.g.:
      # {1537, 48},
      # {2305, 72},
    ]

    1..num_frames
    |> Task.async_stream(
      fn frame ->
        angle = rem(360 * frame, 447 * 360) / 447
        points_to_plot = div(length(points) * frame, num_frames)

        color = get_color_for_frame(frame, transitions)

        gnuplot_commands = """
        set term pngcairo size 1920,1080 font "Arial,12" enhanced background rgb 'black'
        set output 'frames/woohaa_#{String.pad_leading(Integer.to_string(frame), 3, "0")}.png'
        set encoding utf8
        unset border
        unset tics
        unset xlabel
        unset ylabel
        unset zlabel
        unset title
        unset colorbox
        set view 90, #{angle}, 1.2, 1.2
        set samples 10000
        set isosamples 100
        set hidden3d
        set palette defined (0 '#{color}', 1 '#{color}')
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

  defp get_color_for_frame(frame, transitions) do
    {start_frame, interval, color_offset} = get_current_transition(frame, transitions)
    color_index = div(frame - start_frame, interval) + color_offset
    :rand.seed(:exsss, {color_index, 0, 0})
    random_color()
  end

  defp get_current_transition(frame, transitions) do
    {start_frame, interval, color_offset} =
      Enum.reduce_while(transitions, {1, 24, 0}, fn {transition_frame, new_interval},
                                                    {prev_frame, prev_interval, prev_offset} ->
        if frame < transition_frame do
          {:halt, {prev_frame, prev_interval, prev_offset}}
        else
          new_offset = prev_offset + div(transition_frame - prev_frame, prev_interval)
          {:cont, {transition_frame, new_interval, new_offset}}
        end
      end)

    {start_frame, interval, color_offset}
  end

  defp random_color do
    code =
      for(_ <- 1..3, do: Integer.to_string(:rand.uniform(255), 16) |> String.pad_leading(2, "0"))
      |> Enum.join()

    "#" <> code
  end

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
# 5664
num_frames = 5664

points = LangfordAttractor.simulate(num_points, dt)
LangfordAttractor.plot_tracing_particle(points, num_frames)

IO.puts("Generated #{num_frames} high-quality frames for rotating Langford attractor animation.")
IO.puts("Use FFmpeg to create a high-quality MP4 with:")

IO.puts(
  "ffmpeg -framerate 30 -i langford_frame_%03d.png -c:v libx264 -preset slow -crf 17 -pix_fmt yuv420p lorenz_rotating_hq.mp4"
)
