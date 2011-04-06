#!/usr/bin/env ruby

files = Dir.glob("Classes/**/*.{h,m}")

m_files = files.find_all{|f| f =~ /\.m$/}

m_files.each do |m_file|
  contents = File.read(m_file)
  
  # 1. Identify all the cases where dealloc uses a setter when setter exists
  if contents =~ /-\s*\(void\)\s*dealloc\s+(.*)\[super\s*dealloc\]/mi
    $1.scan(/self.(\w+)\s*=/).each do |varName|
      setterNameRegexp = %r{\)\s*set#{varName.to_s.capitalize}:\s*\(}
      if contents[setterNameRegexp]
        puts %{#{m_file}: property '#{varName}' is used in dealloc where custom setter is defined}
      end
    end
  end
  
  
  
end

