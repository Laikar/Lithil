LITHIL_USER := lithil
LITHIL_HOME := /opt/lithil

LICTL := /usr/local/bin/lictl
LITHIL := /usr/local/bin/lithil
LITHIL_INIT_D := /etc/init.d/lithil
LITHIL_SERVICE := /etc/systemd/system/lithil.service

UPDATE_D := $(wildcard update.d/*)

.PHONY: install update clean

install: update
	useradd --system --user-group --create-home -K UMASK=0022 --home $(LITHIL_HOME) $(LITHIL_USER)
	if which systemctl; then \
		systemctl -f enable lithil.service; \
	else \
		ln -s $(LITHIL) $(LITHIL_INIT_D); \
		update-rc.d lithil defaults; \
	fi

update:
	install -m 0755 lictl.sh $(LICTL)
	install -m 0755 lithil.sh $(LITHIL)
	if which systemctl; then \
		install -m 0644 lithil.service $(LITHIL_SERVICE); \
	fi
	@for script in $(UPDATE_D); do \
		sh $$script; \
	done; true;

clean:
	if which systemctl; then \
		systemctl -f disable lithil.service; \
		rm -f $(LITHIL_SERVICE); \
	else \
		update-rc.d lithil remove; \
		rm -f $(LITHIL_INIT_D); \
	fi
