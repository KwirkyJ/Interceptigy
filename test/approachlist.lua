---Unit-test for approachlist

approach = require 'source.approachlist'
luaunit  = require 'luaunit.luaunit'



TestGetApproaches = {}
TestGetApproaches.test_getApproaches = function(self)
    local e1, e2, e3, e4 = {id=1}, {id=2}, {id=3}, {id=4}
    local ta, tb, tc = 4.4, 9, 5
    local da, db, dc = 100, math.pi, 40
    local approaches = {}
    approach.insert(approaches, ta, da, e1, e2)
    approach.insert(approaches, tb, db, e2, e4)
    approach.insert(approaches, tc, dc, e3, e1)
    local gotten = {}
    for t, d, ea, eb in approach.getApproaches(approaches, e1) do
        gotten[#gotten+1] = {t, d, ea, eb}
    end
    assertEquals(gotten, {{ta,da,e1,e2}, {tc,dc,e3,e1}})
end



luaunit:run(arg)

