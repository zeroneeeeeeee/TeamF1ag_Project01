# Archived Scripts

이 디렉터리는 구조 리팩토링으로 인해 더 이상 사용하지 않는 스크립트들을 보관합니다.

## 아카이브된 파일 목록

### `config.sh`
- **이전 용도**: 모든 환경변수의 단일 소스
- **대체**: `env/dev.json`, `env/test.json`, `env/prod.json` 파일로 대체
- **이유**: Git으로 관리 가능, 환경별 값 분리 명확

### `00-setup-github-oidc.sh`
- **이전 용도**: OIDC Provider + IAM Role 생성
- **대체**: `cfn/bootstrap/oidc.yaml` CloudFormation 템플릿으로 대체
- **이유**: Drift 감지, 변경 이력 추적, 템플릿 검증 가능

### `01-setup-s3.sh`
- **이전 용도**: S3 버킷 생성/확인
- **대체**: `cfn/bootstrap/s3.yaml` CloudFormation 템플릿으로 대체
- **이유**: Drift 감지, 변경 이력 추적, 템플릿 검증 가능

### `02-setup-kms.sh`
- **이전 용도**: KMS 키 생성/확인
- **대체**: `cfn/bootstrap/kms.yaml` CloudFormation 템플릿으로 대체
- **이유**: Drift 감지, 변경 이력 추적, 템플릿 검증 가능

### `setup-all.sh`
- **이전 용도**: 모든 사전 준비 스크립트 통합 실행
- **대체**: GitHub Actions에서 Bootstrap Stack 자동 배포
- **이유**: 자동화, 일관성 보장

### `generate-params.sh`
- **이전 용도**: 로컬 테스트용 params 파일 생성
- **대체**: `env/` 파일 직접 사용
- **이유**: env/ 파일이 직접 CloudFormation 파라미터로 사용됨

## 새로운 구조

### Bootstrap Stack (초기 셋팅)
- `cfn/bootstrap/oidc.yaml` - OIDC Provider + IAM Role
- `cfn/bootstrap/s3.yaml` - S3 버킷
- `cfn/bootstrap/kms.yaml` - KMS 키

### 환경별 파라미터
- `env/dev.json` - dev 환경 파라미터
- `env/test.json` - test 환경 파라미터
- `env/prod.json` - prod 환경 파라미터

### 배포
- GitHub Actions (`.github/workflows/deploy.yml`)에서 자동 배포
- Bootstrap Stack 배포 → env/ 파일 로드 → Main Stack 배포

## 참고
- 이 파일들은 참고용으로 보관됩니다
- 필요 시 복원 가능하지만, 새로운 구조 사용을 권장합니다

