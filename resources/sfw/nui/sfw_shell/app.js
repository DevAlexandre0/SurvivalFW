(function(){
  const RES = (typeof GetParentResourceName==='function') ? GetParentResourceName() : 'survivalfw';
  const $ = sel => document.querySelector(sel);

  function post(type, data){
    fetch(`https://${RES}/${type}`, {
      method: 'POST',
      headers: {'Content-Type':'application/json; charset=UTF-8'},
      body: JSON.stringify(data||{})
    });
  }

  const viewApp = $('#view-app');
  const viewId = $('#view-id');
  const viewInv = $('#view-inv');
  const invGrid = $('#inv-grid');
  const hud = $('#hud');
  const hudVal = {
    hp: $('#hud-hp-value'),
    stam: $('#hud-stamina-value'),
    hun: $('#hud-hunger-value'),
    ths: $('#hud-thirst-value'),
    temp: $('#hud-temperature-value')
  };
  const hudEff = $('#hud-effects');
  const hudAmmoCount = $('#hud-ammo-count');
  const hudAmmoRes = $('#hud-ammo-reserve');
  const hudProg = $('#hud-progress');
  const hudProgBar = $('#hud-progress-bar');
  function setView(name){
    viewApp.classList.add('hidden');
    viewId.classList.add('hidden');
    viewInv?.classList.add('hidden');
    if(name === 'app'){ viewApp.classList.remove('hidden'); }
    if(name === 'id'){ viewId.classList.remove('hidden'); }
    if(name === 'inv'){ viewInv?.classList.remove('hidden'); }
  }

  function renderInv(c){
    if(!invGrid) return;
    invGrid.innerHTML = '';
    const slots = (c && c.slots) || [];
    for(let i=0;i<slots.length;i++){
      const slot = slots[i];
      const div = document.createElement('div');
      div.className = 'inv-slot';
      if(slot){
        const label = slot.label || slot.name || '';
        const count = slot.count !== undefined ? ` (${slot.count})` : '';
        div.textContent = `${label}${count}`;
      }
      invGrid.appendChild(div);
    }
  }

  window.addEventListener('message', (e)=>{
    const d = e.data || {};
    if(d.type === 'app:open'){ setView('app'); }
    if(d.type === 'app:close'){ setView(null); }
    if(d.type === 'id:open'){ setView('id'); }
    if(d.type === 'id:close'){ setView(null); }
    if(d.type === 'inv:open'){ setView('inv'); renderInv(d.payload||{}); }
    if(d.type === 'inv:update'){ renderInv(d.payload||{}); }
    if(d.type === 'inv:close'){ setView(null); }

    if(d.type === 'vis'){
      if(d.show){ hud?.classList.remove('hidden'); }
      else { hud?.classList.add('hidden'); }
    }

    if(d.type === 'hud:vitals'){
      const p = d.payload || {};
      if(hudVal.hp && p.hp !== undefined){ hudVal.hp.textContent = Math.round(p.hp); }
      if(hudVal.stam && p.stam !== undefined){ hudVal.stam.textContent = Math.round(p.stam); }
      if(hudVal.hun && p.hun !== undefined){ hudVal.hun.textContent = Math.round(p.hun); }
      if(hudVal.ths && p.ths !== undefined){ hudVal.ths.textContent = Math.round(p.ths); }
      if(hudVal.temp && p.temp !== undefined){ hudVal.temp.textContent = Math.round(p.temp); }
    }

    if(d.type === 'hud:effects'){
      if(hudEff){
        hudEff.innerHTML = '';
        (d.payload || []).forEach(eff => {
          const span = document.createElement('span');
          span.className = 'hud-effect';
          span.title = eff.type || '';
          const img = document.createElement('img');
          img.alt = eff.type || '';
          img.src = `effects/${(eff.type||'').toLowerCase()}.png`;
          span.appendChild(img);
          hudEff.appendChild(span);
        });
      }
    }

    if(d.type === 'hud:ammo'){
      const p = d.payload || {};
      if(hudAmmoCount && p.count !== undefined){ hudAmmoCount.textContent = p.count; }
      if(hudAmmoRes && p.reserve !== undefined){ hudAmmoRes.textContent = p.reserve; }
    }

    if(d.type === 'hud:progress'){
      const p = d.payload || {};
      if(typeof p.pct === 'number'){
        hudProg?.classList.remove('hidden');
        if(hudProgBar){ hudProgBar.style.width = `${Math.max(0, Math.min(100, p.pct))}%`; }
      } else {
        hudProg?.classList.add('hidden');
        if(hudProgBar){ hudProgBar.style.width = '0%'; }
      }
    }
  });

  $('#id_form')?.addEventListener('submit', (e)=>{
    e.preventDefault();
    post('id:submit', {
      first_name: $('#id_first')?.value || '',
      last_name: $('#id_last')?.value || '',
      dob: $('#id_dob')?.value || '',
      sex: $('#id_sex')?.value || '',
      height_cm: parseInt($('#id_height')?.value||'0',10) || 0,
      blood_type: $('#id_blood')?.value || '',
      nationality: $('#id_nation')?.value || ''
    });
  });

  $('#id_cancel')?.addEventListener('click', ()=>{
    post('id:cancel', {});
  });

  $('#ap_apply')?.addEventListener('click', ()=>{
    post('app:apply', {
      head: parseInt($('#ap_head')?.value||'0',10) || 0,
      skin: parseInt($('#ap_skin')?.value||'0',10) || 0,
      hair: parseInt($('#ap_hair')?.value||'0',10) || 0,
      color1: parseInt($('#ap_c1')?.value||'0',10) || 0,
      color2: parseInt($('#ap_c2')?.value||'0',10) || 0
    });
  });

  $('#ap_done')?.addEventListener('click', ()=>{
    post('app:done', {});
  });
})();
