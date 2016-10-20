To setup passwrodless clone to your github repo:

1: `ssh-keygen -t ed25519`
(need to read about ed25519 vs rsa )

2: Add this is you .ssh/config file

```
Host *
    ForwardAgent yes
    ServerAliveInterval 60
```

3: To verify whether its working or not, just do ,
  ssh git@github.com and it will tell you whether you are authenticated or not.
