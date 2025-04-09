test -d .venv && exit 0
python3 -m venv .venv
. .venv/bin/activate
pip3 install -q -r requirements.txt
