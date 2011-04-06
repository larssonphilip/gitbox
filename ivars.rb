#!/usr/bin/env ruby

files = Dir.glob("Classes/**/*.{h,m}")

m_files = files.find_all{|f| f =~ /\.m$/}

m_files.each do |m_file|
  p File.read(m_file).grep(/@synthesize /)
end

