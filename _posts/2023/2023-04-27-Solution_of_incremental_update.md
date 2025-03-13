---
title : Incremental Update 방법
date : 2023-04-27 04:29:00 +09:00
categories : [SQL, Incremental update]
tags : [Incremental]
---

> 이 글은, [프로그래머스에서 진행되는 실리콘밸리에서 날아온 데이터 엔지니어링 키트 with Python](https://school.programmers.co.kr/learn/courses/16448/16448-%EB%9D%BC%EC%9D%B4%EB%B8%8C12%EA%B8%B0-%EC%8B%A4%EB%A6%AC%EC%BD%98%EB%B0%B8%EB%A6%AC%EC%97%90%EC%84%9C-%EB%82%A0%EC%95%84%EC%98%A8-%EB%8D%B0%EC%9D%B4%ED%84%B0-%EC%97%94%EC%A7%80%EB%8B%88%EC%96%B4%EB%A7%81-%EC%8A%A4%ED%83%80%ED%84%B0-%ED%82%A4%ED%8A%B8-with-python)에서 배운 내용을 바탕으로 이루어져 있습니다. 그리고 Airflow을 사용한다는 전제 하에 글을 적어내린다는 점을 참고해주세요.    (데이터베이스 : PostgreSQL)

<br>

## 1. Incremental Update는 왜 필요한가요?

데이터 파이프라인을 거치는 데이터의 크기가 어느정도 커지면 그 크기만큼이나 지우고 다시 채워넣는 것은 많은 비용과 자원을 소모하게 하기 때문에  full refresh 방식을 유지할 수 없게 됩니다. 비용 문제도 있지만 스케줄 주기와 별 차이없이 full refresh 하는데에 시간이 걸리게 되면, 예를 들어 2시간에 한번 실행되는 DAG인데 full refresh 하는데에 1시간 이상이 걸린다면 문제가 생길 수 있겠죠. 

그리고 Backfill이 필요한 데이터라면 full refresh 를 할 수 없습니다. 이런 이유들로 Incremental Update는 필요합니다.

## 2. Incremental Update DAG

Incremental Update를 하는 방법엔 여러가지가 있습니다. 그중에 하나로 
1. 임시 테이블에 원본 데이터와 새 레코드들을 모두 insert하고 
2. ROW_NUMBER를 이용해 가장 최근의 데이터만 남기고 
3. 그걸 원본 데이터로 바꾸는 방법을 공부해보도록 하겠습니다.

먼저 사용할 임시 테이블을 만듭니다.

## 3. 존재하는 테이블의 구조를 그대로 가져올 때의 팁

```python
create_sql = f"""DROP TABLE IF EXISTS {schema}.temp_{table};
CREATE TABLE {schema}.temp_{table} (LIKE {schema}.{table} INCLUDING DEFAULTS);
INSERT INTO {schema}.temp_{table} SELECT * FROM {schema}.{table};"""
```

임시 테이블을 CTAS로 만들게 되면 DEFAULT 값들은 그대로 가져올 수가 없습니다. 만일 DEFAULT로 그 날의 날짜를 받아오는 함수가 지정되어 있다면 그 DEFAULT 설정값이 컬럼의 매우 중요한 설정값이 됩니다. 그래서 CTAS를 사용하지 않고 **LIKE 문**을 써서 CREATE 합니다.

```python
try:
    cur.execute(create_sql) # cur 는 데이터베이스의 커서 객체를 담은 변수입니다.
    cur.execute("COMMIT;")
except Exception as e:
    cur.execute("ROLLBACK;")
    raise
```

try, except를 써서 명시적으로 Rollback 하고 에러가 발생했을 때 방치되어지지 않도록 raise 시켜줍니다.

```python
alter_sql = f"""
DELETE FROM {schema}.{table};
INSERT INTO {schema}.{table}
    SELECT date, temp, min_temp, max_temp
        FROM (SELECT *, ROW_NUMBER() OVER (PARTITION BY date ORDER BY created_date DESC) seq
            FROM {schema}.temp_{table})
    WHERE seq = 1;"""
logging.info(alter_sql)
try:
    cur.execute(alter_sql)
    cur.execute("COMMIT;")
except Exception as e:
    cur.execute("ROLLBACK;")
    raise
```

임시 테이블에서 incremental update를 할 때 가상 최신 데이터가 신뢰성이 가장 높다고 가정하고 ROW_NUMBER를 이용해 내림차순으로 SELECT 한 후 그 number가 1인 경우만 원본 데이터에 추가합니다. 

