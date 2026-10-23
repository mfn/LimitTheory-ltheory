-- Historical entrypoint retained; this now exercises any compiled audio backend.
-- All sounds/images are existing game assets. No generated test media required.
local FMODTest = Application()

function FMODTest:getTitle ()
  return 'Audio Backend Test'
end

function FMODTest:onInit ()
  Audio.Init()
  Audio.Set3DSettings(1, 100, 1)
  self.volume = 0.2
  self.pitch = 1
  self.paused = false
  self.selected = 1
  self.pos = Vec3f(256, 0, 256)
  self.vel = Vec3f(0, 0, 0)
  self.forward = Vec3f(0, 0, -1)
  self.up = Vec3f(0, 1, 0)
  self.font = Font.Load('NovaMono', 16)
  self.emitters = {
    { file = 'cantina', image = 'image/cantinaband', x = 128, y = 300 },
    { file = 'Imperial_March', image = 'image/vader', x = 512, y = 300 },
  }
  self.effects = {
    Sound.LoadAsync('blaster', false, false),
    Sound.LoadAsync('chewy', false, false),
    Sound.LoadAsync('thybidding', false, false),
  }
  for _, e in ipairs(self.emitters) do
    e.tex = Tex2D.Load(e.image)
    e.sound = Sound.Load(e.file, true, true)
    e.sound:set3DPos(Vec3f(e.x, 0, e.y), Vec3f(0, 0, 0))
    e.sound:setVolume(self.volume)
  end
  Audio.SetListenerPos(self.pos, self.vel, self.forward, self.up)
  self.emitters[self.selected].sound:play()
  print('Audio test: 1/2 MP3 effects, 3 WAV, M MP3/Vorbis music, Space pause, R rewind')
  print('WASD/right-drag listener, +/- volume, P pitch, Escape exit. Initial volume: 20%.')
end

function FMODTest:playEffect (index)
  -- Raw ownership transfers to free-on-finish; do not add an FFI GC finalizer.
  local sound = self.effects[index]:clone()
  sound:setVolume(self.volume)
  sound:setPitch(self.pitch)
  sound:setFreeOnFinish(true)
  sound:play()
end

function FMODTest:onInput ()
  local key = Button.Keyboard
  if Input.GetPressed(key.Escape) then self:quit() end
  if Input.GetPressed(key.N1) then self:playEffect(1) end
  if Input.GetPressed(key.N2) then self:playEffect(2) end
  if Input.GetPressed(key.N3) then self:playEffect(3) end
  if Input.GetPressed(key.M) then
    self.emitters[self.selected].sound:pause()
    self.selected = 3 - self.selected
    self.paused = false
    self.emitters[self.selected].sound:play()
  end
  if Input.GetPressed(key.Space) then
    self.paused = not self.paused
    local sound = self.emitters[self.selected].sound
    if self.paused then sound:pause() else sound:play() end
  end
  if Input.GetPressed(key.R) then self.emitters[self.selected].sound:rewind() end
  if Input.GetPressed(key.Equals) then self.volume = min(1, self.volume + 0.05) end
  if Input.GetPressed(key.Minus) then self.volume = max(0, self.volume - 0.05) end
  if Input.GetPressed(key.P) then
    self.pitch = self.pitch == 1 and 1.25 or (self.pitch == 1.25 and 0.8 or 1)
  end
  self.vel:set(0, 0, 0)
  if Input.GetDown(key.W) then self.vel.z = self.vel.z - 150 end
  if Input.GetDown(key.S) then self.vel.z = self.vel.z + 150 end
  if Input.GetDown(key.A) then self.vel.x = self.vel.x - 150 end
  if Input.GetDown(key.D) then self.vel.x = self.vel.x + 150 end
  if Input.GetDown(Button.Mouse.Right) then
    local mouse = Vec2i()
    Input.GetMousePosition(mouse)
    self.pos:set(mouse.x, 0, mouse.y)
  end
end

function FMODTest:onUpdate (dt)
  self.pos.x = self.pos.x + self.vel.x * dt
  self.pos.z = self.pos.z + self.vel.z * dt
  for _, e in ipairs(self.emitters) do
    e.sound:setVolume(self.volume)
    e.sound:setPitch(self.pitch)
  end
  Audio.SetListenerPos(self.pos, self.vel, self.forward, self.up)
  Audio.Update()
end

function FMODTest:onDraw ()
  Draw.Clear(0.1, 0.1, 0.1, 1)
  BlendMode.Push(BlendMode.Alpha)
  Draw.Color(1, 1, 1, 1)
  for i, e in ipairs(self.emitters) do
    e.tex:draw(e.x - 80, e.y - 80, 160, 160)
    self.font:draw(e.file .. (i == self.selected and ' [selected]' or ''),
      e.x - 80, e.y + 110, 1, 1, 1, 1)
  end
  Draw.Color(0.1, 0.6, 1, 1)
  Draw.Rect(self.pos.x - 4, self.pos.z - 4, 8, 8)
  self.font:draw('1/2: MP3 effects   3: WAV   M: MP3/Vorbis music', 20, 30, 1, 1, 1, 1)
  self.font:draw('Space: pause   R: rewind   P: pitch   +/-: volume', 20, 55, 1, 1, 1, 1)
  self.font:draw('WASD / right-drag: listener   Escape: quit', 20, 80, 1, 1, 1, 1)
  self.font:draw(format('Volume %.0f%%  Pitch %.2f  Resources %d  Sounds %d  Playing %d',
    self.volume * 100, self.pitch, Audio.GetLoadedCount(),
    Audio.GetTotalCount(), Audio.GetPlayingCount()), 20, 105, 1, 1, 1, 1)
  BlendMode.Pop()
end

function FMODTest:onExit ()
  for _, sound in ipairs(self.effects) do sound:free() end
  for _, e in ipairs(self.emitters) do e.sound:free(); e.tex:free() end
  self.font:free()
  Audio.Update()
  Audio.Free()
end

return FMODTest
