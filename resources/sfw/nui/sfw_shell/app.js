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
  function setView(name){
    viewApp.classList.add('hidden');
    if(name === 'app'){ viewApp.classList.remove('hidden'); }
  }

  window.addEventListener('message', (e)=>{
    const d = e.data || {};
    if(d.type === 'app:open'){ setView('app'); }
    if(d.type === 'app:close'){ setView(null); }
  });

  $('#ap_apply')?.addEventListener('click', ()=>{
    post('app:apply', {
      hair: parseInt($('#ap_hair')?.value||'0',10) || 0,
      color1: parseInt($('#ap_c1')?.value||'0',10) || 0,
      color2: parseInt($('#ap_c2')?.value||'0',10) || 0
    });
  });

  $('#ap_done')?.addEventListener('click', ()=>{
    post('app:done', {});
  });
})();
