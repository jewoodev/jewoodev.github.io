---
title : "JDBC user가 이해하기 쉬운 Spring Data R2DBC"
date : 2025-06-28 22:13:00 +09:00
categories : [R2DBC, Spring Data]
tags : []
math : true
image:
---

애플리케이션이 동작하기 위한 일련의 data interaction을 위해선 data store가 필요하다. 그리고 data store에 어떻게 interaction을 할 것인지는 애플리케이션의 전반적인 동작에 큰 영향을 준다. 이번 포스팅에선 수많은 data store 중에 "RDBMS" 카테고리에 속하는 database를 비동기적으로 interaction하는 API 중 하나이자 Spring Data Family Project인 Spring Data R2DBC에 대해 알아볼 것이다.

이야기를 시작하기 전에 이 글이 "JDBC에 경험이 있는 사람"을 독자로 설정했음을 알린다. 이 설정의 이유는 동기식 (애플리케이션) 아키텍처와 비동기식 아키텍처를 비교했을 때, 비동기식에는 보다 더 필요한 전제들이 있고 이로 인해 더 복잡성을 띄기 때문에 동기식을 이해하고서 비동기식으로 넘어가는 것이 좋다는 사실에 있다. 만약 동기 방식 개발 경험이나 지식이 없거나 JDBC에 대해 익숙하지 않은 독자라면 그걸 선행하고서 이 글을 읽는 것이 저자의 의도대로 이 글을 맛보는 것임을 전한다. 

## R2DBC( Reactive Relational Database Connectivity )란?
**R2DBC**는 Spring Data Relational에 속하는 Reactive Relational Database Connectivity Project로 관계형 데이터베이스에 리액티브 API를 제공한다.

R2DBC가 탄생하기 전엔 몇몇 NoSQL 벤더만 리액티브 API를 제공했었다. 그래서 리액티브 애플리케이션에서 관계형 데이터베이스를 사용할 경우, 완전한 Non-Blocking I/O를 구현하는 것이 불가능했다. JDBC API 자체가 Blocking API 이기 때문이다.

하지만 R2DBC는 JDBC와 완전히 다른 구현을 적용함으로써 클라이언트의 요청부터 데이터베이스 접근까지 완전한 Non-Blocking 구현이 가능케 한다.

### R2DBC와 기존의 Relational Database Project와의 차이 - 1. 아키텍처 차이
JDBC와 R2DBC의 가장 근본적인 차이는 블로킹과 논블로킹 방식의 차이이다. JDBC는 각 작업 단계에서 응답을 기다리는 동안 스레드가 대기 상태가 되어 시스템 리소스를 점유한다. 반면 R2DBC는 비동기적으로 작업을 처리하여 스레드가 다른 작업을 처리할 수 있도록 하며, 결과는 스트리밍 방식으로 처리된다.

```java
// JDBC - Blocking 방식
public List<User> getUsers() {
    // 1. 연결 요청 (블로킹)
    Connection conn = DriverManager.getConnection(url);
    
    // 2. 쿼리 실행 (블로킹) - 응답을 받을 때까지 스레드 대기
    Statement stmt = conn.createStatement();
    ResultSet rs = stmt.executeQuery("SELECT * FROM users");
    
    // 3. 결과 처리 (블로킹)
    List<User> users = new ArrayList<>();
    while (rs.next()) { // 각 행을 읽을 때마다 블로킹
        users.add(new User(rs.getString("name")));
    }
    return users;
}

// R2DBC - Non-blocking 방식
public Flux<User> getUsers() {
    return connectionFactory
            .create() // 1. 비동기 연결 생성
            .flatMapMany(connection ->
                    connection
                            .createStatement("SELECT * FROM users")
                            .execute() // 2. 비동기 쿼리 실행
            )
            .flatMap(result ->
                    result.map((row, metadata) -> // 3. 스트리밍 결과 처리
                            new User(row.get("name", String.class))
                    )
            );
}
```

R2DBC의 메소드의 시그니처에서 리턴타입이 `Flux<User>` 인데 이는 JVM의 다양한 asychronize 라이브러리 중 Spring이 채택한 Reactor Project의 `Publisher` 라는 개념에 속하는 것이다. 이에 대해 무지하다면, Mono는 데이터를 0개 혹은 하나 뱉어내는 물줄기, Flux는 데이터를 0개부터 여러 개까지 뱉어내는 물줄기라는 개념으로 이해하고 넘어가자.  

### R2DBC와 기존의 Relational Database Project와의 차이 -  2. 프로토콜 레벨에서의 차이
데이터베이스와의 통신 방식에서도 큰 차이가 있다. JDBC는 요청을 보내고 완전한 결과를 받을 때까지 기다리는 전통적인 요청-응답 패턴을 사용한다. R2DBC는 백프레셔(Backpressure)를 지원하는 스트리밍 방식으로, 클라이언트가 처리할 수 있는 만큼만 데이터를 받아 메모리 사용량을 효율적으로 관리할 수 있다.

**JDBC 기반:**
``` 
클라이언트 → [동기 요청] → 데이터베이스
클라이언트 ← [완전한 결과 반환] ← 데이터베이스
```
**R2DBC 기반:**
``` 
클라이언트 → [비동기 요청] → 데이터베이스
클라이언트 ← [스트리밍 결과] ← 데이터베이스 (Backpressure 지원)
```

### R2DBC와 기존의 Relational Database Project와의 차이 -  3. 연결 관리
연결 관리 방식도 완전히 다르다. JDBC는 스레드와 연결이 강하게 결합되어 하나의 스레드가 연결을 점유하고 있는 동안 다른 작업을 할 수 없다. R2DBC는 이벤트 루프 방식을 사용하여 스레드와 연결을 분리함으로써 적은 수의 스레드로도 많은 연결을 효율적으로 관리할 수 있다.

**JDBC:**
``` java
// Connection Pool에서 스레드가 연결을 점유
Connection conn = dataSource.getConnection(); // 블로킹
// 쿼리 완료까지 연결과 스레드가 묶임
```
**R2DBC:**
``` java
// 이벤트 기반 연결 관리
Mono<Connection> connectionMono = connectionFactory.create();
// 스레드와 연결이 분리됨 - 이벤트 루프 방식
```

### R2DBC와 기존의 Relational Database Project와의 차이 -  4. 결과 처리 방식
대용량 데이터 처리에서 가장 큰 차이가 드러난다. JDBC는 모든 결과를 메모리에 한 번에 로드하는 풀 버퍼링 방식을 사용하여 대용량 데이터 처리 시 메모리 부족 문제가 발생할 수 있다. R2DBC는 결과를 행 단위로 스트리밍하고 백프레셔를 통해 메모리 사용량을 제어할 수 있어 안정적인 대용량 데이터 처리가 가능하다.

**JDBC - 풀 버퍼링:**
``` java
ResultSet rs = stmt.executeQuery("SELECT * FROM large_table");
// 모든 결과를 메모리에 로드한 후 처리
while (rs.next()) {
    // 이미 메모리에 있는 데이터 처리
}
```
**R2DBC - 스트리밍:**
``` java
connection.createStatement("SELECT * FROM large_table")
    .execute()
    .flatMap(result -> result.map(...)) // 행별로 스트리밍 처리
    .interval(Duration.ofMillis(10L) // Backpressure로 메모리 사용량 제어
    .onBackpressureDrop(); 
```

### R2DBC와 기존의 Relational Database Project와의 차이 -  5. 동시 요청 처리 방식
동시 요청 처리 능력에서 R2DBC의 진가가 발휘된다. JDBC 방식에서는 각 요청마다 별도의 스레드가 필요하여 많은 동시 요청이 있을 때 스레드 풀이 고갈될 수 있다. R2DBC는 이벤트 루프 기반으로 동작하여 소수의 스레드로도 수천 개의 동시 요청을 효율적으로 처리할 수 있다.

```java
// JDBC 방식 - 각 요청마다 스레드 필요
@RestController
public class JdbcController {
    public ResponseEntity<List<User>> getUsers() {
        // 1000개 동시 요청 = 1000개 스레드 필요
        return ResponseEntity.ok(userService.getAllUsers());
    }
}

// R2DBC 방식 - 소수의 이벤트 루프 스레드로 처리
@RestController
public class R2dbcController {
    public Mono<ResponseEntity<Flux<User>>> getUsers() {
        // 1000개 동시 요청을 4-8개 스레드로 처리 가능
        return Mono.just(ResponseEntity.ok(userService.getAllUsers()));
    }
}
```

### R2DBC와 기존의 Relational Database Project와의 차이 -  6. 메모리 사용량
메모리 사용 패턴에서도 중요한 차이가 있다. JDBC는 대용량 결과셋을 처리할 때 모든 데이터를 메모리에 로드하여 OutOfMemoryError 위험이 있다. R2DBC는 스트리밍과 배치 처리를 통해 메모리 사용량을 일정 수준으로 유지하면서 대용량 데이터를 안전하게 처리할 수 있다.

```java
// JDBC - 대용량 결과셋 처리
public List<User> getLargeDataset() {
    // 100만 개 레코드를 모두 메모리에 로드
    return userRepository.findAll(); // OutOfMemoryError 위험
}

// R2DBC - 스트리밍 처리 
public Flux<User> getLargeDataset() {
    return userRepository.findAll() // 스트리밍으로 처리
        .buffer(1000) // 배치 단위로 처리
        .flatMap(batch -> processBatch(batch));
}
```

### R2DBC가 Non-blocking을 구현할 수 있는 이유
1. **새로운 SPI (Service Provider Interface)**: JDBC API를 사용하지 않고 처음부터 반응형으로 설계
2. **이벤트 기반 아키텍처**: 스레드-연결 바인딩을 제거
3. **스트리밍 프로토콜**: 결과를 배치로 스트리밍하여 메모리 효율성 확보
4. **Reactive Streams 준수**: Backpressure를 통한 플로우 제어

R2DBC는 단순히 JDBC 위에 반응형 래퍼를 씌운 것이 아니라, **완전히 새로운 데이터베이스 접근 방식**으로 구현되었다.


## R2DBC 실전
Spring Data R2DBC는 JPA 같은 ORM 프레임워크에서 제공하는 캐싱, 지연 로딩, 그리고 다른 ORM 프레임워크가 가지고 있는 특징이 제거되어 단순하다. 그러면서도 다른 Spring Data Family 프로젝트들처럼 갖는 데이터 접근 계층의 보일러플레이트를 제거할 수 있다.

25/06/21 일자로 최신 버전은 3.5.1 버전에서 R2DBC가 지원하는 데이터베이스 종류는 다음과 같다.

- [H2](https://github.com/r2dbc/r2dbc-h2), [MariaDB](https://github.com/mariadb-corporation/mariadb-connector-r2dbc),[Microsoft SQL Server](https://github.com/r2dbc/r2dbc-mssql), [MySQL](https://github.com/asyncer-io/r2dbc-mysql), [jasync-sql MySQL](https://github.com/jasync-sql/jasync-sql), [Postgres](https://github.com/pgjdbc/r2dbc-postgresql), [Oracle](https://github.com/oracle/oracle-r2dbc)

### 1. 테이블 스키마 정의
R2DBC는 JPA처럼 엔티티에 정의된 매핑 정보로 테이블을 자동 생성해주는 기능이 없기 때문에 테이블 생성을 직접 수행해야 한다. Database 스키마 생성을 별도로 해도 좋고 애플리케이션 구동과 연동시켜도 좋다. 이 절에서는 독자들이 더 폭넓게 참고할 수 있도록 스프링이 '테이블 생성 스크립트'를 실행하도록 하는 방법을 선택한다.

스프링 애플리케이션의 `src/main/resources/db/h2` 디렉터리 위치에 schema.sql 파일을 생성한 다음 스크립트를 작성하자.

```sql
CREATE TABLE IF NOT EXISTS STUDY_PARTICIPANTS (
    sp_id BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    sp_name VARCHAR(5) NOT NULL UNIQUE, -- 스터디원 이름
    warning INT NOT NULL -- 경고 횟수
)
```

생성 스크립트가 성공적으로 작성되었다면 다음과 같이 설정을 함으로써 애플리케이션이 실행되는 시점에 테이블이 생성되도록 만들자.

```
spring:
  sql:
    init:
      schema-locations: classpath*:db/h2/schema.sql
```

### 2. 도메인 엔티티 클래스 생성
이제 데이터베이스의 `STUDY_PARTICIPANTS` 테이블에 액세스하기 위한 도메인 엔티티 클래스를 정의하자. Spring Data Family Project와 닮아있는 스펙이기 때문에 Spring Data 프로젝트 중 하나라도 사용해봤다면 익숙할 것이다.

```java
@Getter
@AllArgsConstructor
@NoArgsConstructor
public class StudyParticipant {
    @Id
    private long spId;
    private String spName;
    private int warning;

    @Builder
    private StudyParticipant(String spName, int warning) {
        this.spName = spName;
        this.warning = warning;
    }
}
```

예시의 엔티티 클래스가 어떻게 작성된 것인지 살펴보자.

- '도메인 엔티티 클래스'를 '테이블'과 매핑하기 위해서 테이블의 기본키에 해당하는 필드에 `@Id` 애너테이션을 추가해야 한다.
- `@Table` 애너테이션을 생략하면 기본적으로 클래스 이름을 테이블 이름으로 사용한다.

### 3. R2DBC Repositories를 이용한 데이터 접근 - Repository 정의
R2DBC는 여타 Spring Data Family Project와 마찬가지로 추상화된 데이터 접근 기술을 손쉽게 사용할 수 있는 Repository API를 제공한다.

```java
public interface StudyParticipantsRepository extends ReactiveCrudRepository<StudyParticipant, Long> {
    Mono<StudyParticipants> findBySpName(String spName);
    Mono<Boolean> existsBySpName(String spName);
}
```

R2DBC의 Repository API는 다른 Spring Data Project의 Repository와 다르게 리액티브 방식으로 동작하는 `ReactiveCrudRepository`를 상속한다는 것과 리턴 타입이 Mono 또는 Flux이다. 이는 여러 리액티브 스트림즈 구현체 중에 Spring이 채택한 `Reactor`의 Publisher 타입이다.

### 4. 서비스 클래스 구현
```java
@Slf4j
@RequiredArgsConstructor
@Service
public class StudyParticipantService {
    private final StudyParticipantRepository studyParticipantRepository;
    
    public Mono<StudyParticipant> save(SaveRequest saveRequest) {
        return studyParticipantRepository.existsBySpName(studyParticipant.getSpName())
                .flatMap(isExist -> {
                    if (isExist)
                        return Mono.error(new DuplicatedSpNameException("This participant name has already been saved."));
                    studyParticipantRepository.save(StudyParticipant.builder()
                            .spName(saveRequest.spName())
                            .warning(saveRequest.warning())
                            .build());
                });
    }
    
    public Mono<StudyParticipant> getBySpName(String spName) {
        return studyParticipantRepository.findBySpName(spName);
    }
}
```

'3. R2DBC Repositories를 이용한 데이터 접근 - Repository 정의' 절에서 정의한 리포지토리를 사용해 데이터베이스와 상호작용하는 서비스 로직을 살펴보자. 각 메서드 코드에 대한 설명은 다음과 같다.

- `save(SaveRequest saveRequest)`
  - 저장 요청된 `StudyParticipant` 엔티티 객체를 저장하기 전에 해당 객체의 `spName` 값이 이미 저장된 적이 있는지 확인하고 없다면 저장한다. 있다면 중복된 `spName`로 요청되었음을 명시하는 에러를 발생시킨다.
    - `repository.existsBySpName(String spName)` 메서드는 인자 `spName`과 같은 값의 spName을 갖는 레코드가 있는지 여부를 return 한다.
    - `flatMap`
      - input sequence를 받아 새로운 inner sequence를 반환하는 오퍼레이터이다.
      - `repository.existsBySpName(...)` 을 통해 같은 이름으로 등록된 참여자가 '존재하는지'를 확인하고,
        - 존재한다면
          - `Mono.error(java.lang.Throwable error)` 를 리턴한다.
            - 이 메서드는 구독 후 즉시 지정된 오류와 함께 종료되는 `Mono`를 생성한다. 동기 방식에서 `throw`로 에러를 던지는 것과 흡사하다.
        - 존재하지 않으면
          - `repository.save(StudyParticipant studyParticipant)` 를 리턴한다.
            - 이 메서드는 인자로 주어진 엔티티 객체를 데이터베이스에 저장하고, `Mono<'저장된 엔티티 객체'>`를 return 한다.
- `repository.findBySpName(String spName)`
  - 참여자 이름이 일치하는 레코드를 읽어 `Mono<'검색된 엔티티 객체'>` 객체로 return 한다.

### 5. `R2dbcEntityTemplate`을 이용한 데이터 액세스
R2DBC는 `JdbcTemplate`처럼 템플릿/콜백 패턴이 적용된 `R2dbcEntityTemplate`을 제공한다. `R2dbcEntityTemplate`는 Spring Data R2DBC의 central entrypoint(`insert()`, `select()`, `update()`) 이다. 이 기능으로 R2DBC는 데이터 쿼리, 삽입, 업데이트, 삭제와 같은 일반적인 임시 사용 사례에 대해 엔티티 중심의 직접적인 메서드와 더욱 간결하고 유연한 인터페이스를 제공한다.

`R2dbcEntityTemplate` entrypoint로 시작되는 스트림의 모든 terminal(끝에 위치하는) method는 그 다음의 작업을 처리하기에 적합한 `Publisher` 를 return 한다. 이게 무슨 말인가 하면, terminal method 중 하나인 `all()` method는 하나의 sequence가 아닌 여러 개의 sequence를 emit하는 `Flux`(`Publisher`)를 return 한다.

```java
@Slf4j
@RequiredArgsConstructor
@Service
public class StudyParticipantService {
    private final R2dbcEntityTemplate template;

    public Mono<StudyParticipant> save(SaveRequest saveRequest) {
        return existsBySpName(saveRequest.spName())
                .flatMap(exists -> {
                    if (exists) {
                        return Mono.error(new DuplicatedSpNameException("duplicated sp name"));
                    }
                    return template.insert(StudyParticipant.builder()
                            .spName(saveRequest.spName())
                            .warning(saveRequest.warning())
                            .build());
                });
    }

    private Mono<Boolean> existsBySpName(String spName) {
        return template.exists(query(where("sp_name").is(spName)), StudyParticipant.class);
    }

    public Mono<StudyParticipant> getBySpName(String spName) {
        return template.selectOne(query(where("sp_name").is(spName)), StudyParticipant.class);
    }
}
```

'4. 서비스 클래스 구현' 절의 Repository API를 이용한 Data Access 코드를 template 코드로 바꾼 예시이다. R2dbcEntityTemplate로 데이터베이스와 상호작용하는 방법을 살펴보자.

- `template.exists(Query query)`
  - 이 메서드는 쿼리의 결과가 하나 이상의 결과를 갖는지 여부를 반환하며, 인자로 `Query` 받는다.
    - `Query` 객체는 `Query.query(...)` 에 Criteria 객체를 인자로 넘겨주어 생성할 수 있다.
      - `where(...)` 메서드는 SQL에서 WHERE 절을 표현하는 Criteria 객체이다.
    - `is(...)` 메서드는 SQL에서 `=` 를 표현한다.
- `template.insert(...)`
  - 인자로 엔티티 클래스의 인스턴스를 넘겨주면 해당 엔티티 클래스에 해당하는 테이블에 레코드를 삽입한다.
- `template.selectOne(Query query)`
  - 이 메서드는 한 건의 데이터를 조회하는 데에 사용되며, 인자로 `Query` 를 받는다.


## R2DBC를 사용하면 우리 아이가 달라져요!(?)
Data source의 구현이 특이한 R2DBC를 쓰면 우리 아이(애플리케이션)가 달라지는 것을 느낄 수 있을 것이다. 왜 달라지는 걸까?

여느 애플리케이션이 그러하듯 대부분의 서버는 요청에 응답하기 위한 일련의 작업의 시작점이 data source에 있다. 그런데 data source가 Publisher 타입을 리턴하는 reactor streams 사양으로 이루어진 API를 사용하기 때문에, 이후의 대부분의 로직이 streams 형태인 declarative code로 작성되게 되어 아이가 달라지는 것이다.

여기까지 우리 아이가 변하는 이유까지 알아보는 것으로 이번 포스팅을 마무리하려 한다. 다들 달라진 우리 아이도 사랑해주길 바라며 모두가 즐거운 개발생활을 이어가길 바라겠다. 

