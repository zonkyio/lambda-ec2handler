help:
	@echo " works on Linux/OSX/BSD"
	@echo " --------------------------------------------------------------------------------"
	@echo " info		... detail informations"
	@echo " build      	... prepare ./files/python36_env.zip (require pip3)"
	@echo ""
	@echo "For more info go to README.md"


build:
	@echo "Build ./files/python36_env.zip required by terraform module"
	rm -rf tmp_pyenv || @echo "cleanup before build"
	pip3 install virtualenv
	virtualenv tmp_pyenv
	sh tmp_pyenv/bin/activate
	pip3 install -r files/source/requirements.txt
	cd tmp_pyenv &&	zip -r ../files/python36_env.zip .
	rm -rf tmp_pyenv
	@echo "DONE"


info:
	cat README.md
