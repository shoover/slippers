watch('lib/engine/slippers.treetop') { test; parser }
watch('lib/engine/(.*)\.rb') {|md| test if md[1] != 'slippers' }
watch('spec/.*\.rb') { test }

def test
  system('rake spec:run')
end

def parser
  system('tt lib/engine/slippers.treetop')
end
