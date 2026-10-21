# Minimal Stargate prompt: path, git, chevron. Colours come from
# ~/.config/hypr-w89/zsh-colors.zsh (written by theme.sh --zsh); defaults below.
zmodload zsh/nearcolor 2>/dev/null
: ${HW_ACCENT:=#7fd4ff} ${HW_DIM:=#5f7a90} ${HW_PATH:=#5fb3ff} ${HW_ERR:=#da4453}

ZSH_THEME_GIT_PROMPT_PREFIX=" %F{$HW_DIM}"
ZSH_THEME_GIT_PROMPT_SUFFIX="%f"
ZSH_THEME_GIT_PROMPT_DIRTY="*"
ZSH_THEME_GIT_PROMPT_CLEAN=""

PROMPT='%F{$HW_PATH}%~%f$(git_prompt_info) %(?:%F{$HW_ACCENT}❯:%F{$HW_ERR}❯)%f '
