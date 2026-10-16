# 10 shared-backend Android apps

10 brands: NovaTalk, OceanTalk, ForestTalk, EmberTalk, RoseTalk, ArcticTalk, SolarTalk, IndigoTalk, MintTalk, SlateTalk. Har app ka alag name, numbered/shaped color icon, accent/background/bubble/button colours aur corner styling hai. Folder/APK names Chat_01 ... Chat_10 hain; phone par brand name nazar aayega. Har app ka alag application ID hai. Sab existing https://chumairali.pythonanywhere.com/api se connect hain. Same backend hone ki wajah se accounts, contacts, chats aur media shared hain. Har installed app ka login/session apna hai; ek account se multiple apps mein login ya alag accounts register kar sakte ho. Naya account banane se uski alag identity hogi. App copies server capacity nahi barhati.

## Windows par build

ZIP ko Downloads mein extract karo. PowerShell:

```powershell
cd "$env:USERPROFILE\Downloads\WhatsAppClone_10_Apps"
Set-ExecutionPolicy -Scope Process -ExecutionPolicy RemoteSigned
.\BUILD_ALL.ps1
```

Agar extraction ne extra parent folder banaya ho, BUILD_ALL.ps1 wale folder mein terminal kholo. Is script ko PythonAnywhere par nahi chalana. Existing Flutter/Android SDK/JDK use honge. Internet dependencies download karne ke liye chahiye. 10 builds waqt aur disk space lenge. Pehle sirf pehli app check karna ho:

```powershell
.\BUILD_ALL.ps1 -From 1 -To 1
```

Success ke baad APKs/Chat_01.apk se APKs/Chat_10.apk milengi. Phone par APK copy karke install karo; Android install permission maang sakta hai. USB ya local backend app chalane ke liye zaroori nahi. Backend ke free hosting account ko active/renewed rakhna hai. Existing hosted backend ko dobara upload karna zaroori nahi.

Build fail ho to complete error share karo. Jis app par fail ho, misaal app 4, resume:

```powershell
.\BUILD_ALL.ps1 -From 4
```

## Folder map

Chat_01 ... Chat_10 = standalone Flutter source projects (Android identity configured). Shared_Backend = one reference copy of shared Flask/browser source. apps.json = names/package IDs/server mapping. BUILD_ALL.ps1 = release builds and APK collection.

This package configures Android clones only. iOS folders retain original identifiers: do not use them to claim 10 independent iOS apps. iOS identities/signing and Mac builds need separate setup.

## Verification and limits

All 10 source identities, XML resources, Dart titles and default backend URLs were checked. APKs have NOT been compiled here: Flutter execution was previously blocked by automatic approval review when SDK bootstrap attempted cloud metadata access. Run builds on your configured Windows machine. Existing release builds use the project's debug signing key: these APKs are for direct testing, not Play Store release. Keep the same signing key for future updates; proper release signing is required before distribution to a store.

The slow-app report has not been diagnosed/fixed in this package. Ten active apps can increase polling/server load. Existing scope remains: no full WhatsApp parity, E2E, background push/ringing, or guaranteed calling across every network. Calls may require a working TURN service.
