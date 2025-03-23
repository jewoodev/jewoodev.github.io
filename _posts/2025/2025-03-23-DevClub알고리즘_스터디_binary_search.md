---
title : "Dev Club 알고리즘 스터디, 이진 탐색"
date : 2025-03-23 14:55:00 +09:00
categories : [Algorithm, Binary search]
tags : [Binary search]
math : true
image:
---

이번 포스팅에선 알고리즘 권위자, 라는 말이 어울리는 Jason 멘토님과 함께 했던 이진 탐색에 대한 스터디를 공유하려고 한다. 알고리즘을 잘하면 이렇게 커리어를 자유롭게 만들어 갈 수 있구나, 생각이 드는 경험을 나눠주시기도 했던 분인데 어떤 이야기인지 궁금하다면 Dev Club에 참여해보는 것을 추천한다.

> [Dev Club](https://f-lab.kr/dev-club)은 F-Lab에서 주최하는 개발자들을 위한 커뮤니티로, 다양한 주제로 세미나와 네트워킹 행사를 열고 있다. 월 회비를 크게 할인하고 있어, 부담없이 참여해볼 수 있다. 

## 1. 이진 탐색을 써야하는 문제인지 모르겠다면, 알려드리는게 인지상정

이런 걸 요구하면 이진 탐색을 적용하여 풀기에 좋은 문제이다. 

#### _"최솟값과 최댓값이 정해져 있고 그 사이에서 그 조건을 만족하는 가장 작은 값, 어느 순간부터 true가 되고 그 이후는 모두 true다."_ 

혹은

#### _~한 값들 중에 최소값을 찾아라._

와 같은 메세지가 있다면 그것은 이진 탐색 냄새가 나는 것이다..

`fffffffff.... ttttttt`

> f: false / t: true

위처럼 어떤 조건을 만족하지 않는 것과 만족하는 것이 나뉘어지는데 그 중에 최솟값을 찾으려면 이진탐색을 하는 것이다.

t인 값들 중에 최솟값을 찾으라는 문제면 가운데를 찍어서 f일 때 왼쪽 값들은 볼 필요가 없게 되는, 효율적인 탐색을 할 수 있기 때문이다.

그리고

_`while(l <= r)`과 `while(l < r)`_ 와 같은 조건문을 사용해서 이진 탐색을 진행한다고 생각하면 쉽다. 

전자는 m = l = r 인 경우도 확인해봐야 할 때 필요한 조건문이다. 이진탐색을 다음 단계로 넘어갈 때 t로 바뀌는게 명확하다면 `l <= r` 조건을 사용해도 되지만 아니라면 무한 루프에 빠질 위험이 있다.

## 2. 실제로 사용해보자.

[LeetCode 278](https://leetcode.com/problems/first-bad-version/description/) 문제에 우리가 배운 이론을 사용해보자.

다음은 문제의 설명이다.

You are a product manager and currently leading a team to develop a new product. Unfortunately, the latest version of your product fails the quality check. Since each version is developed based on the previous version, all the versions after a bad version are also bad.

Suppose you have n versions [1, 2, ..., n] and you want to find out the first bad one, which causes all the following ones to be bad.

You are given an API bool isBadVersion(version) which returns whether version is bad. Implement a function to find the first bad version. You should minimize the number of calls to the API.

문제의 설명에서 각 버전은 이전 버전을 베이스로 만들어지기 때문에, 한 번 bad 버전이 출연하면 이후의 버전은 모두 bad임을 설명하고 있다. 그리고 요구되는 것이 첫 번째 bad 버전의 위치를 찾는 것이다.

우리가 1절에서 살펴본 이진 탐색의 냄새가 이제 당신에게 나는가? 그렇다.. 우리는 모두 느끼고 있다.

그렇다면 이미 다 푼 것이나 다름없다. 가보자.

```java
public class Solution extends VersionControl {
    public int firstBadVersion(int n) {
        int l = 1, r = n;
       
        while (l < r) {
            int m = l + (r - l) / 2;
           
            if (isBadVersion(m)) {
                r = m;
            } else {
                l = m + 1;
            }
        }
       
        return l;
    }
}
```

## 마무리

아직 설명이 부족한 거 같으므로 차차 내용을 좀 더 추가할 예정이다. 다른 사람들도 이진 탐색을 좋아하게 되길 바라며 마치겠다.
