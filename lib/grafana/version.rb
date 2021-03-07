module Grafana

  # namespace for version information
  module Version

    # major part of version
    MAJOR = 1
    # minor part of version
    MINOR = 1
    # tiny part of version
    TINY  = 1
  end

  # Current version of gem.
  VERSION = [Version::MAJOR, Version::MINOR, Version::TINY].compact * '.'

end
