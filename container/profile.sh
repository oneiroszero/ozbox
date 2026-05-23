case ":$PATH:" in
    *:"$HOME/.local/bin":*) ;;
    *) PATH="$PATH:$HOME/.local/bin" ;;
esac

case ":$PATH:" in
    *:/opt/pipx/bin:*) ;;
    *) PATH="$PATH:/opt/pipx/bin" ;;
esac

export PATH
export EDITOR="${EDITOR:-vi}"

alias ll='ls -lah'
alias sfwpip='sfw pip'
alias sfwnpm='sfw npm'
