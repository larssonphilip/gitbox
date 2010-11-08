#!/usr/bin/env ruby

# the license number:
# - a number
# - easy to generate
# - verifiable by <=N rules

# L = R*a*b*c mod 2**64
# L - license number
# R - random number
# a - prime number
# b - prime number
# c - prime number

# Generated number should be dividable by a*b*c, but the verification could be progressive:
# a, b, c, ab, ac, bc, abc


#p rand(2**64).to_s(16)
puts [[576437832740,367432849].pack("Q2")].pack("H*")
