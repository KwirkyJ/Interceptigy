package = 'lua_stringbuffer'
version = '1.0.0-0'
description = {
    summary  = 'Lightweight library to concatenate strings.',
    detailed = 'Fast and simple single-module library for buliding strings.',
    homepage = 'http://github.com/KwirkyJ/lua_stringbuffer/'
    license  = 'MIT <http://opensource.org/licenses/MIT>'
}
source = {
    url = 'http://github.com/KwirkyJ/lua_stringbuffer/archive/lua_stringbuffer-1.0.0-0.tar.gz'
}
dependencies = {
    'lua >= 5.1'
}
build = {
    type = 'builtin'
    modules = {
        ['lua_stringbuffer.init'] = init.lua,
    }
    copy_directories = {'test'}
}

