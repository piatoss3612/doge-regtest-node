# aarch64 아키텍처용 Ubuntu 베이스 이미지 사용
FROM arm64v8/ubuntu:20.04

# 비대화형 모드 설정
ENV DEBIAN_FRONTEND=noninteractive

# 필요한 패키지 설치
RUN apt-get update && apt-get install -y \
    ca-certificates \
    tar \
    wget \
    tar \
    curl \
    && rm -rf /var/lib/apt/lists/*

# 작업 디렉터리: 데이터 디렉터리로 사용할 위치 (예: /root/.dogecoin)
WORKDIR /root/.dogecoin

# 로컬에 준비한 dogecoin.conf 파일을 컨테이너에 복사
COPY dogecoin.conf /root/.dogecoin/dogecoin.conf

# 작업 디렉터리 생성
WORKDIR /opt/dogecoin

# GitHub Releases에서 Dogecoin 1.14.9 aarch64 바이너리 다운로드 및 압축 해제
RUN wget https://github.com/dogecoin/dogecoin/releases/download/v1.14.9/dogecoin-1.14.9-aarch64-linux-gnu.tar.gz && \
    tar -xzvf dogecoin-1.14.9-aarch64-linux-gnu.tar.gz && \
    rm dogecoin-1.14.9-aarch64-linux-gnu.tar.gz

# 압축 해제 후 생성된 디렉터리로 이동 (디렉터리 이름은 압축 파일 내부 구조에 따라 다를 수 있음)
WORKDIR /opt/dogecoin/dogecoin-1.14.9

# PATH에 바이너리 위치 추가 (필요에 따라)
ENV PATH="/opt/dogecoin/dogecoin-1.14.9/bin:${PATH}"

# 외부에서 RPC 접근을 위해 18332 포트 노출 (dogecoin.conf 또는 실행 옵션에서 rpcbind 설정 필요)
EXPOSE 18332

# 컨테이너 시작 시 dogecoind 실행 (설정 파일을 자동으로 읽음)
CMD ["dogecoind", "-regtest", "-printtoconsole"]
