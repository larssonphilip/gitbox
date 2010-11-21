#!/usr/bin/env ruby

# Serial number: N random bytes + M checksum prefixes by H hexbytes each
# Secret: M secret keys

require 'digest/md5'

N = 12
M = 8
H = 4

KEYS = %w[
  2tb8e1irclkbhrsjsdne80kic6j513tdgh2ivuff012mstc544
  1fahqgk8mebj78i9srvdlje5jrhbrmn5p166kcu474q83ausr4
  plcmac8idko953ntbvsiun8u4cff3k5nf7nv7kr40vnt5g21ee
  lbq8o711gesd0s5b1m8g1o919cvfvrt7igjb05lvlkvn220v3g
  1ej44ifp9i1rsl5g8u11oh2rs54emupvfl0cgmgu5g9it91t3h
  17pgkrckcvd80rumvi5vbji6p8gmbth0hi1h1gmsv8hevc6fd8
  ig6dsbuvmg2gubu0e35bbrj95nd8sek7t3vp8o3varucgktcno
  1rjjdnjmv6gaefdocq20if3avrovdv92lheoaairmkviven63t
]

def main
  if !ARGV[0]
    puts "Usage: #{$0} (serials|testvalid|testinvalid) [n]"
    exit
  end

  args = ARGV.dup

  puts send(*args)
end

def genrandomprefix(n)
  rand(10**(n+2)).to_s(16).rjust(n, '0')[0,n]
end

def genrandomkeys(m)
  (1..m).map{rand(2**256).to_s(32)[0,50] }
end

def genpartialchecksum(prefix, key, hexsize)
  Digest::MD5.hexdigest(prefix + key)[0, hexsize].rjust(hexsize, '0')
end

def genfullchecksum(prefix, keys, hexsize)
  keys.map {|key| genpartialchecksum(prefix, key, hexsize) }.join("")
end

def genserial(n, keys, hexsize)
  prefix = genrandomprefix(n)
  prefix + genfullchecksum(prefix, keys, hexsize)
end

# this allows to check only a subset of keys to be able to grow further
def checkserial(serial, n, m, keys, hexsize)
  required_size = n + m*hexsize
  serial.size == required_size or return false
  prefix = serial[0,n]
  fullchecksum = serial[n, required_size - n]
  partialchecksums = fullchecksum.scan(/.{#{hexsize}}/)
  keys.each do |key|
    partialchecksum = partialchecksums.shift
    partialchecksum == genpartialchecksum(prefix, key, hexsize) or return false
  end
  return true
end


# srand(56234837478365823439)
# keys = genrandomkeys(M)

def serials(n = 1)
  n = n.to_i
  srand
  (1..n).map { genserial(N, KEYS, H) }
end

def testvalid(n = 10)
  n = n.to_i
  serials(n).map do |serial|
    serial + "\t" + checkserial(serial, N, M, KEYS[0,2], H).inspect + "\t" + checkserial(serial, N, M, KEYS, H).inspect
  end
end

def testinvalid
  invalid_serials = [
    "",
    "1",
    "12",
    "4a522efb6f17fc55837-ba790890b1a3442ef0414f1d",
    "1c48049d3d1748cf5da64d21d7ef303b92072260e5f8"
  ]

  puts "#{invalid_serials.size} invalid serials:"

  invalid_serials.map do |serial|
    serial + "\t" +checkserial(serial, N, M, KEYS[0,2], H).inspect
  end
end

main
