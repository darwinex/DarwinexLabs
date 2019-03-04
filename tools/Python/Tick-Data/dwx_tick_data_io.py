# -*- coding: utf-8 -*-
"""
    Sample code:
    dwx_tick_data_io.py
    --
    @author: Darwinex Labs (www.darwinex.com)
    
    Copyright (c) 2017-2019, Darwinex. All rights reserved.
    
    Licensed under the BSD 3-Clause License, you may not use this file except 
    in compliance with the License. 
    
    You may obtain a copy of the License at:    
    https://opensource.org/licenses/BSD-3-Clause
"""

from pathlib import Path
import pandas as pd
import numpy as np
import gzip

pd.set_option('display.max_columns', 500)
pd.set_option('display.width', 1000)

class DWX_TICK_DATA_IO():
    
    def __init__(self,
                 _format='{}_{}_{}_{}',
                 _extension='.log.gz',
                 _delimiter=',',
                 _path='<INSERT_PATH_TO_TICK_DATA_GZIPS_HERE>'):
        
        self._format = _format
        self._extension = _extension
        self._delimiter = _delimiter
        self._path = _path
        self._symbol_df = None
        
    ##########################################################################
    
    # Return list of files for BID and ASK each.
    def _find_symbol_files_(self, _symbol='EURUSD',
                                  _date='2017-10-02',
                                  _hour='15'):
        
        if _date == '':
            _fs = [filename.name for filename in Path(self._path).glob('{}/*{}'
                                .format(_symbol, self._extension))]
        else:
            if _hour == '':
                _fs = [filename.name for filename in Path(self._path).glob('{}/*{}'
                                    .format(_symbol, self._extension)) 
                                        if _date in filename.name]
                
            else:
                _fs = [filename.name for filename in Path(self._path).glob('{}/*{}'
                                    .format(_symbol, self._extension)) 
                                        if _date in filename.name
                                            and _hour in filename.name]
    
        if len(_fs) > 0:
            
            return ['{}/{}/{}'.format(self._path, _symbol, _f) for _f in _fs if 'BID' in _f], ['{}/{}/{}'
                    .format(self._path, _symbol, _f) for _f in _fs if 'ASK' in _f]
            
        else:
            print('[WARNING] No files found for {} - {} - {}'
                  .format(_symbol, _date, _hour))
            
            return None, None
    
    ##########################################################################
    
    def _construct_data_(self, _filename):
        
        _df = pd.DataFrame([line.strip().decode().split(self._delimiter) 
                for line in gzip.open(_filename) if len(line) > 10])
        
        if 'BID' in _filename:
            _df.columns = ['timestamp','bid_price','bid_size']
        elif 'ASK' in _filename:
            _df.columns = ['timestamp','ask_price','ask_size']
            
        _df.set_index('timestamp', drop=True, inplace=True)
        
        return _df.apply(pd.to_numeric)
    
    ##########################################################################
    
    def _get_symbol_as_dataframe_(self, _symbol='EURUSD',
                                        _date='',
                                        _hour='',
                                        _convert_epochs=True,
                                        _check_integrity=False,
                                        _calc_spread = False,
                                        _reindex=['ask_price','bid_price'],
                                        _precision='tick',
                                        _daily_start=22,
                                        _symbol_digits=5):
        
        """
        See http://pandas.pydata.org/pandas-docs/stable/user_guide/timeseries.html
        for .resample() rule / frequency strings.        
        """
        
        print('[INFO] Finding symbol files.. please wait..')
        
        _bid_files, _ask_files = self._find_symbol_files_(_symbol,_date,_hour)
        
        print('[INFO] Processing BID ({}) / ASK ({}) files.. please wait..'.format(len(_bid_files), len(_ask_files)))
        
        # BIDS
        _bids = pd.concat([self._construct_data_(_bid_files[i]) 
                    for i in range(0, len(_bid_files)) if ((print('\rBIDS: {} / {} - {}'
                                  .format(i+1,len(_bid_files),_bid_files[i]), end="", flush=True) or 1==1))], axis=0, sort=True)
        print('')
        
        # ASKS
        _asks = pd.concat([self._construct_data_(_ask_files[i]) 
                    for i in range(0, len(_ask_files)) if ((print('\rASKS: {} / {} - {}'
                                  .format(i+1,len(_ask_files),_ask_files[i]), end="", flush=True) or 1==1))], axis=0, sort=True)
                
        _df = _asks.merge(_bids, how='outer', left_index=True, right_index=True, copy=False).fillna(method='ffill').dropna()
            
        # Calculate spread?
        if _calc_spread:
            _df['spread'] = abs(np.diff(_df[['ask_price','bid_price']]))
        
        # Convert timestamps?
        if _convert_epochs:
            _df.index = pd.to_datetime(_df.index, unit='ms')
        
        # Reindex to selected columns?
        if len(_reindex) > 0:
            _df = _df.reindex(_reindex, axis=1)
            
        # Resample?
        if _precision != 'tick':
            _df['mid_price'] = round((_df.ask_price + _df.bid_price) / 2, _symbol_digits)
            
            if _precision not in ['B','C','D','W','24H']:
                _df = _df.mid_price.resample(rule=_precision).ohlc()
            else:
                _df = _df.mid_price.resample(rule=_precision, base=_daily_start).ohlc().dropna()
            
        # Check data integrity?
        if _check_integrity:
            
            print('\n\n[INFO] Checking data integrity..')
            self._integrity_check_(_df)
        
        return _df
    
    ##########################################################################
    
    def _integrity_check_(self, _df):
        
        if isinstance(_df, pd.DataFrame) == False:
            
            print('[ERROR] Input must be a Pandas DataFrame')
            
        else:
            
            _diff = _df.index.to_series().diff()
            
            print('\n[TEST #1] Data Frequency Statistics\n--')
            print(_diff.describe())
            
            print('\n[TEST #2] Mode of Gap Distribution\n--')
            print(_diff.value_counts().head(1))
            
            print('\n[TEST #3] Hourly Spread Distribution\n--')
            _df.groupby(_df.index.hour).spread.mean().plot(
                    xticks=range(0,24), 
                    title='Average Spread by Hour (UTC)')
            
    ##########################################################################
