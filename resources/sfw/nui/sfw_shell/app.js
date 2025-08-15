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
  function setView(name){
    viewApp.classList.add('hidden');
    viewId.classList.add('hidden');
    if(name === 'app'){ viewApp.classList.remove('hidden'); }
    if(name === 'id'){ viewId.classList.remove('hidden'); }
  }

  window.addEventListener('message', (e)=>{
    const d = e.data || {};
    if(d.type === 'app:open'){ setView('app'); }
    if(d.type === 'app:close'){ setView(null); }
    if(d.type === 'id:open'){ setView('id'); }
    if(d.type === 'id:close'){ setView(null); }
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
