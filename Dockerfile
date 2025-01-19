FROM alpine AS builder-alist

WORKDIR /app/
RUN apk add --no-cache bash curl gcc git go musl-dev
COPY ./upstream-repo/go.mod ./upstream-repo/go.sum ./
RUN go mod download
COPY ./upstream-repo ./
RUN bash build.sh release docker


FROM alpine AS dist

COPY ./content /workdir/

ARG TARGETPLATFORM

ENV ALIST_PORT=61600
ENV ARIA2_PORT=61601
ENV QBT_WEBUI_PORT=61602
ENV ARIA2_TRACKER_UPDATE=enable

RUN apk add --no-cache --update curl runit tzdata \
    && wget -O - https://github.com/mayswind/AriaNg/releases/download/1.3.7/AriaNg-1.3.7.zip | busybox unzip -qd /workdir/ariang - \
    && wget -O - https://github.com/WDaan/VueTorrent/releases/latest/download/vuetorrent.zip | busybox unzip -qd /workdir - \
    && wget -O - https://github.com/bastienwirtz/homer/releases/latest/download/homer.zip | busybox unzip -qd /workdir/homer - \
    && cp /workdir/homer_conf/* /workdir/homer/assets/tools/ \
    && mv /workdir/homer_conf/homer.yml /workdir/homer/assets/config.yml \
    && sh /workdir/install.sh \
    && rm -r /workdir/install.sh /workdir/homer_conf \
    && chmod +x /workdir/service/*/run /workdir/service/*/log/run \
    && ln -s /workdir/service/* /etc/service/

COPY --from=builder-alist /app/bin/alist /usr/bin/

ENTRYPOINT ["runsvdir","/etc/service"]
