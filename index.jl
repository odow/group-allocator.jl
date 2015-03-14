#
#   Plotting needs
#   https://github.com/FVANCOP/ChartNew.js.git
#
#  In Morsel.js you need to make a change to the line
#      stack = middleware(DefaultHeaders, URLDecoder, CookieDecoder, BodyDecoder, MorselApp)
#  in the function start(app, port).
#   Becomes
#      stack = middleware(DefaultHeaders, URLDecoder, FileServer(pwd()), CookieDecoder, BodyDecoder, MorselApp, NotFound)
#
using Morsel
using DataFrames

include(string(ARGS[1], "/model.jl"))
using PartitionModel

cd(string(ARGS[1], "/html"))

app = Morsel.app()

function getIndexWithCSS()
  if isfile("css/site.min.css")
    index = replace(readall("index.html"), "/*css*/", readall("css/site.min.css"))
  else
    css_files = readdir("css")
    css = ""
    for f in css_files
      css = string(css, readall("css/" * f))
    end
    index = replace(readall("index.html"), "/*css*/", css)
  end
  return index
end

function build_index(tmp_fn::String, warning::Bool)
  index = getIndexWithCSS()
  if tmp_fn != ""
    index = replace(index, "{{output_class}}", "block")
    index = replace(index, "{{not_output_class}}", "none")
    index = replace(index, "{{results_file}}", tmp_fn)
  else
    index = replace(index, "{{not_output_class}}", "block")
    index = replace(index, "{{output_class}}", "none")
  end

  if warning
    index = replace(index, "{{warning}}", "block")
  else
    index = replace(index, "{{warning}}", "none")
  end

  return index
end

build_index(tmp_fn::String) = build_index(tmp_fn, false)

function build_index()
  build_index("", false)
end

get(app, "/") do req, res
  build_index()
end

get(app, "/group-allocator") do req, res
  build_index()
end

get(app, "/downloads/<filename>") do req, res
  println("requesting file")
  fn = "../downloads/" * req.params[:filename]
  if isfile(fn)
    d = readall(fn)
    rm(fn)
    return d
  end
end


post(app, "/group-allocator") do req, res
  tl = parsefloat(req.state[:data]["timelimit"])
  fn = string(req.state[:data]["input_filename"])
  ng = parseint(req.state[:data]["ngroups"])
  println("Timelimit: " * string(tl) * " N: " * string(ng) * " Filename: " * fn)
  warning = false
  tmp_fn = ""

  try
    df = PartitionModel.Solve("uploads/" * fn, ng, tl)
    tmp_fn = "downloads/" * randstring(20) * ".csv"
    println("Writing solution")
    writetable("../" * tmp_fn, df)
  catch
    println("Unable to solve model")
    warning = true
  end

  try
    rm("uploads/" * fn)
  catch
  end

  return build_index(tmp_fn, warning)
end

getpid

post(app, "/") do req, res
  f = open(string("uploads/", req.http_req.headers["X_FILENAME"]), "w")
  try
    write(f, req.http_req.data)
  catch
    println("bad file")
  end
  close(f)
  build_index()
end

start(app, 8080)
