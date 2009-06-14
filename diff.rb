# basically stolen from Active Reload's Warehouse project.
def diff(bit)
  raw_diff = bit.diff
  diff_line_regex = %r{@@ -(\d+),?(\d*) \+(\d+),?(\d*) @@}
  lines = raw_diff.split("\n")
      
  table_rows = []  
      
  lines = lines[2..lines.length].collect{ |line| escape_html(line) }

  ln = [0, 0]   # line counter
  lines = lines.collect do |line|      
    if line =~ /^\-/
      [ln[0] += 1, '', ' ' + line[1..line.length], 'delete']
    elsif line =~ /^\+/
      ['', ln[1] += 1, ' ' + line[1..line.length], 'insert']
    elsif line_defs = line.match(diff_line_regex)
            ln[0] = line_defs[1].to_i - 1
            ln[1] = line_defs[3].to_i - 1
      ['---', '---', '', nil]
    elsif line.match('\ No newline at end of file')
      nil
    else
      [ln[0] += 1, ln[1] += 1, line, nil]
    end     
  end.compact
  
  lines[1..lines.length].collect do |line|
    pnum = '<td class="ln">' + line[0].to_s + '</td>'
    cnum = '<td class="ln">' +  line[1].to_s + '</td>'
    code = '<td class="code ' + (line[3] ? " #{line[3]}" : '') + '">' + line[2].gsub(/ /, '&nbsp;') + '</td>'
    table_rows << '<tr>' + pnum + cnum + code + '</tr>'
  end
  
  %(
  <table class="diff">
    #{table_rows.join("\n")}
  </table>
  )
end