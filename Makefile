# for not calling from mix compile
# if calling from mix compile, MIX_APP_PATH is defined
MIX_APP_PATH ?= _build/dev/lib/os_info_measurer

$(info $(MIX_APP_PATH))

PRIV_DIR = $(MIX_APP_PATH)/priv
A_OUT = $(PRIV_DIR)/measurer

all: $(PRIV_DIR) build

build: Makefile src/test_caller.cpp
	g++ -std=c++20 -Wall -Wextra -Wpedantic -Werror src/main.cpp -lpthread -o $(A_OUT)
	g++ -std=c++20 -Wall -Wextra -Wpedantic -Werror src/test_caller.cpp -o src/test_caller

test: build
	./src/test_caller
	python3 ./src/test_caller.py

$(PRIV_DIR):
	@mkdir -p $@

clean:
	rm -rf $(A_OUT)
	rm -rf ./src/test_caller
