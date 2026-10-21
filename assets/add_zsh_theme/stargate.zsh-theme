# Stargate prompt: gate glyph, user, path, git. Colours come from
# ~/.config/hypr-w89/zsh-colors.zsh (written by theme.sh --zsh); defaults below.
zmodload zsh/nearcolor 2>/dev/null
: ${HW_ACCENT:=#7fd4ff} ${HW_FG:=#d8e6f2} ${HW_DIM:=#5f7a90} ${HW_PATH:=#5fb3ff} ${HW_ERR:=#da4453}

ZSH_THEME_GIT_PROMPT_PREFIX=" %F{$HW_DIM}on%f %F{$HW_ACCENT}"
ZSH_THEME_GIT_PROMPT_SUFFIX="%f"
ZSH_THEME_GIT_PROMPT_DIRTY=" %F{$HW_ERR}✗%f"
ZSH_THEME_GIT_PROMPT_CLEAN=" %F{$HW_ACCENT}✓%f"

PROMPT='%F{$HW_ACCENT}◉%f %F{$HW_FG}%n%F{$HW_DIM}@%m%f %F{$HW_PATH}%~%f$(git_prompt_info)
%(?:%F{$HW_ACCENT}❯:%F{$HW_ERR}❯)%f '
RPROMPT='%F{$HW_DIM}%*%f'
