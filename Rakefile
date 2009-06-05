require 'rubygems'
require 'rake'

bundle_name    = 'WhatJustPlayed'
src_paths      = %w[Classes] # any included projects, add folders here
src_files      = %w[Classes/WhatJustPlayed.m Classes/Snap.m]
req_frameworks = %w[Foundation] # use only frameworks available to both Cocoa + iPhone SDKs
req_libraries  = %w[] # e.g. add sqlite3 for libsqlite3 to be used by linking step

Dir['tasks/**/*.rake'].each { |rake| load rake }

namespace :objc do
  desc 'Compiles all Objective-C bundles for testing'
  task :compile
end

task :compile => 'objc:compile'

# Converts ('-I', ['foo', 'bar'])
# Into: -Ifoo -Ibar
def make_options(flag, items)
  items.map { |item| "#{flag}#{item}" }.join(" ")
end

src_files.each do |file|
  FileUtils.mkdir_p 'build'
  base = file.gsub(/\.m$/,'')
  dot_o = "build/#{File.basename base}.o"
  file dot_o => ["#{base}.m", "#{base}.h"] do
    sh "gcc -c #{base}.m -o #{dot_o} #{make_options '-I', src_paths}"
  end
end

dot_o_files = src_files.map { |file| "build/" + File.basename(file).gsub(/\.m$/,'') + ".o" }

namespace :objc do
  task :compile => "build/bundles/#{bundle_name}.bundle" do
    if Dir.glob("**/#{bundle_name}.bundle").length == 0
      STDERR.puts 'Bundle failed to build!'
      exit(1)
    end
  end

  file "build/bundles/#{bundle_name}.bundle" => dot_o_files do |t|
    FileUtils.mkdir_p 'build/bundles'
    FileUtils.rm Dir["build/bundles/#{bundle_name}.bundle"]
    sh "gcc -o build/bundles/#{bundle_name}.bundle #{dot_o_files.join(" ")} -bundle " +
      "#{make_options '-framework ', req_frameworks} " +
      "#{make_options '-l', req_libraries} " +
      "#{make_options '-I', src_paths}"
  end
end
