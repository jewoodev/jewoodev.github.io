---
title : Jekyll web 구현해보기 on Ubuntu
date : 2023-04-16 17:36:00 +09:00
categories : [Web, Jekyll]
tags : [Install]
---

# Jekyll 이란?

지금 제가 글을 적고 있는 이 블로그는 Jekyll 을 사용해서 만들었습니다. Jekyll 은 정적 사이트 생성기로 깃헙 설립자 중 한 분이 Ruby 언어를 이용해 만든 프레임워크인데요. 깃헙 자체적으로 Jekyll Contents Management System을 내장하고 있어서 깃헙을 이용해 호스팅하기 적합합니다.

# Jekyll 설치

기본적으로 Ruby와 Jekyll 모두 Linux 에서 개발된 것들이기 때문에, Window 에서 사용하기에 조금의 어려움이 있습니다. 필자는 Ubuntu 20.04 에 Jekyll 을 설치합니다. 

먼저, Jekyll 을 설치하기 전에 필요한 모든 의존요소들을 가지고 있는지 확인해야 합니다.

```bash
sudo apt-get install ruby-full build-essential zlib1g-dev
```

루트 사용자로 루비 젬을 설치하는 것은 피하는게 좋습니다. 따라서, 일반 사용자 계정에 젬 설치 디렉토리를 설정할 필요가 있습니다. 다음 명령어들은 젬 설치 경로를 설정하는 환경설정 변수들을 ~/.bashrc 파일에 추가할 것입니다. 다음과 같이 실행하세요.

```bash
echo '# Install Ruby Gems to ~/gems' >> ~/.bashrc
echo 'export GEM_HOME="$HOME/gems"' >> ~/.bashrc
echo 'export PATH="$HOME/gems/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc
```

마지막으로, Jekyll 을 설치합니다.

```bash
gem install jekyll bundler
```

Jekyll 설치가 끝났습니다! 이제 Jekyll Web을 ```bundle exec jekyll serve``` command를 이용해 배포해보세요!

![image](https://user-images.githubusercontent.com/105477856/232289796-c37f9373-763e-484d-bc4c-9a15deb461d3.png)

이렇게 localhost:4000 으로 배포가 된 걸 확인하실 수 있을 겁니다!