**[简体中文](./README.md) | [English](./README_en-us.md) | 한국어**

# PawnIO 보안 수정 버전

[이 수정 버전 다운로드](https://github.com/Jeon-JongChan/TrafficMonitor_SecurityFix/releases/latest)

- **하드웨어 센서 접근 변경:** WinRing0 기반 LibreHardwareMonitor DLL을 PawnIO를 사용하는 **LibreHardwareMonitorLib 0.9.6** NuGet 패키지로 교체했습니다.
- **기존 기능 유지:** 기존 C++/CLI 래퍼와 센서 API를 그대로 사용합니다. CPU·GPU·메모리·디스크 등의 표시 기능은 기존 설정에서 사용할 수 있습니다.
- **PawnIO 설치:** CPU 및 메인보드 센서 사용에는 [공식 PawnIO 드라이버](https://pawnio.eu/)가 필요합니다. 해당 모니터링을 활성화한 상태에서 드라이버가 없으면 설치 주소를 안내합니다. 설치 후 앱을 다시 시작해 주세요.
- **센서 값 처리 보완:** 값이 없는 센서와 빈 CPU 클럭 목록을 안전하게 처리하고, GPU 사용률을 읽지 못한 경우 실제 0%와 구분합니다.
- **한국어 선택 지원:** 앱을 우클릭해 **Options → General Settings → Language → 한국어**를 선택하고 적용한 뒤 다시 시작하세요. 한국어 번역이 실행 파일에 포함되어 별도 언어 파일을 복사할 필요가 없습니다.

---

# TrafficMonitor 소개

TrafficMonitor는 Windows에서 네트워크 속도와 CPU·메모리 사용률을 표시하는 프로그램입니다. 바탕 화면의 작은 창이나 작업 표시줄에 정보를 표시할 수 있으며, 스킨 변경, 사용한 네트워크 트래픽 기록, 하드웨어 센서 모니터링, 플러그인 기능을 제공합니다.

이 저장소는 [원본 TrafficMonitor](https://github.com/zhongyang219/TrafficMonitor)에 PawnIO 기반 하드웨어 모니터링과 한국어 선택 지원을 반영한 수정 버전입니다.

## 다운로드와 관련 문서

- [PawnIO 수정 버전 다운로드](https://github.com/Jeon-JongChan/TrafficMonitor_SecurityFix/releases/latest)
- [수정 버전 소스 코드](https://github.com/Jeon-JongChan/TrafficMonitor_SecurityFix)
- [원본 프로젝트](https://github.com/zhongyang219/TrafficMonitor)
- [자주 묻는 질문 — 영문](./Help_en-us.md) / [중문](./Help.md)
- [원본 프로젝트 사용 설명서 — 중문](https://github.com/zhongyang219/TrafficMonitor/wiki)

실행에는 Microsoft Visual C++ 재배포 패키지와 .NET Framework 4.7.2 이상이 필요합니다. 시작할 때 `MSVC*.dll`을 찾을 수 없다는 메시지가 나타나면 [Microsoft Visual C++ 재배포 패키지 안내](https://docs.microsoft.com/ko-kr/cpp/windows/latest-supported-vc-redist?view=msvc-170)를 참고해 설치하세요.

## 버전과 기능

이 수정 저장소의 배포 스크립트는 온도 모니터링을 포함하는 전체 기능 버전을 빌드합니다. 아래 표는 원본 프로젝트의 표준 버전과 Lite 버전 기능 비교입니다.

| 기능 | 표준 버전 | Lite 버전 |
| --- | --- | --- |
| 네트워크 속도 표시 | ✔ | ✔ |
| CPU·메모리 사용률 표시 | ✔ | ✔ |
| CPU·GPU·디스크·메인보드 온도 표시 | ✔ | ❌ |
| CPU 클럭 표시 | ✔ | ✔ |
| GPU 사용률 표시 | ✔ | ✔ |
| 디스크 사용률 표시 | ✔ | ✔ |
| 네트워크 연결 상세 정보 | ✔ | ✔ |
| 플러그인 | ✔ | ✔ |
| 메인 창 스킨 변경 | ✔ | ✔ |
| 관리자 권한 필요 | 예 | 아니요 |

원본 프로젝트는 1.86부터 Lite 버전에도 GPU·디스크 사용률 표시를 제공합니다. 원본의 후속 개발에서는 온도 모니터링을 [하드웨어 모니터링 플러그인](https://github.com/zhongyang219/TrafficMonitorPlugins/blob/main/download/plugin_download_en.md#hardware-monitor-plugin)으로 옮기고 Lite 버전을 중심으로 제공한다는 안내가 있습니다. 이 저장소의 PawnIO 수정은 기존 전체 기능 버전을 대상으로 합니다.

## 주요 기능

- 실시간 업로드·다운로드 속도와 CPU·메모리 사용률 표시
- 여러 네트워크 어댑터의 자동 또는 수동 선택
- 네트워크 연결 상세 정보 확인
- 작업 표시줄에 모니터링 정보 표시
- 스킨 변경 및 직접 만든 스킨 사용
- 과거 네트워크 사용량 통계
- 온도·CPU 클럭·GPU 사용률 등 하드웨어 정보 표시
- 플러그인 지원

## 화면 예시

아래 이미지는 원본 프로젝트의 영문 UI 예시입니다.

### 메인 창과 우클릭 메뉴

![메인 창](./Screenshots/en_us/main1.png)

![우클릭 메뉴](./Screenshots/en_us/main.png)

### 작업 표시줄과 스킨

![작업 표시줄](./Screenshots/en_us/taskbar.png)

![다양한 스킨](./Screenshots/skins.PNG)

## 사용 방법

프로그램을 실행하면 네트워크 속도를 표시하는 작은 창이 나타납니다. 창을 우클릭하면 설정과 기능 메뉴를 열 수 있습니다.

작업 표시줄에 정보를 표시하려면 우클릭 메뉴에서 **작업 표시줄 창 표시**를 선택하세요. 작업 표시줄 창은 기본적으로 네트워크 속도를 표시합니다. CPU·메모리 사용률 등을 추가하려면 작업 표시줄 창의 우클릭 메뉴에서 **표시 설정**을 열고 원하는 항목을 선택하세요.

![작업 표시줄 표시 항목 설정](./Screenshots/en_us/taskbar_item_settings.png)

### 한국어로 변경하기

1. 메인 창 또는 알림 영역 아이콘을 우클릭합니다.
2. **Options → General Settings → Language**에서 **한국어**를 선택합니다.
3. 설정을 적용하고 프로그램을 다시 시작합니다.

한국어 UI에서는 **옵션 설정 → 일반 설정 → 언어**에서 다른 언어로 변경할 수 있습니다.

## 스킨 변경과 제작

메인 창이나 알림 영역 아이콘의 우클릭 메뉴에서 **기타 기능 → 스킨 변경**을 선택하세요. [원본 프로젝트의 스킨 모음](https://github.com/zhongyang219/TrafficMonitorSkin/blob/master/皮肤下载.md)에서 추가 스킨을 받을 수 있습니다.

![스킨 선택](./Screenshots/en_us/selecte_skin.png)

스킨은 프로그램 폴더의 `skins` 아래에 저장합니다. 스킨마다 별도의 폴더를 사용하며, 폴더 이름이 스킨 이름이 됩니다.

| 파일 | 용도 |
| --- | --- |
| `background.bmp`, `background_l.bmp` | 배경 이미지 |
| `skin.ini` | 글자 색·글꼴·제작자·표시 항목의 크기와 위치 설정 |
| `skin.xml` | 1.80부터 지원하는 XML 설정. 온도와 GPU 사용률 표시에 필요 |
| `background.png`, `background_l.png` | 1.85부터 지원하는 PNG 배경. 투명 배경 사용 가능 |

자세한 제작 방법은 [스킨 제작 안내 — 중문](./皮肤制作教程.md) 또는 [원본 프로젝트 Wiki](https://github.com/zhongyang219/TrafficMonitor/wiki/皮肤制作教程)를 참고하세요.

## 옵션 설정

![옵션 설정](./Screenshots/en_us/option.jpg)

우클릭 메뉴의 **옵션 설정**에서 메인 창과 작업 표시줄 창의 글자 색, 글꼴, 배경색, 네트워크 속도 단위, 표시 문구를 각각 설정할 수 있습니다.

**일반 설정**에서는 시작 시 업데이트 확인, Windows 시작 시 자동 실행, 알림 조건과 하드웨어 모니터링을 설정합니다.

1.72부터는 표시 항목별 글자 색을 지정할 수 있습니다. 항목별 색상 지정 옵션을 켜고 글자 색 옆의 색상 상자를 누르면 상세 설정을 열 수 있습니다.

## 플러그인

1.82부터 플러그인 기능을 지원합니다. 플러그인 DLL은 `TrafficMonitor.exe`와 같은 위치에 있는 `plugins` 폴더에 넣으세요. 프로그램을 시작할 때 자동으로 불러옵니다. **기타 기능 → 플러그인 관리**에서 불러온 플러그인을 확인하고 관리할 수 있습니다.

- [플러그인 개발 안내 — 영문](https://github.com/zhongyang219/TrafficMonitor/wiki/Plugin-Development-Guide)
- [원본 프로젝트 플러그인 다운로드 안내](https://github.com/zhongyang219/TrafficMonitorPlugins/blob/main/download/plugin_download.md)

## 하드웨어 모니터링

1.80부터 온도, CPU 클럭, GPU 사용률 등의 하드웨어 모니터링을 지원합니다. 이 수정 버전은 [LibreHardwareMonitor](https://github.com/LibreHardwareMonitor/LibreHardwareMonitor)의 0.9.6 패키지를 사용합니다.

온도 모니터링은 기본적으로 꺼져 있습니다. **옵션 설정 → 일반 설정 → 하드웨어 모니터링**에서 필요한 항목을 켜세요. CPU와 메인보드 센서를 사용하려면 [PawnIO](https://pawnio.eu/)를 설치한 뒤 프로그램을 다시 시작해야 합니다.

사용 가능한 센서는 하드웨어와 드라이버에 따라 달라집니다. 문제가 생기면 해당 모니터링 항목을 끄고 [온도 모니터링 관련 도움말 — 영문](./Help_en-us.md#13-about-the-temperature-monitoring-of-trafficmonitor)을 참고하세요. 원본 프로젝트는 하드웨어 모니터링 사용 시 CPU·메모리 사용량 증가와 일부 환경에서의 프로그램 또는 시스템 오류 가능성을 안내하고 있습니다.

## 업데이트 기록

[원본 업데이트 기록 — 영문](./UpdateLog/update_log_en-us.md) / [중문](./UpdateLog/update_log.md)

이 수정 버전의 주요 변경 사항은 문서 상단의 **PawnIO 보안 수정 버전**을 참고하세요.

## 프로젝트와 배포 경로

원본 개발자의 안내에 따르면 `www.trafficmonitor.cn`은 원본 개발자와 관계가 없습니다. 원본 프로젝트의 배포 경로는 [GitHub](https://github.com/zhongyang219/TrafficMonitor), [Gitee](https://gitee.com/zhongyang219/TrafficMonitor), [개발자의 Baidu 공유 링크](https://pan.baidu.com/s/15PMt7s-ASpyDwtS__4cUhg)(코드: `ou0m`)입니다.

이 저장소의 PawnIO 수정 버전은 [TrafficMonitor_SecurityFix 릴리스 페이지](https://github.com/Jeon-JongChan/TrafficMonitor_SecurityFix/releases/latest)에서 배포합니다.
