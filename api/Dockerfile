FROM node:20.19.5-alpine3.22

WORKDIR /app

COPY api/package.json /app/package.json
RUN npm install --omit=dev && chown -R node:node /app

COPY --chown=node:node api/ /app/

ENV BIND_HOST=0.0.0.0
ENV PORT=3002
EXPOSE 3002

USER node

CMD ["node", "server.js"]
