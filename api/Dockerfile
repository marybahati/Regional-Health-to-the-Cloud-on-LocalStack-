FROM node:20.19.5-alpine3.22@sha256:6178e78b972f79c335df281f4b7674a2d85071aae2af020ffa39f0a770265435

WORKDIR /app

COPY api/package.json /app/package.json
RUN npm install --omit=dev && chown -R node:node /app

COPY --chown=node:node api/ /app/

ENV BIND_HOST=0.0.0.0
ENV PORT=3002
EXPOSE 3002

USER node

HEALTHCHECK --interval=30s --timeout=5s --start-period=10s \
  CMD node -e "fetch('http://127.0.0.1:3002/healthz').then(r=>process.exit(r.ok?0:1)).catch(()=>process.exit(1))"

CMD ["node", "server.js"]
