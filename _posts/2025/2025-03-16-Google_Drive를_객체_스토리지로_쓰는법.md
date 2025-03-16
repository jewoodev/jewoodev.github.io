---
title : "Google Drive를 객체 스토리지로 사용하기"
date : 2025-03-16 00:29:00 +09:00
categories : [Google, Drvie]
tags : [Google Drive]
math : true
---

이번 글에서는 Google Drive를 웹서비스의 객체 스토리지로 사용하는 방법에 대해 알아볼 것이다. 

구글 드라이브 업로드 기능을 서버에 추가하기 위해서는 당연하겠지만 먼저 구글 드라이브가 필요하다. 그리고 구글 드라이브 API를 이용해서 어플리케이션이 구글 드라이브에 요청을 보낼 수 있도록 세팅을 해야 한다.

## 1. 구글 드라이브 API 설정
어플리케이션을 통해 구글 드라이브에 파일을 업로드하려면 구글 드라이브 API를 활용해야 한다. 이를 위해 다음 단계들을 수행해야 한다.
1. Google Cloud Console에서 프로젝트 생성
2. Google Drive API 활성화
3. OAuth 2.0 자격 증명 생성 (서비스 계정)
4. 서비스 계정에 필요한 권한 추가
5. `credentials.json` 다운로드 및 프로젝트에 추가

[Google Cloud Console](https://console.cloud.google.com/)에 접속해서 검색창에 '프로젝트 만들기'를 검색하자.

![프로젝트_생성.png](https://github.com/jewoodev/blog_img/blob/main/%EC%A3%BC%EB%AC%B8_%EB%B2%8C%ED%81%AC_%EC%9D%B8%EC%84%9C%ED%8A%B8_%ED%94%84%EB%A1%9C%EC%A0%9D%ED%8A%B8/%EA%B5%AC%EA%B8%80%EB%93%9C%EB%9D%BC%EC%9D%B4%EB%B8%8C_%EC%97%85%EB%A1%9C%EB%93%9C_%EA%B8%B0%EB%8A%A5/%ED%94%84%EB%A1%9C%EC%A0%9D%ED%8A%B8_%EC%83%9D%EC%84%B1.png?raw=true)

그리고 프로젝트를 생성한다. 그냥 프로젝트 이름과 조직을 설정하면 된다.

![사용자_인증_정보.png](https://github.com/jewoodev/blog_img/blob/main/%EC%A3%BC%EB%AC%B8_%EB%B2%8C%ED%81%AC_%EC%9D%B8%EC%84%9C%ED%8A%B8_%ED%94%84%EB%A1%9C%EC%A0%9D%ED%8A%B8/%EA%B5%AC%EA%B8%80%EB%93%9C%EB%9D%BC%EC%9D%B4%EB%B8%8C_%EC%97%85%EB%A1%9C%EB%93%9C_%EA%B8%B0%EB%8A%A5/%EC%82%AC%EC%9A%A9%EC%9E%90_%EC%9D%B8%EC%A6%9D_%EC%A0%95%EB%B3%B4.png?raw=true)

그 다음 사진에서 보이는 -이 세로로 세줄 그어져 있는 걸 클릭해서, 'API 및 서비스' > '사용자 인증 정보' 탭으로 이동한다.

![oauth_클라이언트_id_만들기.png](https://github.com/jewoodev/blog_img/blob/main/%EC%A3%BC%EB%AC%B8_%EB%B2%8C%ED%81%AC_%EC%9D%B8%EC%84%9C%ED%8A%B8_%ED%94%84%EB%A1%9C%EC%A0%9D%ED%8A%B8/%EA%B5%AC%EA%B8%80%EB%93%9C%EB%9D%BC%EC%9D%B4%EB%B8%8C_%EC%97%85%EB%A1%9C%EB%93%9C_%EA%B8%B0%EB%8A%A5/oauth_%ED%81%B4%EB%9D%BC%EC%9D%B4%EC%96%B8%ED%8A%B8_id_%EB%A7%8C%EB%93%A4%EA%B8%B0.png?raw=true)

그 다음 'OAuth 클라이언트 ID 만들기' 탭으로 이동한다.

![동의_화면_구성.png](https://github.com/jewoodev/blog_img/blob/main/%EC%A3%BC%EB%AC%B8_%EB%B2%8C%ED%81%AC_%EC%9D%B8%EC%84%9C%ED%8A%B8_%ED%94%84%EB%A1%9C%EC%A0%9D%ED%8A%B8/%EA%B5%AC%EA%B8%80%EB%93%9C%EB%9D%BC%EC%9D%B4%EB%B8%8C_%EC%97%85%EB%A1%9C%EB%93%9C_%EA%B8%B0%EB%8A%A5/%EB%8F%99%EC%9D%98_%ED%99%94%EB%A9%B4_%EA%B5%AC%EC%84%B1.png?raw=true)

그럼 먼저 동의 화면을 구성해야 한다고 안내받게 된다. 그래서 '동의 화면 구성' 버튼을 누르면

![인증_플랫폼_구성.png](https://github.com/jewoodev/blog_img/blob/main/%EC%A3%BC%EB%AC%B8_%EB%B2%8C%ED%81%AC_%EC%9D%B8%EC%84%9C%ED%8A%B8_%ED%94%84%EB%A1%9C%EC%A0%9D%ED%8A%B8/%EA%B5%AC%EA%B8%80%EB%93%9C%EB%9D%BC%EC%9D%B4%EB%B8%8C_%EC%97%85%EB%A1%9C%EB%93%9C_%EA%B8%B0%EB%8A%A5/%EC%9D%B8%EC%A6%9D_%ED%94%8C%EB%9E%AB%ED%8F%BC_%EA%B5%AC%EC%84%B1.png?raw=true)

인증 플랫폼을 먼저 구성하도록 안내해준다. 그 안내에 따라서 인증 플랫폼을 구성해 만들어준다.

![인증_플랫폼_구성2.png](https://github.com/jewoodev/blog_img/blob/main/%EC%A3%BC%EB%AC%B8_%EB%B2%8C%ED%81%AC_%EC%9D%B8%EC%84%9C%ED%8A%B8_%ED%94%84%EB%A1%9C%EC%A0%9D%ED%8A%B8/%EA%B5%AC%EA%B8%80%EB%93%9C%EB%9D%BC%EC%9D%B4%EB%B8%8C_%EC%97%85%EB%A1%9C%EB%93%9C_%EA%B8%B0%EB%8A%A5/%EC%9D%B8%EC%A6%9D_%ED%94%8C%EB%9E%AB%ED%8F%BC_%EA%B5%AC%EC%84%B12.png?raw=true)

이 또한 프로젝트의 한 종류라 구글 클라우드는 프로젝트라고 표현하는 것이 확인('프로젝트 구성')된다.

![유저타입.png](https://github.com/jewoodev/blog_img/blob/main/%EC%A3%BC%EB%AC%B8_%EB%B2%8C%ED%81%AC_%EC%9D%B8%EC%84%9C%ED%8A%B8_%ED%94%84%EB%A1%9C%EC%A0%9D%ED%8A%B8/%EA%B5%AC%EA%B8%80%EB%93%9C%EB%9D%BC%EC%9D%B4%EB%B8%8C_%EC%97%85%EB%A1%9C%EB%93%9C_%EA%B8%B0%EB%8A%A5/%EC%9C%A0%EC%A0%80%ED%83%80%EC%9E%85.png?raw=true)

이제 다시 OAuth 동의 화면을 구성한다. 여기에서는 '외부'를 선택한다.

![앱정보.png](https://github.com/jewoodev/blog_img/blob/main/%EC%A3%BC%EB%AC%B8_%EB%B2%8C%ED%81%AC_%EC%9D%B8%EC%84%9C%ED%8A%B8_%ED%94%84%EB%A1%9C%EC%A0%9D%ED%8A%B8/%EA%B5%AC%EA%B8%80%EB%93%9C%EB%9D%BC%EC%9D%B4%EB%B8%8C_%EC%97%85%EB%A1%9C%EB%93%9C_%EA%B8%B0%EB%8A%A5/%EC%95%B1%EC%A0%95%EB%B3%B4.png?raw=true)

그 후에 앱 정보에서 앱 이름은 헷갈리지 않게 되도록 프로젝트 이름과 동일하게 설정하고 지원 이메일에는 자신의 이메일을 입력하거나, 별도의 지원 이메일을 입력한다.  
개발자 연락처 정보에는 개발자 이메일을 입력한다. 나머지는 꼭 입력해야하는 게 없다. 필요하다면 추가하도록 하자.

![oauth_클라이언트_id_만들기2.png](https://github.com/jewoodev/blog_img/blob/main/%EC%A3%BC%EB%AC%B8_%EB%B2%8C%ED%81%AC_%EC%9D%B8%EC%84%9C%ED%8A%B8_%ED%94%84%EB%A1%9C%EC%A0%9D%ED%8A%B8/%EA%B5%AC%EA%B8%80%EB%93%9C%EB%9D%BC%EC%9D%B4%EB%B8%8C_%EC%97%85%EB%A1%9C%EB%93%9C_%EA%B8%B0%EB%8A%A5/oauth_%ED%81%B4%EB%9D%BC%EC%9D%B4%EC%96%B8%ED%8A%B8_id_%EB%A7%8C%EB%93%A4%EA%B8%B02.png?raw=true)
그 다음 'OAuth 클라이언트 ID를 만들기' 로 돌아와서 진행한다. 우리는 스프링 서버가 사용할 클라이언트 ID를 만들 것이기 때문에 웹 애플리케이션을 골라준다.

![oauth_클라이언트_id_만들기3.png](https://github.com/jewoodev/blog_img/blob/main/%EC%A3%BC%EB%AC%B8_%EB%B2%8C%ED%81%AC_%EC%9D%B8%EC%84%9C%ED%8A%B8_%ED%94%84%EB%A1%9C%EC%A0%9D%ED%8A%B8/%EA%B5%AC%EA%B8%80%EB%93%9C%EB%9D%BC%EC%9D%B4%EB%B8%8C_%EC%97%85%EB%A1%9C%EB%93%9C_%EA%B8%B0%EB%8A%A5/oauth_%ED%81%B4%EB%9D%BC%EC%9D%B4%EC%96%B8%ED%8A%B8_id_%EB%A7%8C%EB%93%A4%EA%B8%B03.png?raw=true)

그 후에 본인 서버의 URI를 '승인된 JavaScript 원본'에 추가하고, 서버가 Google에서 인증을 받은 후 리다이렉션 될 URI를 '승인된 리디렉션 URI' 에 추가한 후 저장한다.

생성된 OAuth 2.0 클라이언트 ID를 다운받는다. '사용자 인증 정보' 탭에서 생성한 ID의 작업 컬럼에서 다운로드 버튼을 누르고 'JSON 다운로드' 를 클릭하면 된다.

여기까지 수행했다면 이제 쉽다. 고생많았다.

이제 Google Drive API를 검색해 사용 설정을 한다.

![google_drive_api_사용.png](https://github.com/jewoodev/blog_img/blob/main/%EC%A3%BC%EB%AC%B8_%EB%B2%8C%ED%81%AC_%EC%9D%B8%EC%84%9C%ED%8A%B8_%ED%94%84%EB%A1%9C%EC%A0%9D%ED%8A%B8/%EA%B5%AC%EA%B8%80%EB%93%9C%EB%9D%BC%EC%9D%B4%EB%B8%8C_%EC%97%85%EB%A1%9C%EB%93%9C_%EA%B8%B0%EB%8A%A5/google_drive_api_%EC%82%AC%EC%9A%A9.png?raw=true)

사용 버튼을 누르면 된다.

## 2. 스프링 코드 작성
의존성 부터 추가하자.

```groovy
// Google Drive
implementation 'com.google.apis:google-api-services-drive:v3-rev20250210-2.0.0'
implementation 'com.google.api-client:google-api-client:1.33.0' // api client
implementation 'com.google.auth:google-auth-library-oauth2-http:1.19.0' // Google Authentication
implementation 'com.google.http-client:google-http-client-gson:1.43.3' // JSON Factory
implementation 'com.google.http-client:google-http-client:1.43.3' // HTTP Client (NetHttpTransport 관련)
implementation 'com.google.api-client:google-api-client-gson:2.2.0' // Google API Client Core
```

```java
@Slf4j
@Service
public class GoogleDriveService {
    public final Drive driveService;
    private static final String APPLICATION_NAME = ""; // 변경 필요
    private static final GsonFactory JSON_FACTORY = GsonFactory.getDefaultInstance();
    private static final List<String> SCOPES = Collections.singletonList(DriveScopes.DRIVE_FILE);
    private static final String CREDENTIALS_FILE_PATH = ""; // 변경 필요

    public GoogleDriveService() throws IOException {
        driveService = getDriveService();
    }

    private static Drive getDriveService() throws IOException {
        InputStream in = new FileInputStream(CREDENTIALS_FILE_PATH);
        GoogleCredentials credentials = GoogleCredentials.fromStream(in).createScoped(SCOPES);

        return new Drive.Builder(new NetHttpTransport(), JSON_FACTORY, new HttpCredentialsAdapter(credentials))
                .setApplicationName(APPLICATION_NAME)
                .build();
    }
}
```

업로드를 하는 역할을 맡을 객체를 만든다. 필자는 이렇게 만들었다.

여기에서 DriverScopes는 Google Drive API를 통해 수행할 수 있는 작업 권한의 범위를 지정한다. 필요하지 않은 권한까지 포함하는 것은 운영 이슈로 이어질 수 있기 때문에 본인의 케이스에 맞는 범위를 선택하는 것을 권장한다.

![google_drive_api_scope.png](https://github.com/jewoodev/blog_img/blob/main/%EC%A3%BC%EB%AC%B8_%EB%B2%8C%ED%81%AC_%EC%9D%B8%EC%84%9C%ED%8A%B8_%ED%94%84%EB%A1%9C%EC%A0%9D%ED%8A%B8/%EA%B5%AC%EA%B8%80%EB%93%9C%EB%9D%BC%EC%9D%B4%EB%B8%8C_%EC%97%85%EB%A1%9C%EB%93%9C_%EA%B8%B0%EB%8A%A5/google_drive_api_scope.png?raw=true)
_Google Drive API 공식 문서 발췌_

위의 표의 '사용' 열에 기재된 표현에 대한 자세한 민감도는 다음과 같다. 이 또한 [공식 문서](https://developers.google.com/drive/api/guides/api-specific-auth?hl=ko)에서 발췌했다.
- **권장 / 민감하지 않음**: 이 범위는 가장 작은 승인 액세스 범위를 제공하며 기본 앱 인증만 필요하다. 이 요구사항에 관한 자세한 내용은 [인증 요구사항](https://support.google.com/cloud/answer/13464321?hl=ko을 참고하자.
- **권장 / 민감한 정보**: 이러한 범위는 사용자가 앱에 대해 승인한 특정 Google 사용자 데이터에 대한 액세스 권한을 제공한다. 추가 앱 인증을 거쳐야 합니다. 이 요구사항에 대한 자세한 내용은 [민감한 정보 및 제한된 범위 요구사항](https://support.google.com/cloud/answer/13464321?hl=ko#ss-rs-requirements)을 참고하자.
- **제한됨**: 이러한 범위는 Google 사용자 데이터에 대한 광범위한 액세스 권한을 제공하며 제한된 범위 확인 절차를 거쳐야 한다. 이러한 요구사항에 대한 자세한 내용은 [Google API 서비스 사용자 데이터 정책](https://developers.google.com/terms/api-services-user-data-policy) 및 [특정 API 범위의 추가 요구사항](https://developers.google.com/terms/api-services-user-data-policy#additional_requirements_for_specific_api_scopes)을 참고하자. 제한된 범위의 데이터를 서버에 저장하거나 전송하는 경우 보안 평가를 거쳐야 한다.

이렇게 생성한 `Drive` 객체를 이용해 파일을 업로드 할 수 있다. 아래의 예제는 폴더를 생성한 후 그 곳에 업로드하는 코드이다.

```java
public class GoogleDriveService {
    
    public String makeFolder(Drive driverService, String folderName) throws IOException {
        String query = "mimeType='application/vnd.google-apps.folder' and name='" + folderName;
        List<File> files = driverService.files().list().setQ(query).setSpaces("drive").execute().getFiles();
        
        if (!files.isEmpty()) {
            return files.get(0).getId();
        }

        File fileMetadata = new File();
        fileMetadata.setName(folderName);
        fileMetadata.setMimeType("application/vnd.google-apps.folder");
        if (parentFolderId != null) {
            fileMetadata.setParents(Collections.singletonList(parentFolderId));
        }

        File folder = driveService.files().create(fileMetadata).setFields("id").execute();
        return folder.getId();
    }
    
    public String uploadFile(java.io.File uploadFile, String seller, String buyer, String orderDate, String folderId) throws IOException {
        folderId = makeFolder(driveService, forderName);

        File fileMetadata = new File();
        fileMetadata.setName(uploadFile.getName());
        fileMetadata.setParents(Collections.singletonList(folderId));

        AbstractInputStreamContent mediaContent = new FileContent("application/octet-stream", uploadFile);
        File uploadedFile = driveService.files().create(fileMetadata, mediaContent)
                .setFields("id, parents")
                .execute();
        return uploadedFile.getId();
    }
}
```
