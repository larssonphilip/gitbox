#!/usr/bin/env ruby

puts "First line"
STDOUT.flush
sleep 2.0
puts "Second line"
STDOUT.flush
sleep 2.0

puts "Username:"
STDOUT.flush
username = gets
puts "Password:"
STDOUT.flush
password = gets

puts "Your name is #{username.to_s.strip} and password is #{password.to_s.strip}"
