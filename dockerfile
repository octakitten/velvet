FROM nvidia/cuda:12.8.1-cudnn-devel-ubuntu24.04

RUN apt-get update && apt-get install -y \
    curl \
    gcc
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
RUN cargo install hvm
RUN cargo install bend-lang
RUN git clone https://github.com/octakitten/velvet.git
WORKDIR /velvet
RUN bend run-cu

