make
./reg GOOG.csv TSLA.csv ^VIX.csv BA.csv NFLX.csv
gnuplot -p plotinfo.txt < riskreturn.txt 
gnuplot -p plotinfo.txt < riskreturngold.txt 