# 컨테이너 이름 및 RPC 관련 설정 (dogecoin.conf에 설정한 값과 동일해야 함)
CONTAINER   := dogecoin-node
RPC_USER    := myrpcuser
RPC_PASSWORD:= myrpcpassword
RPC_PORT    := 18332
RPC_URL     := http://localhost:$(RPC_PORT)/

# docker exec를 이용해 dogecoin-cli 명령어를 실행하는 함수
CLI = docker exec $(CONTAINER) dogecoin-cli -regtest

.PHONY: newaddress generate balance rpc-test rpc-test-jq

# 0. 컨테이너 빌드 및 실행
build:
	docker build -t dogecoin-node .
	docker run -d --name dogecoin-node -p 18332:18332 dogecoin-node

# 1. 새로운 지갑 주소 생성 (라벨 "initial_account" 부여)
newaddress:
	@echo "Generating new address..."
	@docker exec $(CONTAINER) dogecoin-cli -regtest getnewaddress "initial_account"

# 2. 입력한 주소로 101개의 블록을 생성하여 초기 보상 지급 (블록 생성 전 주소를 확인하세요)
generate:
	@read -p "Enter the address to receive block rewards: " addr; \
	echo "Generating 101 blocks and paying rewards to $$addr"; \
	docker exec $(CONTAINER) dogecoin-cli -regtest generatetoaddress 101 $$addr

# 3. 현재 지갑 잔액 확인
balance:
	@echo "Checking current wallet balance..."
	@docker exec $(CONTAINER) dogecoin-cli -regtest getbalance

# 4. 외부에서 RPC URL로 요청 보내기 (Python 사용)
rpc-test:
	@echo "Testing external RPC call (getblockchaininfo)..."
	@curl --user $(RPC_USER):$(RPC_PASSWORD) --data-binary '{"jsonrpc": "1.0", "id":"curltest", "method": "getblockchaininfo", "params": [] }' -H 'content-type: application/json;' $(RPC_URL)

# 또는 jq를 사용하는 방법 (jq가 설치되어 있어야 함)
rpc-test-jq:
	@echo "Testing external RPC call (getblockchaininfo)..."
	@curl --user $(RPC_USER):$(RPC_PASSWORD) --data-binary '{"jsonrpc": "1.0", "id":"curltest", "method": "getblockchaininfo", "params": [] }' -H 'content-type: application/json;' $(RPC_URL) | jq '.'
