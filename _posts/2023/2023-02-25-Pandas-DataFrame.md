---
title : Pandas - DataFrame
date : 2023-02-25 13:20:00 +09:00
categories : [Python, Basic]
tags : [Data]
---

Pandas는 주로 데이터 분석에 사용됩니다.  
대부분의 데이터는 시계열(series)이나 표(table)의 형태로 나타낼 수 있습니다.   
Pandas 패키지는 이러한 데이터를 다루기 위한 Series 클래스와 DataFrame 클래스를 제공합니다.   
숫자 테이블과 시계열 을 조작하기 위한 데이터 구조 와 연산을 제공합니다.  

- series : 열
- dataframe : table

## DataFrame class
DataFrame은 Pandas의 주요 데이터 구조입니다. label된 row와 column, 두 개의 축을 갖습니다.  
산술 연산은 row와 column 모두 적용됩니다. Series 객체를 갖는 dictionary라고 생각하면 비슷합니다.   
첫 인자로 data, 두 번째 인자로 index를 전달합니다.  
![image](https://user-images.githubusercontent.com/105477856/221333163-b6632b72-163b-4d66-bf9a-862dea3ea9c1.png)  
[pandas.DataFrame document link](https://pandas.pydata.org/docs/reference/api/pandas.DataFrame.html#pandas.DataFrame)  
DataFrame은 각 column 마다 자료형이 다를 수 있습니다.

## DataFrame 생성
Series가 1차원 벡터 데이터에 행방향 index(row index)를 붙인 것이라면  
DataFrame 클래스는 2차원 행렬 데이터에 index를 붙인 것과 형태가 비슷합니다.  
row와 column을 갖는 2차원이므로 각각의 행 데이터의 이름이 되는  
행 index(row index) 뿐 아니라 각각의 열 데이터의 이름이 되는 열 index(column index)도 붙일 수 있습니다.  
DataFrame을 만드는 방법은 다양합니다. 가장 간단한 방법은 다음과 같습니다.  
1. 우선 하나의 열이 되는 데이터를 리스트나 일차원 배열을 준비합니다.
2. 이 각각의 열에 대한 이름(label)을 키로 가지는 딕셔너리를 만듭니다.
3. 이 데이터를 DataFrame 클래스 생성자에 넣는다. 동시에 열방향 index는 columns 인수로, 행방향 index는 index 인수로 지정합니다.  

![image](https://user-images.githubusercontent.com/105477856/221209793-e9161917-fb8c-415e-ac95-ed36a8e4d6bf.png)  
![image](https://user-images.githubusercontent.com/105477856/221209883-010f312a-0bf3-47e9-b366-60907d6edd45.png)  

## DataFrame Indexing

### DataFrame Indexing - Column
DataFrame은 column label을 키로, column Series를 값으로 가지는 딕셔너리와 비슷합니다.  
따라서 DataFrame을 인덱싱을 할 때도 column label을 키(key)로 생각하여 인덱싱을 할 수 있습니다.  
index로 label 값을 하나만 넣으면 Series 객체가 반환됩니다.  
![image](https://user-images.githubusercontent.com/105477856/221210566-fd3fcc19-7000-4c1d-b20d-6f0c015baa47.png)  
label의 배열 또는 리스트로 인덱싱하면 DataFrame 타입이 반환됩니다.  
![image](https://user-images.githubusercontent.com/105477856/221210682-9416c59b-511d-49ad-9694-d2d817b112fc.png)  
만약 하나의 column만 빼내어더라도 DataFrame 자료형을 유지하고 싶다면 요소가 하나인 리스트 자료형을 사용해서 인덱싱하면 됩니다.  
![image](https://user-images.githubusercontent.com/105477856/221210787-3c885a66-b79b-4ad6-82f4-4fa17b603642.png)  
- DataFrame의 column index가 문자열 label일 때는 순서를 나타내는 정수 index를 column 인덱싱에 사용할 수 없습니다.   column index가 문자열인데 정수 index를 넣으면 KeyError 오류가 발생합니다.  
- 원래부터 문자열이 아닌 정수형 column index를 가지는 경우에는 index 값으로 정수를 사용할 수 있습니다.  
- 별도의 columns 키워드 인수를 전달하지 않으면 RangeIndex를 기본 값으로 부여합니다.

### DataFrame Indexing - Row
만약 row 단위로 인덱싱을 하고자 하면 항상 슬라이싱(slicing)을 해야 합니다. index의 값이 문자 label이면 label 슬라이싱도 가능합니다.  
![image](https://user-images.githubusercontent.com/105477856/221211119-d7f6d2a7-78fd-4eed-9e78-952846db2d1a.png)  
![image](https://user-images.githubusercontent.com/105477856/221211183-e2005040-947c-4eab-bfc8-e089c37f73ae.png)  

### DataFrame row 인덱싱할 경우
KeyError가 발생합니다.  
![image](https://user-images.githubusercontent.com/105477856/221211408-cd39ce91-1edc-452f-9d85-eed372b4aaa5.png)  

### DataFrame 개별 데이터 인덱싱
DataFrame에서 column label로 인덱싱하면 Series가 됩니다. 이 Series를 다시 row label로 인덱싱하면 개별 데이터가 나옵니다.  
![image](https://user-images.githubusercontent.com/105477856/221211566-824391d2-ca45-452f-b217-dc925006742b.png)  

### DataFrame 개별 데이터 인덱싱, 역순으로
앞서 공부했듯 DataFrame에서 row label로 인덱싱하면 KeyError가 발생됩니다. 그래도 굳이 row 단위로 먼저 시도하려면 슬라이싱해야 합니다.  
그 때 반환 타입은 DataFrame이 됩니다. 이 DataFrame을 다시 column label로 인덱싱하면 개별 데이터가 아닌 Series 객체가 나옵니다. 즉 역순으로 하는 것은 썩 효율적이지 않음을 알 수 있습니다.  
![image](https://user-images.githubusercontent.com/105477856/221211826-29752d0f-3c20-4bd8-aa29-b022d70c2852.png)  


### Dataframe Indexing - Boolean
Boolean Series로 row를 기준으로 인덱싱할 수 있습니다.  
아래 예제에서는 df.A(영어 문자열은 속성처럼 접근 가능)의 값 중 15 초과인 결과를 Boolean Series 값을 얻을 수 있습니다.   
이 Boolean Series를 활용해 인덱싱하고 있습니다. 이는 데이터베이스와 같이 인덱스를 가지는 Boolean Series도 row를 선택하는 인덱싱 값으로 쓸 수 있습니다.  
```python
df.A > 15  # 컬럼만 된다.
df.loc[df.A > 15]
df.loc[df.A > 10, ['C', 'D']]
```

## Pandas 데이터 CSV로 출력하기
데이터 출력하기에 앞서 우선 다음과 같은 DataFrame을 만들어 봅시다.   
데이터를 csv 파일로 출력할 땐 to_csv() 메서드를 활용합니다. 첫 인자로는 파일 경로를 입력합니다. 현재 만든DataFrame의 index는 의미 없는 값이므로 출력할 때 배제하겠습니다.  
to_csv()의 기본값 인자인 index의 default가 True이니 index=False 키워드를 활용하여 설정해줘야 합니다.  
![image](https://user-images.githubusercontent.com/105477856/221333255-fa7370d3-b032-4d2d-b313-85337c49a4a1.png)  
- - -
column 인덱스를 배제하고 저장할수도 있습니다.  
header=False 키워드 인수를 추가해주면 됩니다.  
저장된 파일을 열어 의도한 대로 column 인덱스가 없는 상태인지 확인해보세요.
- - -
이번에는 콤마로 구분되지 않은 텍스트 파일에 대해서 처리해 보도록 하겠습니다. 
주피터 환경에선 매직 명령어인 ‘%%writefile 파일명’을 사용하여 파일을 저장할 수 
있습니다.   
```python
%%writefile sample1-19-3.txt
c1        c2        c3        c4
0.179181 -1.538472  1.347553  0.43381
1.024209  0.087307 -1.281997  0.49265
0.417899 -2.002308  0.255245 -1.10515
```
- - -
이번에는 파일 안 내용을 살펴봤을 때 데이터뿐만 아니라 상단에 부가적인 텍스트가 
있는 경우를 살펴보려 합니다. 아래의 코드를 작성하여 파일을 저장해보세요. 
```python
%%writefile sample1-19-4.txt
파일 제목: sample1-19-4.txt
데이터 포맷의 설명:
c1, c2, c3
1, 1.11, one
2, 2.22, two
3, 3.33, three
```
- - -
na_rep 키워드 인수를 사용해서 NaN 표시값을 
바꿀 수도 있습니다.  
![image](https://user-images.githubusercontent.com/105477856/221333703-654a2bfc-f5eb-45c4-be94-42789941a3c3.png)  
> 데이터간의 구분자를 바꾸고 싶을 땐 sep 인수로 구분자를 바꿀 수 있습니다.  

## Pandas csv로부터 데이터 입력하기
csv 파일로부터 데이터를 불러오는 작업은 read_csv() 메서드를 사용하면 가능합니다.  
![image](https://user-images.githubusercontent.com/105477856/221333290-a9f8037e-2bc9-47e7-8d0a-f3a3c94c9895.png)  
- - -
column 인덱스 정보가 없는 경우에는 
read_csv()의 names 키워드 인수를 활용해서 설정할 수 있습니다. 아래 예제 코드를 
살펴보고 데이터를 불러올 때 names 키워드를 통하여 column 인덱스 정보를 직접 
추가해보도록 합시다.  
```python
pd.read_csv('sample1-19-2.csv', names=['c1', 'c2', 'c3'])
```
- - -
데이터를 구분하는 구분자(separator)가 
콤마(comma)가 아니면 sep 인수를 써서 구분자를 사용자가 지정해줘야 합니다.  
만약 길이가 정해지지 않은 공백이 구분자인 경우에는 ‘\s+’ 정규식(regular expression) 문자열을 사용하면 됩니다.  
![image](https://user-images.githubusercontent.com/105477856/221333453-670b6fcf-8c03-4c21-a0ed-6adf063223bf.png)  
- - -
데이터로 불러올 자료 파일 중에 건너 뛰어야 할 상단 행이 있으면 skiprows 인수를 
사용하면 됩니다. 건너 뛸 줄을 리스트 안에 작성하면 됩니다. 리스트가 아닌 range(2)를 
활용할 수도 있습니다.
- - -
데이터로 불러올 자료의 특정한 값을 NaN으로 취급하고 싶으면 na_values 인수에 
NaN 값으로 취급할 값을 넣습니다.  

## DataFrame 데이터 개수 세기
DataFrame 객체에 count() 메서드를 사용하면 각 column마다의 데이터 개수를 셉니다. 그리고 그 결과를 Series로 반환합니다.  
count() 메서드는 NaN 값을 제외하고 개수를 세기 때문에 데이터에서 값이 누락된 부분(NaN)을 찾을 때 유용합니다.   

## DataFrame 카테고리 값 세기
DataFrame 값이 정수, 문자열, 카테고리 값인 경우에도 value_counts() 메서드를 이용해 각각의 값이 나온 횟수를 셀 수 있습니다.  
DataFrame에 사용할 때는 리스트 형태의 값을 첫 인자로 전달합니다. 이 리스트는 column label을 요소로 갖습니다. NaN 값이 있는 row는 개수로 안 칩니다.  
![image](https://user-images.githubusercontent.com/105477856/221338204-cf569f1c-7778-4d84-92f0-868645eed924.png)
label 값을 문자열로 하나만 전달해도 됩니다. 그러면 해당 column에 대한 값을 가지고 카테고리 분류를 하여 Series 타입의 값을 반환합니다.   
![image](https://user-images.githubusercontent.com/105477856/221338256-71f1096b-201b-4629-ab73-bf12f4fcfa2e.png)
> **Tip**   
> value_counts 함수에 normalize 인자로 True를 주면 개수가 아닌 비율을 반환해줍니다.

## DataFrame 정렬
DataFrame에서 sort_values 메서드를 사용하려면 by 키워드 인수를 활용하여 DataFrame의 정렬 기준이 되는 column을 지정해 주어야 합니다.  
![image](https://user-images.githubusercontent.com/105477856/221333962-dc05a18b-ad0e-42fc-80f6-a6676b502e32.png)  
DataFrame은 테이블 형태이므로 1개 column만 정렬하는 것이 아닌 1개 column을 기준으로 다른 column도 모두 정렬합니다.  
by 키워드 인수에 전달할 값으로 리스트 자료형의 형태로 지정할 수 있습니다. 이때는 요소의 순서대로 정렬 기준의 우선 순위가 됩니다.  
즉, 리스트의 첫번째 column을 기준으로 먼저 정렬한 후 동일한 순서 값이 나오면 그 다음 기준으로 순서를 결정합니다.  
![image](https://user-images.githubusercontent.com/105477856/221333976-4122f78f-b6c8-45cf-9e35-027dce2ab10f.png)  
- 데이터프레임에선 로우 단위로 정렬을 합니다. 한 컬럼에서 정렬을 하며 데이터의 위치가 바뀔 때 로우 단위로 다른 컬럼의 데이터도 위치가 바뀐다는 것입니다.
  
## DataFrame row/column 합계
row과 column의 합계를 구할 때는 sum(axis) 메서드를 사용합니다.  
axis 인수에는 합계로 인해 없어지는 방향축(0=row, 1=column)을 지정합니다. row의 집계를 구할 때는 sum(axis=1) 메서드를 사용합니다.  
![image](https://user-images.githubusercontent.com/105477856/221334004-5fa719c2-0d65-4e62-9e44-f154b201ef80.png)  
![image](https://user-images.githubusercontent.com/105477856/221334013-da4372a3-3ae2-467b-b036-47bf70cc29a7.png)  
![image](https://user-images.githubusercontent.com/105477856/221334030-d9d96a07-1243-4c28-9663-152806c6de38.png)  

## DataFrame row/column 평균
평균을 구할 때는 mean()메서드를 사용합니다.  
mean() 메서드는 평균을 구하며 앞서 설명한 sum() 메서드와 사용법이 같습니다. axis 인수에는 집계로 인해 없어지는 방향축(0=row, 1=column)을 지정합니다.  
![image](https://user-images.githubusercontent.com/105477856/221334040-d30473d0-e34e-449f-b7ec-06cf6e82d7bf.png)  

## DataFrame apply() 메서드
DataFrame에 대해 Function을 적용하고 싶다면 apply()를 활용하면 좋습니다. 이 메서드는 첫 인자로 함수를 필수 값으로 받습니다. 경우에 따라 두 번째 인자로 axis를 사용할 수 있습니다. axis 인자는 0이 default 입니다.   
- axis가 0 or ‘index’인 경우 각 column에 대해 함수를 적용합니다.
- axis가 1 or ‘columns’인 경우 각 row에 대해 함수를 적용합니다.   
  ![image](https://user-images.githubusercontent.com/105477856/221334069-700f4d37-7c54-42b6-8c28-0d641a139bf4.png)  
  
## NumPy Universal function
넘파이의 Universal function은 줄여서 ufunc이라고 합니다. 이 함수는 ndarray 전체에 요소 요소마다 적용됩니다.  
함수의 argument와 return의 결과가 동일한 크기로 나오는 것이 특징입니다.  
[document link](https://numpy.org/doc/stable/user/basics.ufuncs.html#ufuncs-basics)  
아래의 코드를 한번 확인해보세요.
```python
import pandas as pd
import numpy as np

df = pd.DataFrame([[4, 9]] * 3, columns=['A', 'B'])
df.apply(np.sqrt)   # np.sqrt는 각 요소마다 적용되는 함수(universal function)로 이 경우에는 np.sqrt(df)와 같은 결과를 가져옵니다.
# 하지만 차원 축소 함수(reducing function)의 경우는 다릅니다.
df.apply(np.sum, axis=0) # column 별 집계
df.apply(np.sum, axis=1) # row 별 집계
```
> axis : {0 or 'index', 1 or 'columns'}, default 0 axis along which the function is applied:  
- 0 or 'index': apply function to each column.  
- 1 or 'columns': apply function to each row.  

함수의 return이 column마다 리스트를 반환하면 DataFrame의 결과를 얻을 수 있습니다.  
함수의 return이 row마다 리스트를 반환하면 각 row마다 리스트를 하나의 값으로 취급하는 Series 타입의 결과가 나옵니다.  
![image](https://user-images.githubusercontent.com/105477856/221334113-d625340c-4a89-4884-a1f6-b94ccf3f874e.png)  
- - -
이번에는 앞의 axis=1에 동시에 result_type=’expand’를 인수로 전달해봅시다.  
그러면 이번에는 리스트를 하나의 값으로 보지 않고 리스트 요소마다 column으로 인식하도록 확장합니다.  
그래서 DataFrame의 결과를 얻을 수 있습니다.  
![image](https://user-images.githubusercontent.com/105477856/221334125-3abb6d19-c2f7-4f09-ae01-9dd7b4f687f3.png)  
- - -
Series를 return하는 함수를 사용하면 result_type=’expand’와 비슷한 결과를 얻을 수 있습니다. 이때 Series의 index는 column label이 됩니다.  
![image](https://user-images.githubusercontent.com/105477856/221334136-8fafa4cd-6428-4ef6-a52e-e2c8399071bb.png)  
- - -
result_type=’broadcast’를 인수로 전달하면 동일한 shape의 결과를 보장합니다.  
함수로부터 반환되는 게 리스트인지 스칼라인지에 상관없이 axis 방향으로 브로드캐스트합니다.  
결과의 column label은 본래의 column label을 유지합니다.  
![image](https://user-images.githubusercontent.com/105477856/221334167-786e1f84-e32f-49ad-9ff1-10d4ac240a19.png)
- - -
apply는 이렇게 활용될 수도 있습니다. 
```python
# 예를 들어 column마다의 최대값과 최솟값의 차이를 구하고 싶다면
df3.apply(lambda x: x.max() - x.min())
df3.apply(lambda x: x.max() - x.min(), axis=1) # row에 대해 적용하고 싶다면 axis 키워드 argument를 바꾼다.
# 어떤 값이 얼마나 사용되었는지 알고 싶다면
df3.apply(pd.value_counts)
```
## DataFrame astype() 메서드
astype() 메서드로 column의 자료형을 바꾸는 것도 가능합니다. 
다만 1.3.0 버전부터 timezone-naive dtype을 timezone-aware dtype으로 변경하는 것은 불가하다고 합니다.  
대신 Series.dt.tz_localize()를 사용해야 합니다.  
![image](https://user-images.githubusercontent.com/105477856/217522599-1b3e1983-fffb-4d69-bcdc-33a4792db314.png)  
출처:https://pandas.pydata.org/docs/reference/api/pandas.DataFrame.astype.html[링크](https://pandas.pydata.org/docs/reference/api/pandas.DataFrame.astype.html)  
- astype()메서드는 in-place 가 아니라는 점을 기억해두세요.  

## DataFrame 실수 값을 카테고리 값으로 변환
실수 값을 크기 기준으로 하여 카테고리 값으로 변환하고 싶을 때는 다음과 같은 명령을 사용합니다.
- cut: 실수 값의 경계선을 지정하는 경우
  - x = 1차원 형태의 배열 형태가 옵니다.
  - bins = int, 스칼라를 요소로 갖는 시퀀스가 옵니다.  
  

![image](https://user-images.githubusercontent.com/105477856/217522853-145b50c4-6e8b-4e7a-ab22-44f67cd62b51.png)  
출처:https://pandas.pydata.org/docs/reference/api/pandas.cut.html[링크](https://pandas.pydata.org/docs/reference/api/pandas.cut.html)
- qcut: 개수가 똑같은 구간으로 나누는 경우(분위수)
  - x = 1d ndarray 혹은 Series
  - q = int 혹은 분위수를 나타내는 1.이하의 실수를 요소로 갖는 list (e.g. [0, .25, .5, .75, 1.])    
  

![image](https://user-images.githubusercontent.com/105477856/217523194-562088c2-4d2c-451d-8465-650ccd7a80dd.png)  
출처:https://pandas.pydata.org/docs/reference/api/pandas.qcut.html[링크](https://pandas.pydata.org/docs/reference/api/pandas.qcut.html)

예를 들어 다음과 같은 나이 데이터가 있습니다.
![image](https://user-images.githubusercontent.com/105477856/230706112-0756c75c-ab51-4200-b12d-87612b06e2bc.png)  

cut 명령을 사용하면 실수값을 다음처럼 카테고리 값으로 바꿀 수 있습니다.  
bins 인수는 카테고리를 나누는 기준값이 됩니다. 영역을 넘는 값은 NaN으로 처리됩니다.
![image](https://user-images.githubusercontent.com/105477856/230706143-7b4ffb97-c3fa-45f8-8f5e-82629cf66875.png)

cut() 명령이 반환하는 값은 Categorical 클래스 객체입니다.   
이 객체는 categories 속성으로 label 문자열을, codes 속성으로 정수로 인코딩한 카테고리 값을 가집니다.
![image](https://user-images.githubusercontent.com/105477856/230706166-2acd8b2c-1c8a-42a5-9c5f-f99bce6a176b.png)  
![image](https://user-images.githubusercontent.com/105477856/230706182-21b303fe-ca83-42de-a174-e2b34a427c8a.png)  

따라서 위 DataFrame의 age_cat column 값은 문자열이 아닙니다. 이를 문자열로 만들려면 astype() 메서드를 사용해야 합니다.
![image](https://user-images.githubusercontent.com/105477856/230706206-4f832d80-7f6d-492c-9be3-e3555b20e702.png)

qcut() 명령은 구간 경계선을 지정하지 않고 분위수와 같이 데이터 개수가 같도록 구간을 나눕니다.  
예를 들어 다음 코드는 1,000개의 데이터를 4개의 구간으로 나누는데 각 구간은 250개씩의 데이터를 가집니다.  
![image](https://user-images.githubusercontent.com/105477856/230706235-d6a773af-c89c-4c48-94b5-ebf71a60bf29.png)
