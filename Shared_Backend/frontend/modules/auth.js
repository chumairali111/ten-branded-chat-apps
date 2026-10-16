import{state,$,api,toast}from'./api.js';
export function setupAuth(onReady){
 $('switch-auth').onclick=()=>{state.register=!state.register;$('name-label').hidden=!state.register;$('name').required=state.register;$('auth-submit').textContent=state.register?'Create account':'Sign in';$('switch-auth').textContent=state.register?'Already registered? Sign in':'New here? Create account';};
 $('auth-form').onsubmit=async e=>{e.preventDefault();$('auth-error').textContent='';$('auth-submit').disabled=true;try{const d=await api(state.register?'/register':'/login','POST',{username:$('username').value,password:$('password').value,name:$('name').value});await ready(d,onReady);}catch(e){$('auth-error').textContent=e.message;}finally{$('auth-submit').disabled=false;}};
 api('/me').then(d=>ready(d,onReady)).catch(()=>{});
}
async function ready(d,onReady){state.user=d.user;state.csrf=d.csrf;$('auth').hidden=true;$('workspace').hidden=false;$('password').value='';$('my-avatar').textContent=state.user.name[0].toUpperCase();await onReady();}
