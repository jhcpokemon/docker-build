###
# STAGE: builder
# 基于官方 builder stage，改为自包含构建（直接从源码编译）
#
# 相较官方的变更：
#   1. 移除 builder-entrypoint.sh 入口模式，改为 RUN 内联构建
#   2. 新增 git clone 拉取源码
#   3. [核心修复] ENV RUSTFLAGS="-C target-cpu=x86-64"
#      官方二进制默认启用 SSE4.2/POPCNT 等 x86-64-v2 指令
#      此参数将指令集降回 baseline x86-64，兼容旧 CPU
###

FROM docker.io/rockylinux/rockylinux:9@sha256:53f4c6dcb34e1403bd93207351f0af9a593610faeb7165cb8a037346765199b0 AS builder

RUN dnf install -y gcc-toolset-13 git cmake llvm-toolset patch zlib-devel python3.11 openssl-devel

ENV OPENSSL_NO_VENDOR=1

ENV RUSTUP_UPDATE_ROOT=https://mirrors.tuna.tsinghua.edu.cn/rustup/rustup
ENV RUSTUP_DIST_SERVER=https://mirrors.tuna.tsinghua.edu.cn/rustup
# Rust 工具链安装（与官方完全一致）
#ARG RUST_VERSION=1.91.1
#ARG RUSTUP_SHA256=6c30b75a75b28a96fd913a037c8581b580080b6ee9b8169a3c0feb1af7fe8caf
#RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs -o /tmp/rustup.sh \
#    && echo "${RUSTUP_SHA256}  /tmp/rustup.sh" | sha256sum -c - \
#    && bash /tmp/rustup.sh -y --default-toolchain ${RUST_VERSION}
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --default-toolchain stable
ENV PATH="/root/.cargo/bin:${PATH}"

RUN rustup target add x86_64-unknown-linux-gnu

# [核心修复] 将编译目标 CPU 降级到 baseline x86-64，不生成 v2 指令集代码
# 官方预编译包默认开启 target-cpu=x86-64-v2，导致旧 CPU 报 "CPU does not support x86-64-v2"
ENV RUSTFLAGS="-C target-cpu=x86-64"

# 拉取指定版本源码
ARG SURREALDB_VERSION=v3.0.5
RUN git clone --depth 1 --branch ${SURREALDB_VERSION} https://github.com/surrealdb/surrealdb /surrealdb

WORKDIR /surrealdb
RUN sed -i 's/^channel[[:space:]]*=.*/channel = "stable"/' rust-toolchain.toml
RUN sed -i 's|#!\[recursion_limit = "[0-9]*"\]|#![recursion_limit = "512"]|' src/main.rs
RUN sed -i 's|#!\[recursion_limit = "[0-9]*"\]|#![recursion_limit = "512"]|' surrealdb/src/lib.rs
RUN sed -i 's|#!\[recursion_limit = "[0-9]*"\]|#![recursion_limit = "512"]|' surrealdb/core/src/lib.rs

# 激活 gcc-toolset-13 并编译（首次构建耗时约 30~60 分钟，属正常现象）
SHELL ["/bin/bash", "-c"]
RUN source /opt/rh/gcc-toolset-13/enable \
    && cargo build --release --target x86_64-unknown-linux-gnu --bin surreal

RUN chmod +x /surrealdb/target/x86_64-unknown-linux-gnu/release/surreal

# 预创建数据目录（运行时 distroless 镜像无 shell，无法执行 RUN）
RUN mkdir -p /data /logs \
    && chmod 777 /data /logs

###
# STAGE: tzdata（与官方完全一致）
###

FROM cgr.dev/chainguard/wolfi-base:latest@sha256:52e71f61c6afd1f8d2625cff4465d8ecee156668ca665f7e9c582d1cc914eb6a AS tzdata

RUN apk add --no-cache tzdata

###
# Production image
#
# [运行时变更] gcr.io/distroless/cc-debian12
#   替换：cgr.dev/chainguard/glibc-dynamic:latest@sha256:e9a3236...
#   原因：Chainguard Wolfi 的 glibc 以 x86-64-v2 为编译基准，启动时主动检测 CPU 并拒绝旧机器
#         Debian 12 的 glibc 2.36 为标准上游编译，无 x86-64-v2 检测，且版本 >= Rocky 9 的 glibc 2.34
#   相似性：同为 distroless 风格极小镜像（无 shell、无包管理器），均含动态 glibc + libstdc++
#
# 若需要 debug 模式（含 busybox shell）可将基础镜像改为：
#   gcr.io/distroless/cc-debian12:debug
###

FROM gcr.io/distroless/cc-debian12 AS prod

COPY --from=builder /surrealdb/target/x86_64-unknown-linux-gnu/release/surreal /surreal

COPY --from=tzdata /usr/share/zoneinfo /usr/share/zoneinfo

COPY --from=tzdata /usr/share/zoneinfo/UTC /etc/localtime

COPY --from=builder /data /data

COPY --from=builder /logs /logs

VOLUME /data /logs

ENV SURREAL_BIND="0.0.0.0:8000"

ENTRYPOINT ["/surreal"]
