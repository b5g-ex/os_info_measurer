$(info $(MIX_APP_PATH))

PRIV_DIR = $(MIX_APP_PATH)/priv
A_OUT = $(PRIV_DIR)/measurer

all: $(PRIV_DIR) build

build: Makefile src/test_caller.cpp
	g++ -std=c++17 src/main.cpp -lpthread -o $(A_OUT)
	g++ src/test_caller.cpp -o src/test_caller

test: build
	./src/test_caller
	python3 ./src/test_caller.py

$(PRIV_DIR):
	@mkdir -p $@

clean:
	rm -rf $(A_OUT)
	rm -rf ./src/test_caller
