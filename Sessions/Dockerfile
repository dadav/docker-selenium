# !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
# NOTE: DO *NOT* EDIT THIS FILE.  IT IS GENERATED.
# PLEASE UPDATE Dockerfile.txt INSTEAD OF THIS FILE
# !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
FROM seleniarm/base:4.1.0-prerelease-20211105
LABEL authors=sj26

USER 1200

#========================
# Selenium SessionMap Configuration
#========================

EXPOSE 5556

COPY start-selenium-grid-sessions.sh \
    /opt/bin/

COPY selenium-grid-sessions.conf /etc/supervisor/conf.d/
