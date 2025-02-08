---
title : (WSL2) systemctl 명령어 에러
date : 2023-04-17 15:10:00 +09:00
categories : [Linux, Ubuntu]
tags : [Error]
---

wsl 을 사용하시다가 systemctl 명령어를 사용할 때 

![image](https://user-images.githubusercontent.com/105477856/232275285-eb591bb0-a5a4-48da-bb59-a91191b5bbe0.png)

와 연관된 에러가 발생하고, 에러를 해결하고 싶다면 아래 command 를 차례로 실행해주세요.

```bash
sudo -b unshare --pid --fork --mount-proc /lib/systemd/systemd --system-unit=basic.target
```

```bash
sudo -E nsenter --all -t $(pgrep -xo systemd) runuser -P -l $USER -c "exec $SHELL"
```