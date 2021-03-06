# Based on https://github.com/plone/volto/blob/master/entrypoint.sh

FROM node:10-jessie as build

ARG NPM_CONFIG_REGISTRY
ARG MAX_OLD_SPACE_SIZE=8192

ENV NODE_OPTIONS=--max_old_space_size=$MAX_OLD_SPACE_SIZE
ENV CYPRESS_INSTALL_BINARY=0
ENV NODE_ENV=development

RUN apt-get update -y \
 && apt-get install -y git bsdmainutils vim-nox mc \
 && rm -rf /var/lib/apt/lists/*

RUN npm i -g mrs-developer

WORKDIR /opt/frontend/

COPY . .
# RUN chmod +x optimize_node_modules.sh

RUN mkdir -p /opt/frontend/src/develop
RUN chown -R node /opt/frontend
USER node

RUN echo "prefix = \"/home/node\"\n" > /home/node/.npmrc
RUN rm -rf node_modules .git

RUN missdev
RUN make activate-all
RUN NPM_CONFIG_REGISTRY=$NPM_CONFIG_REGISTRY npm ci
RUN RAZZLE_API_PATH=VOLTO_API_PATH RAZZLE_INTERNAL_API_PATH=VOLTO_INTERNAL_API_PATH npm run build

# Second stage build
FROM node:10-jessie

RUN apt-get update -y \
 && apt-get install -y git bsdmainutils vim-nox mc \
 && rm -rf /var/lib/apt/lists/*

WORKDIR /opt/frontend/

COPY entrypoint-prod.sh /opt/frontend/entrypoint.sh
RUN chmod +x entrypoint.sh

COPY . .
RUN rm -rf node_modules

COPY --from=build /opt/frontend/public ./public
COPY --from=build /opt/frontend/build ./build

RUN chown -R node /opt/frontend

USER node

WORKDIR /opt/frontend/

RUN mkdir -p /opt/frontend/src/develop
RUN echo "" >> /opt/frontend/docker-image.txt

COPY scripts .

ENV CYPRESS_INSTALL_BINARY=0
ENV NODE_ENV=production

RUN NPM_CONFIG_REGISTRY=$NPM_CONFIG_REGISTRY npm ci

ENTRYPOINT ["/opt/frontend/entrypoint.sh"]

EXPOSE 3000 3001 4000 4001

CMD npm run start:prod
