---
title : Airflow(에어플로우) Backfill
date : 2023-05-03 14:06:00 +09:00
categories : [Apache, Airflow]
tags : [workflow management]
---

> 이 글은, [프로그래머스에서 진행되는 실리콘밸리에서 날아온 데이터 엔지니어링 키트 with Python](https://school.programmers.co.kr/learn/courses/16448/16448-%EB%9D%BC%EC%9D%B4%EB%B8%8C12%EA%B8%B0-%EC%8B%A4%EB%A6%AC%EC%BD%98%EB%B0%B8%EB%A6%AC%EC%97%90%EC%84%9C-%EB%82%A0%EC%95%84%EC%98%A8-%EB%8D%B0%EC%9D%B4%ED%84%B0-%EC%97%94%EC%A7%80%EB%8B%88%EC%96%B4%EB%A7%81-%EC%8A%A4%ED%83%80%ED%84%B0-%ED%82%A4%ED%8A%B8-with-python)에서 배운 내용을 바탕으로 이루어져 있습니다.

# Backfill이란...
데이터 파이프라인을 운영하다보면 이미 지난 날짜를 기준으로 ETL을 재처리 해야하는 경우가 종종 생깁니다. 그런 재처리 작업을 Backfill('메우는 작업')이라는 이름으로 부릅니다.

# Backfill을 하게 되는 경우
Backfill을 하는 경우는 나름 명확합니다. 다음과 같은 사례가 있습니다.
- 버그가 있거나 어떤 이유로 로직이 변경되었을 때 전체 데이터를 새로 말아주어야 할 때
- 컬럼 등의 메타 데이터가 변경되었을 때 이를 반영하기 위한 append 성의 작업이 필요할 때

이외에도 과거의 데이터를 재처리하고자 하는 니즈가 있다면 백필을 먼저 떠올리면 됩니다.

# Airflow의 Backfill
Airflow의 Backfill를 이해하기 위해 Incremental Update에 대한 이해가 어느정도 필요합니다.

Daily Incremental Update는 어떻게 구현될까요? 예를 들어 2023년 1월 1일부터 매일매일 하루치 데이터를 읽어온다고 가정해봅시다. 그럴 경우 언제부터 ETL이 동작해야할까요?

2023년 1월 2일부터 동작해야합니다. 1일의 데이터를 얻기 위해 1일이 끝나고 다음 날이 되어야 하기 때문이죠.

이렇듯이 Airflow의 start_date는 시작 날짜라기보다는 **처음 데이터를 읽어와야하는 날짜**입니다.

날짜를 이런 식으로 다루는 일이 드물기 때문에 처음엔 굉장히 헷갈리는데, 만약 내가 1월 2일 날 이 DAG가 처음 실행되도록 하고 싶어서 start_date을 1월 2일로 지정을 해주면 1월 3일 날 처음 실행이 되기 때문에 왜 실행이 안되는 건지 발을 동동 굴리게 됩니다. 1월 2일에 처음 실행되도록 하고 싶으면 start_date을 1월 1일로 지정해야합니다. start_date는 데이터를 읽어올 날짜이고, **실행되는 날짜는 start_date에서 interval이 지나고 난 후** 이기 때문입니다.

Airflow에서 이 'DAG가 실행되는 날짜'를 execution_date라는 이름으로 사용합니다. 

## catchup parameter
catchup parameter는 DAG의 실행 상태가 disable로 되어있는 상태로 start_date이 지나도록 시간이 흐른 후에 enable했을 때 실행되지 않았던 밀린 작업들을 실행할 것인지를 정하는 parameter입니다. Default로 True값을 갖으며 True로 설정되면 밀린 작업을 모두 실행하고, False이면 밀린 작업을 하지 않게됩니다.  
이 parameter는 DAG를 생성할 때 `DAG(....)` 안에 지정합니다.

### 예시
```python
test_dag = DAG(
  "dag_v1", # DAG name
  schedule="0 9 * * *", 
  tags=['test'],
  catchup= True,
  default_args=default_args 
)
```

## Incremental하게 1년치 데이터를 Backfill 해야한다면
어떻게 ETL을 구현해놓으면 Backfill이 편해질까요?

- 해결방법 1
  - 기존 ETL 코드를 조금 수정해서 지난 1년치 데이터에 대해 돌린다.
    - 실수하기 쉽고 수정하는데 시간이 걸린다.

```python
from datetime import datetime, timedelta
y = datetime.now() - timedelta(1)
yesterday = datetime.strftime(y, '%Y-%m-%d')

#yesterday에 해당하는 데이터를 소스에서 읽어옴

#예를 들어 프로덕션 DB의 특정 테이블에서 읽어온다면
sql = f"SELECT * FROM table WHERE DATE(ts) = '{yesterday}'"
```

---

- 해결방법 2
    - 시스템적으로 이걸 쉽게 해주는 방법을 구현한다
    - 읽어와야하는 데이터의 날짜를 계산하지 않고 시스템이 지정해준 날짜에 해당하는 데이터를 다시 읽어온다
        - Airflow의 접근방식
            - 모든 DAG 실행에는 “execution_date”이 지정되어 있음
            - execution_date으로 채워야하는 날짜와 시간이 넘어옴
            - 이를 바탕으로 데이터를 갱신하도록 코드를 작성해야함
            - 잇점: backfill이 쉬워짐

### 중요!
개발자가 '데이터를 읽어들어와야 하는 날짜' 를 계산하는게 아니라 **Airflow가 알려주는** 날짜의 데이터를 읽어오게 코딩을 해놓으면 앞으로 운영을 해나가는 것과 과거의 잘못된 데이터들을 다시 읽어오는 것을 하나의 코드로 동시에 해결할 수 있습니다. 그래서 Airflow를 쓰면 Backfill하기 용이합니다. 그리고 이런 점은 Airflow의 큰 장점입니다.


# 참고 자료
[https://wookiist.dev/175](https://wookiist.dev/175)

