---
title : "MongoDB 성능이 RDBMS 보다 뛰어난 이유"
date : 2025-07-19 16:40:00 +09:00
categories : [Database, MongoDB]
tags : []
math : true
image:
---

MongoDB는 'MongoDB는 대용량 데이터 처리에 적합하다.'라고 표현되며 설명되곤 한다.  
RDBMS와 어떤 차이점이 있길래 그런 수식어가 붙는걸까?  

궁금증에 그런 이유들을 알아보기 위해 서칭해보면 "_스키마가 유연하다_", "_대규모 분산 데이터를 효율적으로 처리할 수 있는 구조이다_" 등등 그 이유에 관련된 키워드가 나오지만, 그래서 왜 더 뛰어난 건지에 대한 원리를 잘 모르겠다.

이번 포스팅은 그 원리를 알아보는 목적을 가졌다. 

그것에 대한 답은 MongoDB의 데이터 모델링 방식, 그리고 스토리지 엔진 작동 방식에 있었다. 먼저 데이터 모델링 방식을 살펴보자.

## 데이터 모델링: 임베디드 구조 (No JOIN)
MongoDB는 document-oriented data model을 사용한다.  
이 모델은 복잡한 데이터에 대해서 정규화를 필요로 하지 않아서 JOIN 연산없이 모든 데이터를 간단하고 효율적으로 조회할 수 있게 한다.

### '보험 정책 시스템' 예시로 보는 모델링 차이
보험 정책(Policy)을 중심으로 고객(Customer)과 보장내용(Coverage)이 연결된 시스템을 예시로 두 데이터베이스의 모델링 방식을 비교해보자.

MySQL에서는 정규화 원칙에 따라 각 엔터티를 별도 테이블로 분리한다.

```sql
-- 고객 테이블
CREATE TABLE customers (
    customer_id INT PRIMARY KEY,
    name VARCHAR(100),
    email VARCHAR(100),
    phone VARCHAR(20),
    address TEXT
);

-- 정책 테이블
CREATE TABLE policies (
    policy_id INT PRIMARY KEY,
    customer_id INT,
    policy_number VARCHAR(50),
    start_date DATE,
    end_date DATE,
    premium DECIMAL(10,2),
    status VARCHAR(20),
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id)
);

-- 보장내용 테이블
CREATE TABLE coverages (
    coverage_id INT PRIMARY KEY,
    policy_id INT,
    coverage_type VARCHAR(50),
    coverage_amount DECIMAL(12,2),
    deductible DECIMAL(8,2),
    FOREIGN KEY (policy_id) REFERENCES policies(policy_id)
);
```
이 구조에서 하나의 정책과 관련된 모든 정보를 조회하려면 복잡한 JOIN이 필요하다.
```sql
SELECT 
    p.policy_number,
    p.premium,
    c.name as customer_name,
    c.email,
    GROUP_CONCAT(cov.coverage_type) as coverages,
    SUM(cov.coverage_amount) as total_coverage
FROM policies p
JOIN customers c ON p.customer_id = c.customer_id
JOIN coverages cov ON p.policy_id = cov.policy_id
WHERE p.policy_id = 12345
GROUP BY p.policy_id;
```
<br>
MongoDB에서는 관련된 데이터를 하나의 문서에 임베드하여 저장한다.

```javascript
// policies 컬렉션의 단일 문서
{
  _id: ObjectId("507f1f77bcf86cd799439011"),
  policy_number: "POL-2024-001",
  start_date: ISODate("2024-01-01"),
  end_date: ISODate("2024-12-31"),
  premium: 1200.50,
  status: "active",
  
  // 고객 정보 임베디드
  customer: {
    name: "김철수",
    email: "kim@example.com",
    phone: "010-1234-5678",
    address: "서울시 강남구 테헤란로 123"
  },
  
  // 보장내용 배열로 임베디드
  coverages: [
    {
      coverage_type: "생명보험",
      coverage_amount: 100000000,
      deductible: 0
    },
    {
      coverage_type: "상해보험",
      coverage_amount: 50000000,
      deductible: 100000
    },
    {
      coverage_type: "질병보험",
      coverage_amount: 30000000,
      deductible: 50000
    }
  ]
}
```
같은 정보를 조회할 때는 단순한 쿼리만 필요하다.
```javascript
db.policies.findOne({ _id: ObjectId("507f1f77bcf86cd799439011") })
```

### 성능 상의 차이점
앞서 살펴본 이론에 의해 **MySQL**은 MongoDB와 비교했을 때 다음과 같은 성능 저하가 생긴다.
1. 3개 테이블에서 데이터를 읽어야 함 
2. JOIN 연산으로 인한 CPU 오버헤드 발생 
3. 인덱스 스캔이 여러 테이블에 걸쳐 발생
4. 네트워크 I/O가 여러 번 발생할 가능성


그리고 MongoDB는 MySQL과 비교했을 때 다음과 같은 성능적 이점이 있다.
1. 단일 문서 읽기로 모든 데이터 획득
2. JOIN 연산 불필요 
3. 하나의 인덱스 스캔으로 완료 
4. 단일 네트워크 I/O

---

## 데이터 지역성(Data Locality)이 만드는 성능 차이
![mongodb_locality_compare_with_rdbms.png](https://github.com/jewoodev/blog_img/blob/main/2025-07-18-MongoDB%EC%9D%98_%EC%84%B1%EB%8A%A5%EC%9D%B4_RDBMS%EB%B3%B4%EB%8B%A4_%EB%9B%B0%EC%96%B4%EB%82%9C_%EC%9D%B4%EC%9C%A0/MongoDB%EA%B3%BC_RDBMS%EC%9D%98_%EC%A7%80%EC%97%AD%EC%84%B1_%EB%B9%84%EA%B5%90.png?raw=true)
_출처:[MongoDB's Performance over RDBMS](https://www.mongodb.com/developer/products/mongodb/mongodb-performance-over-rdbms/)_

그러한 데이터 모델링 방식의 차이는 **데이터 지역성**이 달라지는 결과로도 이어진다.  
그리고 데이터 지역성에서 성능의 결정적인 차이가 생겨난다.

### RDBMS의 물리적 분산 저장 문제
MySQL에서는 정규화로 인해 **논리적으로 연관된 데이터가 물리적으로는 연속되지 않은 디스크 위치에 저장**된다.
```
디스크 주소 1000-2000: Policies 테이블 데이터
디스크 주소 5000-6000: Coverage 테이블 데이터  
디스크 주소 8000-9000: Customer 테이블 데이터
```
물리적 분산 저장이 위의 예시대로 이루어진다면 하나의 Policy 정보를 조회할 때
1. 디스크 헤드가 주소 1000번대로 이동 → Policy 데이터 읽기
2. 디스크 헤드가 주소 8000번대로 이동 → Customer 데이터 읽기
3. 디스크 헤드가 주소 5000번대로 이동 → Coverage 데이터 읽기

의 과정을 거칠 것이다. 

그리고 이런 **물리적으로 분산된 위치 접근**이 랜덤 I/O를 유발한다. 즉, 성능이 저하된다.
- 디스크 헤드의 잦은 이동 (Seek Time 증가)
- 디스크 회전 대기 시간 (Rotational Latency) 누적
- HDD 기준 랜덤 I/O는 순차 I/O보다 100-1000배 느림

### MongoDB의 물리적 연속 저장
반면 MongoDB는 관련된 모든 데이터를 **물리적으로 연속된 디스크 공간**에 저장한다.
```
디스크 주소 1000-1500: Policy + Customer + Coverage 모든 데이터
```
따라서 하나의 Policy 정보를 조회할 때는 **단일 위치에서 순차적으로** 모든 데이터를 읽는다.
1. 디스크 헤드가 주소 1000번대로 한 번만 이동
2. 연속된 공간에서 모든 관련 데이터를 순차적으로 읽기

즉, 성능이 향상된다.
- 디스크 헤드 이동 최소화 (Seek Time 거의 없음)
- 연속된 데이터 블록을 한 번에 읽기 가능
- HDD/SSD 모두에서 최적의 성능 발휘

이것이 **데이터 지역성의 차이에서 생겨나는 성능 차이**이다. 논리적으로 연관된 데이터를 물리적으로도 가까운 곳에 배치하여 디스크 접근을 최적화하는 것이다.

### 성능 수치로 보는 차이
실제 벤치마크에서 이런 차이가 어떤 퍼포먼스 차이로 이어지는지 살펴보자.

**데이터 조회 시간 (1만건 기준):**
- MySQL (3-table JOIN): 평균 45ms
- MongoDB (embedded): 평균 8ms

**디스크 I/O 횟수:**
- MySQL: 정책 1건 조회시 평균 3-5회의 디스크 액세스
- MongoDB: 정책 1건 조회시 1회의 디스크 액세스

### 확장성 측면에서의 장점
대용량 데이터 환경에서 이러한 데이터 지역성 차이는 더욱 극명해진다. 수백만 건의 정책 데이터가 있을 때 각각 어떻게 달라지는지 살펴보자.

**MySQL**: 각 쿼리마다 여러 테이블을 조인해야 하므로, 데이터가 늘어날수록 성능이 급격히 저하된다. 특히 분산 환경에서는 테이블들이 서로 다른 서버에 위치할 경우 네트워크 오버헤드가 기하급수적으로 증가한다.

**MongoDB**: 문서 하나만 읽으면 되므로 데이터양이 증가해도 성능 저하가 선형적이다. 또한 샤딩(분산)시에도 관련 데이터가 함께 이동하므로 분산 환경에서의 성능 저하가 최소화된다.

---

## 스토리지 엔진: WiredTiger가 갖는 다른 작동 방식
데이터 모델링 방식의 차이와 함께 MongoDB의 성능 우위를 가져오는 또 다른 핵심 요소는 바로 **WiredTiger 스토리지 엔진**이다.  

MongoDB는 MySQL처럼 다양한 스토리지 엔진을 플러그인 형태로 지원한다. 그래서 어떤 스토리지 엔진을 사용할지 선택할 수 있다.  

그런 MongoDB의 디폴트 스토리지 엔진은 **WiredTiger 스토리지 엔진**이다. 이 엔진은 고동시성 워크로드에서 전통적인 RDBMS와는 많은 차이점을 보인다.  

왜 그런 차이점을 보이는지 살펴보기 전에 공유 캐시라는 것부터 살펴보자.

이 엔진은 내장된 공유 캐시(버퍼 풀)를 가지고 있다.  
WiredTiger의 내장된 공유 캐시는 디스크의 인덱스나 데이터 파일을 메모리에 캐시해서 빠르게 쿼리를 처리할 뿐만 아니라, 데이터의 변경을 모아서 한 번에 디스크에 기록하는 쓰기 배치 기능도 가지고 있다.

도큐먼트(레코드)의 변경은 공유 캐시에 먼저 적용이 된다. WiredTiger 스토리지 엔진은 변경된 데이터가 디스크에 기록되는 과정을 **기다리지 않고** 변경 내용을 저널 로그에 기록한 다음 사용자에게 작업 처리 결과를 리턴한다.

그리고 공유 캐시의 객체에 대한 잠금 경합을 최소화하기 위해 Lock-Free 알고리즘을 사용한다. 그런 알고리즘으로 "하자드 포인터"와 "스킵 리스트" 자료 구조를 활용해 Lock-Free 콘셉을 구현하고 있다.

### 하자드 포인터: 안전한 동시성 제어
하자드 포인터의 작동 원리를 이해하기 위해 두 가지 스레드 타입을 구분해보자.
- **사용자 스레드**: 사용자의 쿼리를 처리하기 위해 WiredTiger 캐시를 참조하는 스레드
- **이빅션 스레드**: 캐시가 다른 데이터 페이지를 읽어 들일 수 있도록 빈 공간을 만드는 스레드

WiredTiger 스토리지 엔진의 모든 "사용자 스레드"는 캐시의 데이터 페이지를 참조할 때, 먼저 하자드 포인터에 자신이 참조하는 페이지를 등록한다.  
그리고 이빅션 스레드는 삭제할 페이지를 선택한 후 하자드 포인터에 등록되어 있는지 확인하고, 등록되어 있다면 해당 페이지를 삭제하지 않는다.

### 스킵 리스트: 효율적인 데이터 구조
WiredTiger 스토리지 엔진에서 Lock-Free를 구현하기 위한 또 다른 기술이 스킵 리스트 자료 구조이다.

스킵 리스트 자료 구조를 이해하기 위해 링크드 리스트와 비교해보려 한다.  
링크드 리스트는 조회 구조가 단방향이며, 8번째 노드를 검색하려면 8번의 노드 검색이 필요하다. 스킵 리스트는 중간 노드를 갖는 여러 개의 리스트 층을 형성해 필요한 노드 검색 횟수를 줄인다. 이런 스킵 리스트의 평균 검색 기능은 B-Tree와 같은 O(log(n)) 이다.  

![링크드_리스트와_스킵_리스트의_작동_방식_비교.png](https://github.com/jewoodev/blog_img/blob/main/2025-07-18-MongoDB%EC%9D%98_%EC%84%B1%EB%8A%A5%EC%9D%B4_RDBMS%EB%B3%B4%EB%8B%A4_%EB%9B%B0%EC%96%B4%EB%82%9C_%EC%9D%B4%EC%9C%A0/%EB%A7%81%ED%81%AC%EB%93%9C_%EB%A6%AC%EC%8A%A4%ED%8A%B8%EC%99%80_%EC%8A%A4%ED%82%B5_%EB%A6%AC%EC%8A%A4%ED%8A%B8%EC%9D%98_%EC%9E%91%EB%8F%99_%EB%B0%A9%EC%8B%9D_%EB%B9%84%EA%B5%90.png?raw=true)
_링크드 리스트와 스킵 리스트의 조회 과정 비교_

스킵 리스트는 B-Tree에 비해 검색 기능이 조금 떨어지긴 하지만, 구현이 간단하고 메모리 공간을 많이 필요로 하지 않는다. 그뿐만 아니라 WiredTiger 스토리지 엔진에 사용된 스킵 리스트는 새로운 노드를 추가하기 위해 잠금을 필요로 하지 않으며, 검색에도 필요하지 않다. 노드 삭제는 잠금을 필요로 하지만, B-Tree 자료 구조보다는 잠금을 덜 필요로 하므로 그다지 큰 성능 저하 이슈는 아니다.

WiredTiger 스토리지 엔진도 다른 RDBMS와 동일하게 변경되기 전 레코드(언두 로그)를 별도의 저장 공간에 관리한다. 이렇게 언두 로그를 관리하는 이유는 트랜잭션이 롤백될 때 기존 데이터를 복구하기 위함인데, 많은 RDBMS에서는 언두 로그를 잠금 없는 데이터 읽기(MVCC) 용도로도 같이 사용한다. WiredTiger 스토리지 엔진에서는 언두 로그를 스킵 리스트로 관리하는데, 조금 독특하게 데이터 페이지의 레코드를 직접 변경하지 않고 변경 이후의 데이터를 스킵 리스트에 추가한다.

WiredTiger 스토리지 엔진에서는 데이터가 변경돼도 데이터 페이지에 변경된 내용을 직접적으로 변경하지 않는다. 대신 변경된 내용을 스킵 리스트에 차곡차곡 기록해둔다. 그리고 사용자 쿼리가 데이터를 읽을 땐 변경 이력이 저장된 스킵 리스트를 검색해서 원하는 시점의 데이터를 가져온다. 이런 방식의 의도는 쓰기 처리를 빠르게 하기 위함이다.

다른 RDBMS는 데이터가 변경되면서 크기가 커지면 데이터 페이지 내에서 레코드 위치를 옮겨야 할 수도 있는데, 이런 일련의 과정 때문에 성능 저하가 발생한다.
그에 반해 WiredTiger 스토리지 엔진에서는 변경되는 내용을 스킵 리스트에 추가하기만 하면 된다. 그리고 그런 스킵 리스트에 내용을 추가하는 작업은 매우 빠르게 처리되므로 사용자의 응답 시간도 훨씬 빨라진다.

일부 RDBMS에서 데이터 페이지는 한 시점에 하나의 스레드만 사용(읽고 쓰기)할 수 있다.
그에 반해 WiredTiger 스토리지 엔진은 이런 관리 방식 덕분에 여러 스레드가 하나의 페이지를 동시에 읽고 쓸 수 있다.

> 여기서 '스킵 리스트에 추가하기만 한다~'는 표현은 메모리 상의 스킵 리스트에 저장한다는 걸 의미한다. 그렇게 메모리에서 관리되는 스킵 리스트에 변경 내역을 저장해나가다가, 특정 주기마다 디스크에 한 번에 저장하는 메커니즘으로 영속화 작업을 한다. 

### 독특한 데이터 변경 방식
WiredTiger의 가장 독특한 특징은 **데이터 변경 방식**이다.  
다른 RDBMS와 달리 WiredTiger는 데이터가 변경돼도 데이터 페이지에 직접 변경하지 않는다. 대신 변경된 내용을 스킵 리스트에 차곡차곡 기록해둔다.  
그리고 사용자 쿼리가 데이터를 읽을 때는 변경 이력이 저장된 스킵 리스트를 검색해서 원하는 시점의 데이터를 가져온다.

이러한 방식의 장점은 다음과 같다.
- **빠른 쓰기 처리**: 변경 내용을 스킵 리스트에 추가하기만 하면 되므로 매우 빠름
- **동시성 향상**: 여러 스레드가 하나의 페이지를 동시에 읽고 쓸 수 있음
- **성능 최적화**: 전통적인 RDBMS처럼 데이터 크기 변경 시 레코드 위치를 옮길 필요 없음

### 고급 압축 및 최적화 기능
WiredTiger는 **구성 가능한 데이터 압축**을 지원한다.   
사용자는 요구사항에 따라 다양한 압축 알고리즘을 선택할 수 있어, 워크로드와 성능 목표에 가장 적합한 설정을 구성할 수 있다.

압축의 트레이드오프를 고려해보면 아래와 같은 장/단점이 있다.
- **장점**: 저장 비용 절감, 읽기/쓰기 성능 향상
- **단점**: 압축/해제 과정에서 추가 CPU 오버헤드 발생

중요한 것은 WiredTiger의 압축 기능이 애플리케이션에 완전히 투명하며, 애플리케이션 코드 변경을 요구하지 않는다는 점이다.

---

## 고급 인덱싱
MongoDB의 성능 우위를 완성하는 세 번째 요소는 인덱싱 기능의 차이이다. 하지만 간단히 말해 인덱싱 기능이지, 결국엔 데이터 모델링 방식, 지역성, I/O 메커니즘 등등.. 이 맞물려있다. 어떤 차이가 있는지 살펴보자.

### 임베디드 문서 인덱싱: 중첩 구조의 최적화
고객명으로 정책을 검색하는 경우를 살펴보자. MongoDB부터 살펴보면 다음과 같다.
```javascript
// 중첩 필드 직접 인덱싱
db.policies.createIndex({"customer.name": 1})
db.policies.find({"customer.name": "김철수"})
```
MongoDB는 중첩된 문서 구조에서 점 표기법으로 직접적인 조회문을 작성할 수 있으며, 이는 관련 데이터가 물리적으로 함께 저장되는 구조와 결합되어 JOIN 연산 없이 효율적인 검색을 할 수 있다.
```javascript
// 복합 중첩 인덱스도 가능
db.policies.createIndex({
  "customer.name": 1,
  "coverages.coverage_type": 1,
  "status": 1
})

// 이런 복잡한 쿼리도 단일 인덱스로 최적화
db.policies.find({
  "customer.name": "김철수",
  "coverages.coverage_type": "생명보험",
  "status": "active"
})
```
그래서 MongoDB는 위와 같은 복잡한 조회에서도 단일 인덱스만으로 조회를 최적화할 수 있다. 하지만 MySQL은 그렇게 간단하게 조회가 이루어지지 않는다.

MySQL의 JOIN 연산이 포함된 복잡한 쿼리에서 인덱스 사용이 어떻게 이루어지는지 단계별로 살펴보면 다음과 같다.

#### MySQL 옵티마이저의 실행 계획
```sql
SELECT p.policy_number, c.name, cov.coverage_type
FROM policies p
JOIN customers c ON p.customer_id = c.customer_id  
JOIN coverages cov ON p.policy_id = cov.policy_id
WHERE c.name = '김철수' AND cov.coverage_type = '생명보험';
```
이 쿼리의 실행 계획을 옵티마이저가 어떻게 수립할까? 다음과 같다.

1. 첫 번째 테이블 선택 (Driving Table)
    - 가장 선택적인 조건을 가진 테이블을 먼저 선택
    - 예: customers 테이블의 `name = '김철수'` 조건이 가장 선택적이라면 `idx_customer_name` 인덱스를 사용해 해당 고객 레코드들을 먼저 찾음
2. 중첩 루프 조인 (Nested Loop Join)
    ```
    FOR each customer WHERE name = '김철수':
    customer_id = 123
    
        FOR each policy WHERE customer_id = 123:  -- idx_customer_id 사용
        policy_id = 456
    
            FOR each coverage WHERE policy_id = 456 AND coverage_type = '생명보험':
              -- idx_policy_coverage 복합 인덱스 사용
              결과 반환
    ```
   맨 처음 `For each` 에 해당하는 조회가 수행되고, 그 결과물을 다음 조인 연산의 키로 사용하는 작업이 순차적으로 이루어진다. 위에서 묘사된 바와 같이 첫 번째 테이블이 `customer`로 정해지면 해당 테이블의 조건으로 다음 조인 연산의 키를 찾고, 다음 조인 연산의 결과로 그 다음 조인 연산의 키를 찾는 것을 순차적으로 수행하는 계획이 수립된다.

#### 인덱스 활용의 제약사항
```sql
-- 복합 조건의 쿼리
WHERE c.name = '김철수'
  AND p.status = 'active'
  AND cov.coverage_type = '생명보험'
  AND cov.coverage_amount > 10000000
```
만약 쿼리 조건이 더 복합적이라면 MySQL 옵티마이저는 여러 테이블의 **통계 정보를 종합하여 최적의 실행 계획을 수립**해야 하므로 복잡성이 증가한다. 
```sql
-- 각 조건의 선택도를 정확히 예측하기 어려움
WHERE c.name = '김철수'        -- 선택도: 0.001%?
  AND p.status = 'active'      -- 선택도: 80%?
  AND cov.coverage_type = '생명보험'  -- 선택도: 30%?
  AND cov.coverage_amount > 10000000  -- 선택도: 5%?
```

현대의 옵티마이저는 이런 복잡성도 잘 처리하지만, 구조적으로 여러 테이블을 조인해야 하는 **근본적 제약은 여전히 남아있다**.
- 3개 테이블을 반드시 조인해야 함
- 각 테이블의 인덱스를 개별적으로 탐색
- 중간 결과셋을 메모리에서 처리
- 물리적으로 분산된 데이터 접근

반면 MongoDB는 단일 문서 구조로 인해 이러한 **최적화 복잡성 자체가 필요없다**.
```javascript
// 옵티마이저 복잡성 자체가 필요 없음
db.policies.find({
  "customer.name": "김철수",
  "status": "active", 
  "coverages.coverage_type": "생명보험",
  "coverages.coverage_amount": {$gt: 10000000}
})
```

#### 실제 성능 이슈 (인덱스가 있어도 느린 이유)
```sql
SELECT p.policy_number, c.name, cov.coverage_type
FROM policies p
JOIN customers c ON p.customer_id = c.customer_id  
JOIN coverages cov ON p.policy_id = cov.policy_id
WHERE c.name = '김철수'
```
MySQL의 성능이 나빠지는 이유에는 **다중 인덱스 접근**으로 인한 오버헤드도 빼놓을 수 없다. "인덱스가 어떻게 활용되지?" 라는 의문점을 중점적으로 두고 살펴보면

1. `customers.name` 를 인덱스(를 통해) 조회해서 → `customer_id` 획득
2. `policies.customer_id` 를 인덱스 조회해서 → `policy_id`들 획득
3. `coverages.policy_id` 를 인덱스 조회해서 → `coverage` 레코드들 획득

순서로 수행되며 각 단계마다 실제 데이터 페이지 접근이 일어나게 될 것이다. 즉, 인덱스 스캔만 3번, 그것도 랜덤 I/O가 발생한다. 

**조인 순서 최적화의 복잡성**도 성능 이슈의 원인이다.
```sql
-- 옵티마이저가 잘못된 순서를 선택할 수 있음
EXPLAIN SELECT ...
-- 때로는 STRAIGHT_JOIN 힌트가 필요
```

느려지는 이슈 외에 메모리 사용이 MongoDB보다 비효율적인 면이 있다. 이는 잠시 후에 '메모리 캐시 효율성' 섹션에서 살펴보도록 하겠다.

### 다중키 인덱스: 배열 데이터 처리
보험 정책의 보장내용(coverages) 배열을 검색하는 상황을 보자.

**MySQL에서 특정 보장내용을 검색**하는 경우엔 다음과 같이 쿼리를 해야 한다.

```sql
-- "생명보험"이 포함된 정책 찾기
SELECT p.policy_number, p.premium 
FROM policies p
JOIN coverages c ON p.policy_id = c.policy_id
WHERE c.coverage_type = '생명보험';
```
이 경우 coverages 테이블 전체를 스캔하거나, coverage_type에 인덱스가 있어도 JOIN 연산이 필요하다. 이에 반해 MongoDB의 데이터 모델에서는 이를 배열로 설계함으로써 **배열 내 요소 검색**을 수행하게 된다. 이는 부가적인 작업 없이 조회를 수행하는 결과로 이어진다.

```javascript
// "생명보험"이 포함된 정책 찾기
db.policies.find({"coverages.coverage_type": "생명보험"})
```
MongoDB는 배열의 각 요소에 인덱스를 걸 수 있다. 예를 들어, coverage_type에 인덱스를 생성하면 다음과 같이 인덱스 엔트리가 생성된다.
```javascript
// coverages.coverage_type 인덱스 생성
db.policies.createIndex({"coverages.coverage_type": 1})

// 하나의 문서에 배열로 저장
{
    _id: ObjectId("507f1f77bcf86cd799439011"),
        
    // ...

    coverages: [
        {
            coverage_type: "생명보험",
            coverage_amount: 100000000,
            deductible: 0
        },
        {
            coverage_type: "상해보험",
            coverage_amount: 50000000,
            deductible: 100000
        },
        {
            coverage_type: "질병보험",
            coverage_amount: 30000000,
            deductible: 50000
        }
    ]
}

// 실제로는 다음과 같은 인덱스 엔트리들이 생성됨:
// "생명보험" -> ObjectId("507f1f77bcf86cd799439011")
// "상해보험" -> ObjectId("507f1f77bcf86cd799439011") 
// "질병보험" -> ObjectId("507f1f77bcf86cd799439011")
```
여기서 살펴본 차이점 때문에 다음과 같은 **성능 차이**가 있다.
- **MySQL**: JOIN으로 인한 CPU 오버헤드 + 두 테이블의 인덱스 스캔
- **MongoDB**: 단일 인덱스 스캔으로 즉시 문서 식별

### '인덱스 지역성'과 'I/O 처리 방식'의  차이
MongoDB는 단일 문서로 데이터를 모델링 하기 때문에 하나의 인덱스 테이블만 스캔한다. 그리고 I/O 방식도 다르다. 어떻게 다를까?

**전통적인 RDBMS 인덱스 접근**은 다음과 같이 랜덤 I/O를 유발한다.
1. 인덱스 스캔으로 Row ID 획득 (디스크 위치 A)
2. Row ID로 실제 데이터 접근 (디스크 위치 B)
3. JOIN을 위해 다른 테이블 접근 (디스크 위치 C, D)

이에 반해 **MongoDB 인덱스 접근**은 순차 I/O를 통해 수행된다.
1. 인덱스 스캔으로 Document ID 획득 (디스크 위치 A)
2. Document ID로 모든 관련 데이터를 한 번에 접근 (디스크 위치 B)

그리고 MongoDB의 I/O는 클러스터드 인덱스 룩업을 수행하지 않고 `_id`값으로 직접 물리적 위치를 계산하는 메커니즘으로 되어 있다.   

```sql
SELECT * FROM coverages WHERE coverage_type = '생명보험';

-- 실행 과정:
-- 1. 세컨더리 인덱스: coverage_type → primary_key
-- 2. 클러스터드 인덱스: primary_key → 데이터 페이지
```
MySQL은 이렇게 클러스터디 인덱스 룩업이 수행되면서 I/O가 처리되지만

```javascript
db.policies.find({"coverages.coverage_type": "생명보험"})

// 실행 과정:
// 1. 세컨더리 인덱스: coverage_type → _id
// 2. _id로 직접 문서 위치 계산 (추가 인덱스 룩업 없음)
```
MongoDB는 그렇지 않다. 그런 참조 없이 WiredTiger가 ObjectId로 문서의 물리적 위치를 직접 계산한다.

### 메모리 캐시 효율성
MySQL는 여러 테이블로 분산, MongoDB는 단일 문서로 저장하기 때문에 **메모리 사용 패턴**에서 차이가 생긴다.

**MySQL의 캐시 사용:**
- 논리적으로 연관된 데이터가 물리적으로 분산된 페이지들에 저장
- 3개 테이블의 각기 다른 페이지를 모두 메모리에 유지해야 함
- **메모리 사용량 증가**: 관련 없는 테이블의 페이지들까지 점유
    - 예시: 48KB를 메모리에 로드 -> 650 바이트만 실제 사용 (1.4% 효율)

**MongoDB의 캐시 사용:**
- 논리적으로 연관된 데이터가 물리적으로 하나의 문서에 집중
- 단일 페이지 로드로 모든 관련 정보 확보
- **메모리 사용량 효율**: 최소한의 페이지로 최대 정보 획득
    - 예시: 8KB를 메모리에 로드 -> 650 바이트 실제 사용 (8% 효율)

그리고 위 예시에서 MySQL은 3개의 테이블에 접근하므로 3번의 CPU 캐시 미스가 생겨날 수 있지만 MongoDB는 1개의 문서에 접근하므로 캐시 미스가 1번만 일어날 수 있다.  
CPU 캐시 미스 또한 당연히 오버헤드로 이어질 수 있다는 걸 재미로 알아두자. 성능 차이의 주요 원인은 아니다.

### 와일드카드 인덱스: 스키마리스의 진정한 활용
MongoDB는 스키마가 자주 변경되는 환경에서 동적으로 인덱싱을 할 수 있다. 와일드카드 인덱스를 활용하면 되는데, 아래에서 와일드카드 인덱스를 걸면 어떻게 인덱스가 생성되는지 확인해보자.
```javascript
// 모든 하위 필드에 대한 동적 인덱싱
db.policies.createIndex({"coverages.$**": 1})

// 새로운 필드가 추가되어도 자동으로 인덱싱됨
db.policies.insertOne({
  policy_number: "POL-2024-002",
  coverages: [
    {
      coverage_type: "생명보험", // 자동으로 인덱싱됨
      new_field: "새로운 속성",  // 이것도 자동으로 인덱싱됨
      another_field: "또 다른 속성"  // 이것도 자동으로 인덱싱됨
    }
  ]
})
```
코드에서 `coverages.$**`의 `$**`가 와일드카드 지정자이다. 이렇게 설정하면 `coverages` 필드가 내장된 문서 또는 배열인 경우 그 문서/배열의 모든 필드에 인덱스를 생성한다. 

---

## 결론: 통합적 성능 우위
MongoDB가 대용량 데이터 처리에서 보여주는 성능 우위는 아래의 세 가지 핵심 요소의 시너지 효과다.

1. **데이터 모델링**: 임베디드 구조를 통한 데이터 지역성 확보와 JOIN 연산 제거
2. **스토리지 엔진**: WiredTiger의 Lock-Free 아키텍처
3. **고급 인덱싱**: 다양한 쿼리 패턴에 최적화된 특화 인덱스 지원

RDBMS와는 다른 목적으로 설계되었기 때문에, 위와 같은 주요 차이점이 있으며 이로 인해 MongoDB는 전통적인 RDBMS 대비 향상된 처리량과 효과적인 워크로드 분산을 달성할 수 있다.  

다만 주의할 점이 있는데, MongoDB의 유연성이 스키마 설계의 중요성을 간과해도 된다는 의미는 아니다. 프로젝트 초기부터 스키마 설계 모범 사례를 적용하는 것이 향후 리팩토링 노력을 절약하는 핵심이다.

---

## Reference
- [Real MongoDB](https://product.kyobobook.co.kr/detail/S000001766322)
- [MongoDB's Performance over RDBMS](https://www.mongodb.com/developer/products/mongodb/mongodb-performance-over-rdbms/)