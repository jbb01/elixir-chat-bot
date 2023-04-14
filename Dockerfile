FROM elixir:1.14.4-alpine AS builder

RUN mkdir -p /opt/chat_bot
WORKDIR /opt/chat_bot

RUN mix local.hex --force
RUN mix local.rebar --force

COPY mix.exs mix.lock /opt/chat_bot/
RUN mix deps.get
RUN mix deps.compile

ADD . .
ENV MIX_ENV=prod
RUN mix release

FROM alpine:3.17.3

RUN apk add --update bash openssl libstdc++
RUN mkdir -p /opt/chat_bot
WORKDIR /opt/chat_bot

COPY --from=builder /opt/chat_bot/_build/prod/rel/chat_bot /opt/chat_bot/

ENTRYPOINT ./bin/chat_bot start
