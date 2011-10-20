#!/usr/bin/env ruby

require 'fileutils'

loop do
  
  filename = "#{rand(20)}.txt"
  
  op = rand(3)
  
  if op == 0
    `git rm -rf #{filename}`
  elsif op == 1
    File.open(filename, "w"){|f| f.write("#{rand(10000000)}")}
  else
    `git stage #{filename}`
  end
  
  sleep(0.01*rand(10))
  
end
