---
title : Docker container 와 Local 간의 파일 이동, 볼륨 마운트
date : 2023-06-30 13:26:00 +09:00
categories : [Docker, Command]
tags : [Summary]
---

## 파일 이동
```bash
# 로컬에서 컨테이너로 파일을 복사
docker cp [호스트 경로] [컨테이너 이름:컨테이너 경로]

# 컨테이너에서 로컬로 파일 복사
docker cp [컨테이너 이름:컨테이너 경로] [호스트 경로]
```

## 볼륨 마운트
```bash
docker run -itd --name [컨테이너 이름] --mount "$(pwd)"/target:/[컨테이너 위치] [이미지 이름:버전]
```
