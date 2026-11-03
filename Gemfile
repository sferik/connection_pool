source "https://rubygems.org"

gemspec
gem "standard"
gem "benchmark-ips"

group :test do
  gem "maxitest"
  gem "simplecov"
end

group :development do
  # Duel requires Ruby 3.4 or later
  if Gem::Version.new(RUBY_VERSION) >= Gem::Version.new("3.4")
    gem "duel", ">= 0.1.4"
    gem "duel-gvl", ">= 0.1.2"
  end
  gem "stackprof", platforms: :mri
end
