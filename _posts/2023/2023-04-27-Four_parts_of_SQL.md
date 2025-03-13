---
title : SQL의 DDL, DML, DCL, TCL은 뭘까?
date : 2023-04-27 00:20:00 +09:00
categories : [SQL, Base]
tags : [Base]
---

![image](https://user-images.githubusercontent.com/105477856/234650836-3426fa67-0e98-4a60-9ee1-a3d97b331882.png)

## 1. SQL이란?
SQL은 <span style="color:blueviolet">Structured Query Language</span> (구조적 질의 언어)의 줄임말로, <span style="color:blueviolet">관계형 데이터베이스 관리 시스템(RDBMS)</span>의 데이터를 처리하고 저장하기 위해 설계된 특수 목적의 프로그래밍 언어입니다. 

**관계형 데이터베이스**는 정보를 **표** 형식으로 저장하며, **행과 열**은 **데이터 속성**과 **데이터 값** 간의 다양한 관계를 나타냅니다. 

SQL 문을 사용해서 데이터베이스에서 정보를 **저장, 업데이트, 제거, 검색**하는 것이 가능하며, 데이터베이스 성능을 **유지 관리하고 최적화**하는데에 SQL을 사용할 수도 있습니다. 


### 1.1 SQL의 역사
이 언어는 1970년대에 IBM에서 최초 개발되었고 관계형 모델을 기반으로 발명되었습니다. 처음에는 구조적 영어 쿼리 언어(SEQUEL)이라고 불리다가 나중에 SQL로 줄였습니다.  
이런 SQL은 현재 ANSI SQL을 표준으로 정립되어있습니다. 각 DBMS 프로그램들은 ANSI SQL을 기반으로 하지만, 모두 같지는 않으며 조금씩은 다른 SQL 문법을 갖습니다.

### 1.2 SQL 실행 순서

> **SQL** → **Syntax Check** → **Semantic Check** → **Library Cache Check** → **Optimization** → **Raw Source Generation** → **Execution**

1. **SQL**: 쿼리 실행 
2. **Syntax Check**: 문법 체크 
3. **Semantic Check**: 객체(Object) 및 권한 유무 체크 
4. **Library Cache Check**: Cache에서 쿼리 저장 유무 검사 → 저장되어 있다면 Soft Parse로 Library Cache에 저장된 쿼리 바로 사용 → 저장되어 있지 않으면 Hard Parse로 다음 단계로 넘어갑니다.
5. **Optimization**: 최적화한 쿼리 실행 계획을 만드는 단계 
6. **Raw Source Generation**: 위 Optimization 단계에서 생성된 실행 계획을 실제 실행할 수 있게 Formatting 
7. **Execution**: 실행

### 1.3 Query 순서

1. **SELECT** 
2. **FROM** 
3. **WHERE** 
4. **GROUP BY** 
5. **HAVING** 
6. **ORDER BY**

### 1.4 SQL 문법 종류

SQL 문법은 크게 네가지로 나눠볼 수 있습니다.
1. **데이터 정의 언어 (DDL: Data Definition Language)**
   - 각 **릴레이션을 정의**하기 위해 사용하는 언어입니다.
2. **데이터 조작 언어 (DML:Data Manipulation Language)**
   - 데이터 추가/수정/삭제/갱신/..등을 위한, 즉 **데이터 관리**를 위한 언어입니다.
3. **데이터 제어 언어 (DCL:Date Control Language)**
   - 사용자 관리 및 사용자별로 릴레이션 또는 데이터를 관리하고 접근하는 **권한**을 다루기 위한 언어입니다.
4. **트랜잭션 제어 언어 (TCL: Transaction Control Language)**
   - 데이터베이스에서 **논리적인 작업** 단위로 수행되는 일련의 작업 트랜잭션을 제어하기 위한 언어입니다.

## 2. DDL이란?

스키마, 데이터베이스, 테이블 등 데이터의 **전체 골격을 결정하는 역할**을 맡습니다.  
DDL은 <span style="color:blueviolet">즉시 반영(Auto commit)</span>되는 특징을 가지고 있어서 **사용 시 주의**를 기울여야 합니다.

| 명령어 | 역할 |
| --- | --- |
| CREATE | 생성하는 역할 |
| ALTER | 수정하는 역할 |
| DROP | 삭제하는 역할 |
| RENAME | 이름을 변경하는 역할 |
| TRUNCATE | 초기화하는 역할 |

### 2.1 CREATE 규칙
- 객체를 의미하는 것이므로 **단수형**으로 이름 짓는걸 권장합니다.
- 유일한 이름으로 명명해야 합니다.
- 컬럼명은 데이터 표준화 관점에서 **일관성**있게 사용해야 합니다.
- 이름은 반드시 문자로 시작합니다.

## 3. ALTER 문법

| 명령어 | 역할 |
| --- | --- |
| ADD COLUMN | 컬럼을 추가하는 역할 |
| DROP COLUMN | 컬럼을 삭제하는 역할 |
| MODIFY COLUMN | 컬럼을 수정하는 역할 |
| RENAME COLUMN | 컬럼 이름을 변경하는 역할 |

## 4. DML 특징
<span style="color:blueviolet">DML은 자동으로 커밋되지 않습니다.</span> 즉, DML 명령에 의한 변경은 **되돌리는게 가능합니다.**  
이게 가능한 이유는 DML 명령이 이루어지는 구조를 살펴보면 알 수 있는데, DML 명령은 조작하려는 테이블을 **메모리 버퍼**에 올려놓고 작업을 하기 때문에 **실제 테이블에 영향을 주지 않습니다.**

만약 버퍼에서 처리한 테이블을 실제 테이블에 반영하고자 한다면 **COMMIT**과 함께 트랜잭션을 종료해야 합니다.

예외적으로 **SQL Server**의 경우는 DML 또한 **Auto commit** 으로 처리됩니다.

### 4.1 DML 문법

| 명령어 | 역할 |
| --- | --- |
| SELECT | 데이터를 검색하는 역할 |
| INSERT | 데이터를 추가하는 역할 |
| UPDATE | 데이터를 수정하는 역할 |
| DELETE | 데이터를 삭제하는 역할 |


## 5. DCL이란?

DCL은 데이터를 관리하기에 용이하도록 **권한**을 부여해 잘못된 처리나 불법적인 사용자로부터 데이터를 **보호**하기 위한 보안의 역할을 수행합니다.

| 명령어 | 역할 |
| --- | --- |
| CREATE | 생성하는 역할 |
| ALTER | 수정하는 역할 |

## 6. TCL이란?

앞서 말했던 트랜잭션이란 것은 데이터베이스에서 **논리적인 작업** 단위로 수행되는 일련의 작업, 다시 말해 데이터베이스의 상태를 변화시키기 위해 수행하는 작업의 단위입니다. 
> 보통 DBMS의 성능을 측정할 때 초당 몇 개의 트랜잭션이 수행되는지를 통해 평가합니다.

```sql
BEGIN; -- 트랜잭션 생성, 시작점
    DELETE FROM {schema}.{table};
    INSERT INTO {schema}.{table} VALUES ('{name}', '{gender}');
END; -- END = COMMIT, 커밋과 함께 트랜잭션 종료
```
위의 쿼리는 Postgresql에서 트랜잭션을 사용한 예입니다.

### 6.1 트랜잭션의 특징
1. **원자성(Atomicity)**  
트랜잭션은 **하나의 원자와 같이**, 트랜잭션 내의 변경사항이 모두 반영이 되거나 전혀 반영되지 않아야 합니다. 
2. **일관성(Consistency)**  
트랜잭션의 작업 처리 결과가 항상 일관성이 있게, **전과 후의 데이터 타입이 동일**해야 합니다.
3. **독립성(Isolation)**  
하나의 트랜잭션은 다른 트랜잭션에 끼어들 수 없으며 독립적으로 존재합니다.  
각각의 트랜잭션은 서로 **간섭이 불가**하기 때문에 하나의 트랜잭션이 완료될 때까지, 다른 트랜잭션이 특정 트랜잭션의 결과를 참조할 수 없습니다.
4. **지속성(Dutability)**  
트랜잭션이 성공적으로 완료되었을 경우, 결과는 영구적으로 반영되어야 합니다. 

### 6.2 트랜잭션의 상태 5가지

![image](https://user-images.githubusercontent.com/105477856/234617196-928df5f6-6caa-457a-874f-3ad002b4e614.png)

1. **Active**: 트랜잭션이 현재 **실행 중**인 상태 
2. **Failed**: 트랜잭션이 실행되다 **오류가 발생**해서 중단된 상태 
3. **Aborted**: 트랜잭션이 **비정상 종료**되어 Rollback이 수행된 상태 
4. **Partially Committed**: 트랜잭션의 연산이 마지막까지 실행되고 **Commit**이 되기 **직전** 상태 
5. **Commited**: 트랜잭션이 성공적으로 종료되어 **Commit** 연산을 **실행한 후**의 상태

### 6.3 Commit

Commit은 모든 작업들을 정상 처리하겠다고 확정하는 명령어입니다. 해당 처리 과정을 DB에 영구 저장하겠다는 의미로 Commit을 수행하면 하나의 트랜잭션 과정이 종료됩니다.  
Commit을 하기 전에는 다른 사용자가 트랜잭션의 세션 상황을 확인할 수 없습니다. 또, 변경된 행은 잠금이 설정되어 있어서 다른 사용자가 변경할 수 없습니다.

### 6.4 Rollback

Roll-back은 작업 중 문제가 발생되어 트랜잭션의 처리 과정에서 발생한 **변경사항을 취소**하는 명령어입니다.  
해당 명령을 트랜잭션에게 하달하면 **마지막 Commit이 이루어졌던 상태**로 돌아갑니다. 

### 6.5 TCL 종류

| 명령어 | 역할 |
| --- | --- |
| COMMIT | 트랜잭션 내의 작업을 정상적으로 처리하겠다는 명령어 |
| ROLLBACK | 트랜잭션 내의 작업이 이루어지기 전으로다시 돌려 놓겠다는 명령어 |
| SAVEPOINT | COMMIT 전에 특정 시점까지만 반영하거나 ROLLBACK 하겠다는 명령어 |

## 7. 부록 : TRUNCATE와 DELETE의 차이

### 7.1 DELETE FROM TABLE

DELETE 명령어를 사용하면 데이터는 지워지지만 **테이블 용량은 줄어 들지 않습니다**. 그리고 **원하는 데이터**만 지울 수 있습니다.  
TRUNCATE에 비해 메모리 소모가 많이 되지만 삭제 후 **잘못 삭제**한 것을 **되돌릴 수 있습니다.** 

### 7.2 TRUNCATE

DELETE와 다르게 데이터 전체를 날려버리기 때문에 메모리를 많이 차지 하지 않습니다. 하지만 이때문에 정상적인 데이터 **복구가 불가능**합니다.  
**테이블 구조는 그대로 남겨놓고 데이터만 삭제합니다.** DELETE 처럼 조건을 걸어서 **원하는 데이터만 삭제하는 것은 불가능합니다.**

## 참고 자료
1. [SQL이란 무엇인가요? - 구조적 쿼리 언어(SQL) 설명 - AWS (amazon.com)](https://aws.amazon.com/ko/what-is/sql/)
2. [DB 개요: DDL, DML, DCL, TCL이란? (velog.io)](https://velog.io/@alicesykim95/DB-DDL-DML-DCL-TCL%EC%9D%B4%EB%9E%80)
3. [DBMS 데이터 언어 - DDL, DML, DCL, TCL 의 정의 (tistory.com)](https://iamfreeman.tistory.com/entry/DBMS-%EB%8D%B0%EC%9D%B4%ED%84%B0-%EC%96%B8%EC%96%B4-DDL-DML-DCL-TCL-%EC%9D%98-%EC%A0%95%EC%9D%98#recentComments)
4. [SQL이란? - 한 눈에 끝내는 SQL (goorm.io)](https://edu.goorm.io/learn/lecture/15413/%ED%95%9C-%EB%88%88%EC%97%90-%EB%81%9D%EB%82%B4%EB%8A%94-sql/lesson/767683/sql%EC%9D%B4%EB%9E%80)
