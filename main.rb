# typed: true
# frozen_string_literal: true

require "bundler"
Bundler.setup(:default)

require "debug"
require "sorbet-runtime"

pdf_io.seek(root_obj_entry[:offset], IO::SEEK_SET)

root_obj = []
loop do
  current_line = pdf_io.readline
  root_obj << current_line

  break if current_line.include?("endobj")
end

end_of_root_obj_index = root_obj.join.index(/\n>>/)
last_entry = xref_table.max_by { |td| td[:id] }

new_form = {id: last_entry[:id] + 1, offset: 0, generation_number: 0}
new_form_field = {id: last_entry[:id] + 2, offset: 0, generation_number: 0}
new_sig = {id: last_entry[:id] + 3, offset: 0, generation_number: 0}

new_root_obj = "#{root_obj.join[..end_of_root_obj_index]}" \
               "/Acroform #{new_form[:id]} #{new_form[:generation_number]} R\n" \
               ">>\n" \
               "endobj"


new_form_obj = "#{new_form[:id]} #{new_form[:generation_number]} obj\n" \
               "<</Fields [#{new_form_field[:id]} #{new_form[:generation_number]} R]\n" \
               "/SigFlags 3>>\n" \
               "endobj\n"

new_form_field_obj = "#{new_form_field[:id]} #{new_form_field[:generation_number]} obj\n" \
                     "<</FT /Sig\n" \
                     "/V #{new_sig[:id]} #{new_sig[:generation_number]} R>>\n" \
                     "endobj\n"

new_sig_obj = ""

binding.b
