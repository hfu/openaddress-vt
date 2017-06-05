require 'sqlite3'
require 'sequel'
require 'json'
require 'fileutils'
require 'zlib'
require 'stringio'

0.upto(12) {|z|
  dir = "#{z}"
  FileUtils.rm_r(dir) if File.directory?(dir)
}
db = Sequel.sqlite("openaddress-vt.mbtiles")
md = {}
db[:metadata].all.each {|pair|
  key = pair[:name]
  value = pair[:value]
  next unless %w{minzoom maxzoom center bounds}.include?(key)
  value = value.to_i if %w{minzoom maxzoom}.include?(key)
  value = value.split(',').map{|v| v.to_f} if %w{center bounds}.include?(key)
  md[key] = value
}
File.write("metadata.json", JSON::dump(md))
count = 0
db[:tiles].each {|r|
  z = r[:zoom_level]
  x = r[:tile_column]
  y = (1 << r[:zoom_level]) - r[:tile_row] - 1
  data = r[:tile_data]
  dir = "#{z}/#{x}"
  FileUtils::mkdir_p(dir) unless File.directory?(dir)
  File.open("#{dir}/#{y}.mvt", 'w') {|w|
    w.print Zlib::GzipReader.new(StringIO.new(data)).read
    count += 1
  }
}
print "wrote #{count} tiles.\n"
