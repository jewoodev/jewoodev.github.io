---
title : Docker 명령어 정리
date : 2023-06-30 12:55:00 +09:00
categories : [Docker, Command]
tags : [Summary]
---

## 도커 이미지 검색

```bash
docker images
```

![image](https://github.com/jewoodev/jewoodev.github.io/assets/105477856/387078bb-198b-4f11-a8ac-38f463a3d3ff)

### 1. 도커 이미지 삭제

```bash
docker images rm <image ID>
```

해당 이미지를 컨테이너에서 사용하고 있으면 이미지를 삭제할 수 없습니다.

### 2. 모든 이미지 삭제

```bash
docker rm $(docker images -q) -f
```

(docker image -q)라는 명령어는 이미지의 ID를 출력하는 명령어입니다.

## 도커 컨테이너 생성

```bash
docker run <옵션> --name <컨테이너이름> <이미지 Repository>
```

생성과 동시에 실행하는 명령어입니다.

> 옵션
- i : 사용자가 입출력을 할 수 있는 상태
- t : 가상 터미널 환경을 에뮬레이션하겠다는 말
- d : 컨테이너를 일반 프로세스가 아닌 데몬프로세스(백그라운드) 형태로 실행해 프로세스가 끝나도 유지되도록 한다.

세가지 옵션을 다 사용하려면
```bash
docker run -itd --name <컨테이너이름> <이미지 Repository>
```

### 1. 실행으로 이어지지 않는 생성

```bash
docker create <옵션> --name <컨테이너이름> <이미지 Repository>
```

실행을 하는 것이 아니기 때문에 옵션은 -it까지만 허용됩니다!

## 컨테이너 목록 조회

```bash
docker ps
```

> 옵션
- a : 모든 컨테이너 (이 옵션이 없으면 실행중인 것만 출력)

## 컨테이너 접속

1. running 컨테이너

```bash
docker exec -it <컨테이너이름> /bin/bash
```

2. exception

```bash
docker attach 컨테이너ID
```

## 컨테이너 연결 끊기

1. 컨테이너를 종료하면서 빠져나오기

```bash
exit 또는 ctrl+D
```

2. 컨테이너가 가동되는 상태를 유지하면서 접속만 종료하기

```bash
ctrl + P 입력 후 Q 입력
```

## 컨테이너 실행/종료

1. 실행

```bash
docker start <컨테이너이름>
```

2. 종료

```bash
docker stop <컨테이너이름>
```

## 컨테이너 삭제

```bash
docker rm <컨테이너이름>
```
