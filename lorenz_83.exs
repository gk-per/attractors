defmodule StrangeAttractor.Lorenz83 do
  # Define your attractor parameters here
  @a 0.95
  @b 7.91
  @f 4.83
  @g 4.66
  # Add more parameters as needed

  def simulate(num_points, dt) do
    initial_state = {1.0, 1.0, 1.0}
    states = Stream.iterate(initial_state, &next_state(&1, dt))
    Enum.take(states, num_points)
  end

  defp next_state({x, y, z}, dt) do
    # Define your attractor equations here
    dx = -@a * x - y ** 2 - z ** 2 + @a * @f
    dy = -y + x * y - @b * x * z + @g
    dz = -z + @b * x * y + x * z

    {
      x + dx * dt,
      y + dy * dt,
      z + dz * dt
    }
  end

  def plot_rotating_frames(points, num_frames) do
    File.write!("tmp/attractor_data.dat", format_points(points))

    1..num_frames
    |> Task.async_stream(
      fn frame ->
        # Calculate zoom factor
        zoom =
          if frame <= num_frames / 2 do
            # Zoom in for the first half
            1.25 + 9.75 * frame / (num_frames / 2)
          else
            # Zoom out for the second half
            10 - 9.75 * (frame - num_frames / 2) / (num_frames / 2)
          end

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
        set view #{angle}, #{angle}, #{zoom}, #{zoom}
        set samples 10000
        set isosamples 100
        set hidden3d
        splot 'tmp/attractor_data.dat' with lines lc rgb '#f1c232' lw 1.5 notitle
        """

        File.write!("tmp/plot_commands_#{frame}.gp", gnuplot_commands)
        System.cmd("gnuplot", ["tmp/plot_commands_#{frame}.gp"])
        File.rm("tmp/plot_commands_#{frame}.gp")
        IO.puts("Generated frame #{frame}/#{num_frames}")
      end,
      max_concurrency: System.schedulers_online()
    )
    |> Stream.run()
  end

  # def plot_rotating_frames(points, num_frames) do
  #   File.write!("tmp/attractor_data.dat", format_points(points))

  #   # Calculate the bounding box of the attractor
  #   {min_point, max_point} = Enum.min_max_by(points, fn {x, y, z} -> x + y + z end)
  #   {min_x, min_y, min_z} = min_point
  #   {max_x, max_y, max_z} = max_point

  #   # Calculate the range for each dimension
  #   x_range = max_x - min_x
  #   y_range = max_y - min_y
  #   z_range = max_z - min_z

  #   # Calculate scaling factors for 16:9 aspect ratio
  #   horizontal_scale = 2.6 * Enum.max([x_range, z_range])  # 16:10 ratio for horizontal
  #   vertical_scale = Enum.max([y_range, z_range])

  #   # Calculate the center of the attractor
  #   center_x = (max_x + min_x) / 2
  #   center_y = (max_y + min_y) / 2
  #   center_z = (max_z + min_z) / 2

  #   1..num_frames
  #   |> Task.async_stream(
  #     fn frame ->
  #       angle = 2 * :math.pi() * frame / num_frames
  #       gnuplot_commands = """
  #       set term pngcairo size 1920,1080 font "Arial,12" enhanced background rgb 'black'
  #       set output 'frames/attractor_frame_#{String.pad_leading(Integer.to_string(frame), 3, "0")}.png'
  #       set encoding utf8
  #       unset border
  #       unset tics
  #       unset xlabel
  #       unset ylabel
  #       unset zlabel
  #       unset title
  #       set view 90,0
  #       set samples 10000
  #       set isosamples 100
  #       set hidden3d
  #       set parametric
  #       set xrange [#{center_x - horizontal_scale/2}:#{center_x + horizontal_scale/2}]
  #       set yrange [#{center_y - vertical_scale/2}:#{center_y + vertical_scale/2}]
  #       set zrange [#{center_z - horizontal_scale/2}:#{center_z + horizontal_scale/2}]
  #       # Combine 90-degree z-rotation with y-rotation
  #       r11(x,y,z) = cos(#{angle})
  #       r12(x,y,z) = sin(#{angle})
  #       r13(x,y,z) = 0
  #       r21(x,y,z) = -sin(#{angle})
  #       r22(x,y,z) = cos(#{angle})
  #       r23(x,y,z) = 0
  #       r31(x,y,z) = 0
  #       r32(x,y,z) = 0
  #       r33(x,y,z) = 1
  #       x_rot(x,y,z) = r11(x,y,z)*y + r12(x,y,z)*z + r13(x,y,z)*x
  #       y_rot(x,y,z) = r21(x,y,z)*y + r22(x,y,z)*z + r23(x,y,z)*x
  #       z_rot(x,y,z) = r31(x,y,z)*y + r32(x,y,z)*z + r33(x,y,z)*x
  #       splot 'tmp/attractor_data.dat' using (x_rot($1,$2,$3)):(y_rot($1,$2,$3)):(z_rot($1,$2,$3)) with lines lc rgb '#f1c232' lw 1.5 notitle
  #       """

  #       File.write!("tmp/plot_commands_#{frame}.gp", gnuplot_commands)
  #       System.cmd("gnuplot", ["tmp/plot_commands_#{frame}.gp"])
  #       File.rm("tmp/plot_commands_#{frame}.gp")
  #       IO.puts("Generated frame #{frame}/#{num_frames}")
  #     end,
  #     max_concurrency: System.schedulers_online()
  #   )
  #   |> Stream.run()
  # end

  defp format_points(points) do
    points
    |> Enum.map(fn {x, y, z} -> "#{x} #{y} #{z}\n" end)
    |> Enum.join()
  end
end

# Usage
num_points = 15000
dt = 0.005
num_frames = 3600

points = StrangeAttractor.Lorenz83.simulate(num_points, dt)
StrangeAttractor.Lorenz83.plot_rotating_frames(points, num_frames)

IO.puts("Generated #{num_frames} frames for the strange attractor animation.")
IO.puts("Use FFmpeg to create a high-quality MP4 with:")

IO.puts(
  "ffmpeg -framerate 30 -i frames/attractor_frame_%03d.png -c:v libx264 -preset slow -crf 17 -pix_fmt yuv420p strange_attractor.mp4"
)
