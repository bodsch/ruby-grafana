module Grafana

  # namespace for version information
  module Version

    # major part of version
    MAJOR = 1
    # minor part of version
    MINOR = 0
    # tiny part of version
    TINY  = 0
  end

  # Current version of gem.
  VERSION = [Version::MAJOR, Version::MINOR, Version::TINY].compact * '.'

end
