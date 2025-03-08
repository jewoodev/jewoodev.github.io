---
title : Spark application의 개념
date : 2023-07-01 18:29:00 +09:00
categories : [Apache, Spark]
tags : [Concept]
use_math : true
published: false
---

# 관련 용어
## Application
API를 써서 스파크 위에서 돌아가는 사용자 프로그램. 드라이버 프로그램과 클러스터의 실행기로 이루어진다.

## SparkSession
스파크 코어 기능들과 상호 작용할 수 있는 진입점을 제공하며 그 API로 프로그래밍을 할 수 있게 해주는 객체이다. 스파크 셸에서 스파크 드라이버는 기본적으로 SparkSession을 제공하지만 스파크 애플리케이션에서는 사용자가 SparkSession 객체를 생성해서 써야 한다.

## 잡(job)
스파크 액션$_{action}$(예: save(), collect())에 대한 응답으로 생성되는 여러 태스크로 이루어진 병렬 연산

## 스테이지(stage)
각 job은 스테이지라고 불리는 서로 의존성을 가지는 다수의 태스크 모음으로 나뉜다.

## 태스크(task)
스파크 이그제큐터로 보내지는 작업 실행의 가장 기본적인 단위

# 개념
