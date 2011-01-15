#!/usr/bin/ruby
#!/usr/bin/env ruby

DEBUG = 0

if DEBUG
  Log = File.open("/Users/oleganza/Desktop/gitbox-askpass.log", "a")
end

def main
  title = ENV["MACOS_ASKPASS_TITLE"]
  if title.to_s.strip == ""
    title = "Gitbox SSH Password"
  end
  message = ARGV.join(" ").to_s.strip
  
  keychain_name = ENV["GITBOX_KEYCHAIN_NAME"]
  if keychain_name.to_s.strip == ""
    keychain_name = keychain_service_name_for_string(title)
  end
  
  read_from_keychain = (ENV["GITBOX_USE_KEYCHAIN_PASSWORD"].to_s != "")

  if DEBUG
    #read_from_keychain = false
  end

  if DEBUG
    Log.puts "----------------------------------------------"
    Log.puts "title = #{title.inspect}"
    Log.puts(message.to_s + "\n\n")
    Log.puts "ASKPASS DEBUG: GITBOX_USE_KEYCHAIN_PASSWORD: " + ENV["GITBOX_USE_KEYCHAIN_PASSWORD"].to_s
  end
  
  if message =~ /\(?yes\/no\)?\??$/
    message = message.gsub(/\s*\(?yes\/no\)?\??/, "?")
    result = yes_no_prompt(title, message)
  else
    result = password_prompt(title, keychain_name, message, :read_from_keychain => read_from_keychain, :write_to_keychain => true)
  end
  
  if result == ""
    exit 1
  else
    puts result
    exit 0
  end
end

def password_prompt(title, keychain_name, message, options = {})
  dialog = %{display dialog #{double_quote(message)} default answer "" with title #{double_quote(title)}  with icon note with hidden answer} 
  
  if options[:read_from_keychain]
    password = password_from_keychain(keychain_name)
    if password.to_s != ""
      return password
    end
  end
  
  result = `osascript -e 'tell application "Gitbox"' -e "activate"  -e #{double_quote(dialog)} -e 'end tell'`.to_s
  password = result.gsub(/, button returned:.*/mi, "").gsub(/.*text returned:/,"").strip
  
  if DEBUG
    #Log.puts "ASKPASS DEBUG: returned password: #{password.inspect}"
  end
  
  if options[:write_to_keychain]
    if password != ""
      store_password_in_keychain(password, keychain_name)
    end
  end
  
  password
end

def yes_no_prompt(title, message)
  dialog = %{display dialog #{double_quote(message)} buttons {"No", "Yes"} default button 2 with title #{double_quote(title)} with icon note} 
  
  result = `osascript -e 'tell application "Gitbox"' -e "activate"  -e #{double_quote(dialog)} -e 'end tell'`.to_s
  
  if result =~ /returned:Yes/i
    return 'yes'
  else
    return 'no'
  end
end


# Keychain utilities


def keychain_service_name_for_string(string)
  string.to_s.gsub(%r{[^a-z0-9A-Z\,\.:/]+}," ").gsub(/\s+/," ").strip
end

def password_from_keychain(service)
  pass = `security find-generic-password -gs #{double_quote(service)} 2>&1 >/dev/null | cut -d '"' -f 2`.strip
  return '' if pass =~ /SecKeychainSearchCopyNext:/
  pass
end

def store_password_in_keychain(password, keychain)
  user_name = `$USER`.to_s.strip
  if DEBUG
    #Log.puts "Storing passwordin keychain: #{password.inspect}"
  end
  `security add-generic-password -a #{double_quote(user_name)} -s #{double_quote(keychain)} -w #{double_quote(password)} -U`
end


# Other utilities


def double_quote(s)
  '"' + s.to_s.gsub('\\', '\\\\').gsub('"', '\\"') + '"'
end

main

if DEBUG
  Log.close
end