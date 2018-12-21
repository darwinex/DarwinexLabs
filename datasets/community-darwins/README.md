# Update (as of December 21, 2018)

This flat-file repository of DARWIN data has been taken offline. Please contact info@darwinex.com to request DARWIN API access instead.

#

Community Darwins are created by Darwinex Labs, quantitatively leveraging community behaviour.

Community behaviour is the Darwinex community's intellectual property. Therefore, to protect this intellectual property, Community Darwins are only available to the Darwinex Community for investment.

The data structure of any datasets in this directory is exactly the same as any other DARWIN asset on the Darwinex Exchange.

DARWIN Data Structure:
--
Quotes:
1) timestamp (Unix EPOCH in milliseconds)
2) Quote (quoted price of the asset on the exchange, indexed to 100 base)

Scores:
1) timestamp (Unix EPOCH in milliseconds)
2) Dp - D Periods
3) Ex - Experience
4) Mc - Market Correlation
5) Rs - Risk Stability
6) Ra - Risk Adjustment
7) Os - Open Strategy
8) Cs - Close Strategy
9) R+ - Positive Return Consistency
10) R- - Negative Return Consistency
11) Dc - Duration Consistency
12) La - Loss Aversion
13) Pf - Performance
14) Cp – Capacity
15) Ds - D-Score

For more detail on each of the above features, please visit: https://www.darwinex.com/education

Filename Conventions:
--
Filenames for datasets in this directory have the following format:

DARWIN-TICKER . TIMEFRAME . DATATYPE . LATEST-UPDATE

For example, if a file is named "DWC.D1.QUOTES.29.11.2017", it contains:

1) Data for DARWIN $DWC
2) Data Sensitivity / Timeframe is D1 (M1 = 1-Minute, D1 = Daily)
3) Type of data (QUOTES or SCORES)
4) Contains data up to the 29th of November, 2017.

**Please note:**
1) Data in 1-minute precision for DARWIN $DWC is only available from 21st of May, 2017 onwards.
2) SCORES data will be made available in future releases.
