#!/usr/bin/env ruby

require 'nokogiri'

source_dir = ARGV[0]

output_file = ARGV[1] ||= 'frankenEAD.xml'

@doc = '<ead>'

@first = true

Dir.glob(File.dirname(__FILE__) + "/#{source_dir}/*.xml").each do |e|
  puts e
  reader = Nokogiri::XML::Reader(IO.read(e))

  reader.each do |node|
    if (node.name == 'eadheader') && @first && (node.node_type == 1)
      @doc << node.outer_xml
      @doc << '<archdesc level="collection">'
    end

    @doc << node.outer_xml if (node.name == 'arrangement') && @first && (node.node_type == 1)

    @doc << '<dsc>' if (node.name == 'dsc') && @first && (node.node_type == 1)

    @doc << node.inner_xml if (node.name == 'dsc') && (node.node_type == 1)
  end

  @first = false
end

@doc << '</dsc></archdesc></ead>'

@doc.gsub!(/id="([a-zA-Z0-9]*)"/) { |_i| "id=\"#{rand(1_000_000)}\"" }

File.open(output_file, 'w') { |f| f.write(@doc) }
