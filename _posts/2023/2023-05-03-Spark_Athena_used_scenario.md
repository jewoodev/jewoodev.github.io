---
title : 데이터 파이프라인에서 Spark와 Athena를 사용하는 시나리오 
date : 2023-05-03 10:06:00 +09:00
categories : [Architecture, Data]
tags : [Architecture]
---

> 이 글은, [프로그래머스에서 진행되는 실리콘밸리에서 날아온 데이터 엔지니어링 키트 with Python](https://school.programmers.co.kr/learn/courses/16448/16448-%EB%9D%BC%EC%9D%B4%EB%B8%8C12%EA%B8%B0-%EC%8B%A4%EB%A6%AC%EC%BD%98%EB%B0%B8%EB%A6%AC%EC%97%90%EC%84%9C-%EB%82%A0%EC%95%84%EC%98%A8-%EB%8D%B0%EC%9D%B4%ED%84%B0-%EC%97%94%EC%A7%80%EB%8B%88%EC%96%B4%EB%A7%81-%EC%8A%A4%ED%83%80%ED%84%B0-%ED%82%A4%ED%8A%B8-with-python)에서 배운 내용을 바탕으로 이루어져 있습니다.

# 비구조화된 데이터 처리

![image](https://user-images.githubusercontent.com/105477856/235756087-006c1edb-aeb9-4bf7-8cf8-cb88d91abe41.png)

비구조화된 데이터는 AWS에서 제공하는 S3라는 클라우드 스토리지에 저장합니다. S3외에 다른 스토리지를 선택할 수도 있습니다. 다만, S3는 가격이 싸면서도 로그파일같은 굉장히 크고 비구조화된 데이터를 저장하는데 가장 좋은 스토리지입니다.  
그렇게 저장해둔 데이터에서 필요한 것만 processing해서 정제한 다음 Redshift에 table같은 형태로 load하는 경우가 많습니다. 그리고 그렇게 할 때 Spark나 Athena같은 걸 많이 씁니다.  
여기서 이야기하는 Spark, Athena는 빅데이터 SQL이라고 생각하시면 되는데, 흔히 Presto, Hive 라고 불리는 Hadoop위에서 돌아가는 SQL입니다.

## Spark 사용 방법
1. SparkSQL을 이용해서 정제를 통해 크기를 작게 만들고 Redshift에 load
2. Python을 이용해서 precejure하게 step by step으로 column을 만들고 value 채우기
3. 주기적으로(배치로) 어떤 값을 계산해서(머신러닝에 들어가는 feature값) 사용할 수 있고, Spark streaming이라는 걸 통해서 배치가 아니라 real time으로 데이터가 계속 만들어지는 것을 가져다가 처리할 수도 있습니다.
