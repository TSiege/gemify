module Buildable
  
  module ClassMethods

  end

  module InstanceMethods 

    def build_info_rb
      info_name = File.join(self.gemfiles_dir, 'info.rb')
      info = File.new(info_name, "w")
      info.puts(<<-EOT)

module #{gem_name_constant}

  class Info

    def initialize(data)
      data.each do |d|
        unless d.length == 0
          key, value = d.first
          method_name = key
          instance_variable_set("@" + method_name, value)
          define_singleton_method(key) {instance_variable_get("@" + key)} 
        end  
      end  
    end

  end

end  

    EOT

    info.close
    end

    def build_model_rb
      module_name = File.join(self.gemfiles_dir, "#{self.gem_name_snake_case}.rb")
      module_file = File.new(module_name, "w")
      module_file.puts(<<-EOT)

module #{gem_name_constant}
  
  class Magic

    attr_accessor :source, :doc  

    def initialize
      @source = "#{self.target_website}"
    end

    def call
      @doc = Nokogiri::HTML(open(self.source))
      
      result = #{self.method_names_and_node_paths}.collect do |v| 
        set_value(v)
      end
      
      #{self.gem_name_constant}::Info.new(result)
    end

    private

    def set_value(hash)
      key, value = hash.first
      result = get_data_by(key, value)
      if result.empty?
        result = get_data_by(key, strip_tbody(value))
      end
      {key => result}
    end

    def get_data_by(method_name, path)
      method_type_hash = #{self.method_types_by_name}
      if method_type_hash[method_name] == "Text"
        self.doc.xpath(path).text.strip
      elsif method_type_hash[method_name] == "Links"
        self.doc.xpath(path).attr('href').text
      elsif method_type_hash[method_name] == "Media"
        self.doc.xpath(path).attr('src').text
      end
    end

    def strip_tbody(path)
      path.gsub(/tbody\[.\]/,"") if !path.nil?
    end

  end

end

    EOT
    module_file.close
    end

    def build_runner 
      bin_name = File.join(self.bin_dir, self.gem_name_snake_case)
      bin = File.new(bin_name, "w")
      bin.puts(<<-EOT)

#!/usr/bin/env ruby

require '#{self.gem_name_snake_case}'

data = #{self.gem_name_constant}::Magic.new.call

data.instance_variables.each do |v|
  method = v.to_s.gsub("@", "")
  method_name = method.gsub("_", " ")
  puts method_name + ": " + data.send(method)
end

      EOT
      bin.close

    end

    def build_gitignore
      # Create .gitignore
      gitignore_name = File.join(@tmpdir, '.gitignore')
      gitignore = File.new(gitignore_name, "w")
      gitignore.puts(<<-EOT)

*.rbc
.bundle
.config
.yardoc
Gemfile.lock
InstalledFiles
_yardoc
coverage
doc/
lib/bundler/man
pkg
rdoc
spec/reports
#{self.gem_name_snake_case}/tmp
#{self.gem_name_snake_case}/version_tmp
tmp

      EOT
      gitignore.close

    end

    def build_gemfile
      # Create Gemfile
      gemfile_name = File.join(@tmpdir, 'Gemfile')
      gemfile = File.new(gemfile_name, "w")
      gemfile.puts(<<-EOT)

source 'https://rubygems.org'

# Specify your gem's dependencies in #{self.gem_name_snake_case}.gemspec
gemspec

      EOT
      gemfile.close

    end

    def build_license 
      # Create License.txt
      license_name = File.join(@tmpdir, 'License.txt')
      license = File.new(license_name, "w")
      license.puts(<<-EOT)

source 'https://rubygems.org'

Copyright (c) 2014 #{self.author}

MIT License

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
"Software"), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

      EOT
      license.close


    end

    def build_rakefile
      # Create Rakefile
      rakefile_name = File.join(@tmpdir, 'Rakefile')
      rakefile = File.new(rakefile_name, "w")
      rakefile.puts(<<-EOT)

require "bundler/gem_tasks"

      EOT
      rakefile.close

    end

    def build_readme
      # Create README.md
      readme_name = File.join(@tmpdir, 'README.md')
      readme = File.new(readme_name, "w")
      readme.puts(<<-EOT)

# #{self.gem_name}

#{self.description}

## Installation

Clone #{self.gem_name_snake_case}'s git repository and install it as a gem.

    $ git clone #{@repo.html_url}.git

    $ cd #{@repo.name}

    $ gem install #{self.gem_name_snake_case}

## Command Line Usage

Use #{self.gem_name_snake_case} in your command line to print out the data whenever you want.

    $ #{self.gem_name_snake_case}

## Ruby Usage

Require #{self.gem_name_snake_case} in your app to return an object with the data included. 

    $ require '#{self.gem_name_snake_case}'

Alternatively, require it directly from Github. Don't forget to bundle to add it to your Gemfile.lock.

    $ gem '#{self.gem_name_snake_case}', :git => '#{self.repo.git_url}'

    $ bundle

Instantiate an instance of #{self.gem_name_snake_case.titleize} to use it in your Ruby app.

    $ #{self.gem_name_snake_case.titleize.gsub(" ", "")}::Magic.new.call

Save that instance in a variable and call any of your defined methods (#{self.method_names.join(', ')}) on it.

#{self.gem_name} was cut with love, by [Gem It](http://gemit.us/).

      EOT
      readme.close
    end

    def build_gemspec 
      # Create #{gem_name_snake_case}.gemspec
      gemspec_name = File.join(@tmpdir, "#{self.gem_name_snake_case}.gemspec")
      gemspec = File.new(gemspec_name, "w")
      gemspec.puts(<<-EOT)

# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require '#{self.gem_name_snake_case}/version'

Gem::Specification.new do |spec|
  spec.name          = "#{self.gem_name_snake_case}"
  spec.version       = #{self.gem_name_constant}::VERSION
  spec.authors       = ["#{self.author}"]
  spec.email         = ["#{self.author_email}"]
  spec.summary       = "#{self.description}"
  spec.description   = %q{I thought this was optional}
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = Dir['{bin/*,lib/**/*}'] +
                        %w(#{self.gem_name_snake_case}.gemspec Rakefile README.md) 
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.5"
  spec.add_development_dependency "rake", "~> 2.2"
  spec.add_development_dependency "nokogiri", "~> 2.2"

end

      EOT
      gemspec.close

    end

    def build_env
      # Create lib/gem.rb
      gem_name_snake_case = File.join(self.lib_dir, "#{self.gem_name_snake_case}.rb")
      gem = File.new(gem_name_snake_case, "w")
      gem.puts(<<-EOT)

require "open-uri"
require "nokogiri"
Dir[File.dirname(__FILE__) + '/#{self.gem_name_snake_case}/*.rb'].each do |file|
  require file
end

      EOT
      gem.close
    end  

    def build_version
      # Create lib/gem/version.rb
      version_name = File.join(self.gemfiles_dir, 'version.rb')
      version = File.new(version_name, "w")
      version.puts(<<-EOT)

module #{self.gem_name_constant}
  VERSION = "0.0.1"
end

      EOT
      version.close

    end
  end
end