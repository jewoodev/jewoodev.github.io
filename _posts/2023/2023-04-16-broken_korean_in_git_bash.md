---
title : Git bash 에서 한글깨짐 문제 해결
date : 2023-04-17 09:20:00 +09:00
categories : [Git, Korean]
tags : [Config]
---

Git bash 혹은 CLI 로 git을 사용 시 한글 내용이 깨지는 현상이 발생합니다. 아주 자연스러운 현상이에요.

![image](https://user-images.githubusercontent.com/105477856/232352355-140778e5-14d7-4dfa-805d-981ecc4e24c2.png)

이렇게 git 에서 알려줘도 당황하지 않으셔도 됩니다. Git config 를 조금만 만져주면 해결이 되거든요.

```bash
git config --global core.quotepath false
```

한글이 깨지는 이유는, 큰 바이트를 가진 문자를 unusual인 케이스로 포함되기 때문이라고 합니다. 따라서 core.quotepath 라는 config 를 false로 셋팅해주면 한글이 unusual 케이스로 분류되지 않고 정상적으로 출력되는걸 확인하실 수 있습니다.
