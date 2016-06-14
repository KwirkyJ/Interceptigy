-- Test suite for lua_stringbuffer
--
-- (c) 2016 J. KwirkyJ Smith <kwirkyj.smith0@gmail.com>
-- Version 1.0.0
-- MIT License

local lua_stringbuffer = require 'lua_stringbuffer'

local b, b2 = lua_stringbuffer.new(), lua_stringbuffer.new()



---- TEST BASIC USE --------------------------------------------------

assert(b:getString() == '', 'blank buffers are empty')
assert(b:getString() == b2:getString(), 'initial empty strings match')
assert(b ~= b2, 'unique instances')

b:add('\tword')
b:add("\n")
b:add('honey')
assert(b:getString() == '\tword\nhoney', 'additions are concatenated')
assert(b:getString() ~= b2:getString(),  'buffers are separate')

b2:add('\tword\nhoney')
assert(b:getString() == b2:getString(), 'generated strings match')



---- TEST ADD --------------------------------------------------------

b = lua_stringbuffer.new()
b:add(nil)
b:add(5)
b:add(function() end)
assert(b:getString() == '', 'non-string additions are ignored')

b = lua_stringbuffer.new()
b:add('apples', 'cherries', 'peaches', 'pears', 'kumquats')
assert(b:getString() == 'applescherriespeachespearskumquats',
       'vararg additions are concatenated by default')

b = lua_stringbuffer.new()
b:add{'apples', 'cherries', 'peaches', 'pears', 'kumquats'}
assert(b:getString() == 'applescherriespeachespearskumquats',
       'addition by table')

b = lua_stringbuffer.new()
b:add{suffix=', ', 'apples', 'cherries', 'peaches', 'pears', 'kumquats'}
assert(b:getString() == 'apples, cherries, peaches, pears, kumquats, ',
       'table-add with suffix argument')

b = lua_stringbuffer.new()
b:add('apples', 'cherries', 5, 'pears', 'kumquats')
assert(b:getString() == 'applescherries',
       'non-strings halt vararg addition')

b = lua_stringbuffer.new()
b:add{suffix=' ', 'apples', 'cherries', 5, 'pears', 'kumquats'}
assert(b:getString() == 'apples cherries ',
       'non-strings halt table addition')

b = lua_stringbuffer.new()
b:add('apples', 'pears', {'cherries'}, 'kumquats')
assert(b:getString() == 'applespears',
       'tables are a halting element')

b = lua_stringbuffer.new()
b:add{}
assert(b:getString() == '', 'empty table adds nothing')

b = lua_stringbuffer.new()
b:add({suffix = ' ', 'apples', 'cherries'}, {suffix = ' ', 'pears'})
assert(b:getString() == 'apples cherries ', 'uses only first table')



---- TEST SUFFIXES -----------------------------------------------------------

b = lua_stringbuffer.new('\t')
b:add()
b:add('pickelbarrel')
b:add('kumquat')
b:add('')
assert(b:getString() == '\tpickelbarrel\tkumquat\t\t',
      'constructor accepts global delimiter')

b = lua_stringbuffer.new()
b:add('1')
b:add('2')
b:setSuffix('/')
b:add('3')
b:add('4')
b:setSuffix()
b:add('5')
b:add('6')
b:setSuffix('\\') -- -> \
b:add('7')
b:add('8')
b:setSuffix('')
b:add('9')
assert(b:getString() == [=[123/4/567\8\9]=],
       'demonstrating setter')

b = lua_stringbuffer.new('  ')
b:add{suffix = '\n', 'apples', 'oranges', 'kiwis'}
b:setSuffix()
b:add('citrangelos')
assert(b:getString() == 'apples\noranges\nkiwis\n  citrangelos',
       'table-add and preset delimiter interaction')



---- TEST MODULE CALLS -------------------------------------------------------

b = lua_stringbuffer.new()
lua_stringbuffer.add(b, 'passionfruit')
lua_stringbuffer.setSuffix(b, '\n')
lua_stringbuffer.add(b, {'apples', 'bananas', suffix=', '})
assert(lua_stringbuffer.getString(b) == 'passionfruitapples, bananas, \n',
       'less OOP calls for the verbose-inclined')



print('==== TEST_STRINGBUFFER SUCCESSFUL ====')

