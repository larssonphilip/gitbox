#!/usr/bin/ruby
#!/usr/bin/env ruby

def main
  title = ENV["MACOS_ASKPASS_TITLE"]
  title = "Gitbox SSH" if title.to_s.strip == ""
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

def keychain_service_name_for_string(string)
  string.to_s.gsub(/[^a-z0-9A-Z\,\.]+/," ").gsub(/\s+/," ").strip
end

def password_from_keychain(service)
  pass = `security find-generic-password -gs #{double_quote(service)} 2>&1 >/dev/null | cut -d '"' -f 2`.strip
  return '' if pass =~ /SecKeychainSearchCopyNext:/
  pass
end

def store_password_in_keychain(password, keychain)
  user_name = `$USER`.to_s.strip
  `security add-generic-password -a #{double_quote(user_name)} -s #{double_quote(keychain)} -w #{double_quote(password)} -U`
end

def password_prompt(title, message)
  dialog = %{display dialog #{double_quote(message)} default answer "" with title #{double_quote(title)}  with icon note with hidden answer} 
  
  keychain = keychain_service_name_for_string(title.to_s + ": " + message.to_s)
  password = password_from_keychain(keychain)
  if password.to_s != ""
    return password
  end
  
  result = `osascript -e 'tell application "Gitbox"' -e "activate"  -e #{double_quote(dialog)} -e 'end tell'`.to_s
  password = result.gsub(/, button returned:.*/mi, "").gsub(/.*text returned:/,"").strip
  
  store_password_in_keychain(password, keychain)
  
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

def double_quote(s)
  '"' + s.to_s.gsub('\\', '\\\\').gsub('"', '\\"') + '"'
end

main
