{
  config,
  lib,
  pkgs,
  ...
}:
let
  piPackages = pkgs.importNpmLock.buildNodeModules {
    npmRoot = ../../../pkgs/pi-extensions;
    nodejs = pkgs.nodejs;
    derivationArgs.npmFlags = [ "--legacy-peer-deps" ];
  };

  stateDir = "${config.home.homeDirectory}/.local/state/pi-sandbox";
  piConfigDir = "${stateDir}/.pi/agent";
  innerPath = lib.makeBinPath [
    pkgs.pi-coding-agent
    pkgs.nodejs
    pkgs.coreutils
    pkgs.findutils
    pkgs.gnused
    pkgs.gnugrep
    pkgs.git
    pkgs.ripgrep
    pkgs.fd
    pkgs.jq
    pkgs.curl
    pkgs.socat
    pkgs.bash
    pkgs.which
  ];

  piInner = pkgs.writeShellApplication {
    name = "pi-inner";
    runtimeInputs = [
      pkgs.socat
      pkgs.curl
      pkgs.coreutils
    ];
    text = ''
      socat TCP-LISTEN:8080,bind=127.0.0.1,reuseaddr,fork UNIX-CONNECT:/run/pi-model/llama.sock >/tmp/socat.log 2>&1 &
      for ((attempt = 0; attempt < 30; attempt++)); do
        if curl --silent --fail --max-time 1 http://127.0.0.1:8080/models >/dev/null; then
          exec ${pkgs.pi-coding-agent}/bin/pi "$@"
        fi
        sleep 0.2
      done
      cat /tmp/socat.log >&2
      printf '%s\n' 'The sandbox could not connect to the local llama router.' >&2
      exit 1
    '';
  };

  piSandbox = pkgs.writeShellApplication {
    name = "pi";
    runtimeInputs = [
      pkgs.bubblewrap
      pkgs.coreutils
      pkgs.findutils
      pkgs.curl
      pkgs.systemd
    ];
    text = ''
      readonly state_dir=${lib.escapeShellArg stateDir}

      case "''${1-}" in
        install|update|remove|uninstall|config)
          printf '%s\n' "pi $1 is disabled in the sandbox. Edit the Nix package manifest and rebuild the Home Manager configuration instead." >&2
          exit 2
          ;;
      esac

      cwd=$(pwd -P)
      case "$cwd" in
        /|/run|/run/*|/nix|/nix/*|/etc|/etc/*|/usr|/usr/*|/bin|/bin/*|/sbin|/sbin/*|/lib|/lib/*|/lib64|/lib64/*|/dev|/dev/*|/proc|/proc/*|/sys|/sys/*|/boot|/boot/*|/var|/var/*|/root|/root/*|/snap|/snap/*|/lost+found|/lost+found/*)
          printf 'Refusing to run pi from protected system directory: %s\n' "$cwd" >&2
          exit 2
          ;;
      esac

      if ! sockets=$(find "$cwd" -type s -print -quit); then
        printf 'Could not safely inspect sockets under %s; refusing to run pi.\n' "$cwd" >&2
        exit 2
      fi
      if [ -n "$sockets" ]; then
        printf 'Refusing to run pi because the workspace contains a Unix socket: %s\n' "$sockets" >&2
        exit 2
      fi

      workspace_hash=$(printf '%s' "$cwd" | sha256sum)
      workspace_hash=''${workspace_hash%% *}
      runtime_dir="''${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"
      tunnel_socket="$runtime_dir/pi-llama/llama.sock"

      systemctl --user start pi-llama-tunnel.service
      ready=0
      for ((attempt = 0; attempt < 30; attempt++)); do
        if curl --silent --show-error --fail --noproxy '*' --max-time 1 \
          --unix-socket "$tunnel_socket" http://localhost/models >/dev/null 2>&1; then
          ready=1
          break
        fi
        sleep 1
      done
      if [ "$ready" -ne 1 ]; then
        printf 'The local llama tunnel did not become ready within 30 seconds.\n' >&2
        exit 1
      fi

      if [ -L /tmp/pi ]; then
        printf '%s\n' 'Refusing to use a symlink at /tmp/pi.' >&2
        exit 2
      fi
      install -d -m 0700 /tmp/pi
      if [ "$(stat -c %u /tmp/pi)" -ne "$(id -u)" ]; then
        printf '%s\n' 'Refusing to use /tmp/pi because it is owned by another user.' >&2
        exit 2
      fi
      temp_dir=$(mktemp -d /tmp/pi/pi.XXXXXXXXXX)
      mkdir -m 0700 "$temp_dir/runtime"
      cleanup() {
        rm -rf -- "$temp_dir"
      }
      trap cleanup EXIT HUP INT TERM

      bwrap \
        --unshare-user --unshare-net --unshare-pid --unshare-ipc --unshare-uts \
        --disable-userns --die-with-parent --clearenv \
        --dir /run \
        --dir /run/current-system \
        --ro-bind /nix/store /nix/store \
        --ro-bind /etc /etc \
        --ro-bind /usr /usr \
        --ro-bind /bin /bin \
        --ro-bind /lib64 /lib64 \
        --ro-bind /run/current-system/sw /run/current-system/sw \
        --proc /proc \
        --dev /dev \
        --dir /workspace \
        --dir "/workspace/$workspace_hash" \
        --bind "$cwd" "/workspace/$workspace_hash" \
        --chdir "/workspace/$workspace_hash" \
        --dir /home \
        --bind "$state_dir" /home/pi \
        --ro-bind "$runtime_dir/pi-llama" /run/pi-model \
        --bind "$temp_dir" /tmp \
        --setenv HOME /home/pi \
        --setenv PI_CODING_AGENT_DIR /home/pi/.pi/agent \
        --setenv LLAMA_BASE_URL http://127.0.0.1:8080 \
        --setenv ACP_AUTO_UPDATE 0 \
        --setenv PI_SKIP_VERSION_CHECK 1 \
        --setenv PI_TELEMETRY 0 \
        --setenv SHELL /bin/sh \
        --setenv TERM "''${TERM:-xterm-256color}" \
        --setenv LANG "''${LANG:-C.UTF-8}" \
        --setenv PATH ${lib.escapeShellArg innerPath} \
        --setenv XDG_RUNTIME_DIR /tmp/runtime \
        -- ${piInner}/bin/pi-inner "$@"
    '';
  };
in
{
  programs.pi-coding-agent = {
    enable = true;
    package = piSandbox;
    configDir = piConfigDir;
    settings.packages = [
      "${piPackages}/node_modules/billion-context"
      "${piPackages}/node_modules/@juicesharp/rpiv-ask-user-question"
      "${piPackages}/node_modules/pi-clean-tps"
    ];
  };

  home.activation.piSandboxStateDirs =
    lib.hm.dag.entryBetween [ "linkGeneration" ] [ "writeBoundary" ]
      ''
        $DRY_RUN_CMD install -d -m 0700 ${lib.escapeShellArg stateDir}
        $DRY_RUN_CMD install -d -m 0700 ${lib.escapeShellArg piConfigDir}
        $DRY_RUN_CMD chmod 0700 ${lib.escapeShellArg stateDir} ${lib.escapeShellArg piConfigDir}
      '';

  systemd.user.services.pi-llama-tunnel = {
    Unit = {
      Description = "On-demand SSH tunnel to the llama.cpp server";
    };
    Service = {
      ExecStart = "${pkgs.openssh}/bin/ssh -N -T -o BatchMode=yes -o ExitOnForwardFailure=yes -o StreamLocalBindUnlink=yes -o ServerAliveInterval=30 -o ServerAliveCountMax=3 -L %t/pi-llama/llama.sock:127.0.0.1:8080 mandu";
      Restart = "on-failure";
      RestartSec = "5s";
      RuntimeDirectory = "pi-llama";
      RuntimeDirectoryMode = "0700";
      RuntimeDirectoryPreserve = "yes";
    };
  };
}
