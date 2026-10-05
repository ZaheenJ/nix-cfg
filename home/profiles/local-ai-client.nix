{
  config,
  ...
}:
let
  routerUrl = "http://127.0.0.1:8080";
  qwen38Byteshape = "byteshape/Qwen3.8-27B-GGUF:IQ4_XS";
  qwen38Unsloth = "unsloth/Qwen3.8-27B-GGUF:IQ4_XS";
  qwen35 = "unsloth/Qwen3.5-9B-GGUF:Q5_K_M";
  qwen38Compaction = {
    reserveTokens = 8192;
    keepRecentTokens = 8192;
  };
  qwen38Override = {
    contextWindow = 32768;
    reasoning = true;
    thinkingLevelMap = {
      off = "off";
      minimal = null;
      low = "low";
      medium = "medium";
      high = null;
      xhigh = "xhigh";
      max = null;
    };
    compat = {
      thinkingFormat = "chat-template";
      chatTemplateKwargs = {
        enable_thinking."$var" = "thinking.enabled";
        preserve_thinking = true;
        reasoning_effort = {
          "$var" = "thinking.effort";
          omitWhenOff = true;
        };
      };
    };
  };
in
{
  programs.pi-coding-agent = {
    enable = true;

    settings = {
      defaultProvider = "llama.cpp";
      defaultModel = qwen38Byteshape;
      modelThinkingLevels = {
        "llama.cpp/${qwen38Byteshape}" = "xhigh";
        "llama.cpp/${qwen38Unsloth}" = "xhigh";
        "llama.cpp/${qwen35}" = "medium";
      };
      compaction.modelOverrides = {
        "llama.cpp/${qwen38Byteshape}" = qwen38Compaction;
        "llama.cpp/${qwen38Unsloth}" = qwen38Compaction;
      };
    };

    models.providers."llama.cpp".modelOverrides = {
      "${qwen38Byteshape}" = qwen38Override;
      "${qwen38Unsloth}" = qwen38Override;
      "${qwen35}" = {
        contextWindow = 131072;
        reasoning = true;
        thinkingLevelMap = {
          off = "off";
          minimal = null;
          low = null;
          medium = "medium";
          high = null;
          xhigh = null;
          max = null;
        };
        compat.thinkingFormat = "qwen-chat-template";
      };
    };
  };

  home.file."${config.programs.pi-coding-agent.configDir}/settings.json".force = true;
  home.file."${config.programs.pi-coding-agent.configDir}/models.json".force = true;

  home.sessionVariables = {
    LLAMA_BASE_URL = routerUrl;
    ACP_AUTO_UPDATE = "0";
  };

  programs.nushell.extraEnv = ''
    $env.LLAMA_BASE_URL = "${routerUrl}"
    $env.ACP_AUTO_UPDATE = "0"
  '';
}
