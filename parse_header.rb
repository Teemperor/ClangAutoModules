#!/usr/bin/ruby

modules = Hash.new
File.open("module_header","r").read.each_line do |line|
  # delete "boost/ and parse each line separated by "/""
  sline = line.split(File::SEPARATOR)[1..-1]
  top = sline[0]
  if sline.count == 1 then
    top = top.strip[0..-5]
  end
  # if the hpp file was in toplevel directory
  if !modules[top] then
    modules[top] = Array.new
  end
  modules[top].push(sline)
end

modules.each{|key, array|
  print "module " + key + " {\n"
  array.each do |line|
    print "  module \"" + line.join("__").strip[0..-5] + "\" { header \"" + line.join("/").strip + "\" export * }\n"
  end
  print "}\n"
}
