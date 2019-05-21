# CUDA Efficient Frontier
Just a CPU and CUDA implementation of generating portfolios for purchasing stocks. Essentially, given historical stock 
data the program will create random portfolios (using different weights for each stocks). The portfolios can then be written 
to a text file and then graphed using a tool like GNUPlot. 

# Getting Data
The current input function prefers historical data from Yahoo Finance. Search for a stock, go to the Historical Data tab, 
change the time period so there is at least 100 data points (preferably use weekly price or monthly prices), click apply, 
then Download Data. Repeat these steps with each of the stocks (at least 3, max 85). 

# Use
The current commit does not write to a textfile as I was doing timings. If you would like to write to an output, you will
need to uncomment a line or two.
```
./executableName [each of the csv files from yahoo] numberOfPortfoliosToCreate
```
Example
```
./myExecutableVersion Tesla.csv Google.csv BitCoin.csv 10000
```
To plot your output below a list a simple way to view the data graphically. In terminal put in the following commands:
```
gnuplot
set xlabel "Risk (Standard Deviations)"
set ylabel "Return (Weekly Percent)"
plot 'riskreturn.txt' with points pt 0
```


# Notes
This was my final project for CS677: Programming for GPUs (or something like that)
Please note this is a work in progress and can be a great jumping point for a similar project.

