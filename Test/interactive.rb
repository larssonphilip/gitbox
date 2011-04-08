#!/usr/bin/env ruby

puts "First line"
sleep 2.0
puts "Second line"

sleep 2.0
puts "Username:"
username = gets
puts "Password:"
password = gets

puts "Your name is #{username.to_s.strip} and password is #{password.to_s.strip}"
