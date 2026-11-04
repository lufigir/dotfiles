---
name: remote-session
description: Open a new Remote Control session in a repo on this machine, with either Claude account, to use it from the phone. Spanish triggers: "ábreme una sesión en", "abre otra sesión en", "inicia una sesión en <repo>", "sesión con la otra cuenta".
---

1. Take the repo (a folder name under `D:\Code`) and the account from the request. With no account named, leave `-Account` out and the script stays on this session's account.
2. Run the script:

   ```
   pwsh -File "<skill dir>/open.ps1" -Repo <repo> [-Account lgiraldoo|luisgir827] [-Name <title>]
   ```

   It marks the repo as trusted for that account and starts the session detached with permissions bypassed. The session survives the one that opened it, and its process exits when the user archives it.
3. Report the URL and the account the script printed. The session shows up in the phone's Code tab only under that account.

*Done:* the script printed a URL, or the user has its error.
