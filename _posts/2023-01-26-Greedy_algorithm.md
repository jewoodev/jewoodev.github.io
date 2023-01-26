---
title : 그리디 알고리즘
date : 2023-01-26 23:41:36 +09:00
categories : [Study, for_my_team]
tags : [algorithm]
---

오늘 제가 스터디에서 나누었던 문제가 적절하지 않기도 했고 준비도 미흡했던 걸 이유로 그리디 알고리즘 글을 만듭니다.  

문제는 백준 - 11047.동전 0 문제입니다.
  
  


# [Silver IV] 동전 0 - 11047 

[문제 링크](https://www.acmicpc.net/problem/11047) 

### 성능 요약

메모리: 30616 KB, 시간: 36 ms

### 분류

그리디 알고리즘(greedy)

### 문제 설명

<p>준규가 가지고 있는 동전은 총 N종류이고, 각각의 동전을 매우 많이 가지고 있다.</p>

<p>동전을 적절히 사용해서 그 가치의 합을 K로 만들려고 한다. 이때 필요한 동전 개수의 최솟값을 구하는 프로그램을 작성하시오.</p>

### 입력 

 <p>첫째 줄에 N과 K가 주어진다. (1 ≤ N ≤ 10, 1 ≤ K ≤ 100,000,000)</p>

<p>둘째 줄부터 N개의 줄에 동전의 가치 A<sub>i</sub>가 오름차순으로 주어진다. (1 ≤ A<sub>i</sub> ≤ 1,000,000, A<sub>1</sub> = 1, i ≥ 2인 경우에 A<sub>i</sub>는 A<sub>i-1</sub>의 배수)</p>

### 출력 

 <p>첫째 줄에 K원을 만드는데 필요한 동전 개수의 최솟값을 출력한다.</p>

# 고민의 칸
고민하시고 싶은 만큼 고민하실 수 있게 하기위해 만든 칸입니다.

# 고민의 칸
고민하시고 싶은 만큼 고민하실 수 있게 하기위해 만든 칸입니다.

# 고민의 칸
고민하시고 싶은 만큼 고민하실 수 있게 하기위해 만든 칸입니다.

# 고민의 칸
고민하시고 싶은 만큼 고민하실 수 있게 하기위해 만든 칸입니다.


___
여기부터 제 의견이 들어가므로 정답과 관련되 내용을 보아도 괜찮으실 때 확인해주세요.

저와 같은 부분에서 고민을 하셨을 수도, 아닐수도 있을 것 같습니다.
먼저, 처음에 접근했던 방식입니다.
"""
import sys
input = sys.stdin.readline
N, K = map(int, input().split())
coin_list = []
rmdr = K
cost_coin = 0
for i in range(N):
    coin_list.append(int(input()))
while 1:
    for i in range(len(coin_list)):
        if rmdr < coin_list[i]:
            cost_coin += rmdr // coin_list[i-1]
            rmdr = rmdr % coin_list[i-1]
            break
    if rmdr == 0:                          
        break
print(cost_coin)
"""

코인을 소모하는 최소 갯수를 구하기 위해 먼저 코인 리스트의 길이 만큼 반복하게 코드를 짜고, 그 안에서 소모 갯수와 나머지를 갱신하도록 했는데 정답이 되질 않았습니다. 여기서 어떤 이유로 오답 판정이 났을지 고민해보시면 좋을 것 같습니다.




다음은 최종 정답 코드입니다.
```
import sys
input = sys.stdin.readline
N, K = map(int, input().split())
coin_list = []
cost_coin = 0
for i in range(N):
    coin_list.append(int(input()))
coin_list.reverse()
for j in coin_list:
    if K - j >= 0:                 
        cost_coin += K // j
        K = K % j
    if K == 0:
        break
print(cost_coin)
```

동전을 역순으로 바꾸고 불필요한 절차를 줄였습니다. 그리고 ```if K - j >= 0:```에서 등호를 넣어 반례를 없앴습니다.

