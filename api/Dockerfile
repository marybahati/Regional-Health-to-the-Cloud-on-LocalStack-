# syntax=docker/dockerfile:1.7

# Pin by digest. Bump only in a reviewed PR — never FROM ...:latest.
FROM node:20.19.5-alpine3.22@sha256:6178e78b972f79c335df281f4b7674a2d85071aae2af020ffa39f0a770265435 AS deps
WORKDIR /app
COPY api/package.json api/package-lock.json ./
RUN npm ci --omit=dev

FROM node:20.19.5-alpine3.22@sha256:6178e78b972f79c335df281f4b7674a2d85071aae2af020ffa39f0a770265435
RUN apk upgrade --no-cache \
 && apk add --no-cache nginx wget \
 && rm -rf /usr/local/lib/node_modules /opt/yarn* \
      /usr/local/bin/npm /usr/local/bin/npx /usr/local/bin/yarn /usr/local/bin/corepack \
 && adduser -D -u 10001 app \
 && mkdir -p /var/cache/nginx /var/log/nginx /var/lib/nginx/tmp /tmp /etc/app /app \
 && chown -R app:app /var/cache/nginx /var/log/nginx /var/lib/nginx /tmp /etc/app /app /etc/nginx
WORKDIR /app
COPY --from=deps --chown=app:app /app/node_modules /app/node_modules
COPY --chown=app:app api/package.json /app/package.json
COPY --chown=app:app api/src /app/src
COPY --chown=app:app api/nginx.conf /etc/nginx/nginx.conf
COPY --chown=app:app api/entrypoint.sh /app/entrypoint.sh
RUN chmod 0755 /app/entrypoint.sh

ENV NODE_ENV=production
ENV PORT=3000
ENV BIND_HOST=127.0.0.1
USER app
EXPOSE 8080 3000
ENTRYPOINT ["/app/entrypoint.sh"]
