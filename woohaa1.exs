module LangfordAttractor = struct
  let a = 0.95
  let b = 0.7
  let c = 0.6
  let d = 3.5
  let e = 0.25
  let f = 0.1

  type state = float * float * float

  let next_state ((x, y, z) : state) dt =
    let dx = (z -. b) *. x -. d *. y in
    let dy = d *. x +. (z -. b) *. y in
    let dz = c +. a *. z -. z ** 3. /. 3. -. (x ** 2. +. y ** 2.) *. (1. +. e *. z) +. f *. z *. x ** 3. in
    (x +. dx *. dt, y +. dy *. dt, z +. dz *. dt)

  let simulate num_points dt =
    let initial_state = (1.0, 1.0, 1.0) in
    let rec aux n state acc =
      if n = 0 then List.rev acc
      else
        let next = next_state state dt in
        aux (n - 1) next (next :: acc)
    in
    aux num_points initial_state []

  let format_points points =
    let format_point (x, y, z) =
      Printf.sprintf "%f %f %f\n" x y z
    in
    String.concat "" (List.map format_point points)

  let write_data_file points filename =
    let oc = open_out filename in
    output_string oc (format_points points);
    close_out oc

  let generate_gnuplot_commands frame num_frames =
    let angle = float_of_int (360 * frame mod (447 * 360)) /. 447. in
    let color_cycle = 96.0 in
    let color = if float_of_int frame mod (color_cycle *. 2.) < color_cycle then "#0000FF" else "#FF0000" in
    Printf.sprintf "
set term pngcairo size 1920,1080 font \"Arial,12\" enhanced background rgb 'black'
set output 'frames/langford_frame_%03d.png'
set encoding utf8
unset border
unset tics
unset xlabel
unset ylabel
unset zlabel
unset title
unset colorbox
set view 90, %f, 1.2, 1.2
set samples 10000
set isosamples 100
set hidden3d
set palette defined (0 '%s', 1 '%s')
splot 'lorenz_data.dat' with lines lc palette z notitle
" frame angle color color

  let plot_tracing_particle points num_frames =
    write_data_file points "lorenz_data.dat";
    for frame = 1 to num_frames do
      let commands = generate_gnuplot_commands frame num_frames in
      let filename = Printf.sprintf "plot_commands_%d.gp" frame in
      let oc = open_out filename in
      output_string oc commands;
      close_out oc;
      ignore (Sys.command (Printf.sprintf "gnuplot %s" filename));
      Sys.remove filename;
      Printf.printf "Generated frame %d/%d\n" frame num_frames
    done
end

let () =
  let num_points = 30000 in
  let dt = 0.005 in
  let num_frames = 5664 in

  let points = LangfordAttractor.simulate num_points dt in
  LangfordAttractor.plot_tracing_particle points num_frames;

  Printf.printf "Generated %d high-quality frames for rotating Langford attractor animation.\n" num_frames;
  Printf.printf "Use FFmpeg to create a high-quality MP4 with:\n";
  Printf.printf "ffmpeg -framerate 30 -i langford_frame_%%03d.png -c:v libx264 -preset slow -crf 17 -pix_fmt yuv420p lorenz_rotating_hq.mp4\n"
