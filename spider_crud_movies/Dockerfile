FROM llllollooll/zig:master AS builder
WORKDIR /app
COPY . .
RUN zig build -Doptimize=ReleaseSmall

FROM debian:bookworm-slim
WORKDIR /app
COPY --from=builder /app/zig-out/bin/spider_crud_movies /app/spider_crud_movies
COPY --from=builder /app/public /app/public
EXPOSE 3000
CMD ["./spider_crud_movies"]
