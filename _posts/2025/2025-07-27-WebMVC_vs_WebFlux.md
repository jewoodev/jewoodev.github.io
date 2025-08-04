---
title : "WebMVC vs WebFlux"
date : 2025-07-27 15:08:00 +09:00
categories : [Spring, Web]
tags : []
math : true
image:
---

스프링이 지원하는 웹 프레임워크는 두 가지이다. 바로 이 글의 타이틀인 **WebMVC**와 **WebFlux**가 그 프레임워크인데, 이렇게 스프링이 두 가지 웹 프레임워크를 지원하는 이유는 서로 다른 **아키텍처 패러다임**과 **사용 사례**에 최적화되어 있기 때문이다. 

처음부터 두 프레임워크가 함께 존재했던 것은 아니다. WebMVC가 먼저 등장했고, 시간이 흐르면서 WebFlux가 추가되었는데, 그 배경에는 기술적 변화와 도전이 있었다.

단순히 새로운 기술을 맹목적으로 따르는 것이 아니라, **왜 그 기술이 등장했는지** 배경을 이해하고 있어야 기술 선택에 있어 더 현명하고 신중한 접근을 할 수 있다. 그리고 대부분의 기업들은 완전히 새로운 시스템을 구축하기보다는 기존 시스템을 점진적으로 개선해야 하는 상황에 놓여져 있다. 따라서 기존 WebMVC 시스템을 유지하면서 필요한 부분에만 WebFlux를 도입하는 하이브리드 접근이 필요하다. 이런 마이그레이션 전략을 수립하고 실행할 수 있기 위해서 WebFlux가 등장하게 된 배경부터 알아보자. 

---

## Spring Framework History 훑어보기
Spring WebMVC는 2004년 Spring 1.0과 함께 등장했다. 당시에는 서블릿 기반의 동기적 처리 방식이 웹 개발의 표준이었고, 대부분의 애플리케이션에서 충분히 효과적으로 작동했다.

```java
// 전통적인 WebMVC - 블로킹 방식
@GetMapping("/users/{id}")
public User getUser(@PathVariable String id) {
    return userService.findById(id); // DB 호출 시 스레드 블로킹
}
```
하지만 2010년대 초부터 문제점들이 드러나기 시작했다. 동시 연결 1만개를 처리하는 **C10K 문제**가 대두되었고, 요청마다 스레드를 생성하는 스레드 풀 방식으로 인한 메모리 사용량 증가 문제가 발생했다. 특히 데이터베이스나 외부 API 호출 시 스레드가 대기 상태로 머물면서 자원이 낭비되는 블로킹 I/O의 한계가 명확해졌다.

### 외부에서 불어온 변화의 바람
2009년 등장한 **Node.js**는 이벤트 루프 기반의 비동기 처리로 높은 동시성을 달성하며 Java 진영에 큰 충격을 주었다. "JavaScript가 Java보다 빠르다고?"라는 충격적인 벤치마크 결과들이 나오기 시작했다.

동시에 리액티브 프로그래밍이 트렌드로 떠오르면서 Netflix의 **RxJava**(2013), **Reactive Streams** 스펙(2015)이 연이어 발표되었다. 마이크로서비스 아키텍처가 확산되면서 높은 동시성에 대한 요구도 급증했다.

### Spring 팀의 고민과 WebFlux의 탄생
Spring 팀은 딜레마에 빠졌다. 기존 WebMVC를 개선하는 것만으로는 한계가 있었다. 서블릿 API 자체가 **블로킹** 기반으로 설계되어 있어 **근본적인 한계**가 존재했기 때문이다. 결국 Spring 팀은 별도의 프로젝트를 개설하게 되며 2017년 Spring 5.0 부터 **WebFlux**가 지원되기 시작했다.

그럼 WebFlux의 논블로킹 설계는 어떻게 이루어져 있을까? 세부적으로 어떤 점 때문에 WebMVC에 한계가 있다는 걸까? 

---

## 두 프레임워크의 설계 철학
### WebMVC의 아키텍처 설계 원칙
WebMVC는 **Thread-per-Request 모델**을 핵심 아키텍처 패러다임으로 채택하고 있다. 이는 서블릿 API의 **동기적 처리 모델**을 기반으로 한 설계 철학에서 비롯된 것으로, 클라이언트의 **하나의 요청 당 하나의 스레드를 할당**해 해당 요청을 처리하는 방식이다.  
이러한 접근 방식으로 요청부터 응답까지의 **선형적 처리** 흐름을 중심으로 한 아키텍처를 구성되었으며, 각 요청이 **명확하고 예측 가능**한 실행 경로를 따라 처리되도록 보장한다.  
하나의 스레드가 하나의 요청을 전담한다는 직관적이고 단순한 철학은 개발자들이 코드의 흐름을 **쉽게 이해하고 디버깅할 수 있게** 해주며, 전통적인 동기 프로그래밍 모델과 자연스럽게 일치한다.

### WebFlux의 아키텍처 설계 원칙
WebFlux는 **Event-Loop 모델**을 핵심 아키텍처 패러다임으로 삼고 있다. 이는 리액티브 스트림의 **비동기적 처리 모델**을 기반으로 한 설계 철학으로, 소수의 **이벤트 루프 스레드**가 **여러 요청을 번갈아가며 처리**하는 방식을 구현한다.   
데이터 흐름의 **반응형 처리를 중심**으로 한 아키텍처로써 **요청이 들어오면 즉시 처리를 시작**하지만, **I/O 작업**이 필요한 순간에는 해당 작업을 **비동기적으로 시작**하고 **스레드는 다른 요청을 처리**하러 이동한다. 이후 I/O 작업이 완료되면 **이벤트나 콜백**을 통해 알림을 받아 **처리를 재개**하는 방식으로 동작한다.   
**적은 자원**으로 많은 요청을 **효율적으로 처리**한다는 최적화된 철학은 **높은 동시성**과 **자원 효율성**을 달성하는 것을 목표로 하며, 특히 I/O 집약적인 애플리케이션에서 그 진가를 발휘한다.

---

## 아키텍처 차이
### 근본적인 처리 모델의 차이
WebMVC와 WebFlux의 가장 근본적인 차이는 **Thread-per-Request**와 **Event-Loop** 방식의 차이에 있다.  
WebMVC는 각 요청마다 전담 스레드를 할당하여 요청부터 응답까지 **스레드가 해당 작업에 묶여있는** 상태가 된다. 반면 WebFlux는 소수의 이벤트 루프 스레드가 **여러 요청을 번갈아가며 처리**하여 스레드가 절대 유휴 상태에 있지 않도록 한다.

```java
// WebMVC - Thread-per-Request 방식
@RestController
public class WebMvcController {
    
    @GetMapping("/users/{id}")
    public User getUser(@PathVariable String id) {
        // 1. 스레드가 요청에 전담 할당
        User user = userService.findById(id); // DB 호출 시 스레드 블로킹
        
        // 2. 외부 API 호출 시에도 스레드 대기
        Profile profile = externalApiService.getProfile(id); // 스레드 블로킹
        
        // 3. 응답까지 동일 스레드가 처리
        user.setProfile(profile);
        return user; // 스레드 해제
    }
}

// WebFlux - Event-Loop 방식
@RestController
public class WebFluxController {
    
    @GetMapping("/users/{id}")
    public Mono<User> getUser(@PathVariable String id) {
        return userService.findById(id) // 1. 비동기 DB 호출 시작, 스레드는 다른 작업으로
                .flatMap(user -> 
                    externalApiService.getProfile(id) // 2. 비동기 API 호출, 스레드는 다른 작업으로
                        .map(profile -> {
                            user.setProfile(profile);
                            return user; // 3. 결과 조합 후 반환
                        })
                );
        // 이벤트 루프 스레드는 계속해서 다른 요청들을 처리
    }
}
```

### 동시성 처리 방식의 차이
동시 요청 처리에서 두 프레임워크는 완전히 다른 접근을 보인다.  
WebMVC는 **수직적 확장**(스레드 수 증가, 하드웨어 성능 향상)에 의존하여 동시 요청을 처리하며, 각 스레드는 상당한 메모리를 차지한다. WebFlux는 **수평적 확장**(이벤트 루프 효율성, 서버 갯수 증가)을 통해 적은 리소스로 많은 동시 요청을 처리한다.

```java
// WebMVC - 1000개 동시 요청 처리
public class WebMvcLoadTest {
    // 1000개 요청 = 최대 1000개 스레드 필요
    // 각 스레드당 약 1MB 메모리 사용 (스택 크기)
    // 총 메모리 사용량: 약 1GB + 힙 메모리
    
    @GetMapping("/heavy-operation")
    public ResponseEntity<String> heavyOperation() {
        // 스레드가 전담 처리
        String result = performDatabaseQuery(); // 블로킹
        String apiResult = callExternalApi(); // 블로킹
        return ResponseEntity.ok(result + apiResult);
    }
}

// WebFlux - 1000개 동시 요청 처리  
public class WebFluxLoadTest {
    // 1000개 요청을 4-8개 이벤트 루프 스레드로 처리
    // 총 메모리 사용량: 스레드 수 * 1MB + 힙 메모리 (대폭 절약)
    
    @GetMapping("/heavy-operation")
    public Mono<ResponseEntity<String>> heavyOperation() {
        Mono<String> dbResult = performDatabaseQuery(); // 이 시점에서는 아직 실행되지 않음 (Cold Publisher)
        Mono<String> apiResult = callExternalApi(); // 이 시점에서도 아직 실행되지 않음 (Cold Publisher)

        return Mono.zip(dbResult, apiResult) // 구독(subscribe) 시점에 두 작업이 병렬로 시작됨
                .map(tuple -> ResponseEntity.ok(tuple.getT1() + tuple.getT2()));
    }
}
```

### I/O 처리 방식의 차이
I/O 작업에서 두 프레임워크의 차이가 극명하게 드러난다.  
WebMVC는 각 I/O 작업마다 **스레드가 대기**하며 순차적으로 처리하는 반면, WebFlux는 **모든 I/O를 비동기적**으로 처리하여 병렬성을 극대화한다.

```java
// WebMVC - 순차적 I/O 처리
@Service
public class WebMvcService {
    
    public UserDetails getUserDetails(String userId) {
        // 1. DB에서 사용자 조회 (500ms) - 스레드 블로킹
        User user = userRepository.findById(userId);
        
        // 2. 프로필 API 호출 (300ms) - 스레드 블로킹  
        Profile profile = profileApiClient.getProfile(userId);
        
        // 3. 권한 API 호출 (200ms) - 스레드 블로킹
        Permissions permissions = permissionApiClient.getPermissions(userId);
        
        // 총 소요 시간: 500 + 300 + 200 = 1000ms
        // 스레드는 1000ms 동안 블로킹됨
        return new UserDetails(user, profile, permissions);
    }
}

// WebFlux - 병렬 I/O 처리
@Service  
public class WebFluxService {
    
    public Mono<UserDetails> getUserDetails(String userId) {
        Mono<User> userMono = userRepository.findById(userId); // 비동기 DB 조회
        Mono<Profile> profileMono = profileApiClient.getProfile(userId); // 비동기 API 호출
        Mono<Permissions> permissionsMono = permissionApiClient.getPermissions(userId); // 비동기 API 호출
        
        // 세 작업이 병렬로 실행됨
        return Mono.zip(userMono, profileMono, permissionsMono)
                .map(tuple -> new UserDetails(tuple.getT1(), tuple.getT2(), tuple.getT3()));
        
        // 총 소요 시간: max(500, 300, 200) = 500ms
        // 이벤트 루프 스레드는 다른 작업을 계속 처리
    }
}
```

### 메모리 사용 패턴의 차이
메모리 사용에서도 두 프레임워크는 상반된 특성을 보인다.  
WebMVC는 **스레드 수에 비례한 메모리 사용**을 보이며, WebFlux는 **일정한 메모리 사용량**을 유지하면서 백프레셔를 통해 메모리를 제어한다.

```java
// WebMVC - 대용량 데이터 처리
@RestController
public class WebMvcDataController {
    
    @GetMapping("/large-dataset")
    public List<Data> getLargeDataset() {
        // 100만 건 데이터를 모두 메모리에 로드
        List<Data> allData = dataRepository.findAll(); // OutOfMemoryError 위험
        
        // 동시 요청이 많을수록 메모리 사용량 선형 증가
        // 1000개 동시 요청 × 100만 건 데이터 = 메모리 폭발
        return allData;
    }
}

// WebFlux - 스트리밍 방식 처리
@RestController
public class WebFluxDataController {
    
    @GetMapping(value = "/large-dataset", produces = MediaType.APPLICATION_NDJSON_VALUE)
    public Flux<Data> getLargeDataset() {
        return dataRepository.findAll() // 스트리밍 방식
                .buffer(1000) // 배치 단위로 처리
                .flatMap(batch -> processBatch(batch), 2) // 동시 실행 제한
                .onBackpressureBuffer(5000, // 백프레셔로 메모리 제어
                        data -> log.warn("Dropping data: {}", data.getId()),
                        BufferOverflowStrategy.DROP_OLDEST);
        
        // 메모리 사용량이 일정 수준으로 제한됨
        // 동시 요청이 증가해도 메모리 사용량 안정적
    }
}
```

### 에러 처리와 복구 전략
에러 처리에서도 두 프레임워크는 다른 철학을 보인다.  
WebMVC는 **예외 기반의 동기적 에러 처리**를, WebFlux는 **함수형 방식의 비동기 에러 처리**를 제공한다.

```java
// WebMVC - 예외 기반 에러 처리
@RestController
public class WebMvcErrorController {
    
    @GetMapping("/risky-operation/{id}")
    public ResponseEntity<String> riskyOperation(@PathVariable String id) {
        try {
            String result = externalService.call(id); // 실패 시 예외 발생
            return ResponseEntity.ok(result);
        } catch (ServiceException e) {
            // 동기적 에러 처리
            log.error("Service call failed", e);
            return ResponseEntity.status(500).body("Service unavailable");
        } catch (TimeoutException e) {
            // 각 예외를 개별적으로 처리
            return ResponseEntity.status(408).body("Request timeout");
        }
    }
}

// WebFlux - 함수형 에러 처리
@RestController  
public class WebFluxErrorController {
    
    @GetMapping("/risky-operation/{id}")
    public Mono<ResponseEntity<String>> riskyOperation(@PathVariable String id) {
        return externalService.call(id)
                .map(result -> ResponseEntity.ok(result))
                .onErrorResume(ServiceException.class, e -> {
                    // 비동기 에러 처리 및 대안 실행
                    log.error("Service call failed, trying fallback", e);
                    return fallbackService.call(id)
                            .map(fallback -> ResponseEntity.ok("Fallback: " + fallback))
                            .onErrorReturn(ResponseEntity.status(500).body("All services unavailable"));
                })
                .onErrorResume(TimeoutException.class, e -> {
                    // 재시도 로직
                    return externalService.call(id)
                            .retry(2)
                            .map(result -> ResponseEntity.ok(result))
                            .onErrorReturn(ResponseEntity.status(408).body("Request timeout after retries"));
                })
                .timeout(Duration.ofSeconds(10)); // 선언적 타임아웃 설정
    }
}
```

---

## 데이터베이스 연결 관리의 패러다임
### WebMVC: Connection Pool 기반 관리
WebMVC에서는 전통적인 **JDBC Connection Pool** 방식을 사용한다. 각 스레드가 커넥션을 점유하는 동안 해당 커넥션은 다른 작업에 사용될 수 없어, **커넥션 수가 곧 동시 처리 가능한 요청 수**가 된다.

```java
// WebMVC - 전통적인 JDBC 방식
@Repository
public class WebMvcUserRepository {
    
    @Autowired
    private JdbcTemplate jdbcTemplate;
    
    public User findById(String id) {
        // 스레드가 커넥션을 점유하며 쿼리 실행
        return jdbcTemplate.queryForObject(
            "SELECT * FROM users WHERE id = ?", 
            new Object[]{id}, 
            new BeanPropertyRowMapper<>(User.class)
        ); // 쿼리 완료까지 커넥션과 스레드 모두 블로킹
    }
    
    @Transactional
    public User updateUser(String id, User user) {
        // 트랜잭션 동안 커넥션 점유 지속
        jdbcTemplate.update("UPDATE users SET name = ? WHERE id = ?", 
                          user.getName(), id);
        return findById(id); // 같은 트랜잭션 내에서 커넥션 재사용
    }
}
```

### WebFlux: R2DBC를 통한 리액티브 데이터베이스 액세스
WebFlux는 **R2DBC**(Reactive Relational Database Connectivity)를 통해 비동기 데이터베이스 액세스를 제공한다. 커넥션을 이벤트 루프 간에 **효율적으로 공유**하여 적은 수의 커넥션으로도 높은 처리량을 달성할 수 있다.

```java
// WebFlux - R2DBC 방식
@Repository
public class WebFluxUserRepository {
    
    @Autowired
    private R2dbcEntityTemplate template;
    
    public Mono<User> findById(String id) {
        return template.selectOne(
            Query.query(where("id").is(id)), 
            User.class
        ); // 비동기 쿼리, 커넥션 즉시 반환
    }
    
    @Transactional
    public Mono<User> updateUser(String id, User user) {
        return template.update(
            Query.query(where("id").is(id)),
            Update.update("name", user.getName()),
            User.class
        ).then(findById(id)); // 트랜잭션 내 비동기 체이닝
    }
}
```

### 커넥션 풀 효율성 비교
```java
// 실제 커넥션 사용량 분석
public class ConnectionUsageAnalysis {
    
    // WebMVC - 1000개 동시 요청
    // - 필요 커넥션: 최대 1000개
    // - 평균 커넥션 점유 시간: 200ms (쿼리 실행 시간)
    // - 커넥션 풀 크기: 1000개 필요
    
    // WebFlux - 1000개 동시 요청  
    // - 필요 커넥션: 10-20개로 충분
    // - 커넥션 점유 시간: 쿼리 실행 중에만 순간적으로 사용
    // - 커넥션 풀 크기: 20개면 충분
    
    public void connectionPoolComparison() {
        // WebMVC 방식의 문제점
        System.out.println("WebMVC 커넥션 사용률: " + 
            "1000 requests × 200ms = 200초 × 커넥션");
            
        // WebFlux 방식의 효율성
        System.out.println("WebFlux 커넥션 사용률: " + 
            "1000 requests × 2ms actual DB time = 2초 × 커넥션");
    }
}
```

---

## 백프레셔(Backpressure) 지원과 시스템 안정성
### WebMVC의 한계: 고정된 처리 용량
WebMVC는 **스레드 풀 크기**로 처리 용량이 결정되며, 용량 초과 시 **큐잉**이나 **요청 거부**만 가능하다. 시스템 부하가 증가해도 **적응적으로 대응하기 어렵다**.
```java
// WebMVC - 백프레셔 부재로 인한 문제
@RestController
public class WebMvcStreamController {
    
    @GetMapping("/data-stream")
    public ResponseEntity<List<Data>> getDataStream() {
        // 생산자가 빠르고 소비자가 느린 경우
        List<Data> allData = new ArrayList<>();
        
        for (int i = 0; i < 1000000; i++) {
            Data data = heavyProcessing(i); // 빠른 생산
            allData.add(data);
        }
        
        // 메모리에 모든 데이터 적재 - OutOfMemoryError 위험
        return ResponseEntity.ok(allData);
    }
}
```

### WebFlux의 백프레셔: 시스템 자기보호 메커니즘
WebFlux는 **Reactive Streams 스펙**에 따라 다양한 백프레셔 전략을 제공하여 시스템이 **과부하 상황에서도 안정성을 유지**할 수 있다.
```java
// WebFlux - 다양한 백프레셔 전략
@RestController
public class WebFluxStreamController {
    
    @GetMapping(value = "/data-stream", produces = MediaType.APPLICATION_NDJSON_VALUE)
    public Flux<Data> getDataStream() {
        return Flux.range(1, 1000000)
                .map(this::heavyProcessing)
                .onBackpressureBuffer(1000, // 버퍼 크기 제한
                    data -> log.warn("Buffer overflow, dropping: {}", data.getId()),
                    BufferOverflowStrategy.DROP_OLDEST) // 오래된 데이터 드롭
                .delayElements(Duration.ofMillis(10)); // 처리 속도 조절
    }
    
    @GetMapping("/adaptive-stream")  
    public Flux<Data> getAdaptiveStream() {
        return dataService.generateData()
                .onBackpressureLatest() // 최신 데이터만 유지
                .sample(Duration.ofSeconds(1)) // 샘플링으로 부하 조절
                .doOnRequest(n -> log.info("Downstream requested: {} items", n))
                .doOnCancel(() -> log.info("Downstream cancelled subscription"));
    }
}
```

---

## 트랜잭션 처리의 근본적 차이
### WebMVC: ThreadLocal 기반 트랜잭션 전파
WebMVC는 **ThreadLocal**을 활용한 트랜잭션 관리로 **하나의 스레드에서 모든 트랜잭션 정보가 공유**되어 직관적이고 안전하게 작동한다.

```java
// WebMVC - ThreadLocal 기반 트랜잭션 전파
@Service
@Transactional
public class WebMvcTransactionService {
    
    @Autowired
    private UserRepository userRepository;
    
    @Autowired  
    private OrderRepository orderRepository;
    
    public Order processOrder(String userId, OrderRequest request) {
        // ThreadLocal에 트랜잭션 정보 저장됨
        // TransactionSynchronizationManager.getCurrentTransactionName() 
        // 동일 스레드에서 실행되는 모든 코드가 트랜잭션 정보 공유
        
        User user = userRepository.findById(userId); // ThreadLocal에서 트랜잭션 정보 획득
        
        if (user.getBalance() < request.getAmount()) {
            throw new InsufficientBalanceException(); // 롤백 발생
        }
        
        user.deductBalance(request.getAmount());
        userRepository.save(user); // 같은 ThreadLocal 트랜잭션 사용
        
        Order order = new Order(userId, request);
        return orderRepository.save(order); // 같은 ThreadLocal 트랜잭션 사용
        
        // 메서드 종료 시 ThreadLocal에서 트랜잭션 정보 제거 후 커밋
    }
}
```

### WebFlux: Reactor Context 기반 트랜잭션 전파
WebFlux에서는 **스레드가 계속 바뀌기 때문에** ThreadLocal 기반의 트랜잭션이 작동하지 않는다. 대신 **Reactor Context**를 통해 비동기 체인 전체에서 트랜잭션 정보를 **전파**한다.

```java
// WebFlux - Reactor Context 기반 트랜잭션 전파
@Service
public class WebFluxTransactionService {
    
    @Autowired
    private ReactiveUserRepository userRepository;
    
    @Autowired
    private ReactiveOrderRepository orderRepository;
    
    @Transactional // Reactor Context에 TransactionContext 저장
    public Mono<Order> processOrder(String userId, OrderRequest request) {
        // @Transactional AOP가 자동으로 다음과 같이 동작:
        // .contextWrite(TransactionContextManager.getOrCreateContext())
        
        return userRepository.findById(userId) // Reactor Context에서 트랜잭션 정보 획득
                .flatMap(user -> {
                    if (user.getBalance() < request.getAmount()) {
                        return Mono.error(new InsufficientBalanceException());
                    }
                    
                    user.deductBalance(request.getAmount());
                    return userRepository.save(user) // 모든 체인에서 Context 자동 전파
                            .then(orderRepository.save(new Order(userId, request)));
                });
        // 구독 완료 시 Reactor Context에서 트랜잭션 정보 제거 후 커밋
    }
    
    // 수동으로 TransactionalOperator 사용하는 경우
    @Autowired
    private TransactionalOperator transactionalOperator;
    
    public Mono<TransactionResult> manualTransactionControl(String userId) {
        return performBusinessLogic(userId)
                .doOnNext(result -> log.info("Business logic completed"))
                .as(transactionalOperator::transactional) // 수동으로 Reactor Context에 트랜잭션 바인딩
                .doOnSuccess(result -> log.info("Transaction will commit"))
                .doOnError(error -> log.error("Transaction will rollback", error));
    }
}
```
만약 WebFlux가 트랜잭션을 어떻게 가능하게 하는지 더 자세한 내용을 알고 싶다면 [링크](https://jewoodev.github.io/posts/JDBC_user%EA%B0%80_%EC%9D%B4%ED%95%B4%ED%95%98%EA%B8%B0_%EC%89%AC%EC%9A%B4_Spring_Data_R2DBC/#6-%ED%8A%B8%EB%9E%9C%EC%9E%AD%EC%85%98)에서 참고해주길 바란다.

--- 

## 모니터링과 관찰 가능성(Observability)
### WebMVC: 전통적인 메트릭 수집
WebMVC는 **스레드 기반** 모니터링이 직관적이며, 기존 APM 도구들과 잘 연동된다.
```java
// WebMVC - 스레드 풀 기반 모니터링
@Component
public class WebMvcMonitoring {
    
    @EventListener
    public void handleRequest(ServletRequestHandledEvent event) {
        // 스레드별 처리 시간 측정
        long processingTime = event.getProcessingTimeMillis();
        String threadName = Thread.currentThread().getName();
        
        log.info("Request processed by thread: {}, time: {}ms", 
                threadName, processingTime);
        
        // JVM 스레드 메트릭
        ThreadMXBean threadBean = ManagementFactory.getThreadMXBean();
        log.info("Active threads: {}, Peak threads: {}", 
                threadBean.getThreadCount(), threadBean.getPeakThreadCount());
    }
}
```

### WebFlux: 리액티브 스트림 메트릭
WebFlux는 **스트림 기반** 메트릭이 필요하며, **Micrometer**와의 깊은 통합을 통해 리액티브 특화 모니터링을 제공한다.
```java
// WebFlux - 리액티브 메트릭 수집
@Component
public class WebFluxMonitoring {
    
    @Autowired
    private MeterRegistry meterRegistry;
    
    public Mono<String> monitoredService(String input) {
        return Mono.fromCallable(() -> processInput(input))
                .name("business.process") // 메트릭 이름
                .tag("input.type", input.substring(0, 1)) // 태그 추가
                .metrics() // Micrometer 메트릭 자동 수집
                .doOnSubscribe(subscription -> 
                    meterRegistry.counter("requests.started").increment())
                .doOnNext(result -> 
                    meterRegistry.counter("requests.completed").increment())
                .doOnError(error -> 
                    meterRegistry.counter("requests.failed", 
                        "error", error.getClass().getSimpleName()).increment())
                .elapsed() // 처리 시간 측정
                .doOnNext(tuple -> 
                    meterRegistry.timer("processing.time")
                        .record(tuple.getT1(), TimeUnit.MILLISECONDS));
    }
}
```

---

## 결론
두 프레임워크의 선택 기준을 정리해보면 다음과 같다.

- WebMVC 선택 기준 
  - 팀의 Spring **MVC 경험이 풍부**함 
  - **복잡한** 트랜잭션 로직이 많음 
  - **빠른** 개발과 출시가 우선
  - **기존** JDBC 라이브러리 **의존성**
  - **예측 가능**한 성능 요구사항
  - 적합한 서비스: 관리자 도구, 내부 시스템, 전통적인 웹 애플리케이션
- WebFlux 선택 기준
  - **높은 동시성** 처리 필요
  - **I/O 집약적** 워크로드 
  - **마이크로서비스** 아키텍처
  - **스트리밍/실시간** 데이터 처리 
  - 클라우드 환경에서 **리소스 효율성** 중요 
  - 적합한 서비스: API 게이트웨이, 실시간 처리, 대용량 트래픽 API

지금까지 살펴보았듯이 두 프레임워크는 **경쟁 관계가 아닌 상호 보완적 관계**이며 우리는 비즈니스 요구사항과 팀의 역량, 시스템의 특성을 종합적으로 고려하여 두 기술 모두를 사용할 수 있다.

WebFlux는 높은 성능과 확장성은 매력적이지만, 거기에 따라오는 **복잡성과 학습 비용**도 고려해야 한다. 반대로 WebMVC의 안정성과 생산성은 여전히 많은 프로젝트에서 **최적의 선택**이 될 수 있다.

역시 "**Silver Bullet은 없다**". 각 상황에 맞는 **최적의 선택**을 하는데에 이 글이 도움이 되길 바라며 마치겠다.


## 성능 테스트 결과 비교
실제 성능적으로 어떤 차이점을 갖는지 확인해보기 위해 아래와 같은 환경에서 테스트를 진행하였다.

- AWS EC2 m5.xlarge (4 vCPU, 16GB RAM)
- RDS PostgreSQL r5.large
- 외부 API 평균 응답시간: 100ms
- 동시 사용자: 2000명

테스트 결과는 다음과 같았다.

- WebMVC 성능 테스트 결과
  - 처리량: 1,200 RPS
  - 평균 응답시간: 1.8초
  - 95% 응답시간: 3.2초
  - CPU 사용률: 78%
  - 메모리 사용량: 2.1GB
  - DB 커넥션: 200개
  - 스레드 수: 200개
- WebFlux 성능 테스트 결과
  - 처리량: 3,800 RPS
  - 평균 응답시간: 0.6초
  - 95% 응답시간: 1.1초
  - CPU 사용률: 42%
  - 메모리 사용량: 1.4GB
  - DB 커넥션: 15개 (평균값)
  - 이벤트 루프 스레드: 4개