export const state={user:null,csrf:'',chats:[],lists:[],chat:null,messages:[],filter:'all',section:'chats',reply:null,register:false};
export const $=id=>document.getElementById(id);
export const esc=v=>String(v??'').replace(/[&<>"']/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c]));
export const initials=s=>String(s||'?').split(' ').map(x=>x[0]).slice(0,2).join('').toUpperCase();
export async function api(url,method='GET',body){
 const options={method,headers:{'X-CSRF-Token':state.csrf},credentials:'same-origin'};
 if(body instanceof FormData)options.body=body;
 else if(body!==undefined){options.headers['Content-Type']='application/json';options.body=JSON.stringify(body);}
 const r=await fetch('/api'+url,options);const data=await r.json().catch(()=>({error:'Unexpected response'}));
 if(!r.ok){if(r.status===401&&state.user){location.reload();}throw Error(data.error||'Request failed');}return data;
}
export function toast(text){$('toast').textContent=text;$('toast').hidden=false;clearTimeout(window.toastTimer);window.toastTimer=setTimeout(()=>$('toast').hidden=true,3800);}
export function modal(title,html){$('modal-title').textContent=title;$('modal-body').innerHTML=html;if(!$('modal').open)$('modal').showModal();}
export function closeModal(){$('modal').close();}
export function action(fn){return async(...a)=>{try{await fn(...a);}catch(e){toast(e.message);}};}
export function empty(text){return `<div class="empty">${esc(text)}</div>`;}
