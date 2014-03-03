#!/usr/bin/env ruby

# Sort of like vbindiff, except smaller with less functionality, and in our toolshed ;)
# Useful for encoded HTTP parameters, raw dumped pkts and other little things
# todo: print out like hexdump -C
# Chris at mtso

module ColorConstants
	BLACK = "\e[1;30m"
	RED = "\e[1;31m"
	GREEN = "\e[1;32m"
	BROWN = "\e[1;33m"
	BLUE = "\e[1;34m"
	PURPLE = "\e[1;35m"
	CYAN = "\e[1;36m"
	GRAY = "\e[1;37m"
	NO_COLOR = "\e[0m"
end

class ColorDif

	attr_accessor :file1, :file2

	def initialize(file1, file2)
		@file1 = IO.read(file1)
		@file2 = IO.read(file2)
	end

	# Theres definitely a more elegant way to do this, whatever ...
	def diffem
		puts "\nFile 1 [#{file1.size} bytes]"
		puts "File 2 [#{file2.size} bytes]\n\n"

		count = 0

		@file1.each_byte do |byte|
			if byte == @file2[count]
				print sprintf(ColorConstants::BLUE + "%02x ", byte)
			else
				print sprintf(ColorConstants::RED + "%02x ", byte)
			end

			count = count+1

			if count % 32 == 0
				print "\n"
			end
		end

		puts ColorConstants::NO_COLOR + "\n---"
		count = 0

		@file2.each_byte do |byte|
			if byte == @file1[count]
				print sprintf(ColorConstants::BLUE + "%02x ", byte)
			else
				print sprintf(ColorConstants::RED + "%02x ", byte)
			end

			count = count+1

			if count % 32 == 0
				print "\n"
			end
		end
	end
end

f = ColorDif.new(ARGV[0], ARGV[1])
f.diffem

puts ColorConstants::NO_COLOR  + "\n\n"
