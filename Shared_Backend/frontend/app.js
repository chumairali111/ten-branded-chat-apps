import{state,$,api,action,toast}from'./modules/api.js';
import{setupAuth}from'./modules/auth.js';
import{setupChats,refreshChats,renderChats}from'./modules/chats.js';
import{setupMessages,openChat,loadMessages}from'./modules/messages.js';
import{setupAttachments}from'./modules/attachments.js';
import{setupGroups}from'./modules/groups.js';
import{showStatuses}from'./modules/statuses.js';
import{showCommunities}from'./modules/communities.js';
import{showProfile,showSettings,requestNotifications}from'./modules/settings.js';
import{pollCalls,startCall,showCalls}from'./modules/calls.js';
let running=false,previous=new Map();
$('modal-close').onclick=()=>$('modal').close();$('notifications').onclick=requestNotifications;
setupChats(openChat);setupMessages(refreshChats);setupAttachments();setupGroups();window.startCall=action(startCall);
setupAuth(async()=>{await refreshChats();const token=new URLSearchParams(location.search).get('invite');if(token){try{const d=await api('/invite/'+encodeURIComponent(token),'POST',{});history.replaceState({},'',location.pathname);await refreshChats();await openChat(d.id);}catch(e){toast(e.message);}}previous=new Map(state.chats.map(c=>[c.id,c.unread]));setInterval(tick,2000);});
document.querySelectorAll('[data-nav]').forEach(b=>b.onclick=action(async()=>{const nav=b.dataset.nav;if(nav==='profile'){showProfile();return;}state.section=nav;$('sidebar-title').textContent={chats:'WhatsApp',calls:'Calls',statuses:'Updates',communities:'Communities',settings:'Settings'}[nav];$('chat-controls').hidden=nav!=='chats';$('new-chat').hidden=nav!=='chats';document.querySelectorAll('[data-nav]').forEach(x=>x.classList.toggle('active',x===b));if(nav==='chats')renderChats();if(nav==='calls')await showCalls(openChat);if(nav==='statuses')await showStatuses();if(nav==='communities')await showCommunities(openChat);if(nav==='settings')await showSettings();}));
async function tick(){if(running||!state.user)return;running=true;try{await loadMessages();await refreshChats();await pollCalls();if('Notification'in window&&Notification.permission==='granted'&&document.hidden){for(const c of state.chats){if(c.unread>(previous.get(c.id)||0)&&!c.muted&&!c.locked)new Notification(c.title,{body:c.last?.body||'New message'});}}previous=new Map(state.chats.map(c=>[c.id,c.unread]));}catch(e){if(e.message.includes('not a member')){state.chat=null;$('chat-panel').hidden=true;$('welcome').hidden=false;}else if(e.message==='Chat is locked'){state.chat=null;$('chat-panel').hidden=true;$('welcome').hidden=false;$('info-panel').hidden=true;toast('Chat lock expired. Reopen the chat to unlock.');}else console.warn(e.message);}finally{running=false;}}
