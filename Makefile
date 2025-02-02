# =============================================================================
# Dogecoin Node Makefile
# This Makefile provides commands to manage a Dogecoin node in a Docker container
# =============================================================================

# Basic Configuration
# -----------------------------------------------------------------------------
CONTAINER   := dogecoin-node
RPC_USER    := myrpcuser
RPC_PASSWORD:= myrpcpassword
RPC_PORT    := 18332
RPC_URL     := http://localhost:$(RPC_PORT)/

# Command Shortcuts
# -----------------------------------------------------------------------------
CLI         := docker exec $(CONTAINER) dogecoin-cli -regtest
CURL_RPC    := curl --user $(RPC_USER):$(RPC_PASSWORD) -H 'content-type: application/json;' $(RPC_URL)

# Phony Targets
# -----------------------------------------------------------------------------
.PHONY: up down direct help helpdoge \
		getnewaddress listaccounts importprivkey \
		generate balance listunspent gettransaction getrawtransaction \
		sendrawtransaction estimatefee sendfrom rpctest rpctestjq

# =============================================================================
# Docker Management Commands
# =============================================================================

# Start the Dogecoin node container
# Usage: make up [BUILD=1]
# Optional BUILD=1 flag rebuilds the Docker image
up:
	@if [ "$(BUILD)" = "1" ]; then \
		echo "Building new image..."; \
		docker build -t dogecoin-node .; \
	fi
	@echo "Starting container..."
	@docker run -d --name $(CONTAINER) -p $(RPC_PORT):$(RPC_PORT) dogecoin-node

# Stop and remove the container
down:
	docker rm -f $(CONTAINER)

# Help commands
help:
	@echo "Usage: make [command]"
	@echo "Commands:"
	@echo "  help                 - Show this help"
	@echo "  helpdoge             - Show help for a specific dogecoin-cli command"
	@echo "  direct               - Execute a command directly against the container"
	@echo "  ping                 - Ping the node"
	@echo "Docker management:"
	@echo "  up                   - Build and run the container"
	@echo "  down                 - Stop and remove the container"
	@echo "Address operations:"
	@echo "  getnewaddress        - Create a new address"
	@echo "  listaccounts         - List all accounts"
	@echo "  importprivkey        - Import a private key"
	@echo "Block operations:"
	@echo "  generate            - Generate 101 blocks"
	@echo "  balance             - Check account balance"
	@echo "  listunspent         - List unspent (UTXOs)"
	@echo "  gettransaction      - Get transaction details"
	@echo "  getrawtransaction   - Get raw transaction details"
	@echo "  sendrawtransaction  - Send a raw transaction"
	@echo "  estimatefee         - Estimate transaction fee"
	@echo "  sendfrom           - Send funds from an account to an address"
	@echo "RPC operations:"
	@echo "  rpctest            - Test RPC call"
	@echo "  rpctestjq          - Test RPC call with jq"

helpdoge:
	@read -p "Enter the command name (or press Enter for general help): " cmd; \
	if [ -n "$$cmd" ]; then \
		echo "Getting help for command: $$cmd"; \
		$(CLI) help "$$cmd"; \
	else \
		echo "Showing general help..."; \
		$(CLI) help; \
	fi

# Direct command execution
direct:
	@if [ -z "$(cmd)" ]; then \
		echo "Usage: make direct cmd=\"<command> [parameters...]\""; \
		echo "Example: make direct cmd=\"getbalance myaddress\""; \
		exit 1; \
	fi
	@echo "Running command: $(cmd)"
	@$(CLI) $(cmd)

# Ping the node
ping:
	@echo "Pinging the node..."
	data='{"jsonrpc": "1.0", "id":"curltest", "method": "ping", "params": []}'; \
	$(CURL_RPC) --data-binary "$$data" | jq 'if .error then error(.error.message) else .result end'

# Address Operations
# -----------------------------------------------------------------------------
# getnewaddress
#   Creates a new Dogecoin address for receiving payments
#
# Arguments:
#   account  (string, optional) DEPRECATED
#           The account name for the address. Default: ""
#
# Returns:
#   address  (string) The new dogecoin address
getnewaddress:
	@read -p "Enter the label for the new address: " label; \
	echo "Generating new address with label: $$label"; \
	$(CLI) getnewaddress "$$label"

# DEPRECATED - for testing only
listaccounts:
	@echo "Listing all accounts..."; \
	$(CLI) listaccounts

# importprivkey
#   Imports a private key to your wallet
#
# Arguments:
#   dogecoinprivkey  (string, required) The private key
#   label           (string, optional) An optional label
#   rescan          (boolean, optional) Rescan wallet for transactions
#   height          (numeric, optional) Starting block height for rescan
#
# Note: May take several minutes if rescan=true
importprivkey:
	@read -p "Enter the private key to import: " privkey; \
	read -p "Enter the label for the private key: " label; \
	echo "Importing private key: $$privkey"; \
	$(CLI) importprivkey $$privkey $$label

# Block and balance operations
# -----------------------------------------------------------------------------
# generate
#   Generates 101 blocks and pays rewards to the specified address
#
# Arguments:
#   addr  (string, required) The address to receive block rewards
generate:
	@read -p "Enter the address to receive block rewards: " addr; \
	echo "Generating 101 blocks and paying rewards to $$addr"; \
	$(CLI) generatetoaddress 101 $$addr

# balance
#   Checks the current wallet balance for a specified account
#
# Arguments:
#   account  (string, required) The account to check balance for
balance:
	@read -p "Enter the account to check balance: " account; \
	echo "Checking current wallet balance for $$account"; \
	$(CLI) getbalance $$account

# listunspent
#   Returns array of unspent transaction outputs
#   with between minconf and maxconf (inclusive) confirmations.
#   Optionally filter to only include txouts paid to specified addresses.
#
# Arguments:
#   minconf          (numeric, optional, default=1) The minimum confirmations to filter
#   maxconf          (numeric, optional, default=9999999) The maximum confirmations to filter
#   addresses      (string) A json array of dogecoin addresses to filter
#     [
#       "address"     (string) dogecoin address
#       ,...
#     ]
#   include_unsafe (bool, optional, default=true) Include outputs that are not safe to spend
#                  because they come from unconfirmed untrusted transactions or unconfirmed
#                  replacement transactions (cases where we are less sure that a conflicting
#                   transaction won't be mined).
#   query_options    (json, optional) JSON with query options
#     {
#       "minimumAmount"    (numeric or string, default=0) Minimum value of each UTXO in DOGE
#       "maximumAmount"    (numeric or string, default=unlimited) Maximum value of each UTXO in DOGE
#       "maximumCount"     (numeric or string, default=unlimited) Maximum number of UTXOs
#       "minimumSumAmount" (numeric or string, default=unlimited) Minimum sum value of all UTXOs in DOGE
#     }

# Result
# [                   (array of json object)
#   {
#     "txid" : "txid",          (string) the transaction id 
#     "vout" : n,               (numeric) the vout value
#     "address" : "address",    (string) the dogecoin address
#     "account" : "account",    (string) DEPRECATED. The associated account, or "" for the default account
#     "scriptPubKey" : "key",   (string) the script key
#     "amount" : x.xxx,         (numeric) the transaction output amount in DOGE
#     "confirmations" : n,      (numeric) The number of confirmations
#     "redeemScript" : n        (string) The redeemScript if scriptPubKey is P2SH
#     "spendable" : xxx,        (bool) Whether we have the private keys to spend this output
#     "solvable" : xxx          (bool) Whether we know how to spend this output, ignoring the lack of keys
#   }
#   ,...
# ]
listunspent:
	@read -p "Enter the address to list unspent (only check confirmed UTXOs): " addr; \
	if [ "$(rpc)" = "1" ]; then \
		echo "Listing unspent for (RPC) $$addr"; \
		data='{"jsonrpc": "1.0", "id":"curltest", "method": "listunspent", "params": [6,9999999,["'$$addr'"],false]}'; \
		$(CURL_RPC) --data-binary "$$data" | jq 'if .error then error(.error.message) else .result end'; \
	else \
		echo "Listing unspent for $$addr"; \
		$(CLI) listunspent 6 9999999 "[\"$$addr\"]" false; \
	fi

# gettransaction
#   Get detailed information about in-wallet transaction <txid>
#
# Arguments:
#   txid                  (string, required) The transaction id
#   include_watchonly     (bool, optional, default=false) Whether to include watch-only addresses in balance calculation and details[]

gettransaction:
	@read -p "Enter the transaction ID: " txid; \
	if [ "$(rpc)" = "1" ]; then \
		echo "Getting transaction details for $$txid"; \
		data='{"jsonrpc": "1.0", "id":"curltest", "method": "gettransaction", "params": ["'$$txid'"]}'; \
		$(CURL_RPC) --data-binary "$$data" | jq 'if .error then error(.error.message) else .result end'; \
	else \
		echo "Getting transaction details for $$txid"; \
		$(CLI) gettransaction $$txid; \
	fi

# getrawtransaction
#   Get transaction details in raw format
#
# NOTE: By default this function only works for mempool transactions. If the -txindex option is
# enabled, it also works for blockchain transactions.
# DEPRECATED: for now, it also works for transactions with unspent outputs.

# Return the raw transaction data.

# If verbose is 'true', returns an Object with information about 'txid'.
# If verbose is 'false' or omitted, returns a string that is serialized, hex-encoded data for 'txid'.

# Arguments:
#   txid      (string, required) The transaction id
#   verbose   (bool, optional, default=false) If false, return a string, otherwise return a json object
getrawtransaction:
	@read -p "Enter the transaction ID: " txid; \
	if [ "$(rpc)" = "1" ]; then \
		echo "Getting transaction details for $$txid"; \
		data='{"jsonrpc": "1.0", "id":"curltest", "method": "getrawtransaction", "params": ["'$$txid'",true]}'; \
		$(CURL_RPC) --data-binary "$$data" | jq 'if .error then error(.error.message) else .result end'; \
	else \
		echo "Getting transaction details for $$txid"; \
		$(CLI) getrawtransaction $$txid true; \
	fi

# sendrawtransaction
#   Submits raw transaction (serialized, hex-encoded) to local node and network.
#   Also see createrawtransaction and signrawtransaction calls.

# Arguments:
#   hexstring    (string, required) The hex string of the raw transaction)
#   allowhighfees    (boolean, optional, default=false) Allow high fees

# Result:
#   hex             (string) The transaction hash in hex
sendrawtransaction:
	@read -p "Enter the raw transaction: " rawtx; \
	if [ "$(rpc)" = "1" ]; then \
		echo "Sending raw transaction: $$rawtx"; \
		data='{"jsonrpc": "1.0", "id":"curltest", "method": "sendrawtransaction", "params": ["'$$rawtx'"]}'; \
		$(CURL_RPC) --data-binary "$$data" | jq 'if .error then error(.error.message) else .result end'; \
	else \
		echo "Sending raw transaction: $$rawtx"; \
		$(CLI) sendrawtransaction $$rawtx; \
	fi

# estimatefee
#   Estimates the approximate fee per kilobyte needed for a transaction to begin
#   confirmation within nblocks blocks. Uses virtual transaction size of transaction
#   as defined in BIP 141 (witness data is discounted).

# Arguments:
#   nblocks     (numeric, required)
# Result:
#   n              (numeric) estimated fee-per-kilobyte

# A negative value is returned if not enough transactions and blocks
# have been observed to make an estimate.
# -1 is always returned for nblocks == 1 as it is impossible to calculate
# a fee that is high enough to get reliably included in the next block.
estimatefee:
	@read -p "Enter the number of blocks to estimate fee for: " blocks; \
	echo "Estimating fee for $$blocks blocks"; \
	$(CLI) estimatefee $$blocks

# estimatesmartfee
#   Estimates the approximate fee per kilobyte needed for a transaction to begin
#   confirmation within nblocks blocks if possible and return the number of blocks
#   for which the estimate is valid. Uses virtual transaction size as defined
#   in BIP 141 (witness data is discounted).

# WARNING: This interface is unstable and may disappear or change!

# Estimates the approximate fee per kilobyte needed for a transaction to begin
# confirmation within nblocks blocks if possible and return the number of blocks
# for which the estimate is valid. Uses virtual transaction size as defined
# in BIP 141 (witness data is discounted).

# Arguments:
#   nblocks     (numeric)

# Result:
#   {
#     "feerate" : x.x,     (numeric) estimate fee-per-kilobyte (in BTC)
#     "blocks" : n         (numeric) block number where estimate was found
#   }

# A negative value is returned if not enough transactions and blocks
# have been observed to make an estimate for any number of blocks.
# However it will not return a value below the mempool reject fee.
estimatesmartfee:
	@read -p "Enter the number of blocks to estimate fee for: " blocks; \
	echo "Estimating fee for $$blocks blocks"; \
	$(CLI) estimatesmartfee $$blocks


# sendfrom
#   Sent an amount from an account to a dogecoin address.
#
# Arguments:
#   fromaccount       (string, required) The name of the account to send funds from. May be the default account using "".
#                       Specifying an account does not influence coin selection, but it does associate the newly created
#                       transaction with the account, so the account's balance computation and transaction history can reflect
#                       the spend.
#   toaddress         (string, required) The dogecoin address to send funds to.
#   amount                (numeric or string, required) The amount in DOGE (transaction fee is added on top).
#   minconf               (numeric, optional, default=1) Only use funds with at least this many confirmations.
#   comment           (string, optional) A comment used to store what the transaction is for. 
#   comment_to        (string, optional) An optional comment to store the name of the person or organization 
#                                     to which you're sending the transaction. This is not part of the transaction, 
#                                     it is just kept in your wallet.

# Result:
#   txid                 (string) The transaction id.
sendfrom:
	@read -p "Enter the address to send from account: " from; \
	read -p "Enter the address to send to address: " to; \
	read -p "Enter the amount to send: " amount; \
	echo "Sending $$amount from $$from to $$to"; \
	$(CLI) sendfrom $$from $$to $$amount

# RPC operations
# -----------------------------------------------------------------------------
# rpctest
#   Test external RPC call (getblockchaininfo)
rpctest:
	@echo "Testing external RPC call (getblockchaininfo)..."
	@$(CURL_RPC) --data-binary '{"jsonrpc": "1.0", "id":"curltest", "method": "getblockchaininfo", "params": [] }'

# rpctestjq
#   Test external RPC call (getblockchaininfo) with jq
rpctestjq:
	@echo "Testing external RPC call (getblockchaininfo)..."
	@$(CURL_RPC) --data-binary '{"jsonrpc": "1.0", "id":"curltest", "method": "getblockchaininfo", "params": [] }' | jq '.'


