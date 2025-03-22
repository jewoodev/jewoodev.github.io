---
title : "Spring Config Client와 QueryDSL 충돌"
date : 2024-03-01 15:25:00 +09:00
categories : [Trouble Shooting, Version Conflict]
tags : []
math : true

---

## 1. 문제의 시작

기존 모놀리스 프로젝트에 MSA 아키텍처를 도입하던 중, Config Repository와 Config Server를 띄운 후에 Config Client의 연결성을 구성하는 과정에서 아래와 같은 에러를 컴파일러가 건네주었다. 

```
Could not find org.springframework.cloud:spring-cloud-starter-config:.
Required by:
    project :

Possible solution:
 - Declare repository providing the artifact, see the documentation at https://docs.gradle.org/current/userguide/declaring_repositories.html
```

에러가 건네준 링크에서는 Gradle 프로젝트에서 리포지토리를 명시하는 방법에 대한 내용만 있고, 문제의 원인이나 해결방법에 대한 힌트를 얻지 못했다. 하여간 에러에서 알려주는 내용만 가지고는 어떻게 해결하기는 어려운 상황이었는데, 내가 검색 요령이 없는건지 같은 트러블을 만났던 사람이 없는건지 구글링을 해봐도 관련 내용은 전혀 없었고, GPT의 힘을 빌리자니 문제 파악을 전혀 못하고 있는데 도움을 줄 수 있을리가 없었다(당연하다, 오히려 좋아). 

스스로 파헤쳐보려고 머리를 계속 굴리다가 사용 중인 dependencies를 다시 처음부터 하나하나 추가해보면서 어떤 의존성에서 발생되는 것인지 파악해보려 했다. 

그 결과로, 기존 의존성에서 QueryDSL을 제거하고 Config Client를 추가했을 때는 문제 없이 build되는 것을 확인할 수 있었다. 

### 1.1 Config Client Dependency  

```groovy
ext {
  set('springCloudVersion', "2023.0.0")
}

dependencies {
  implementation 'org.springframework.cloud:spring-cloud-starter-config'
}

dependencyManagement {
  imports {
    mavenBom "org.springframework.cloud:spring-cloud-dependencies:${springCloudVersion}"
  }
}
```

### 1.2 QueryDSL Dependency

```groovy
implementation 'com.querydsl:querydsl-jpa:5.0.0:jakarta'
annotationProcessor "com.querydsl:querydsl-apt:${dependencyManagement.importedProperties['querydsl.version']}:jakarta"
annotationProcessor "jakarta.annotation:jakarta.annotation-api"
annotationProcessor "jakarta.persistence:jakarta.persistence-api"
```

## 2. 문제의 원인

어떤 이유로 Config Client가 build 될 수 없는지 정확한 파악은 어려웠다. 

다만 QueryDSL의 의존성 중에서 

```groovy
annotationProcessor "com.querydsl:querydsl-apt:${dependencyManagement.importedProperties['querydsl.version']}:jakarta"
```

에서 문제가 발생되는 것을 확인할 수 있었다. 

> **참고**
>
> querydsl-apt 라이브러리는Q타입 class를 자동 생성해주는 역할을 한다.

## 3. 문제 해결

그래서 아래 명령어로 dependencies 구성 문제를 정확히 살펴보았다.

```bash
./gradlew dependencies
```

![image-20240301150442936](https://github.com/jewoodev/blog_img/blob/main/2024-03-01-Config_Client%EC%99%80_QueryDSL_%EC%B6%A9%EB%8F%8C/image-20240301150442936.png?raw=true)

javax 의존성이 있어서 이상하다 생각했다.

Spring Boot 3.x 부터 jakarta 로 대체되었기 때문이다. 그래서 현재 버전에 맞는 querydsl-apt 버전을 직접 기입해보았다.

```groovy
implementation 'com.querydsl:querydsl-jpa:5.0.0:jakarta'
annotationProcessor "com.querydsl:querydsl-apt:5.0.0:jakarta"
annotationProcessor "jakarta.annotation:jakarta.annotation-api"
annotationProcessor "jakarta.persistence:jakarta.persistence-api"
```

이 시도로 문제가 해결되었다.

## 4. 문제 정리

- GitHub 서버가 개입되면서, 혹은 MSA 아키텍처가 개입되면서 querydsl-apt의 하위 위존성이 javax로 변경되었다. 
- Config Client로써 서버를 띄울 때는 1.2 QueryDSL Dependency의 `${~}`부분에서 컨트롤되는 의존성에 영향을 주어서 변경되었다고 의심할 수 있지만, 정확하게 파악하기는 어렵다.

