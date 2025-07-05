---
title : "JDBC user가 이해하기 쉬운 Spring Data R2DBC"
date : 2025-06-27 22:13:00 +09:00
categories : [R2DBC, Spring Data]
tags : []
math : true
image:
---

애플리케이션이 동작하기 위한 일련의 data interaction을 위해선 data store가 필요하다. 그리고 data store에 어떻게 interaction을 할 것인지는 애플리케이션의 전반적인 동작에 큰 영향을 준다. 이번 포스팅에선 수많은 data store 중에 "RDBMS" 카테고리에 속하는 database와 비동기적으로 상호작용하는 API 중 하나이자 Spring Data Family Project인 Spring Data R2DBC에 대해 알아볼 것이다.

이야기를 시작하기 전에 이 글이 "JDBC에 경험이 있는 사람"을 독자로 설정했음을 알린다. 이렇게 설정하는 이유는 Spring Data Project가 공통적으로 갖는 컨셉(API 스타일, 추상화 구조 등등)에 대한 내용이 방대하기 때문이다. JDBC 기반의 Spring Data 스택을 사용해본 경험이 없거나 무지하다면 그것부터 공부하는 것을 추천한다.

## R2DBC( Reactive Relational Database Connectivity )란?
**R2DBC**는 Spring Data Relational에 속하는 Reactive Relational Database Connectivity Project로 관계형 데이터베이스에 리액티브 API를 제공한다.

R2DBC가 탄생하기 전엔 몇몇 NoSQL 벤더만 비동기 방식의 API를 제공했었다. 그래서 리액티브 애플리케이션에서 관계형 데이터베이스를 사용할 경우, 완전한 Non-Blocking I/O를 구현하는 것이 불가능했다. JDBC API 자체가 Blocking API 이기 때문이다.

하지만 R2DBC는 JDBC와 완전히 다른 구현을 적용함으로써 클라이언트의 요청부터 데이터베이스 접근까지 완전한 Non-Blocking 구현이 가능케 한다.

그리고 R2DBC는 JPA 같은 ORM 프레임워크에서 제공하는 캐싱, 지연 로딩, 그리고 다른 ORM 프레임워크가 가지고 있는 특징이 제거되어 단순하다. 그러면서도 다른 Spring Data Family 프로젝트들처럼 갖는 데이터 접근 계층의 보일러플레이트를 제거할 수 있다.

25/06/21 일자로 최신 버전은 3.5.1 버전에서 R2DBC가 지원하는 데이터베이스 종류는 다음과 같다.

- [H2](https://github.com/r2dbc/r2dbc-h2), [MariaDB](https://github.com/mariadb-corporation/mariadb-connector-r2dbc),[Microsoft SQL Server](https://github.com/r2dbc/r2dbc-mssql), [MySQL](https://github.com/asyncer-io/r2dbc-mysql), [jasync-sql MySQL](https://github.com/jasync-sql/jasync-sql), [Postgres](https://github.com/pgjdbc/r2dbc-postgresql), [Oracle](https://github.com/oracle/oracle-r2dbc)

## R2DBC와 JDBC와의 차이
### 1. 아키텍처 차이
JDBC와 R2DBC의 가장 근본적인 차이는 **블로킹**과 **논블로킹** 방식의 차이에 있다.   
JDBC는 각 작업 단계에서 응답을 기다리는 동안 **스레드가 대기 상태**가 되어 시스템 **리소스를 점유**한다. 반면 R2DBC는 비동기적으로 작업을 처리하여 **스레드가 다른 작업을 처리할 수 있도록** 하며, 결과는 스트리밍 방식으로 처리된다.

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

R2DBC의 메소드의 시그니처를 보면 리턴 타입이 `Flux<User>` 라는 생소한 타입이 명시되어 있다.  
이 타입은 Reactor Project의 Publisher라는 개념이다. 이게 뭔지 잘 몰라도 R2DBC를 이해하는데 큰 문제는 없다. `Mono`는 데이터를 0개 혹은 하나 뱉어내는 물줄기, `Flux`는 데이터를 0개부터 여러 개까지 뱉어내는 물줄기라는 개념으로 이해하자.

### 2. API 레벨에서의 차이
데이터베이스와의 상호작용 방식에서도 큰 차이가 있다.   
JDBC는 동기 방식의 API로 요청을 보내고 완전한 결과를 받을 때까지 스레드가 대기하는 블로킹 방식이다. R2DBC는 Reactive Streams 기반의 비동기 API로, **백프레셔**(Backpressure)를 지원하여 클라이언트가 처리할 수 있는 속도에 맞춰 데이터를 받을 수 있다.

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

### 3. 연결 관리
연결 관리 방식도 완전히 다르다.   
JDBC는 스레드와 연결이 강하게 결합되어 하나의 스레드가 연결을 점유하고 있는 동안 다른 작업을 할 수 없다. R2DBC는 이벤트 루프 방식을 사용하여 **스레드와 연결을 분리**함으로써 적은 수의 스레드로도 많은 연결을 효율적으로 관리할 수 있다.

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

### 4. 결과 처리 방식
JDBC는 **기본적**으로 **전체 결과셋을 메모리에 로드**하는 방식이다.   
추가적으로 `fetch size`를 설정하거나 `Streaming ResultSet`(특정 벤더의 지원이 필요)을 사용해서 결과 처리 방식에 변화를 줄 순 있지만,   
전자는 여전히 `OutOfMemoryError`가 발생할 위험이 있고 후자는 동기적 처리로 인한 **스레드 블로킹** 문제가 남아있다.   
그리고 그런 방법으로 메모리 사용량을 조절하더라도 결국 그런 설정이 각 스레드마다 적용되므로, '동시 실행 스레드' 갯수에 따라 메모리 사용량은 선형적으로 증가하게 된다.

이에 반해 R2DBC는 **본질적**으로 스트리밍과 백프레셔를 지원하여 **메모리 사용량을 일정 수준으로 유지**하면서 **논블로킹** 방식으로 대용량 데이터를 처리할 수 있다.

```java
// JDBC - 기본 방식 (메모리 위험)
public List<User> getLargeDatasetBasic() {
    // 100만 개 레코드를 모두 메모리에 로드
    return userRepository.findAll(); // OutOfMemoryError 위험
}

// JDBC - 개선된 방식 (fetch size 설정)
public List<User> getLargeDatasetImproved() {
    List<User> users = new ArrayList<>();
    String sql = "SELECT * FROM users";

    try (PreparedStatement stmt = connection.prepareStatement(sql)) {
        stmt.setFetchSize(1000); // 배치 단위로 가져오기

        try (ResultSet rs = stmt.executeQuery()) {
            while (rs.next()) { // 여전히 블로킹 방식
                users.add(mapToUser(rs));
                // 스레드가 각 행 처리 동안 블로킹됨
            }
        }
    }
    return users; // 최종적으로는 모든 데이터가 메모리에 존재
}

// JDBC - Streaming ResultSet (MySQL 예시)
public void processLargeDatasetStreaming() {
    String sql = "SELECT * FROM users";

    try (PreparedStatement stmt = connection.prepareStatement(
            sql, ResultSet.TYPE_FORWARD_ONLY, ResultSet.CONCUR_READ_ONLY)) {

        stmt.setFetchSize(Integer.MIN_VALUE); // MySQL streaming

        try (ResultSet rs = stmt.executeQuery()) {
            while (rs.next()) { // 블로킹이지만 메모리 효율적
                User user = mapToUser(rs);
                processUser(user); // 즉시 처리, 메모리에 누적 안됨
                // 하지만 여전히 동기적 처리로 스레드 블로킹
            }
        }
    }
}

// R2DBC - 본질적인 스트리밍 + 논블로킹
public Flux<User> getLargeDataset() {
    return userRepository.findAll() // 논블로킹 스트리밍
            .buffer(1000) // 배치 단위로 처리
            .flatMap(batch -> processBatch(batch)) // 비동기 배치 처리
            .onBackpressureDrop(); // 백프레셔로 메모리 사용량 제어
}

// R2DBC - 더 세밀한 제어
public Flux<User> getLargeDatasetWithBackpressure() {
    return userRepository.findAll()
            .limitRate(100) // 초당 처리량 제한
            .onBackpressureBuffer(500, // 버퍼 크기 제한
                    user -> log.warn("Dropping user: {}", user.getId()),
                    BufferOverflowStrategy.DROP_OLDEST)
            .doOnNext(user -> {
                // 각 항목 처리 시에도 스레드가 블로킹되지 않음
                log.info("Processing user: {}", user.getId());
            });
}
```

### 5. 동시 요청 처리 방식
동시 요청 처리 능력에서 R2DBC의 진가가 발휘된다.   
JDBC 방식에서는 각 요청마다 **별도의 스레드가 필요**하여 많은 동시 요청이 있을 때 스레드 풀이 고갈될 수 있다. R2DBC는 **이벤트 루프 기반**으로 동작하여 소수의 스레드로도 수천 개의 동시 요청을 효율적으로 처리할 수 있다.

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

### 6. 트랜잭션
R2DBC는 구조적으로 동기 방식의 data access API 와는 다른 트랜잭션 구현이 필요하다.   
왜냐하면, R2DBC는 **이벤트 루프 방식으로 동작**하기 때문에 일련의 로직이 **같은 스레드에서 동작하는 것을 보장할 수 없**기 때문이다. 그럼 R2DBC는 어떻게 트랜잭션을 보장할 수 있을까?

Spring boot를 사용하면 `R2dbcTransactionManagerAutoConfiguration`에 의해서 `R2dbcTransactionManager`가 빈으로 자동 등록된다.
```java
public class R2dbcTransactionManager extends AbstractReactiveTransactionManager implements InitializingBean {

    @Nullable
    private ConnectionFactory connectionFactory;

    private boolean enforceReadOnly = false;

    // ...

    @Override
    protected Object doGetTransaction(TransactionSynchronizationManager synchronizationManager) {
        ConnectionFactoryTransactionObject txObject = new ConnectionFactoryTransactionObject();
        ConnectionHolder conHolder = (ConnectionHolder) synchronizationManager.getResource(obtainConnectionFactory());
        txObject.setConnectionHolder(conHolder, false);
        return txObject;
    }

    // ...
}
```

`R2dbcTransactionManager` class는 아래와 같은 상속 관계를 갖고 있다.

```java
public interface TransactionManage {}

public interface ReactiveTransactionManager implements TransactionManager ... {}

public class AbstractReactiveTransactionManager implements ReactiveTransactionManager ... {}

public class R2dbcTransactionManager implements AbstractReactiveTransactionManager ... {}
```

이 관계 구조에서 "어떻게 트랜잭션을 유지할까?" 에 대한 정보를 얻을 수 있는 곳은 `AbstractReactiveTransactionManager`이다.   
트랜잭션이 시작될 때 `AbstractReactiveTransactionManager.getReactiveTransaction(...)` 메소드가 호출된다. 

```java 
@Override
public final Mono<ReactiveTransaction> getReactiveTransaction(@Nullable TransactionDefinition definition) {
    // Use defaults if no transaction definition given.
    TransactionDefinition def = (definition != null ? definition : TransactionDefinition.withDefaults()); // 1번

    return TransactionSynchronizationManager.forCurrentTransaction().flatMap(synchronizationManager -> { // 2번

        Object transaction = doGetTransaction(synchronizationManager);

        // Cache debug flag to avoid repeated checks.
        boolean debugEnabled = logger.isDebugEnabled();

        if (isExistingTransaction(transaction)) {
            // Existing transaction found -> check propagation behavior to find out how to behave.
            return handleExistingTransaction(synchronizationManager, def, transaction, debugEnabled);
        }

        // Check definition settings for new transaction.
        if (def.getTimeout() < TransactionDefinition.TIMEOUT_DEFAULT) {
            return Mono.error(new InvalidTimeoutException("Invalid transaction timeout", def.getTimeout()));
        }
        
        // ...

    };
}
```

- `// 1번` 라인: Transaction propagation 정보를 가져온다.
- `// 2번` 라인: `TransactionSynchronizationManager` 에게서 현재 트랜잭션을 가져온다.

이제 `TransactionSynchronizationManager`가 어떻게 트랜잭션을 가져오는지 확인해보자.

```java
/**
 * Get the {@link TransactionSynchronizationManager} that is associated with
 * the current transaction context.
 * <p>Mainly intended for code that wants to bind resources or synchronizations.
 * @throws NoTransactionException if the transaction info cannot be found &mdash;
 * for example, because the method was invoked outside a managed transaction
 */
public static Mono<TransactionSynchronizationManager> forCurrentTransaction() {
    return TransactionContextManager.currentContext().map(TransactionSynchronizationManager::new);
}
```

`TransactionSynchronizationManager.forCurrentTransaction()` 메소드는 `TransactionContextManager.currentContext()`를 호출하고, 새로운 `TransactionSynchronizationManager`를 만들어서 반환한다.


```java
/**
 * Obtain the current {@link TransactionContext} from the subscriber context or the
 * transactional context holder. Context retrieval fails with NoTransactionException
 * if no context or context holder is registered.
 * @return the current {@link TransactionContext}
 * @throws NoTransactionException if no TransactionContext was found in the
 * subscriber context or no context found in a holder
 */
public static Mono<TransactionContext> currentContext() {
    return Mono.deferContextual(ctx -> {
        if (ctx.hasKey(TransactionContext.class)) { // 1번
            return Mono.just(ctx.get(TransactionContext.class));
        }
        if (ctx.hasKey(TransactionContextHolder.class)) {
            TransactionContextHolder holder = ctx.get(TransactionContextHolder.class);
            if (holder.hasContext()) {
                return Mono.just(holder.currentContext());
            }
        }
        return Mono.error(new NoTransactionInContextException());
    });
}
```

`TransactionContextManager.currentContext()` 메소드를 보면, `Mono.deferContextual(...)` 메소드를 통해 cold start 방식으로 현재 context를 가져오고 `TransactionContext`를 함께 생성해주는걸 알 수 있다.

이때, `// 1번` 라인의 코드에서 `TransactionContext`가 Reactor Context에 포함되어있는지 확인하고, 없다면 `TransactionContextHolder`가 있는지 확인한다. 만약, 둘 다 없다면 `NoTransactionInContextExcepion`을 던진다.

여기까지 봤을때, R2DBC가 트랜잭션을 thread-safe 하게 유지하기 위해 Project Reactor의 Context를 사용한다고 유추할 수 있다.

하지만, 지금까지는 재사용 하거나 이미 있는 트랜잭션을 받아오는 과정이었다. 그럼 실제로 새로운 트랜잭션을 생성되는 과정은 어떻게 구현되어 있을까?

그 답은 Aspect 진입시점인 `TransactionAspectSupport.ReactiveTransactionSupport` class 에서 찾을 수 있었다.

```java
public Object invokeWithinTransaction(Method method, @Nullable Class<?> targetClass, 
          InvocationCallback invocation, @Nullable TransactionAttribute txAttr, ReactiveTransactionManager rtm) {

    String joinpointIdentification = methodIdentification(method, targetClass, txAttr);

    // For Mono and suspending functions not returning kotlinx.coroutines.flow.Flow
    if (Mono.class.isAssignableFrom(method.getReturnType()) || (KotlinDetector.isSuspendingFunction(method) &&
            !COROUTINES_FLOW_CLASS_NAME.equals(new MethodParameter(method, -1).getParameterType().getName()))) {

        return TransactionContextManager.currentContext().flatMap(context ->
                        Mono.<Object, ReactiveTransactionInfo>usingWhen(
                                        createTransactionIfNecessary(rtm, txAttr, joinpointIdentification),
                                        tx -> {
                                            try {
                                                return (Mono<?>) invocation.proceedWithInvocation();
                                            } catch (Throwable ex) {
                                                return Mono.error(ex);
                                            }
                                        },
                                        this::commitTransactionAfterReturning,
                                        this::completeTransactionAfterThrowing,
                                        this::rollbackTransactionOnCancel)
                                .onErrorMap(this::unwrapIfResourceCleanupFailure))
                .contextWrite(TransactionContextManager.getOrCreateContext())
                .contextWrite(TransactionContextManager.getOrCreateContextHolder());
    }
}
```

위 코드는 `Mono`를 반환하는 로직이다. 

트랜잭션이 없다면 생성하고, `.contextWrite`를 통해서 Reactor Context에 커넥션을 등록하는걸 확인할 수 있다.

> 실제 코드를 확인해보면 위의 코드 바로 아래에 `Flux`에 대한 구현을 확인할 수 있다.

## R2DBC API 살펴보기
지금까지 동기 방식의 JDBC 와 다르게 R2DBC 가 갖는 차이점이 무엇인지 살펴보았다. 이제는 어떻게 R2DBC를 사용할 수 있는지 'API 사용 예시 코드'를 살펴보자. R2DBC는 Spring Data Project에 속하는 만큼 익숙한 API 스펙을 제공한다. 

먼저 API 예시 코드에서 사용할 도메인 엔티티 클래스를 살펴보는 것부터 시작하자.

### 1. 도메인 엔티티 클래스
R2DBC API 스펙을 살펴보는 데에 사용할 도메인 엔티티 클래스로 `StudyParticipant`를 사용할 것이다. 아래의 클래스를 참고하자.

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

### 2. Repository 정의
R2DBC는 다른 Spring Data Family Project와 마찬가지로 추상화된 데이터 접근 기술을 손쉽게 사용할 수 있는 Repository API를 제공한다.

```java
public interface StudyParticipantsRepository extends ReactiveCrudRepository<StudyParticipant, Long> {
    Mono<StudyParticipants> findBySpName(String spName);
    Mono<Boolean> existsBySpName(String spName);
}
```

위의 코드에서 JDBC 기반의 Repository와는 다른 인터페이스를 상속하는 것을 볼 수 있다. R2DBC의 Repository API는 보통 리액티브 방식으로 동작하는 `ReactiveCrudRepository`를 상속한다.  
그리고 리턴 타입이 `Mono` 또는 `Flux` 인 점도 다르다. 

### 3. 서비스 클래스 구현
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

'2. Repository 정의' 절에서 정의한 리포지토리를 사용해 데이터베이스와 상호작용하는 서비스 로직을 살펴보자. 각 메서드 코드에 대한 설명은 다음과 같다.

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

### 4. `R2dbcEntityTemplate`을 이용한 데이터 액세스
R2DBC는 `JdbcTemplate`처럼 템플릿/콜백 패턴이 적용된 `R2dbcEntityTemplate`을 제공한다. `R2dbcEntityTemplate`는 Spring Data R2DBC의 central entrypoint(`insert()`, `select()`, `update()`) 이다. 이 entrypoint로 R2DBC는 데이터 쿼리, 삽입, 업데이트, 삭제와 같은 일반적인 사용 사례에 대해 엔티티 중심의 직접적인 메서드와 더욱 간결하고 유연한 인터페이스를 제공한다.

`R2dbcEntityTemplate` entrypoint로 시작되는 스트림의 모든 terminal(끝에 위치하는) method는 그 다음의 작업을 처리하기에 적합한 Publisher를 return 한다. Terminal method 중 하나인 `all()` method는 하나의 sequence가 아닌 여러 개의 sequence를 emit하는 `Flux`(`Publisher`)를 return 한다.

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

'3. 서비스 클래스 구현' 절의 Repository API를 이용한 Data Access 코드를 template 코드로 바꾼 예시이다. R2dbcEntityTemplate로 데이터베이스와 상호작용하는 방법을 살펴보자.

- `template.exists(Query query)`
    - 이 메서드는 쿼리의 결과가 하나 이상의 결과를 갖는지 여부를 반환하며, 인자로 `Query` 받는다.
        - `Query` 객체는 `Query.query(...)` 에 Criteria 객체를 인자로 넘겨주어 생성할 수 있다.
            - `where(...)` 메서드는 SQL에서 WHERE 절을 표현하는 Criteria 객체이다.
        - `is(...)` 메서드는 SQL에서 `=` 를 표현한다.
- `template.insert(...)`
    - 인자로 엔티티 클래스의 인스턴스를 넘겨주면 해당 엔티티 클래스에 해당하는 테이블에 레코드를 삽입한다.
- `template.selectOne(Query query)`
    - 이 메서드는 한 건의 데이터를 조회하는 데에 사용되며, 인자로 `Query` 를 받는다.

## 정리
R2DBC가 이벤트 루프 구조를 갖는 것이나 Reactive Streams 사양으로 구축되었다는 것에는 비동기 애플리케이션에 관련된 Spring의 생태계가 있다. 더 세부적으로 그러한 것들을 이해하기 위해서는 Project Reactor와 Spring Webflux에 대해 더 공부하면 좋다.

서버 자원을 더 효율적으로 사용할 수 있다는 매력이 있지만, 동기 방식과 비동기 방식 간에는 트레이드오프가 존재한다. 몇가지 살펴보면 아래와 같다.
1. 비동기 및 논블로킹 처리를 위한 리액티브 프로그래밍 패러다임은 동기 방식과는 다른 새로운 개념과 API를 기반으로 하므로 **학습 곡선이 높다**.
2. 코드 실행 흐름이 어디로 튈 줄 모르기 때문에 **디버깅이 어렵다**.
3. I/O bound 작업에 최적화되어 있어 CPU bound 작업이 많다면 **오히려 성능이 떨어질 수 있다**.
4. 일부 APM(Application Performance Monitoring) 툴은 WebFlux와 호환되지 않을 수 있다.

그럼에도 공부해보면 좋은 프로젝트라고 생각한다. 그리고 개발해보다 보면 I/O bound 작업이 큰 비중을 차지하는 애플리케이션이 적잖게 있다는 것을 알 수 있어 매력적인 선택지이기도 하다. 그렇다고 필요하지 않은데 공부하는 것을 권하고 싶진 않다. 많은 학습 비용이 들기 때문에 잘 판단해서 써보는걸 권장한다.   
현재 프로젝트가 WebFlux를 쓰는게 훨씬 좋을게 분명한게 아니라면, 그리고 WebMVC로도 충분히 버터낼 것 같다면 굳이 선택하지 않는 게 더 좋은 선택이라 생각한다.

## Reference
- [Reactive Transactions with Spring](https://spring.io/blog/2019/05/16/reactive-transactions-with-spring)
- [How to maintain Transaction in Spring data R2DBC](https://medium.com/@develxb/spring-data-r2dbc-%EC%BB%A4%EB%84%A5%EC%85%98-%EC%9C%A0%EC%A7%80-%EB%B0%A9%EB%B2%95-fb1bc8d83a4f)
- [스프링으로 시작하는 리액티브 프로그래밍](https://product.kyobobook.co.kr/detail/S000201399476)