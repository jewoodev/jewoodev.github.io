---
title : (WSL2) Ubuntu 20.04 설치
date : 2023-04-16 16:55:00 +09:00
categories : [Linux, Ubuntu]
tags : [WSL2]
---

이번에는 WSL2을 이용해서 가상머신에 Ubuntu 20.04 를 설치보겠습니다. 
필자의 PC 환경은 아래와 같습니다.
- OS : Windows 10 Pro

## WSL 란?
Windows 10 OS 에서 리눅스 운영체제의 쉘, 시스템을 사용할 수 있도록 지원하는 기능입니다.

개발, 코딩, 테스트, 서버 관리 등 많은 작업을 가상화를 통해서 리눅스를 띄우고 진행하는데, 이런 과정에 도움을 주는 좋은 기능이라고 생각하시면 될 거 같습니다. 

초창기에는 버그가 많았지만 현재 1버전이 안정화되고 2004 버전부터는 WSL2를 일반 사용자에게 제공해주고 있고, 해당 버전에 많은 기능 추가와 안정화가 진행되었기 때문에 두 버전 모두 사용하기 좋습니다. 

![image](https://user-images.githubusercontent.com/105477856/232198852-da8ccc64-420b-491d-993f-6e2973eb4d4e.png)

WSL2는 WSL1과 다르게 Hyper-V를 이용해 경량 VM 기술을 사용합니다. 그래서 기존 가상머신처럼 100% 리눅스 커널과 호환됩니다.
사용하는 커널은 마이크로소프트에서 직접 리눅스 4.19 버전 커널을 제공합니다.

게다가 가상머신처럼 메모리가 할당되고 WSL2부터는 가상 IP도 부여됩니다. 

이번 글에서는 WSL2 를 이용해보도록 하겠습니다.

## Windows 10에 WSL2 설치하기
WSL을 설치하려면 Windows 10의 20H1 버전 이상이어야 가능합니다. 만약에 해당 버전보다 낮은 상태라면 Windows Update 설정을 이용해 최신 버전으로 업데이트해주시기 바랍니다.

WSL2를 설치하기 위해서는 가상 터미널을 이용해야 합니다. 어떤 가상 터미널을 이용하면 되는지는 선택사항이지만, Windows Terminal을 추천합니다. Microsoft Store에서 download 할 수 있으며, Microsoft Store는 Window 검색 란에서 쉽게 찾을 수 있습니다.

![image](https://user-images.githubusercontent.com/105477856/232199584-23d9f225-ea84-4fbe-9685-388f581ba73a.png)

작업 표시줄에서 찾을 수 없다면 ```window 키 + s``` 를 눌러보시면 검색이 가능합니다.

그럼, 가상 터미널을 관리자 권한으로 실행해주세요. 가상 터미널 아이콘을 우측 마우스 클릭을 해서 나오는 옵션 중에 '관리자 권한으로 실행' 을 선택하시면 됩니다.

## DISM으로 WSL 관련 기능 활성화

DISM(배포 이미지 서비스 및 관리) 명령어로 Microsoft-Windows-Subsystem-Linux 기능을 활성화합니다.

```bash
$ dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart
버전: 10.0.19041.844

이미지 버전: 10.0.19043.928
기능을 사용하도록 설정하는 중
[==========================100.0%==========================]
```

다음으로 dism 명령어로 VirtualMachinePlatform 기능을 활성화합니다.

```bash
$ dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart
배포 이미지 서비스 및 관리 도구

이미지 버전: 10.0.19043.928

기능을 사용하도록 설정하는 중
[==========================100.0%==========================]
작업을 완료했습니다.
```

작업이 정상적으로 완료되었는지, 메시지를 꼭 확인해주세요. 터미널이 관리자 권한이 아닌 경우 작업이 실패합니다. 작업이 정상 완료되었다면 이 시점에 재부팅을 한 번 해줍니다.

## Microsoft Store에서 리눅스 설치

대망의 Linux 설치를 할 차례입니다! 준비되셨나요? ```Window key + s``` 를 눌러 가상 터미널을 관리자 권한으로 실행해주세요. 켜뒀던 터미널이 있다면 하지 않으셔도 좋습니다.

![image](https://user-images.githubusercontent.com/105477856/232200790-81179306-11f6-4f45-b1ec-d8d17090d08f.png)

터미널에 command를 입력해 설치할 수 있는 배포판 목록을 확인하고 설치해줍니다. 여기서 이야기하는 command는 두가지 입니다. 

```bash
wsl --list --online # 설치할 수 있는 유효한 배포판 목록
wsl --install -d {Distro} # 목록 중에 원하는 것을 설치
```

여기까지 해주셨다면, 설치가 시작될 겁니다. 그리고 설치가 완료되면 사용자에게 Ubuntu를 사용하면서 쓰일 사용자 이름과 암호를 기입하게 합니다. 그러면 원하는 이름과 암호를 기입하면 되는데, Ubuntu를 다루시면서 계속해서 쓸 내용이기 때문에 기억하실 수 있게 조치해주셔야 합니다.

그런데 만약 ```wsl --install -d {Distro}``` 를 입력했을 때 vitual machine 을 언급하는 오류가 뜬다? 거기에 대한 글은 추후 적을 예정입니다. 기다려주세요.

이후에는 관리자 권한이 필요하지 않은 터미널 작업을 할 겁니다. WSL 설치가 되었기 때문에 wsl command 를 사용할 수 있습니다. ```wsl -l -v``` 를 입력해 현재 설치된 리눅스의 상태를 확인해봅시다.

![image](https://user-images.githubusercontent.com/105477856/232201737-3bf2a300-2166-4d72-a83e-26ca3bed26ed.png)

Ubuntu 앞의 * 가 붙어 있는건 디폴트 머신임을 의미합니다. 그리고 VERSION 는 WSL의 버전을 의미합니다. 처음 확인하게 되면 WSL1로 지정되어 있을 수 있는데,

![image](https://user-images.githubusercontent.com/105477856/232201866-6fa265a4-b1fb-4a61-9973-ec3c42047b59.png)

```wsl --set-version {NAME}``` 을 이용해 버전을 바꿀 수 있습니다. 저는 이미 바뀌어져 있어 에러가 생기네요.

이제 설치가 완료되었습니다. Ubuntu 를 사용하실 수 있습니다 :)


## 참고 자료
[https://blog.dalso.org/linux/wsl2/10789](https://blog.dalso.org/linux/wsl2/10789)
