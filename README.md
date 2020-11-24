
# Subregional Estimates of Rt for Covid-19 in Brazil

City level estimates of the time-varying reproduction number of Covid-19 produced using [EpiNow2](epiforecasts.io/EpiNow2) based on data from [brazil.io](https://brasil.io/home/). Regional estimates for Brazil (along with a national estimate) are available [here](https://epiforecasts.io/covid/posts/national/brazil/). Detail of the method used is given [here](https://epiforecasts.io/covid/methods.html), though the estimates shown here were derived using an approximate approach (direct de-convolution of observed cases) rather than the exact method used on [epiforecasts.io](https://epiforecasts.io/covid) and therefore should be considered indicative. The code and data supporting these estimates is available [here](https://github.com/epiforecasts/covid-rt-brazil-subregional). Estimates are available in a summarised form [here](https://github.com/epiforecasts/covid-rt-brazil-subregional/tree/master/data/rt).

## Data

* Rt estimates: `data/rt/<date>/rt.csv`

## Dependencies

Install the required dependencies using:

```r
devtools::install_dev_deps()
```

## Updating

Run the following bash script to update the data, delay distributions and to estimate Rt for each area that fits the criteria specified in `R/update-data.R`.

```bash
bash bin/update.sh
```

See the bash script for links to each underlying script. On a 4 core computer reproducing these estimates should take 
approximately 5 hours.