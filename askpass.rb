#!/usr/bin/ruby
#!/usr/bin/env ruby

def main
  title = ENV["MACOS_ASKPASS_TITLE"]
  title = "SSH" if title.to_s.strip == ""
  message = ARGV.join(" ").to_s.strip
  
  if message =~ /\(?yes\/no\)?\??$/
    message = message.gsub(/\s*\(?yes\/no\)?\??/, "?")
    result = yes_no_prompt(title, message)
  else
    result = password_prompt(title, message)
  end
  
  if result == ""
    exit 1
  else
    puts result
    exit 0
  end
end

def password_prompt(title, message)
  dialog = %{display dialog #{double_quote(message)} default answer "" with title #{double_quote(title)}  with icon caution with hidden answer} 
  
  result = `osascript -e 'tell application "Finder"' -e "activate"  -e #{double_quote(dialog)} -e 'end tell'`.to_s
  return result.gsub(/, button returned:.*/mi, "").gsub(/.*text returned:/,"").strip
end

def yes_no_prompt(title, message)
  dialog = %{display dialog #{double_quote(message)} buttons {"No", "Yes"} default button 2 with title #{double_quote(title)} with icon caution} 
  
  result = `osascript -e 'tell application "Finder"' -e "activate"  -e #{double_quote(dialog)} -e 'end tell'`.to_s
  
  if result =~ /returned:Yes/i
    return 'yes'
  else
    return 'no'
  end
end

def double_quote(s)
  '"' + s.to_s.gsub('\\', '\\\\').gsub('"', '\\"') + '"'
end

main
