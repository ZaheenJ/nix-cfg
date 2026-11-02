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
    derivationArgs = {
      npmFlags = [ "--legacy-peer-deps" ];
      postInstall = ''
        node ${../../../pkgs/pi-extensions}/patch-output-budget.mjs "$out/node_modules/billion-context"
      '';
    };
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
    pkgs.poppler-utils
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
      readonly inner_path=${lib.escapeShellArg innerPath}
      readonly pi_inner=${lib.escapeShellArg "${piInner}/bin/pi-inner"}
      ${builtins.readFile ./pi-sandbox/pi.sh}
    '';
  };
in
{
  programs.pi-coding-agent = {
    enable = true;
    package = piSandbox;
    configDir = piConfigDir;
    settings.extensions = [ "${./pi-prompt-tps.ts}" ];
    settings.packages = [
      "${piPackages}/node_modules/billion-context"
      "${piPackages}/node_modules/@juicesharp/rpiv-ask-user-question"
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
