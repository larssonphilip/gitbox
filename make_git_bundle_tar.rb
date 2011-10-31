#!/usr/bin/env ruby

# How to:
# 1. Check out some commit in ./git submodule which you wish to bundle.
# 2. Run this script from its folder.
# It will make new git and install it in ./git.bundle folder, which will be archived in git.bundle.tar and then removed.

require 'fileutils'

def each_git_binary
  Dir.glob("git.bundle/bin/*").each do |path|
  	yield(path)
  end
	Dir.glob("git.bundle/libexec/git-core/*").each do |path|
  	yield(path)
  end
end

prefix = "#{`pwd`.strip}/git.bundle"
FileUtils.mkdir_p(prefix)
system("cd git && make clean && make prefix=#{prefix} all && make prefix=#{prefix} install")

# Codesign git binaries

if ENV['CODESIGN_BUNDLED_BINARIES']
  each_git_binary do |path|
    result = `codesign -d #{path} 2>&1`
    if result["code object is not signed at all"]
      system(%{codesign --verbose --force --sign "3rd Party Mac Developer Application: Oleg Andreev" --entitlements Helper.entitlements #{path}})
    else
      puts "Already signed: #{path}"
      # file is signed or invalid (a shell script or a folder)
    end
  end
end

system("tar -cf git.bundle.tar git.bundle")
system("rm -rf git.bundle")

exit
