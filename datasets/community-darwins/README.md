Community Darwins are created by Darwinex Labs, quantitatively leveraging community behaviour.

Community behaviour is the Darwinex community's intellectual property. Therefore, to protect this intellectual property, Community Darwins are only available to the Darwinex Community for investment.

The data structure of any datasets in this directory is exactly the same as any other DARWIN asset on the Darwinex Exchange.

DARWIN Data Structure:
--
1) timestamp (Unix EPOCH in milliseconds)
2) Quote (quoted price of the asset on the exchange, indexed to 100 base)

Filename Conventions:
--
Filenames for datasets in this directory have the following format:

DARWIN-TICKER . TIMEFRAME . LATEST-UPDATE

For example, if a file is named "DWC.4.20.D1.QUOTES.06.July.2017", it contains:

1) Data for DARWIN DWC.4.20
2) Data Sensitivity / Timeframe is D1 (M1 = 1-Minute, D1 = Daily)
3) Type of data (QUOTES or SCORES)
4) Contains data up to the 6th of July, 2017.
