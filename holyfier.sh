#!/bin/bash
if [ "$EUID" -ne 0 ]; then
    exit 1
fi

LOGO_PATH="/etc/lordhelop-logo.txt"
cat << 'EOF' > "$LOGO_PATH"
                 ...
                 :&;.
                .$$&&$.
                 :&;.
           .&&&&&&&&&&&&&:
                 :&;.
              +&;&;.
                .X&X;.
                  :&++.
                 ;&;.
                .;x+.
                :xxx+.
               :xxxxx;.
             .:+xxxxxx;.
            .++::xxxxxxx.
           .+xxxxx+xxxxxx.
          .+xxxxxxxxxxxxx+:
        .;xxxxxxxxxxxxxxxxx+:
       .+xxxxxxx:. .:xxxxxxxx.
      .xxxxxxxx:     .xxxxxxxx.
     .+xxxxxxx;.      :xxxxxxx+:.
    .+xxxxxxxx:       :xxxxxx+;:..
    +xxxxxxxxx;.      :xxxxxxxxx;.
  .xxxxx+;:.             ..;+xxxxx:
 .;:..                          ...;.
EOF

if [ -f /etc/os-release ]; then
    [ ! -f /etc/os-release.bak ] && cp /etc/os-release /etc/os-release.bak
    cat << 'EOF' > /etc/os-release
NAME="HolyArch"
PRETTY_NAME="HolyArch Linux"
ID=holyarch
ID_LIKE=arch
BUILD_ID=rolling
ANSI_COLOR="38;2;255;215;0"
HOME_URL="https://archlinux.org"
DOCUMENTATION_URL="https://archlinux.org"
SUPPORT_URL="https://archlinux.org"
BUG_REPORT_URL="https://github.com"
LOGO=lordhelop-logo
EOF
fi

echo "HolyArch \r (\l)" > /etc/issue
echo "HolyArch Linux" > /etc/arch-release

mkdir -p /etc/fastfetch
cat << EOF > /etc/fastfetch/config.jsonc
{
    "\$schema": "https://github.com",
    "logo": {
        "source": "$LOGO_PATH",
        "color": {
            "1": "yellow",
            "2": "yellow"
        },
        "padding": { "right": 4 }
    },
    "modules": [
        "title",
        "separator",
        "os",
        "host",
        "kernel",
        "uptime",
        "packages",
        "shell",
        "terminal",
        "cpu",
        "gpu",
        "memory",
        "colors"
    ]
}
EOF

HIJACK_BIN="/usr/local/bin/holyfier"
cat << 'EOF' > "$HIJACK_BIN"
#!/bin/bash
LOGO_PATH="/etc/lordhelop-logo.txt"
CALLED_AS=$(basename "$0")
case "$CALLED_AS" in
    neofetch|hyfetch)
        exec /usr/bin/"$CALLED_AS" --ascii "$LOGO_PATH" --ascii_colors 3 --os_arch "HolyArch" "$@"
        ;;
    fastfetch)
        exec /usr/bin/fastfetch -c /etc/fastfetch/config.jsonc "$@"
        ;;
    *)
        exec /usr/bin/fastfetch -c /etc/fastfetch/config.jsonc "$@"
        ;;
esac
EOF
chmod +x "$HIJACK_BIN"

ln -sf "$HIJACK_BIN" /usr/local/bin/fastfetch
ln -sf "$HIJACK_BIN" /usr/local/bin/neofetch
ln -sf "$HIJACK_BIN" /usr/local/bin/hyfetch

LORDHELP_BIN="/usr/local/bin/lordhelp"
cat << 'EOF' > "$LORDHELP_BIN"
#!/bin/bash
case "$1" in
    install) shift; exec sudo /usr/bin/pacman -S "$@" ;;
    remove)  shift; exec sudo /usr/bin/pacman -Rns "$@" ;;
    update|upgrade) exec sudo /usr/bin/pacman -Syu ;;
    search)  shift; exec /usr/bin/pacman -Ss "$@" ;;
    *) exec /usr/bin/pacman "$@" ;;
esac
EOF
chmod +x "$LORDHELP_BIN"
ln -sf "$LORDHELP_BIN" /usr/local/bin/pacman

PROFILE_SCRIPT="/etc/profile.d/lordhelop.sh"
cat << 'EOF' > "$PROFILE_SCRIPT"
#!/bin/bash
if [[ $- == *i* ]]; then
    if [ -x /usr/local/bin/fastfetch ]; then
        /usr/local/bin/fastfetch
    fi
fi
EOF
chmod +x "$PROFILE_SCRIPT"

for user_dir in /root /etc/skel /home/*; do
    [ -d "$user_dir" ] || continue
    B_PROF="${user_dir}/.bash_profile"
    if [ ! -f "$B_PROF" ] || ! grep -q ".bashrc" "$B_PROF"; then
        cat << 'EOF' >> "$B_PROF"
if [ -f ~/.bashrc ]; then
    . ~/.bashrc
fi
EOF
    fi
done

echo ""
echo "please reboot for changes to come in act"

