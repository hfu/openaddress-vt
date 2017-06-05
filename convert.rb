require 'json'
require 'find'
require 'csv'
SRC_DIR = "/Volumes/GONOIKE/openaddresses/jp"

c = 0
w = File.open('openaddress-vt.ndjson', 'w')
Find.find(SRC_DIR) {|path|
  next if path.include?('summary')
  next unless path.end_with?('csv')
  File.foreach(path) {|l|
    begin
      r = CSV::parse(l)[0]
    rescue
      print $!, "\n"
      next
    end
    next if r[0] == 'LON'
    f = {
      :type => 'Feature',
      :geometry => {
        :type => 'Point',
        :coordinates => [r[0].to_f, r[1].to_f]
      },
      :properties => {
        :number => r[2],
        :street => r[3],
        :unit => r[4],
        :city => r[5],
        :district => r[6],
        :region => r[7],
        :postcode => r[8],
        :file => File.basename(path, '.csv')
      }
    }
    w.print JSON::dump(f), "\n"
    c += 1
    print "." if c % 1000 == 0
  }
}
w.close
system "../tippecanoe/tippecanoe --layer=openaddresses-jp -P -B12 -r1 --maximum-zoom=12 --drop-densest-as-needed -f -o openaddress-vt.mbtiles openaddress-vt.ndjson"
