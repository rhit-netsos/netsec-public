#
# Last updated: Wed 22 Nov 2023
#

# to make echo -e show up and look nice.
SHELL=bash

.PHONY: clean all

all: www

www:
	@echo -e '\033[1;32mBuilding website\033[0m'
	bundle exec jekyll build -q -I
	@echo -e '\033[1;32mCopying to remote server\033[0m'
	cd ./_site/ && rsync -e ssh -Paz --delete . netsos:/srv/www/html/courses/netsec && cd -
	@echo -e '\033[1;32mDone\033[0m'

serve:
	bundle exec jekyll serve -q -I -o -l -P 1234

background:
	tmux new -d -s netsec-server "bundle exec jekyll serve -q -I -o -l -P 1234"

kill:
	tmux kill-session -t netsec-server || true

restart: kill background

clean: kill
	bundle exec jekyll clean

