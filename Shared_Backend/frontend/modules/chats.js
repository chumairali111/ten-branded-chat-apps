import{state,$,api,esc,initials,modal,closeModal,action,toast,empty}from'./api.js';
let open;
export function setupChats(openChat){open=openChat;$('new-chat').onclick=action(()=>newChat());$('welcome-new').onclick=action(()=>newChat());$('search').oninput=renderChats;
 $('filters').querySelectorAll('[data-filter]').forEach(b=>b.onclick=()=>{state.filter=b.dataset.filter;renderChats();});
 $('new-list').onclick=action(async()=>{const name=prompt('List name');if(name){await api('/lists','POST',{name});await refreshChats();}});
}
export async function refreshChats(){state.chats=(await api('/chats')).chats;state.lists=(await api('/lists')).lists;if(state.section==='chats')renderChats();}
export function renderChats(){
 $('filters').querySelectorAll('[data-filter]').forEach(b=>b.classList.toggle('selected',b.dataset.filter===state.filter));
 $('custom-lists').innerHTML=state.lists.map(l=>`<button data-list="${l.id}" class="${state.filter==='list-'+l.id?'selected':''}">${esc(l.name)}</button>`).join('');
 $('custom-lists').querySelectorAll('[data-list]').forEach(b=>b.onclick=()=>{state.filter='list-'+b.dataset.list;renderChats();});
 const q=$('search').value.toLowerCase();let chats=state.chats.filter(c=>c.title.toLowerCase().includes(q));
 chats=chats.filter(c=>{if(state.filter==='archived')return c.archived;if(c.archived)return false;if(state.filter==='unread')return c.unread;if(state.filter==='favourite')return c.favourite;if(state.filter.startsWith('list-'))return state.lists.find(l=>'list-'+l.id===state.filter)?.chat_ids.includes(c.id);return true;});
 $('sidebar-content').innerHTML=chats.map(c=>`<button class="chat-row ${state.chat?.id===c.id?'selected':''}" data-chat="${c.id}"><span class="avatar">${esc(initials(c.title))}</span><span class="row-content"><strong>${esc(c.title)} ${c.favourite?'♡':''}</strong><small>${esc(c.last?.body|| (c.last?c.last.kind:c.kind==='group'?'Group conversation':'Start chatting'))}</small></span><span class="row-end">${c.last?new Date(c.last.created*1000).toLocaleTimeString([],{hour:'2-digit',minute:'2-digit'}):''}${c.unread?`<span class="badge">${c.unread}</span>`:''}</span></button>`).join('')||empty('No chats here. Use + to start a conversation.');
 $('sidebar-content').querySelectorAll('[data-chat]').forEach(b=>b.onclick=action(()=>open(+b.dataset.chat)));
}
export async function newChat(group=false){
 const users=(await api('/users')).users;
 modal(group?'Create group':'New conversation',`<button id="group-mode" class="primary">${group?'Switch to direct chat':'Create a new group'}</button>${group?'<label>Group name<input id="group-name" placeholder="e.g. Study Buddy team" maxlength="80"></label>':''}<input id="contact-query" placeholder="Search contacts" class="search"><div id="contact-list">${users.map(u=>`<label class="check-person" data-name="${esc((u.name+' '+u.username).toLowerCase())}"><input type="${group?'checkbox':'radio'}" name="contacts" value="${u.id}"><span class="avatar">${esc(initials(u.name))}</span><span>${esc(u.name)}<small> @${esc(u.username)}</small></span></label>`).join('')||empty('No other registered users. Create a second account in another browser.')}</div><button class="primary" id="create-chat">${group?'Create group':'Open chat'}</button>`);
 $('group-mode').onclick=action(()=>newChat(!group));$('contact-query').oninput=()=>document.querySelectorAll('[data-name]').forEach(e=>e.hidden=!e.dataset.name.includes($('contact-query').value.toLowerCase()));
 $('create-chat').onclick=action(async()=>{const ids=[...document.querySelectorAll('input[name=contacts]:checked')].map(e=>+e.value);if(!group&&ids.length!==1)throw Error('Select a contact');const d=await api('/chats','POST',{kind:group?'group':'direct',members:ids,title:group?$('group-name').value:undefined});closeModal();await refreshChats();await open(d.id);});
}
