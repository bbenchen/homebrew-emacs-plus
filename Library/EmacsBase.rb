require_relative "UrlResolver"
require_relative "Icons"

class CopyDownloadStrategy < AbstractFileDownloadStrategy
  def initialize(url, name, version, **meta)
    @cached_location = Pathname.new url
  end
end

class EmacsBase < Formula
  def self.init version
    @@urlResolver = UrlResolver.new(version, ENV["HOMEBREW_EMACS_PLUS_MODE"] || "remote")
  end

  def self.local_patch(name, sha:)
    patch do
      url (@@urlResolver.patch_url name), :using => CopyDownloadStrategy
      sha256 sha
    end
  end

  def self.inject_icon_options
    ICONS_CONFIG.each do |icon, sha|
      option "with-#{icon}-icon", "Using Emacs #{icon} icon"
      next if build.without? "#{icon}-icon"
      resource "#{icon}-icon" do
        url (@@urlResolver.icon_url icon), :using => CopyDownloadStrategy
        sha256 sha
      end
    end
  end

  def inject_path
    ohai "Injecting PATH value to Emacs.app/Contents/Info.plist"
    app = "#{prefix}/Emacs.app"
    plist = "#{app}/Contents/Info.plist"
    path = PATH.new(ORIGINAL_PATHS)

    puts "Patching plist at #{plist} with following PATH value:"
    path.each_entry { |x|
      puts x
    }

    system "/usr/libexec/PlistBuddy -c 'Add :LSEnvironment dict' '#{plist}'"
    system "/usr/libexec/PlistBuddy -c 'Add :LSEnvironment:PATH string' '#{plist}'"
    system "/usr/libexec/PlistBuddy -c 'Set :LSEnvironment:PATH #{path}' '#{plist}'"
    system "/usr/libexec/PlistBuddy -c 'Print :LSEnvironment' '#{plist}'"
    system "touch '#{app}'"
  end

  def print_env
    ohai "Environment"
    ["CC",
     "CXX",
     "OBJC",
     "OBJCXX",
     "CFLAGS",
     "CXXFLAGS",
     "CPPFLAGS",
     "LDFLAGS",
     "SDKROOT",
     "MAKEFLAGS",
     "CMAKE_PREFIX_PATH",
     "CMAKE_FRAMEWORK_PATH",
     "PKG_CONFIG_PATH",
     "PKG_CONFIG_LIBDIR",
     "HOMEBREW_GIT",
     "ACLOCAL_PATH",
     "PATH",
     "CPATH",
    ].each { |key|
      puts "#{key}: #{ENV[key]}"
    }
  end

  def inject_protected_resources_usage_desc
    ohai "Injecting description for protected resources usage"
    app = "#{prefix}/Emacs.app"
    plist = "#{app}/Contents/Info.plist"

    system "/usr/libexec/PlistBuddy -c 'Add NSBluetoothAlwaysUsageDescription string' '#{plist}'"
    system "/usr/libexec/PlistBuddy -c 'Set NSBluetoothAlwaysUsageDescription Emacs requires permission to access the Bluetooth.' '#{plist}'"
    system "/usr/libexec/PlistBuddy -c 'Add NSCameraUsageDescription string' '#{plist}'"
    system "/usr/libexec/PlistBuddy -c 'Set NSCameraUsageDescription Emacs requires permission to access the Camera.' '#{plist}'"
    system "/usr/libexec/PlistBuddy -c 'Add NSMicrophoneUsageDescription string' '#{plist}'"
    system "/usr/libexec/PlistBuddy -c 'Set NSMicrophoneUsageDescription Emacs requires permission to access the Microphone.' '#{plist}'"
    system "/usr/libexec/PlistBuddy -c 'Add NSSpeechRecognitionUsageDescription string' '#{plist}' || true"
    system "/usr/libexec/PlistBuddy -c 'Set NSSpeechRecognitionUsageDescription Emacs requires permission to handle any speech recognition.' '#{plist}' || true"
    system "touch '#{app}'"
  end
end
