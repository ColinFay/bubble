FROM rocker/r-ver:3.6.1

RUN apt-get update && \
  apt install nodejs -y

RUN R -e 'install.packages("remotes")' && \
  R -e 'remotes::install_cran(c("R6","cli", "crayon",\
  "subprocess", "rlang", "testthat", "jsonlite"))'

COPY bubble_*.tar.gz /bubble.tar.gz

RUN R -e 'remotes::install_local("/bubble.tar.gz")'

COPY script.R /script.R

CMD R -e 'source("/script.R")'
