FROM nvidia/cuda:12.8.1-cudnn-devel-ubuntu24.04

RUN apt-get update && apt-get install -y \
    curl \
    gcc \
    git \
    make
RUN curl -sSf https://sh.rustup.rs | sh -s -- -y
ENV PATH="/root/.cargo/bin:${PATH}"
RUN cargo install hvm
RUN cargo install bend-lang
RUN git clone https://github.com/octakitten/velvet.git
WORKDIR /velvet
RUN make
