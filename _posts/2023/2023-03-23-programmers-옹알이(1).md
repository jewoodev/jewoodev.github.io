---
title : 프로그래머스 - 옹알이 (1), 120956번
date : 2023-03-24 14:44:00 +09:00
categories : [Coding test, Programmers]
tags : [Python]
---

## 문제 설명

<p>머쓱이는 태어난 지 6개월 된 조카를 돌보고 있습니다. 조카는 아직 "aya", "ye", "woo", "ma" 네 가지 발음을 최대 한 번씩 사용해 조합한(이어 붙인) 발음밖에 하지 못합니다. 문자열 배열 <code>babbling</code>이 매개변수로 주어질 때, 머쓱이의 조카가 발음할 수 있는 단어의 개수를 return하도록 solution 함수를 완성해주세요.</p>

<hr>

<h5>제한사항</h5>

<ul>
<li>1 ≤ <code>babbling</code>의 길이 ≤ 100</li>
<li>1 ≤ <code>babbling[i]</code>의 길이 ≤ 15</li>
<li><code>babbling</code>의 각 문자열에서 "aya", "ye", "woo", "ma"는 각각 최대 한 번씩만 등장합니다.

<ul>
<li>즉, 각 문자열의 가능한 모든 부분 문자열 중에서 "aya", "ye", "woo", "ma"가 한 번씩만 등장합니다.</li>
</ul></li>
<li>문자열은 알파벳 소문자로만 이루어져 있습니다.</li>
</ul>

<hr>

<h5>입출력 예</h5>

| babbling                                   | result  |
|:-------------------------------------------|--------:|
| ["aya", "yee", "u", "maa", "wyeoo"]        | 1       |
| ["ayaye", "uuuma", "ye", "yemawoo", "ayaa"]| 3       |

<h5>입출력 예 설명</h5>

<p>입출력 예 #1</p>

<ul>
<li>["aya", "yee", "u", "maa", "wyeoo"]에서 발음할 수 있는 것은 "aya"뿐입니다. 따라서 1을 return합니다.</li>
</ul>

<p>입출력 예 #2</p>

<ul>
<li>["ayaye", "uuuma", "ye", "yemawoo", "ayaa"]에서 발음할 수 있는 것은 "aya" + "ye" = "ayaye", "ye", "ye" + "ma" + "woo" = "yemawoo"로 3개입니다. 따라서 3을 return합니다.</li>
</ul>

<hr>

<h5>유의사항</h5>

<ul>
<li>네 가지를 붙여 만들 수 있는 발음 이외에는 어떤 발음도 할 수 없는 것으로 규정합니다. 예를 들어 "woowo"는 "woo"는 발음할 수 있지만 "wo"를 발음할 수 없기 때문에 할 수 없는 발음입니다.</li>
</ul>

<hr>

## 풀이
발음이 가능한 단어들을 순열로 뽑아 경우의 수를 구성해 풀 수 있다.
```python
import itertools

def solution(babbling):
    global l1
    l1 = ["aya", "ye", "woo", "ma"]
    l2 = list(itertools.permutations(l1, 2))
    l3 = list(itertools.permutations(l1, 3))
    l4 = list(itertools.permutations(l1, 4))
    print(l2)
    l2_2 = []
    l3_2 = []
    l4_2 = []
    for i in range(len(l2)):
        l2_2.append("".join(l2[i]))
    for i in range(len(l3)):
        l3_2.append("".join(l3[i]))
    for i in range(len(l4)):
        l4_2.append("".join(l4[i]))
    l1.extend(l2_2)
    l1.extend(l3_2)
    l1.extend(l4_2)
    count = 0
    for i in babbling:
        if i in l1:
            count += 1
    return count
```
#### 다른 풀이
```python
from itertools import permutations
def solution(babbling):
    answer = 0
    speek = ["aya","ye","woo","ma"]
    word = []
    for i in range(1, len(speek)+1):
        for j in permutations(speek, i):
            word.append(''.join(j))

    for i in babbling:
        if i in word:
            answer += 1

    return answer
```
