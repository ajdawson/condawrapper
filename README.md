# condawrapper

A set of wrappers for activating and deactivating
[conda](http://conda.pydata.org/docs/index.html) environments, inspired by
[virtualenvwrapper](http://virtualenvwrapper.readthedocs.org).


## Installation

Source the `condawrapper.sh` script:

    $ source condawrapper.sh


## Usage

Several commands are provided: `activate`, `deactivate`, `mkcondaenv` and
`rmcondaenv`. The `activate` command will activate the specified conda environment:

    $ activate my-env-name

The `deactivate` command deactivates the currently active conda environment:

    $ deactivate

The `mkcondaenv` command will create a new conda environment with a given name. Remaining
arguments are passed to the `conda create` command, and at least one package specification
must be provided. For example, to create an environment containing just Python 2:

    $ mkcondaenv my-env-name python=2

Any `conda create` options may be passed to `mkcondaenv` after the name of the environment:

    $ mkcondaenv my-env-name -c channel -y python=2 [package_spec...]

The `mkcondaenv` command will automatically create the environment and a condawrapper
configuration directory for the environment.

A complementary `rmcondaenv` command is also provided. Its function is to completely
remove a conda environment, including the configuration directory and all its contents:

    $ rmcondaenv my-env-name


### Environment hooks

The main reason for providing the wrapper is to allow the definition of
arbitrary hooks to be run when activating/deactivating an environment.
Four hooks are defined: `preactivate`, `postactivate`, `predeactivate` and
`postdeactivate`. The `preactivate` hook is run *before* the environment is
activated, and the `postactivate` hook is run after the environment is
activated. The deactivation hooks work analgously.

Hooks are just shell scripts that are sourced into the active shell, and are
specific to each environment. The default location for hooks is:

    $HOME/.condawrapper/<environment-name>

This can be changed by setting the variable `CONDAWRAPPER_HOME`, e.g.:

    $ CONDAWRAPPER_HOME=$HOME/path/to/condawrapper

which results in `condawrapper` looking for hooks in:

    $HOME/path/to/condawrapper/<environment-name>

### Example usage

I have a conda environment named `work`, and when I load this environment I
want to set an environment variable called `DATA_DIR`. Assuming I have already
sourced the `condawrapper.sh` script (in my ~/.bashrc most likely) I first need
to create a hooks directory for the `work` environment:

    $ mkdir $CONDAWRAPPER_HOME/work

Now I can define my hooks. I want to set a variable named `DATA_DIR`, and in
this case it doesn't matter if this happens before or after the environment is
activated, so I'll just use the `postactivate hook:

    $ echo "export DATA_DIR='/path/to/data'" >> $CONDAWRAPPER_HOME/work/postactivate

Now when I activate the `work` environment the `DATA_DIR` variable will be set.
I also want to make sure I clean up after the environment is deactivated, so I
will create a second hook to unset the `DATA_DIR` variable when the environment
is deactivated:

    $ echo "unset DATA_DIR" >> $CONDAWRAPPER_HOME/work/predeactivate

Now when the `work` environment is deactivated the environment variable
`DATA_DIR` is un-set:

```
    $ echo $DATA_DIR
    
    $ activate work
    $ echo $DATA_DIR
    /path/to/data
    $ deactivate
    $ echo $DATA_DIR
    
```


## Tab completion

The `activate`  and `rmcondaenv` commands support tab completion in bash, you just need to
source the file `condawrapper_completion.bash` in your shell:

    source condawrapper_completion.bash


## Problems/suggestions

Please use the [Github issue tracker](https://github.com/ajdawson/condawrapper/issues)
to report issues or suggest imporvements. Pull requests welcome.


## License

Released under an [MIT style license](http://opensource.org/licenses/MIT).
