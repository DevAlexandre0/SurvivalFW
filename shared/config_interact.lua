FW = FW or {}
FW.Interact = {
  trader = {
    -- Add as many stations as you want
    { x=2331.6, y=2568.9, z=46.7, radius=1.6, label='Trader Terminal' },
  },
  stash = {
    { x=2328.9, y=2570.8, z=46.7, radius=1.4, label='Stash Locker' },
  },
  craft = function()
    -- Use benches from Crafting config as interactive points
    local pts = {}
    for id,b in pairs((FW.Crafting and FW.Crafting.benches) or {}) do
      for _,p in ipairs(b.points or {}) do table.insert(pts, { x=p.x, y=p.y, z=p.z, radius=1.6, label='Craft: '..(b.label or id), bench=id }) end
    end
    return pts
  end
}
