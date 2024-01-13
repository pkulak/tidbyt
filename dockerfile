FROM debian:latest

# install dependencies
RUN apt-get update && apt-get install -y curl

# install Pixlet
RUN curl -LO https://github.com/tidbyt/pixlet/releases/download/v0.22.4/pixlet_0.22.4_linux_amd64.tar.gz
RUN tar -xvf pixlet_0.22.4_linux_amd64.tar.gz
RUN chmod +x ./pixlet
RUN mv pixlet /usr/local/bin/pixlet

# add our files
COPY home.star /root/home.star
COPY update.sh /root/update.sh

# run with crond
CMD cron
CMD ["/root/update.sh"]

