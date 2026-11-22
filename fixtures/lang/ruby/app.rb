# frozen_string_literal: true
q = <<~SQL
  # not a comment
SQL
WORDS = %w(it's (a) b)
re = /it's/
x = a / b # it's
after = $'
=begin
not a block comment in km
=end
puts "#{x} # no" # yes
sep = ?/
