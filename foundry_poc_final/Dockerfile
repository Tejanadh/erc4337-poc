FROM ethereum/solc:0.8.19
RUN curl -L https://foundry.paradigm.xyz | bash
ENV PATH="/root/.foundry/bin:${PATH}"
COPY . /poc
WORKDIR /poc
RUN forge test --match-path test/EntryPointRealTest.t.sol
