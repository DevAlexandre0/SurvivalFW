FW = FW or {}
FW.Crafting = {
  benches = {
    work = { label='Workbench', radius=3.0, points = { {x=2329.4,y=2571.2,z=46.6} } },
    chem  = { label='ChemBench', radius=3.0, points = { {x=2332.0,y=2570.0,z=46.6} } },
    garage= { label='Garage',    radius=5.0, points = { {x=2335.0,y=2572.5,z=46.6} } },
  },
  recipes = {
    bandage = { bench='work', in_={ cloth=2 }, out_={ med_bandage=1 }, time=4 },
    splint  = { bench='work', in_={ stick=2, cloth=1 }, out_={ splint=1 }, time=6 },
    charcoal= { bench='chem', in_={ wood=3 }, out_={ med_charcoal=1 }, time=8 },
    kitrepair  = { bench='work', in_={ scrap=12, cloth=1 }, out_={ repair_kit=1 }, time=8 },
  }
}
