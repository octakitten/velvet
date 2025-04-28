FROM octakitten/velvet-project:v1.0

RUN git clone https://github.com/octakitten/velvet.git
WORKDIR /velvet
RUN make
