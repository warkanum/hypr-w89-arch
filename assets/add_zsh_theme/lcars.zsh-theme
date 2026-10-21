# LCARS prompt: rounded coloured segments. Colours come from
# ~/.config/hypr-w89/zsh-colors.zsh (written by theme.sh --zsh); defaults below.
zmodload zsh/nearcolor 2>/dev/null
: ${HW_BG:=#000000} ${HW_FG:=#ffcc99} ${HW_DIM:=#996633} ${HW_SEG1:=#ff9900} ${HW_SEG2:=#cc99cc} ${HW_SEG3:=#9999ff} ${HW_ERR:=#cc6666}

ZSH_THEME_GIT_PROMPT_PREFIX=" %F{$HW_SEG3}◖%K{$HW_SEG3}%F{$HW_BG} "
ZSH_THEME_GIT_PROMPT_SUFFIX=" %k%F{$HW_SEG3}◗%f"
ZSH_THEME_GIT_PROMPT_DIRTY="*"
ZSH_THEME_GIT_PROMPT_CLEAN=""

PROMPT='%F{$HW_SEG1}◖%K{$HW_SEG1}%F{$HW_BG} %n %k%F{$HW_SEG1}◗%f %F{$HW_SEG2}◖%K{$HW_SEG2}%F{$HW_BG} %~ %k%F{$HW_SEG2}◗%f$(git_prompt_info)
%(?:%F{$HW_SEG1}▶:%F{$HW_ERR}▶)%f '
RPROMPT='%F{$HW_DIM}%*%f'
