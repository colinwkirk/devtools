#!/bin/bash


print_usage() {
  cat << 'EOF'
Usage: newenv.sh -p project_name -b -h
Description: Set up a Python virtual environment, optionally with Flask installed with a simple template project
Args:
  -p <project name>
     Project name: Will be used as directory for virtual environment
  -v <version number>
     Python version: Defaults to 3.7 (Valid options include 2, 2.7, 3, 3.7.)
  -g
     Run `git init` in project directory
  -f
     Install Flask: Setup Flask and a simple template project
  -b
     Setup bashrc: When specified, will add line to source active.sh in user's bashrc
  -h
     Print usage: Print this message and exit
EOF
  exit 0
}


setup_env() {
  dir="$1"
  py_version="$2"
  git_init="$3"
  mkdir "$dir"
  cd "$dir"


  pip install virtualenv
  [ -n "$git_init" ] && git init
  if [ "$py_version" = "2" ]; then
    virtualenv env
  else
    python$py_version -m venv env
  fi
  source env/bin/activate

  wget https://raw.githubusercontent.com/realpython/flask-by-example/master/.gitignore || echo "Unable to download default .gitignore, good example available at https://raw.githubusercontent.com/realpython/flask-by-example/master/.gitignore"
  pip install --upgrade pip
  pip install python-dotenv
}

setup_flask_env() {
  working_dir="$1"
  pip install Flask
  pip freeze > "$working_dir"/requirements.txt
  cat << 'EOF' > "$working_dir"/app.py
from flask import Flask
import os

app = Flask(__name__)
app.config.from_object(os.environ['APP_SETTINGS'])
print(os.environ['APP_SETTINGS'])

@app.route('/')
def hello():
    return "Hello World!"

@app.route('/<name>')
def hello_name(name):
    return "Hello {}!".format(name)

if __name__ == '__main__':
    app.run()

EOF

  cat << 'EOF' > "$working_dir"/config.py
import os
basedir = os.path.abspath(os.path.dirname(__file__))


class Config(object):
    DEBUG = False
    TESTING = False
    CSRF_ENABLED = True
    SECRET_KEY = 'this-really-needs-to-be-changed'


class ProductionConfig(Config):
    DEBUG = False


class StagingConfig(Config):
    DEVELOPMENT = True
    DEBUG = True


class DevelopmentConfig(Config):
    DEVELOPMENT = True
    DEBUG = True


class TestingConfig(Config):
    TESTING = True
EOF
}

setup_autoenv() {

  pip install autoenv

  cat << 'EOF' > "$working_dir"/.env
source env/bin/activate
export APP_SETTINGS="config.DevelopmentConfig"
EOF

  if [ -n "$setup_bashrc" ]; then
    echo "source `which activate.sh`" >> ~/.bashrc
  fi

  printf "\n******************************\nRun this command to make sure your environment is set up:\nsource ~/.bashrc\n******************************\n"
}

setup_bashrc=
setup_flask=
git_init=
py_version="3.7"
while getopts ":p:v:fbgh" OPT; do
    case "${OPT}" in
        p)
            dir=("$OPTARG")
            ;;
        v)
            py_version=("$OPTARG")
            ;;
        b)
            setup_bashrc="True"
            ;;
        f)
            setup_flask="True"
            ;;
        g)
            git_init="True"
            ;;
        h)  print_usage
            #unfortunately can't use fallthrough since I usually run this on osx which only has bash 3.something
            ;;
        *)  print_usage
            ;;
    esac
done

[ -z "$dir" ] && printf "\n******************************\nERROR: No directory/project name supplied, exiting\n******************************\n" && exit 1

if [[ "$py_version" = "2.7" || "$py_version" = "2" ]]; then
  py_version="2"
  [ -n "$setup_flask" ] && printf "\n******************************\nWARNING: You have specified a Python2 virtual environment to install Flask into; it is highly recommended you use the latest version of Python3 for use with Flask.\n******************************\n"
elif [[ ! $(which python$py_version) ]]; then
  printf "\n******************************\nERROR: Invalid Python version $py_version specified\n******************************\n"
  print_usage
fi


working_dir="$PWD/$dir"
setup_env "$dir" "$py_version" "$git_init"
[ -n "$setup_flask" ] && setup_flask_env "$working_dir"
deactivate
setup_autoenv "$working_dir"

printf "INFO: To exit virtual environment, use the command \`deactivate\`\n"
