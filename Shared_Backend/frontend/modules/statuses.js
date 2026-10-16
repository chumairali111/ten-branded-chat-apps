import{state,$,api,esc,modal,closeModal,action,empty}from'./api.js';
export async function showStatuses(){
 const d=await api('/statuses');
 $('sidebar-content').innerHTML=`<button id="post-status" class="primary">＋ Add story</button>${d.statuses.map(s=>`<article class="status-card"><strong>${esc(s.name)}</strong><p>${esc(s.body)}</p><small>${new Date(s.created*1000).toLocaleString()}${s.user_id===state.user.id?` · ${s.views} views`:''}</small><button data-view="${s.id}">View ${esc(s.kind)}</button>${s.user_id===state.user.id?`<button data-viewers="${s.id}">Viewers</button><button class="danger" data-delete="${s.id}">Delete</button>`:''}</article>`).join('')||empty('No active stories. Stories expire after 24 hours.')}`;
 $('post-status').onclick=()=>{
  modal('Share a story',`<label>Text / caption<textarea id="story-text" maxlength="700"></textarea></label><label>Image or video (optional, max 20 MB)<input id="story-file" type="file" accept="image/png,image/jpeg,image/webp,image/gif,video/mp4,video/webm,video/quicktime"></label><button id="share-story" class="primary">Share</button>`);
  $('share-story').onclick=action(async()=>{
   const button=$('share-story');button.disabled=true;
   try{const file=$('story-file').files[0];let media_id;
    if(file){if(file.size>20*1024*1024)throw Error('Maximum story size is 20 MB');const form=new FormData();form.append('file',file);media_id=(await api('/media/status','POST',form)).id;}
    await api('/statuses','POST',{body:$('story-text').value,...(media_id?{media_id}: {})});closeModal();await showStatuses();
   }finally{button.disabled=false;}
  });
 };
 document.querySelectorAll('[data-view]').forEach(b=>b.onclick=action(async()=>{
  const s=d.statuses.find(s=>s.id===+b.dataset.view);await api(`/statuses/${s.id}/view`,'POST',{});
  const media=s.media_id?(s.kind==='image'?`<img class="story-media" src="/api/media/${esc(s.media_id)}" alt="Story image">`:`<video class="story-media" controls playsinline src="/api/media/${esc(s.media_id)}"></video>`):'';
  modal(s.name,`${media}<p>${esc(s.body)}</p>`);await showStatuses();
 }));
 document.querySelectorAll('[data-viewers]').forEach(b=>b.onclick=action(async()=>{
  const result=await api(`/statuses/${b.dataset.viewers}/viewers`);modal('Story viewers',result.viewers.map(v=>`<p><strong>${esc(v.name)}</strong> · ${v.viewed_at?new Date(v.viewed_at*1000).toLocaleString():'Viewed'}</p>`).join('')||'<p>No views yet.</p>');
 }));
 document.querySelectorAll('[data-delete]').forEach(b=>b.onclick=action(async()=>{if(!confirm('Delete this story?'))return;await api(`/statuses/${b.dataset.delete}`,'DELETE');await showStatuses();}));
}
