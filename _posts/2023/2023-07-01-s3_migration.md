---
title : 다른 계정 간의 S3 Object Migration
date : 2023-07-06 15:58:00 +09:00
categories : [AWS, S3]
tags : [Migration]
use_math : true
---

이번 글에서는 다른 계정 간에 S3 객체를 이전하는 방법을 알아보자.

## 1. 워크로드

- 계정 A: 복사할 파일의 출발지 (Source)
- 계정 B: 복사된 파일의 목적지 (Target)

계정 B에서 S3 Bucket의 권한을 갖는 IAM을 생성하고, 복사할 객체를 가지고 있는 계정 A의 Bucket의 권한을 계정 B에게 줘서 S3 Bucket 안의 Object를 이전한다.

이 방법은 S3의 모든 객체를 가져오는 것 뿐만 아니라 폴더의 구조까지 복사해 올 수 있기 때문에 기존 계정의 Bucket의 폴더 구조가 복잡하게 되어 있더라도 그대로 옮겨 올 수 있다는 장점이 있다.

## 2. IAM 정책 생성 &rarr; 연결

계정 B에 IAM 정책부터 생성한다. 예시로 인라인 코드를 적어보겠다.

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:ListBucket",
        "s3:GetObject"
      ],
      "Resource": [
        "arn:aws:s3:::Source_Bucket",
        "arn:aws:s3:::Source_Bucket/*"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "s3:ListBucket",
        "s3:PutObject",
        "s3:PutObjectAcl"
      ],
      "Resource": [
        "arn:aws:s3:::Target_Bucket",
        "arn:aws:s3:::Target_Bucket/*"
      ]
    }
  ]
}
```

1. 'Source-Bucket'에 계정 A에서 이전할 객체 path를 기입하고 
2. 'Target-Bucket'에 이전된 객체가 위치할 path를 적어보자

3. 정책 검토 &rarr; 정책 생성 순으로 클릭해 정책을 생성하자
4. 생성한 정책을 사용자 권한에 추가하자

## 3. 계정 A의 Bucket Policy 설정

계정 B에 대한 세팅을 끝낸 후 계정 A의 Bucket Policy를 설정한다.

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "DelegateS3Access",
      "Effect": "Allow",
      "Principal": {
        "AWS": "Account B's AccountID"
      },
      "Action": [
        "s3:ListBucket",
        "s3:GetObject"
      ],
      "Resource": [
        "arn:aws:s3:::Source_Bucket/*",
        "arn:aws:s3:::Source_Bucket"
      ]
    }
  ]
}
```

## 4. AWS CLI에서 Sync

계정 B의 IAM 키 값을 등록하여 복사할 Source-Bucket을 조회해보자.

- 여러 계정으로 CLI를 접속해야 한다면 `--profile`이라는 기능을 사용하면 좋다.

```bash
aws configure --profile sync-test
```

```bash
aws s3 ls s3://Bucket-Source
```

## 5. Migration

객체를 이전해보자

```bash
aws s3 sync s3://Bucket-Source s3://Bucket-Target
```

이전이 된 걸 확인할 수 있을 것이다.









