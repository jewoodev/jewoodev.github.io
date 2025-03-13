---
title : (WSL2) Ubuntu 22.04 에서 PostgreSQL 설치 오류, 완전 삭제
date : 2023-04-15 15:10:00 +09:00
categories : [Linux, Ubuntu]
tags : [PostgreSQL]
---

우분투에 PostgreSQL 을 설치하는데에 오류를 겪었고 그로 인해 계속해서 완전 삭제 후 재설치를 하는 과정을 겪어 같은 트러블 슈팅을 하고 계신 분들에게 제 경험을 나누려고 하는 글입니다.

먼저 제가 이 작업을 한 환경은 아래와 같습니다.
1. OS : Windows 10 pro
2. Ubuntu &rarr; WSL2에 Ubuntu 22.04 설치

계속해서 겪었던 오류는 해당 환경에서 PostgreSQL을 설치하고 구동할 때 "/var/run/postgresql/.s.pgsql.5432" 이라는 파일이 없는 탓이었습니다. 아무래도 Ubuntu 22.04 버전에 PostgreSQL 설치 오류 버그가 있는게 아닐까 싶습니다.

## PostgresSQL 완전 삭제

1. postgresql이 설치된 기본 폴더를 삭제합니다.
```bash
sudo rm -rf /var/lib/postgresql
```
2. postgresql 유저를 삭제합니다.
```bash
sudo userdel postgres
```
3. postgresql package를 삭제합니다.
```bash
sudo apt remove "postgresql*"
sudo apt --purge remove "postgresql*"
sudo apt autoremove 
# 순서대로 command를 입력했을 때 오류가 발생하면 다음 것을 진행한 후 다시 시도해보세요
```
4. postgresql 완전 삭제가 됐는지 확인
```bash
dpkg -l | grep postgres*
```
아무것도 검색되지 않으면 완전 삭제가 잘된 것입니다.
