#!/usr/bin/env ruby

puts "First line"
sleep 1.0
puts "Second line"
sleep 1.0

puts "Username:"
#STDOUT.flush
username = gets
puts "Password:"
#STDOUT.flush
password = gets

puts "Your name is #{username.to_s.strip} and password is #{password.to_s.strip}"

sleep 1

puts "Finished OK."
