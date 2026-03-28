#!/bin/sh

LOGTIME=$(date "+%Y-%m-%d %H:%M:%S")
LOG_FILE="/tmp/clash_update.txt"
MODELTYPE=$(uci get clash.config.download_core 2>/dev/null)
CORETYPE=$(uci get clash.config.dcore 2>/dev/null)
lang=$(uci get luci.main.lang 2>/dev/null)

write_log() {
	echo "  ${LOGTIME} - $1" > "$LOG_FILE"
}

map_clash_arch() {
	case "$1" in
		x86_64) echo "linux-amd64" ;;
		aarch64_cortex-a53|aarch64_generic) echo "linux-armv8" ;;
		arm_cortex-a7_neon-vfpv4) echo "linux-armv7" ;;
		mipsel_24kc) echo "linux-mipsle-softfloat" ;;
		mips_24kc) echo "linux-mips-softfloat" ;;
		riscv64) echo "linux-riscv64" ;;
		*) echo "linux-amd64" ;;
	esac
}

map_mihomo_arch() {
	case "$1" in
		x86_64) echo "linux-amd64-compatible" ;;
		aarch64_cortex-a53|aarch64_generic) echo "linux-arm64" ;;
		arm_cortex-a7_neon-vfpv4) echo "linux-armv7" ;;
		mipsel_24kc) echo "linux-mipsle-softfloat" ;;
		mips_24kc) echo "linux-mips-softfloat" ;;
		riscv64) echo "linux-riscv64" ;;
		*) echo "linux-amd64-compatible" ;;
	esac
}

fetch_latest_tag() {
	url="$1"
	wget -qO- "$url" | sed -n 's/.*"tag_name"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -n 1
}

install_binary() {
	tmpfile="$1"
	target="$2"
	mkdir -p "$(dirname "$target")"
	rm -f "$target"
	mv "$tmpfile" "$target"
	chmod 755 "$target"
}

rm -f /tmp/clash.gz /tmp/clash /usr/share/clash/core_down_complete 2>/dev/null
: > "$LOG_FILE"

if [ "$CORETYPE" = "1" ]; then
	TAG=$(fetch_latest_tag "https://api.github.com/repos/frainzy1477/clash_dev/releases/latest")
	ASSET="clash-$(map_clash_arch "$MODELTYPE").gz"
	URL="https://github.com/frainzy1477/clash_dev/releases/download/${TAG}/${ASSET}"
	TARGET="/etc/clash/clash"
	VERSION_FILE="/usr/share/clash/core_version"
elif [ "$CORETYPE" = "2" ]; then
	TAG=$(fetch_latest_tag "https://api.github.com/repos/MetaCubeX/mihomo/releases/latest")
	ASSET="mihomo-$(map_mihomo_arch "$MODELTYPE")-${TAG#v}.gz"
	URL="https://github.com/MetaCubeX/mihomo/releases/download/${TAG}/${ASSET}"
	TARGET="/usr/bin/clash-meta"
	VERSION_FILE="/usr/share/clash/clash_meta_version"
else
	TAG=$(fetch_latest_tag "https://api.github.com/repos/MetaCubeX/mihomo/releases/latest")
	ASSET="mihomo-$(map_mihomo_arch "$MODELTYPE")-${TAG#v}.gz"
	URL="https://github.com/MetaCubeX/mihomo/releases/download/${TAG}/${ASSET}"
	TARGET="/usr/bin/mihomo"
	VERSION_FILE="/usr/share/clash/mihomo_version"
fi

if [ -z "$TAG" ]; then
	write_log "Core version check failed"
	exit 1
fi

write_log "Starting core download"
if ! wget -q --no-check-certificate "$URL" -O /tmp/clash.gz; then
	write_log "Core download failed"
	exit 1
fi

if ! gunzip -f /tmp/clash.gz; then
	write_log "Core unzip failed"
	exit 1
fi

install_binary /tmp/clash "$TARGET"
printf '%s\n' "$TAG" > "$VERSION_FILE"
touch /usr/share/clash/core_down_complete
write_log "Core update successful"
