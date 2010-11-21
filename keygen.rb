#!/usr/bin/env ruby

# Serial number: N=12 random bytes + M=8 checksum prefixes by H hexbytes each
# Secret: M=8 secret keys
#
# License = P12 C1 C2 C3 C4 C5 C6 C7 C8
# C1 = C(P12)
# C2 = C(P12 + C1)
# C3 = C(P12 + C1 + C2)
# C4 = C(P12 + C1 + C2 + C3)
# C5 = C(P12 + C1 + C2 + C3 + C4)
# C6 = C(P12 + C1 + C2 + C3 + C4 + C5)
# C7 = C(P12 + C1 + C2 + C3 + C4 + C5 + C6)
# C8 = C(P12 + C1 + C2 + C3 + C4 + C5 + C6 + C7)

require 'digest/md5'

N = 12
M = 8
H = 4

# srand(56234837478365823439)
# keys = genrandomkeys(M)
KEYS = %w[
  534271628253969666149
  53868794303198114726
  9491754476354925543641310243
  3501320648431136786206865455
  72578056688
  18797547350062531
  732462
  745543651098770262381351052
]

def main
  if !ARGV[0]
    puts "Usage: #{$0} (serials|test|testvalid|testinvalid) [n]"
    exit
  end

  args = ARGV.dup

  puts send(*args)
end

def genrandomprefix(n = N)  
  rand(10**(n+2)).to_s(16).rjust(n, '0')[0,n]
end

def genrandomkeys(m = M)
  m = m.to_i
  (1..m).map{rand(2**256).to_s(10)[0,rand(50)] }
end

def genpartialchecksum(prefix, key, hexsize = H)
  Digest::MD5.hexdigest(prefix + key)[0, hexsize]
end

def genserial(n = N, keys = KEYS, hexsize = H)
  prefix = genrandomprefix(n)
  keys.inject(prefix) do |license, key|
    license + genpartialchecksum(license, key, hexsize)
  end
end

# this allows to check only a subset of keys to be able to grow further
# keys are reversed! checking from end to start
def checkserial(serial, n, m, keys, hexsize = H)
  required_size = n + m*hexsize
  serial.size == required_size or return false
  prefix = serial
  keys.each do |key|
    newprefix = prefix[0, prefix.length - hexsize]
    partialchecksum = prefix[prefix.length - hexsize, hexsize]
    prefix = newprefix
    partialchecksum == genpartialchecksum(prefix, key, hexsize) or return false
  end
  return true
end



# Command-line interface

def debug
  
  serial = serials(1)[0]
  serial = "5253cba5c617:80b:393:ebb:f40:bb7:19d:ba6:5f2"
  
  puts "serial = #{serial}"
  
  puts "C1 = #{genpartialchecksum('5253cba5c617', KEYS[0], H)}"
  puts "C2 = #{genpartialchecksum('5253cba5c617:80b', KEYS[1], H)}"
  puts "C3 = #{genpartialchecksum('5253cba5c617:80b:393', KEYS[2], H)}"
  
  puts checkserial(serial, N, M, KEYS.reverse, H)
  
  nil
end

def serials(n = 1)
  n = n.to_i
  srand
  (1..n).map { genserial(N, KEYS, H) }
end

def test
  testvalid + ["--"] + testinvalid
end

def testvalid(n = 10)
  n = n.to_i
  serials(n).map do |serial|
    serial + "\t" + checkserial(serial, N, M, KEYS.reverse[0,2], H).inspect + "\t" + checkserial(serial, N, M, KEYS.reverse, H).inspect
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
  
  validkey = "5990f4706a9482a67416629cb036dde1b3f6deac5c2c"
  (0..(validkey.length-1)).each do |i|
    k = validkey.dup
    k[i, 1] = "X"
    invalid_serials << k
  end

  ["#{invalid_serials.size} invalid serials:"] +
  invalid_serials.map do |serial|
    serial + "\t" +checkserial(serial, N, M, KEYS.reverse[0,2], H).inspect
  end
end

main
