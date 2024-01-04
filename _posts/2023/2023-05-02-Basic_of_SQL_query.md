---
title : 기본 SQL 
date : 2023-05-02 14:51:00 +09:00
categories : [SQL, Base]
tags : [Base]
---

> 이 글은, [프로그래머스에서 진행되는 실리콘밸리에서 날아온 데이터 엔지니어링 키트 with Python](https://school.programmers.co.kr/learn/courses/16448/16448-%EB%9D%BC%EC%9D%B4%EB%B8%8C12%EA%B8%B0-%EC%8B%A4%EB%A6%AC%EC%BD%98%EB%B0%B8%EB%A6%AC%EC%97%90%EC%84%9C-%EB%82%A0%EC%95%84%EC%98%A8-%EB%8D%B0%EC%9D%B4%ED%84%B0-%EC%97%94%EC%A7%80%EB%8B%88%EC%96%B4%EB%A7%81-%EC%8A%A4%ED%83%80%ED%84%B0-%ED%82%A4%ED%8A%B8-with-python)에서 배운 내용을 바탕으로 이루어져 있습니다.

<br>
이번 글에서는 기본적인 SQL 쿼리문들을 정리해보겠습니다. 먼저 DDL입니다.

# DDL - 테이블 구조 정의 언어
- CREATE TABLE
  - Primary key 속성을 지정할 수는 있지만 Big data 데이터 웨어하우스에서는 uniqueness가 지켜지지 않습니다. (Redshift, Snowflake, BigQuery) 혹시 여기에 대해 궁금하시다면 더 자세한 내용은 [링크](https://jewoodev.github.io/posts/Redshift/)를 참고해주세요. 
- CTAS
  - CREATE TABLE schema_name.table_name AS SELECT
  - vs. CREATE TABLE and then INSERT

```sql
CREATE TABLE raw_data.user_session_channel (
    userid int,
    sessionid varchar(32) PRIMARY KEY,
    channel varchar(32)
);
```

## CTAS의 장점과 단점
- Table을 만들면서 동시에 record까지 적재함으로써 **간편하게** summary table을 생성합니다.
- Test를 해볼 수 없고 만들어지는 Table의 Column을 세밀하게 조정할 수가 없습니다. 관계형 데이터베이스 시스템에서 SELECT를 만들면서 결정한 Type이 최종 Table의 Column들의 Type이 됩니다.

- DROP TABLE
  - DROP TABLE schema_name.table_name;
    - 없는 테이블을 DROP하려고 할 때 error를 일으킵니다.
  - DROP TABLE **IF EXISTS** table_name; 
    - 만약에 이미 존재하는 테이블이 있는 경우에만 DROP하도록 조건을 주면 해결이 됩니다.
  - vs. DELETE FROM
    - DELETE FROM은 조건에 맞는 레코드들을 지웁니다. (테이블 자체는 존재)

- ALTER TABLE
  - 새로운 컬럼 추가:
    - `ALTER TABLE 테이블이름 ADD COLUMN 필드이름 필드타입;`
  - 기존 컬럼 이름 변경:
    - `ALTER TABLE 테이블이름 RENAME 현재필드이름 TO 새필드이름;`
  - 기존 컬럼 제거:
    - `ALTER TABLE 테이블이름 DROP COLUMN 필드이름;`
  - 테이블 이름 변경:
    - `ALTER TABLE 현재테이블이름 RENAME TO 새테이블이름;`

# DML - 테이블 레코드 조작
- 레코드 수정 언어:
  - INSERT INTO : 테이블에 레코드를 추가하는데 사용
  - UPDATE FROM : 테이블 레코드의 필드 값 수정
  - DELETE FROM : 테이블에서 레코드를 삭제
    - vs TRUNCATE 혹시 DELETE와 TRUNCATE의 차이점은 어떤 것인지 궁금하시면 [링크](https://jewoodev.github.io/posts/Four_parts_of_SQL/)의 마지막 부록 부분을 참고해주세요

- 레코드 질의 언어: SELECT
  - SELECT FROM: 테이블에서 레코드와 필드를 읽어오는데 사용
  - WHERE를 사용해서 레코드 선택 조건을 지정
  - GROUP BY를 통해 정보를 그룹 레벨에서 뽑기 위해 사용하기도 함
    - **DAU, WAU, MAU 계산은 GROUP BY를 필요로 함**
    - ORDER BY를 사용해서 레코드 순서를 결정하기도 함
    - 보통 다수의 테이블을 조인해서 사용하기도 함

SELECT는 여러가지 용도로 쓰일 수 있습니다. 다음으로 몇가지를 살펴보겠습니다.

# SELECT
## COUNT
SELECT와 COUNT를 사용하면 여러가지를 확인할 수 있습니다.

| value |
| --- |
| 1 |
| 2 |
| 3 |
| NULL |

```sql
SELECT COUNT(1) FROM count_test; 
SELECT COUNT(value) FROM count_test; 
SELECT COUNT(DISTINCT value) FROM count_test;
```

SELECT문에서 COUNT 함수를 쓰면, SELECT문에서 선택한 레코드의 수만큼 반복하면서 갯수를 세어줍니다.
1. COUNT 함수의 인자값으로 NULL이 아닌 값은 어떤걸 넣든지 레코드 수만큼 반복하면서 1을 더해가서 레코드가 몇개가 있는지 세어줍니다.
2. NULL을 넣어주면 세지 않습니다.
3. 테이블의 필드이름을 넣어주면 그 필드에 NULL값을 제외하고 갯수를 세어줍니다.
4. DISTINCT를 붙이면 같은 값은 한번만 세어서 몇개인지 세어줍니다.

그리고 전체 record의 수를 셀 땐 `COUNT(1)`처럼 1을 넣는 것이 개발자들 사이에서의 관례입니다.  
## WHERE
WHERE를 사용해 특정 조건을 만족하는 레코드를 읽어올 수 있습니다.
```sql
SELECT *
FROM test
WHERE value > 1;
```

## GROUP BY
테이블의 특정 컬럼을 기준으로 값이 같은 것들을 grouping해서 값이 같은 것들의 대표값을 만들어 계산하는 경우 사용할 수 있습니다. 이 경우 grouping하는 컬럼들이 있고 같은 값으로 grouping 되는 컬럼들을 대상으로 aggregation 함수(count, sum, min, max, average ...)가 있어야 합니다. 

GROUP BY로 컬럼을 지정할 때 필드이름이 아니라 SELECT에 지정되는 순서대로 번호를 매겨서 지정할 수도 있습니다.

## 기존의 테이블을 이용해 새로운 column 생성
쇼핑몰 사이트의 사용자 행동 데이터 테이블에서 MAU(Monthly Active User)를 계산할 때, timestamp field '연도 4자리-월 2자리'라는 새로운 컬럼을 만들어서 사용할 수 있습니다.
### timestamp field 다루기
timestamp field에서 용도에 따라서 변환하는 작업이 필요한 경우가 있습니다. 그럴 때 변환하기위해 아래의 방법들을 사용할 수 있습니다.
- LEFT(A.ts, 7)
    - TIMESTAMP에서 처음 7자리만 읽어오는 것
- SUBSTRING(A.ts, 1, 7)
    - TIMESTAMP에서 첫번째 자리부터 7개의 글자를 EXTRACT 하는 것
- DATE_TRUNC(’month’, A.ts)
    - 이건 년도까지 뽑는 건 아니고 월만 뽑는 것

## Window 함수
쇼핑몰 사이트의 신규 가입자의 채널 세션 데이터에서 처음 사이트를 접근하게 된 경로 채널과 가입하기 전에 마지막으로 접근한 경로 채널을 구하려고 하면, Window 함수를 이용해 구해낼 수 있습니다.  
그 중 하나인 ROW_NUMBER()을 사용해서 구해내보도록 하겠습니다.

## ROW_NUMBER
### 기존의 테이블

| userid | time | channel |
| --- | --- | --- |
| 10 | 2023-01-10 | google |
| 10 | 2023-01-15 | youtube |
| 11 | 2023-01-07 | instagram |
| 11 | 2023-01-03 | facebook |
| 10 | 2023-01-17 | naver |

### ROW_NUMBER로 새로운 column 추가, 어떤 의미가 있을까? 

| userid                               | time | channel | seq                               |
|--------------------------------------| --- | --- |-----------------------------------|
| 10 | 2023-01-10 | google | 1 |
| 10  | 2023-01-15 | youtube | 2 |
| 10  | 2023-01-17 | naver | 3 |
| <span style="color:gray">11</span> | 2023-01-03 | facebook | <span style="color:gray">1</span> |
| <span style="color:gray">11</span> | 2023-01-07 | instagram | <span style="color:gray">2</span> |

ROW_NUMBER 함수는 이름 그대로 레코드에 번호를 매기는 함수입니다. 이런 ROW_NUMBER 함수를 어떻게 사용할 수 있을까요? 

ROW_NUMBER은 `ROW_NUMBER() OVER(partition by userid order by time ASC) seq` 와 같은 Syntax로 작동합니다. 이 query가 작동되는 논리는 이렇습니다.
1. `partition by` 뒤에 일련번호를 매길 partition을 어떻게 나눌지 지정합니다. 이건 마치 `GROUP BY`로 grouping하는 것과 비슷합니다. userid로 지정한다면 같은 userid끼리 묶어서 그 덩어리 안에서 일련번호를 매겨줍니다.
2. `order by` 뒤에 어떤 field를 기준으로 어떤 방식(오름차순, 내림차순)으로 정렬할 것인지 지정합니다. 예시에서는 시간을 기준으로 오름차순 정렬을 줬네요. 가장 이른 시간대의 레코드가 '1번'을 갖게 될 것입니다. 

어떻게 하면 될지 감이 오시나요? 조금 더 힌트를 드리자면 ROW_NUMBER 함수를 이용해서 `order by time` 에 `ASC` 과 `DESC` 을 각각 먹이면, 그 일련번호의 각 '1번'들은 어떤 값을 갖게 될까요?  

함께 SQL의 기본적인 내용들을 몇가지 살펴보았습니다. 아직 다루지 못한 내용들이 있는데 기회가 된다면 그런 내용도 다뤄보도록 하겠습니다. 
