FROM  docker.pkg.github.com/epiforecasts/epinow2/epinow2:latest

## Copy files to working directory of server
ADD . covid-rt-brazil-subregional

## Set working directory to be this folder
WORKDIR covid-rt-brazil-subregional

## Install missing packages
RUN Rscript -e "devtools::install_dev_deps()"