import{state,$,api,esc,modal,closeModal,action,toast,empty}from'./api.js';
let refreshList;let signature='';let typingTimer=0;
export function setupMessages(refresh){refreshList=refresh;$('composer').onsubmit=action(async e=>{e.preventDefault();const body=$('message-input').value.trim();if(!body)return;await sendMessage({body});$('message-input').value='';});
 $('message-input').oninput=()=>{if(state.chat&&Date.now()-typingTimer>2500){typingTimer=Date.now();api(`/chats/${state.chat.id}/typing`,'POST',{}).catch(()=>{});}};
 $('emoji').onclick=()=>{$('message-input').value+=' 😊';$('message-input').focus();};
 $('chat-search').onclick=()=>{$('message-search-bar').hidden=false;$('message-query').focus();};$('close-search').onclick=()=>{$('message-search-bar').hidden=true;$('message-query').value='';renderMessages();};$('message-query').oninput=renderMessages;
 $('back').onclick=()=>{$('workspace').classList.remove('chat-open');$('info-panel').hidden=true;};
}
export async function openChat(id){try{state.chat=await api(`/chats/${id}`);}catch(e){if(e.message!=='Chat is locked')throw e;const password=prompt('This chat is locked. Enter your account password');if(password===null)return;await api(`/chats/${id}/unlock`,'POST',{password});state.chat=await api(`/chats/${id}`);}state.reply=null;signature='';$('reply-bar').hidden=true;$('welcome').hidden=true;$('chat-panel').hidden=false;$('workspace').classList.add('chat-open');$('chat-title').textContent=state.chat.title;$('chat-avatar').textContent=state.chat.title.slice(0,2).toUpperCase();$('info-panel').hidden=true;await loadMessages(true);await api(`/chats/${id}/read`,'POST',{});await refreshList();}
export async function loadMessages(force=false){
 if(!state.chat)return;const cid=state.chat.id;const d=await api(`/chats/${cid}/messages`);if(state.chat?.id!==cid)return;state.messages=d.messages;
 $('chat-subtitle').textContent=d.typing.length?d.typing.map(x=>x.name).join(', ')+' typing…':state.chat.kind==='group'?state.chat.members.length+' members':(()=>{const u=state.chat.members.find(u=>u.id!==state.user.id);return u&&Date.now()/1000-u.last_seen<15?'online':u?.about||'';})();
 const s=JSON.stringify(d.messages);if(s!==signature||force){signature=s;renderMessages(force);}
 if(document.visibilityState==='visible')await api(`/chats/${cid}/read`,'POST',{});
}
export async function sendMessage(payload){await api(`/chats/${state.chat.id}/messages`,'POST',{...payload,reply_id:state.reply?.id});state.reply=null;$('reply-bar').hidden=true;await loadMessages(true);await refreshList();}
export function renderMessages(force=false){
 const list=$('messages');const nearBottom=list.scrollHeight-list.scrollTop-list.clientHeight<100;const q=$('message-query').value.toLowerCase();const msgs=state.messages.filter(m=>m.body.toLowerCase().includes(q));let day='';let html='';
 for(const m of msgs){const date=new Date(m.created*1000);const stamp=date.toLocaleDateString();if(stamp!==day){html+=`<div class="day">${esc(stamp)}</div>`;day=stamp;}
 let attachment='';if(m.file_id){const src='/api/files/'+m.file_id;attachment=m.mime?.startsWith('image/')?`<img src="${src}" alt="${esc(m.file_name)}" loading="lazy">`:m.mime?.startsWith('video/')?`<video src="${src}" controls preload="metadata"></video>`:m.kind==='audio'||m.mime?.startsWith('audio/')?`<audio src="${src}" controls preload="metadata"></audio>`:`<a href="${src}?download=1">▤ ${esc(m.file_name)} · ${(m.size/1024).toFixed(0)} KB ↓</a>`;}
 html+=`<article class="message ${m.sender===state.user.id?'own':''}"><div class="sender">${m.sender!==state.user.id&&state.chat.kind==='group'?esc(m.sender_name):''}</div>${m.deleted?'':`<button class="msg-actions" aria-label="Message actions" data-message="${m.id}">⌄</button>`}${m.reply?`<div class="quote">${esc(m.reply)}</div>`:''}${attachment}<div class="body">${esc(m.body)}</div><div class="meta">${m.starred?'★ ':''}${m.edited?'edited · ':''}${date.toLocaleTimeString([],{hour:'2-digit',minute:'2-digit'})} ${m.sender===state.user.id?`<span class="${m.read_by.length?'ticks':''}">${m.read_by.length?'✓✓':'✓'}</span>`:''}</div>${m.reactions.length?`<div class="reactions">${m.reactions.map(r=>esc(r.emoji)).join(' ')}</div>`:''}</article>`;
 }
 list.innerHTML=html||empty(q?'No matching messages':'Say hello! Your conversation starts here.');list.querySelectorAll('[data-message]').forEach(b=>b.onclick=()=>messageMenu(+b.dataset.message));if(force||nearBottom)list.scrollTop=list.scrollHeight;
}
function messageMenu(id){const m=state.messages.find(x=>x.id===id);modal('Message actions',`<div class="button-stack"><button data-action="reply">↩ Reply</button><button data-action="react">♡ React</button><button data-action="star">★ ${m.starred?'Unstar':'Star'}</button><button data-action="copy">Copy text</button><button data-action="forward">Forward text</button>${m.sender===state.user.id?'<button data-action="edit">Edit text</button><button data-action="delete-everyone" class="danger">Delete for everyone</button>':''}<button data-action="delete-me" class="danger">Delete for me</button></div>`);
 document.querySelectorAll('[data-action]').forEach(b=>b.onclick=action(async()=>{const a=b.dataset.action;
 if(a==='reply'){state.reply=m;$('reply-bar').hidden=false;$('reply-bar').innerHTML=`<span>Replying to ${esc(m.sender_name)}: ${esc(m.body.slice(0,80))}</span><button id="cancel-reply">×</button>`;$('cancel-reply').onclick=()=>{state.reply=null;$('reply-bar').hidden=true;};$('message-input').focus();}
 if(a==='react'){const emoji=prompt('Emoji (leave blank to remove)','❤️');if(emoji!==null)await api(`/messages/${id}/reaction`,'POST',{emoji});}
 if(a==='star')await api(`/messages/${id}/star`,'POST',{});
 if(a==='copy'){await navigator.clipboard.writeText(m.body);toast('Copied');}
 if(a==='forward'){const dest=prompt('Destination chat ID:\n'+state.chats.map(c=>`${c.id}: ${c.title}`).join('\n'));if(dest)await api(`/messages/${id}/forward`,'POST',{chat_id:+dest});}
 if(a==='edit'){const body=prompt('Edit message',m.body);if(body)await api(`/messages/${id}`,'PATCH',{body});}
 if(a==='delete-everyone'&&confirm('Delete this message for everyone?'))await api(`/messages/${id}?scope=everyone`,'DELETE');
 if(a==='delete-me')await api(`/messages/${id}`,'DELETE');closeModal();await loadMessages(true);await refreshList();}));}
