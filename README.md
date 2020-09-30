
# Subregional Estimates of Rt for Covid-19 in Brazil


## Data

* Rt estimates: `data/rt-samples/rt.csv`

## Dependencies

Install the required dependencies using:

```r
devtools::install_dev_deps()
```

## Updating

Run the following bash script to update the data, delay distribution and to estimate Rt for each area.

```bash
bash bin/update.sh
```

See the bash script for links to each underlying script.