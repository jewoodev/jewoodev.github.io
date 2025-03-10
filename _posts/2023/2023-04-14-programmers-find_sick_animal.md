---
title : (SQL) 프로그래머스 - 59037. 어린 동물 찾기
date : 2023-04-14 16:22:00 +09:00
categories : [Coding test, Programmers]
tags : [SQL]
---

## 문제 설명

<p><code>ANIMAL_INS</code> 테이블은 동물 보호소에 들어온 동물의 정보를 담은 테이블입니다. <code>ANIMAL_INS</code> 테이블 구조는 다음과 같으며, <code>ANIMAL_ID</code>, <code>ANIMAL_TYPE</code>, <code>DATETIME</code>, <code>INTAKE_CONDITION</code>, <code>NAME</code>, <code>SEX_UPON_INTAKE</code>는 각각 동물의 아이디, 생물 종, 보호 시작일, 보호 시작 시 상태, 이름, 성별 및 중성화 여부를 나타냅니다.</p>

| NAME | TYPE | NULLABLE |
| --- | --- | --- |
| ANIMAL_ID | VARCHAR(N) | FALSE |
| ANIMAL_TYPE | VARCHAR(N) | FALSE |
| DATETIME | DATETIME | FALSE |
| INTAKE_CONDITION | VARCHAR(N) | FALSE |
| NAME | VARCHAR(N) | TRUE |
| SEX_UPON_INTAKE | VARCHAR(N) | FALSE |

<p>동물 보호소에 들어온 동물 중 젊은 동물<sup id="fnref1"><a href="#fn1">1</a></sup>의 아이디와 이름을 조회하는 SQL 문을 작성해주세요. 이때 결과는 아이디 순으로 조회해주세요. </p>

<h5>예시</h5>

<p>예를 들어 <code>ANIMAL_INS</code> 테이블이 다음과 같다면</p>

| ANIMAL_ID | ANIMAL_TYPE | DATETIME | INTAKE_CONDITION | NAME | SEX_UPON_INTAKE |
| --- | --- | --- | --- | --- | --- |
| A365172 | Dog | 2014-08-26 12:53:00 | Normal | Diablo | Neutered Male |
| A367012 | Dog | 2015-09-16 09:06:00 | Sick | Miller | Neutered Male |
| A365302 | Dog | 2017-01-08 16:34:00 | Aged | Minnie | Spayed Female |
| A381217 | Dog | 2017-07-08 09:41:00 | Sick | Cherokee | Neutered Male |

<p>이 중 젊은 동물은 Diablo, Miller, Cherokee입니다. 따라서 SQL문을 실행하면 다음과 같이 나와야 합니다. </p>

| ANIMAL_ID | NAME |
| --- | --- |
| A365172 | Diablo |
| A367012 | Miller |
| A381217 | Cherokee |

<hr>

<p>본 문제는 <a href="https://www.kaggle.com/aaronschlegel/austin-animal-center-shelter-intakes-and-outcomes" target="_blank" rel="noopener">Kaggle의 "Austin Animal Center Shelter Intakes and Outcomes"</a>에서 제공하는 데이터를 사용하였으며 <a href="https://opendatacommons.org/licenses/odbl/1.0/" target="_blank" rel="noopener">ODbL</a>의 적용을 받습니다.</p>

<div class="footnotes">
<hr>
<ol>

<li id="fn1">
<p><code>INTAKE_CONDITION</code>이 Aged가 아닌 경우를 뜻함&nbsp;<a href="#fnref1">↩</a></p>
</li>

</ol>
</div>


> 출처: 프로그래머스 코딩 테스트 연습, https://programmers.co.kr/learn/challenges

## 풀이
```sql
SELECT ANIMAL_ID, NAME
FROM ANIMAL_INS
WHERE INTAKE_CONDITION != 'Aged'
ORDER BY ANIMAL_ID;
```
젊은 동물을 조회해야하는데, 이에 대한 기준이 명확하지 않아서 '주어진 데이터에서 어떤 걸 기준으로 젋다고 판단해야하는걸까?'하는 고민이 휩싸였었습니다. 다른 분들도 데이터를 다루다보면 이런 고민을 할 때가 있을 것 같아 예시로 남겨둡니다.
- - - 
> INTAKE_CONDITION 에 Aged 라는 항목이 존재하는데, 다른 값을 갖고 있는 동물의 경우 나이 든게 아니라고 가정해서 풀었을 때 정답처리가 되었습니다.
