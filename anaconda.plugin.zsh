if [[ -z $ANACONDA ]] && (( ! $+commands[conda] )); then
    function anaconda_prompt_info() { }
else
    fpath+="${0:h}"
    # find the anaconda root
    if [[ -n $ANACONDA ]]; then
        anaconda_root=$ANACONDA
    else
        anaconda_root=$(dirname $(dirname =conda))
    fi
    anaconda_bin_dir=$anaconda_root/bin

    # activate an environment
    function conda-activate {
        local dir
        dir=$anaconda_root/envs/$1/bin
        if [[ ! -d $dir ]]; then
            echo "no such directory $dir" >&2
            return 1
        fi

        if [[ -n $CONDA_DEFAULT_ENV ]]; then
            conda-deactivate
        fi
        conda-root-off

        if [[ -z ${CONDA_QUIET+set} ]]; then # http://stackoverflow.com/a/13864829/344821
            echo "adding $dir to path" >&2
        fi
        path=($dir $path)
        export CONDA_DEFAULT_ENV=$1
    }
    # deactivate the current environment
    function conda-deactivate {
        if [[ -n $CONDA_DEFAULT_ENV ]]; then
            local dir
            dir=$anaconda_root/envs/$CONDA_DEFAULT_ENV/bin
            if [[ -z ${CONDA_QUIET+set} ]]; then
                echo "dropping $dir from path"
            fi
            path[$path[(i)$dir]]=()
            unset CONDA_DEFAULT_ENV
        fi
    }

    # activate the conda root dir
    function conda-root-on {
        if [[ -z ${CONDA_QUIET+set} ]]; then
            echo "adding $anaconda_bin_dir to path"
        fi
        get-first-conda-index
        path[$(( $first_conda_index + 1)),0]=$anaconda_bin_dir
    }
    # deactivate the conda root dir
    function conda-root-off {
        local x
        x=$path[(i)$anaconda_bin_dir]
        if [[ $x -le $#path ]]; then
            if [[ -z ${CONDA_QUIET+set} ]]; then
                echo "dropping $anaconda_bin_dir from path"
            fi
            path[$x]=()
        fi
    }

    # make conda cmd always available even when not active,
    # and add our activation stuff to it
    function conda {
        if [[ $1 == "activate" ]]; then
            conda-activate $2
        elif [[ $1 == "deactivate" ]]; then
            conda-deactivate
            conda-root-on
        elif [[ $1 == "on" || $1 == "root-on" ]]; then
            conda-root-on
        elif [[ $1 == "root-off" ]]; then
            conda-root-off
        elif [[ $1 == "off" ]]; then
            conda-deactivate
            conda-root-off
        else
            $anaconda_bin_dir/conda $*
        fi
        rehash
    }

    # get the first index of a conda entry in the path
    # must be a fancy zsh way to do this, right?
    function get-first-conda-index {
        first_conda_index=0
        local x i
        for x in $path; do
            i=$(( i + 1))
            if [[ $x == "$anaconda_root"/* ]]; then
                first_conda_index=$i
                return 0
            fi
        done
        first_conda_index=0
        return 1
    }

    # any conda envs in path?
    function no-conda-active {
        get-first-conda-index
        return $first_conda_index
    }

    # goes in da prompt
    function anaconda_prompt_info() {
        if [[ -n $CONDA_DEFAULT_ENV ]]; then
            echo "%{$fg[cyan]%}$CONDA_DEFAULT_ENV "
        elif no-conda-active; then
            echo "%{$fg[cyan]%}no-conda "
        fi
    }
fi
