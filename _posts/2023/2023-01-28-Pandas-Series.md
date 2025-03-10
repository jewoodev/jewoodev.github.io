---
title : Pandas - Series
date : 2023-01-28 21:48:00 +09:00
categories : [Python, Basic]
tags : [Basic]
---

Pandas는 주로 데이터 분석에 사용됩니다.  
대부분의 데이터는 시계열(series)이나 표(table)의 형태로 나타낼 수 있습니다.   
Pandas 패키지는 이러한 데이터를 다루기 위한 Series 클래스와 DataFrame 클래스를 제공합니다.   
숫자 테이블과 시계열 을 조작하기 위한 데이터 구조 와 연산을 제공합니다.  

- series : 열
- dataframe : table
  
## Series class
Series 클래스는 Numpy에서 제공하는 1차원 배열과 그 모양이 비슷합니다.  
하지만 Series class는 배열과 다르게 각 데이터의 의미를 표시하는 index(index)를 붙일 수 있습니다.  
데이터 자체는 값(value)라고 합니다.  

## Series 생성하기
- iterable한.. : 한번에 하나씩 꺼내어 쓸 수 있는 ..
  

Series 객체를 만들 때 첫 인수로 data, 두 번째 인수로는 index를 넣습니다.  
data 값으로 iterable, 배열, scalar value, dict(key와 index를 동일하게 사용하거나 생략)를 사용할 수 있습니다.   
index는 label이라고도 합니다. index는 data와 length가 동일해야 합니다.  
label은 꼭 유일(unique)할 필요는 없습니다. 다만 반드시 hashable type만 사용 가능 합니다.  
만약 index를 생략할 경우 RangeIndex(0, 1, … , n)를 제공합니다.  
[pandas.Series document link](https://pandas.pydata.org/docs/reference/api/pandas.Series.html#pandas.Series)  
```python
import pandas as pd
series = pd.Series(["하나", "둘", "셋", "넷", "다섯",
                   "여섯", "일곱", "여덟", "아홉", "열"],
                    index =[i for i in range(1, 11)])  # 시리즈를 생성하는 코드입니다.  
```
이렇게 생성한 Series는 index와 values로 각각 인덱스와 값에 접근할 수 있습니다.  
```python
s.index
s.values
```
data가 dict일 때 index가 최초에 dict의 key로 만들어집니다. 그 후 Series는 index 키워드로 전달받은 인수로 index를 재할당합니다.  
index 지정 없이 dict 객체만 가지고 Series를 만들 수도 있습니다. 그 경우 dict의 key가 index로 사용됩니다.  

## Series의 특징
Series 객체는 index label을 키(key)로 사용하기에 딕셔너리 자료형과 비슷한 특징을 갖습니다. 그리고 Series를 딕셔너리와 같은 방식으로 사용이 가능하기도 합니다.  
예를 들어 in 연산도 가능하고, items() 메서드를 사용해서 for문 루프를 돌려 각 요소의 키(key)와 값(value)에 접근할 수도 있습니다.  
```python
for k, v in s.items():
    print(f"{k}, {v}")
```

## Series 연산하기
넘파이 배열처럼 Series도 벡터화 연산을 할 수 있습니다. 다만 연산은 Series의 value에만 적용되며 index 값은 변하지 않습니다.   
예를 들어 인구 숫자를 백만 단위로 만들기 위해 Series 객체를 1,000,000 으로 나누어도 index label에는 영향을 미치지 않습니다.   

## Series 인덱싱
Series는 넘파이 배열에서 가능한 index 방법 이외에도 index label을 이용한 인덱싱도 할 수 있습니다.  
배열 인덱싱이나 index label을 이용한 슬라이싱(slicing)도 가능합니다.  
![image](https://user-images.githubusercontent.com/105477856/221215918-38b11528-cd2a-4b10-817f-287d1531ad8d.png)  
배열 인덱싱을 하면 부분적인 값을 가지는 Series 자료형을 반환합니다.  
자료의 순서를 바꾸거나 특정한 자료만 취사 선택할 수 있습니다.  
![image](https://user-images.githubusercontent.com/105477856/221216164-2c0a6bf5-89f5-4282-be8e-1f61877c486a.png)  

## Series 슬라이싱
슬라이싱을 해도 부분적인 Series를 반환합니다. 이 때 문자열 label을 이용한 슬라이싱을 하는 경우에는 숫자 인덱싱과 달리 콜론(:) 기호 뒤에 오는 값도 결과에 포함되므로 주의해야 합니다.  
![image](https://user-images.githubusercontent.com/105477856/221207494-cfb786dc-09ab-4722-9d93-35ed5d6b7b29.png)  

## Series index 기반 연산
두 Series에 대해 연산을 하는 경우 index가 같은 데이터에 대해서만 차이를 구합니다.  
대구와 대전의 경우에는 2010년 자료와 2015년 자료가 모두 존재하지 않기 때문에  
계산이 불가능하므로 NaN(Not a Number)이라는 값을 가지게 됩니다.  
![image](https://user-images.githubusercontent.com/105477856/221217030-07493417-0980-4163-a7f1-394c7bf3fdcc.png)  
![image](https://user-images.githubusercontent.com/105477856/221208014-386683d6-7ee2-4f92-82f4-4face6c9696b.png)  

## Series에서 값이 NaN인지 확인
Series 내 값이 NaN인지 아닌지 True / False 값을 구하려면 notnull() 메서드를 사용하면 됩니다.   
## Series에서 NaN이 아닌 값 구하기
notnull() 메서드로 구한 True / False 값을 활용하여 NaN인 값을 배제한 Series 객체를 만들 수 있습니다.   
![image](https://user-images.githubusercontent.com/105477856/221208813-1372cf3c-e020-48f6-af17-7874800596ef.png)  

## Series 데이터 삭제
데이터를 삭제할 때 딕셔너리처럼 del 명령을 사용합니다.  

## Series 데이터 개수 세기
pandas는 NumPy 2차원 배열에서 가능한 대부분의 데이터 처리가 가능합니다.  
또 데이터 처리 및 변환을 위한 다양한 함수와 메서드를 제공합니다.  
가장 간단한 데이터 분석은 데이터의 개수를 세는 것입니다. 개수를 셀 때는 count() 메서드를 사용합니다.  
이때 NaN 값은 세지 않습니다.   

## Series 카테고리 값 세기

Series의 값이 정수, 문자열, 카테고리 값인 경우에는 value_counts() 메서드로 각각의 값이 나온 횟수를 셀 수 있습니다.  
> **Tip**   
> value_counts 함수에 normalize 인자로 True를 주면 개수가 아닌 비율을 반환해줍니다.

## Series 정렬
데이터를 index 순으로 정렬하려면 sort_index()를, value를 기준으로 정렬하려면 sort_values() 메서드를 사용합니다.  
ascending 키워드 인자에 False를 주면 내림차순으로 정렬됩니다.  
