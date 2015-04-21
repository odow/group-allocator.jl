using Morsel
using HttpCommon
using DataFrames

cd(ARGS[1])

include("model.jl")

app = Morsel.app()

function build_index(tmp_fn::String, warning::Bool)
  index = readall("files/index.html")
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

# =================================
# Hack to get file server running
path_in_dir(p::String, d::String) = length(p) > length(d) && noslash(p[1:length(d)]) == noslash(d)
noslash(x::String) = replace(replace(x, "/", ""), "\\", "")
get(app, "/files/<folder>/<filename>") do req, res
  root = "files"
  folder = req.params[:folder]
  filename = req.params[:filename]
  req_resource = folder * "/" * filename

  path = normpath(root, req_resource)
  # protect against dir-escaping
  if path_in_dir(path, root) && isfile(path)
    r = HttpCommon.FileResponse(path)
    if folder == "downloads"
      rm(path)
    end
    return r
  end
end
# =================================

post(app, "/group-allocator") do req, res
  tl = parsefloat(req.state[:data]["timelimit"])
  fn = string(req.state[:data]["input_filename"])
  ng = parseint(req.state[:data]["ngroups"])
  vars = Array(String, 0)
  for k in keys(req.state[:data])
    if contains(k, "var_") && req.state[:data][k] == "on"
      push!(vars, k)
    end
  end
  println("Timelimit: " * string(tl) * " N: " * string(ng) * " Filename: " * fn)
  warning = false
  tmp_fn = ""

  try
    df = PartitionModel.Solve("files/uploads/" * fn, ng, tl, vars)
    tmp_fn = "files/downloads/" * randstring(20) * ".csv"
    writetable(tmp_fn, df)
  catch
    println("Unable to solve model")
    warning = true
  end

  try
    rm("files/uploads/" * fn)
  catch
  end

  return build_index(tmp_fn, warning)
end

getpid

post(app, "/") do req, res
  f = open(string("files/uploads/", req.http_req.headers["X_FILENAME"]), "w")
  try
    write(f, req.http_req.data)
  catch
    println("bad file")
  end
  close(f)
  build_index()
end

start(app, 8080)
