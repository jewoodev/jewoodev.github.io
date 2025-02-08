---
title : (WSL2) Ubuntu dpkg 에러
date : 2023-04-15 15:10:00 +09:00
categories : [Linux, Ubuntu]
tags : [Error]
---

우분투에서 프로그램을 설치하다보면 dpkg 에러를 만나기도 합니다. 만약 dpkg 에러를 없애고 싶다면 아래의 command 를 실행해주세요.

```bash
sudo rm /var/lib/dpkg/info/*
sudo dpkg --configure -a
sudo apt update -y
```
