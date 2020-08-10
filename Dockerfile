from ubuntu:18.04

ENV ORIGIN lenovo1.cf.felsing.net
ENV JWT_SECRET=HnKDSQXcvMABuBp8AMwJ8aWNNTnHPI0z

ADD ./server.key /home/user_skf/server.key
ADD ./server.pem /home/user_skf/server.pem

run DEBIAN_FRONTEND=noninteractive apt-get update
run DEBIAN_FRONTEND=noninteractive apt-get install -q -y apt-utils
run DEBIAN_FRONTEND=noninteractive apt-get install -q -y \
  locales

RUN sed -i -e 's/# de_DE.UTF-8 UTF-8/de_DE.UTF-8 UTF-8/' /etc/locale.gen && \
    locale-gen
ENV LANG de_DE.UTF-8
ENV LANGUAGE de_DE:de
ENV LC_ALL de_DE.UTF-8

RUN \
  ln -fs /usr/share/zoneinfo/Europe/Berlin /etc/localtime \
  && apt install -q -y tzdata \
  && dpkg-reconfigure --frontend noninteractive tzdata

run DEBIAN_FRONTEND=noninteractive \
  apt update \
  && apt -q -y full-upgrade \
  && apt -q -y install software-properties-common

run DEBIAN_FRONTEND=noninteractive \
  apt update \
  && apt -q -y install \
    python3.6 \
    python3-pip \
    python3-nltk

run DEBIAN_FRONTEND=noninteractive apt -q -y install \
  sudo \
  git-core \
  curl \
  npm \
  nginx

RUN \
  npm install n -g \
  && n 12.18.3 \
  && if [ ! -e "/usr/bin/node" ]; then ln -s  /usr/bin/nodejs /usr/bin/node; fi
RUN apt purge -y -q npm nodejs && apt autoremove -y -q --purge
RUN npm install -g @angular/cli

#ARG SOURCE=blabla1337
ARG SOURCE=ip6li
run \
  cd / \
  && git clone https://github.com/${SOURCE}/skf-flask

RUN \
  rm /etc/nginx/sites-enabled/default \
  && cp /skf-flask/installations/local/site-tls.conf /etc/nginx/sites-enabled/default
COPY ./server.key /skf-flask/server.key
COPY ./server.pem /skf-flask/server.pem

run \
  groupadd skf \
  && useradd -d /skf-flask -s /bin/bash -g skf skf

run chown -R skf:skf /skf-flask

USER skf
RUN \
  cd /skf-flask \
  && pip3 install -r requirements.txt \
  && cd ./Angular \
  && npm install \
  && ng build --aot --configuration=production

ENV myhost lenovo1.cf.felsing.net
RUN \
  perl -pi -e "s/JWT_SECRET = ''/JWT_SECRET = 'SZKvp94kVlaKYiS63js4YN5vQ9vuULDx'/" /skf-flask/skf/settings.py \
  && perl -pi -e "s/\*/https:\/\/${myhost}/" /skf-flask/skf/settings.py \
  && perl -pi -e "s/http:\/\/127.0.0.1:8888\/api/https:\/\/${myhost}\/api/" /skf-flask/Angular/src/environments/environment.prod.ts \
  && perl -pi -e "s/localhost/${myhost}/" /skf-flask/installations/local/skf-angular.sh

COPY ./entrypoint.sh /entrypoint.sh

USER root
RUN \
  chown skf:skf /entrypoint.sh \
  && chmod 700 /entrypoint.sh

ENTRYPOINT [ "/entrypoint.sh" ]

