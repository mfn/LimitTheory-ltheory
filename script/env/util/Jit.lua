local Config = require('env.util.Config')

local Jit = {}

function Jit.GetBytecode (fn)
  local bc = require('jit.bc')
  local lines = {}
  local target = bc.targets(fn)
  for pc=1,1000000000 do
    local s = bc.line(fn, pc, target[pc] and '=>')
    if not s then break end
    lines[#lines + 1] = s
  end
  return table.concat(lines, '')
end

function Jit.StartDump ()
  -- The custom dumper targets the historical LuaJIT 2.1 bytecode format.
  -- Use the runtime's matching dumper on newer LuaJIT releases.
  local jd = require(jit.version_num == 20100 and 'jit.dump2' or 'jit.dump')
  jd.on('timT', 'log/jd.txt')
end

function Jit.StartProfile ()
  local jp = require('jit.p')
  if Config.jit.profileVM then
    jp.start('fv2', 'log/jp.txt')
  else
    jp.start('vzF2i1', 'log/jp.txt')
    -- jp.start('Flvi1a', 'log/p.txt')
  end
end

function Jit.StartVerbose ()
  local jv = require('jit.v')
  jv.on('log/jv.txt')
end

function Jit.StopDump ()
  local jd = require(jit.version_num == 20100 and 'jit.dump2' or 'jit.dump')
  jd.off()
end

function Jit.StopProfile ()
  local jp = require('jit.p')
  jp.stop()
end

function Jit.StopVerbose ()
  local jv = require('jit.v')
  jv.off()
end

return Jit
