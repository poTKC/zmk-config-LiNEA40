# ローカルビルド (Docker / colima が必要)
#   make            左右 + settings_reset をビルド
#   make right      右手 (central, DYA Studio 有効) のみ
#   make update     west.yml の依存を更新
#   make clean      ビルド成果物を削除
# 成果物は ./firmware/*.uf2 にコピーされます

CONFIG_DIR = $(CURDIR)/config
WS        ?= $(HOME)/zmk-dya-ws
IMAGE     ?= zmkfirmware/zmk-build-arm:stable
OUT        = $(CURDIR)/firmware

DOCKER = docker run --rm -v $(WS):/ws -v $(CONFIG_DIR):/ws/config -w /ws $(IMAGE) \
	sh -c 'git config --global --add safe.directory "*" && $(1)'

WEST_BUILD = west zephyr-export >/dev/null && \
	west build -p -s zmk/app -d build/$(1) -b xiao_ble//zmk $(3) -- \
	-DZMK_CONFIG=/ws/config -DSHIELD="$(2)"

.PHONY: all left right reset update clean

all: left right reset

$(WS)/.west:
	mkdir -p $(WS)
	$(call DOCKER,west init -l config && west update --narrow -o=--depth=1)

update: | $(WS)/.west
	$(call DOCKER,west update --narrow -o=--depth=1)

left: | $(WS)/.west
	$(call DOCKER,$(call WEST_BUILD,left,LiNEA40_left rgbled_adapter,))
	mkdir -p $(OUT) && cp $(WS)/build/left/zephyr/zmk.uf2 $(OUT)/LiNEA40_left.uf2

right: | $(WS)/.west
	$(call DOCKER,$(call WEST_BUILD,right,LiNEA40_right rgbled_adapter,-S studio-rpc-usb-uart))
	mkdir -p $(OUT) && cp $(WS)/build/right/zephyr/zmk.uf2 $(OUT)/LiNEA40_right.uf2

reset: | $(WS)/.west
	$(call DOCKER,$(call WEST_BUILD,reset,settings_reset,))
	mkdir -p $(OUT) && cp $(WS)/build/reset/zephyr/zmk.uf2 $(OUT)/settings_reset.uf2

clean:
	rm -rf $(WS)/build $(OUT)
