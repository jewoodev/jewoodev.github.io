---
title : (SQL) 프로그래머스 - 131537. 오프라인／온라인 판매 데이터 통합하기
date : 2023-04-14 15:49:00 +09:00
categories : [Coding test, Programmers]
tags : [SQL]
---

## 문제 설명

<p>다음은 어느 의류 쇼핑몰의 온라인 상품 판매 정보를 담은 <code>ONLINE_SALE</code> 테이블과 오프라인 상품 판매 정보를 담은 <code>OFFLINE_SALE</code> 테이블 입니다. <code>ONLINE_SALE</code> 테이블은 아래와 같은 구조로 되어있으며 <code>ONLINE_SALE_ID</code>, <code>USER_ID</code>, <code>PRODUCT_ID</code>, <code>SALES_AMOUNT</code>, <code>SALES_DATE</code>는 각각 온라인 상품 판매 ID, 회원 ID, 상품 ID, 판매량, 판매일을 나타냅니다.</p>

| Column name | Type | Nullable |
| --- | --- | --- |
| ONLINE_SALE_ID | INTEGER | FALSE |
| USER_ID | INTEGER | FALSE |
| PRODUCT_ID | INTEGER | FALSE |
| SALES_AMOUNT | INTEGER | FALSE |
| SALES_DATE | DATE | FALSE |

<p>동일한 날짜, 회원 ID, 상품 ID 조합에 대해서는 하나의 판매 데이터만 존재합니다.</p>

<p><code>OFFLINE_SALE</code> 테이블은 아래와 같은 구조로 되어있으며 <code>OFFLINE_SALE_ID</code>, <code>PRODUCT_ID</code>, <code>SALES_AMOUNT</code>, <code>SALES_DATE</code>는 각각 오프라인 상품 판매 ID, 상품 ID, 판매량, 판매일을 나타냅니다.</p>

| Column name | Type | Nullable |
| --- | --- | --- |
| OFFLINE_SALE_ID | INTEGER | FALSE |
| PRODUCT_ID | INTEGER | FALSE |
| SALES_AMOUNT | INTEGER | FALSE |
| SALES_DATE | DATE | FALSE |

<p>동일한 날짜, 상품 ID 조합에 대해서는 하나의 판매 데이터만 존재합니다.</p>

<hr>

<h5>문제</h5>

<p><code>ONLINE_SALE</code> 테이블과 <code>OFFLINE_SALE</code> 테이블에서 2022년 3월의 오프라인/온라인 상품 판매 데이터의 판매 날짜, 상품ID, 유저ID, 판매량을 출력하는 SQL문을 작성해주세요. <code>OFFLINE_SALE</code> 테이블의 판매 데이터의 <code>USER_ID</code> 값은 NULL 로 표시해주세요. 결과는 판매일을 기준으로 오름차순 정렬해주시고 판매일이 같다면 상품 ID를 기준으로 오름차순, 상품ID까지 같다면 유저 ID를 기준으로 오름차순 정렬해주세요.</p>

<hr>

<h5>예시</h5>

<p>예를 들어 <code>ONLINE_SALE</code> 테이블이 다음과 같고</p>

| ONLINE_SALE_ID | USER_ID | PRODUCT_ID | SALES_AMOUNT | SALES_DATE |
| --- | --- | --- | --- | --- |
| 1 | 1 | 3 | 2 | 2022-02-25 |
| 2 | 4 | 4 | 1 | 2022-03-01 |
| 4 | 2 | 2 | 2 | 2022-03-02 |
| 3 | 6 | 3 | 3 | 2022-03-02 |
| 5 | 5 | 5 | 1 | 2022-03-03 |
| 6 | 5 | 7 | 1 | 2022-04-06 |

<p><code>OFFLINE_SALE</code> 테이블이 다음과 같다면</p>

| OFFLINE_SALE_ID | PRODUCT_ID | SALES_AMOUNT | SALES_DATE |
| --- | --- | --- | --- |
| 1 | 1 | 2 | 2022-02-21 |
| 4 | 1 | 2 | 2022-03-01 |
| 3 | 3 | 3 | 2022-03-01 |
| 2 | 4 | 1 | 2022-03-01 |
| 5 | 2 | 1 | 2022-03-03 |
| 6 | 2 | 1 | 2022-04-01 |

<p>각 테이블의 2022년 3월의 판매 데이터를 합쳐서, 정렬한 결과는 다음과 같아야 합니다.</p>

| SALES_DATE | PRODUCT_ID | USER_ID | SALES_AMOUNT |
| --- | --- | --- | --- |
| 2022-03-01 | 1 | NULL | 2 |
| 2022-03-01 | 3 | NULL | 3 |
| 2022-03-01 | 4 | NULL | 1 |
| 2022-03-01 | 4 | 4 | 1 |
| 2022-03-02 | 2 | 2 | 2 |
| 2022-03-02 | 3 | 6 | 3 |
| 2022-03-03 | 2 | NULL | 1 |
| 2022-03-03 | 5 | 5 | 1 |

> 출처: 프로그래머스 코딩 테스트 연습, https://programmers.co.kr/learn/challenges

## 풀이
```sql
SELECT *
FROM(
    SELECT 
        DATE_FORMAT(N.SALES_DATE, '%Y-%m-%d') SALES_DATE,
        N.PRODUCT_ID,
        N.USER_ID,
        N.SALES_AMOUNT
    FROM ONLINE_SALE N
    UNION ALL
    SELECT 
        DATE_FORMAT(F.SALES_DATE, '%Y-%m-%d') SALES_DATE,
        F.PRODUCT_ID,
        NULL USER_ID,
        F.SALES_AMOUNT
    FROM OFFLINE_SALE F
) T
WHERE T.SALES_DATE BETWEEN '2022-03-01' AND '2022-03-31'
ORDER BY T.SALES_DATE, T.PRODUCT_ID, T.USER_ID
```
UNION ALL을 이용해서 풀어야 했던 문제였습니다. 개인적으로 SQL Script를 작성하면서 UNION ALL을 처음 사용해야 했던 상황이었습니다. 
빈번하게 사용되지는 않지만, 꼭 필요할 때 떠올릴 수 있도록 '언제 쓰일 수 있는지' 생각해두면 좋은데, 그런 예시로 좋은 문제인 것 같습니다.
