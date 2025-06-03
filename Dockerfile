FROM mathworks/matlab:r2024b
LABEL maintainer="rahul.gandbhir@unibas.ch"

WORKDIR /matlab

RUN matlab -batch "eval(webread('https://b.link/rbeast', weboptions('cert','')))"

COPY matlab/ddindd ./ddindd
COPY setup.m .

CMD ["matlab", "-batch", "setup"]