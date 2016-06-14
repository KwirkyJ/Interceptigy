# lua_stringbuffer

Lua library for the supposedly-efficient concatenation of strings.

According to PiL, repeated calls to Lua's built-in `..` operator is rather slow. To avoid this, the `lua_stringbuffer` library uses a table to build up a string and then concatenate them when desired.

To use, just put `lua_stringbuffer` somewhere in your `package path` and `require` it.

```lua
local lua_stringbuffer = require 'lua_stringbuffer'
local buffer = lua_stringbuffer.new()
assert(buffer:getString() == '')
buffer:add('my first add')
buffer:add('ition')
assert(buffer:getString() == 'my first addition')

-- non-OOP syntax is supported:
buffer = lua_stringbuffer.new()
lua_stringbuffer.add(buffer, 'my first addition')
assert(lua_stringbuffer.getString(buffer) == 'my first addition')
```



## API Reference

#### `lua_stringbuffer.new([suffix])`
Returns a new 'StringBuffer' table/object. `suffix` is an optional string that will be added after each call to `add()` and defaults to the empty string. Raises an error iff 
```lua
type(suffix) ~= 'string' or type(suffix) ~= 'nil'`
```

The following calls are equivalent:
```lua
bufferobj = lua_stringbuffer.new(suffix)

bufferobj = lua_stringbuffer.new()
bufferobj:setSuffix(suffix)
```


#### `lua_stringbuffer.setSuffix(bufferobj[, suffix])`
Sets a string to be appended at the end of each `add()` call. If `nil`, sets the empty string. Raises an error iff 
```lua
type(suffix) ~= 'string' or type(suffix) ~= 'nil'`
```


#### `lua_stringbuffer.add(bufferobj[, ...])`
Add one or more strings to the end of the buffer. Accepts a any number of arguments of any type, with behavior as follows:
+ iterates over the arguments in-order adding until the first non-string element, at which point it will halt, add the `bufferobj`'s set separator (if any) and return.
+ if and only if the first agument is a table, it follows the same rules as above with the table's indices 1..n. The table may have a key `suffix` which holds a string which will be inserted *after each added element from the table*; when the first non-string element is encountered, the `bufferobj`'s set separator will be added and the function will return.

```lua
buffer = lua_stringbuffer.new('\n')
buffer:add({suffix = '\t', 'apples', 'tangerines', 'kiwis', true, 'bananas'})
buffer:getString() == 'apples\ttangerines\tkiwis\t\n'
```


#### `lua_stringbuffer.getString(bufferobj)`
Returns the string literal that is the concatenation of all additions (and appropriate separators).



## Examples

#### coming soon

