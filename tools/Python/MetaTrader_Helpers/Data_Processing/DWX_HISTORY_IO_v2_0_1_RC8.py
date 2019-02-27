# -*- coding: utf-8 -*-

"""

    DWX_HISTORY_IO_v2_0_1_RC8.py
    --
    @author: Darwinex Labs (www.darwinex.com)
    
    Copyright (c) 2017-2019, Darwinex. All rights reserved.
    
    Licensed under the BSD 3-Clause License, you may not use this file except 
    in compliance with the License. 
    
    You may obtain a copy of the License at:    
    https://opensource.org/licenses/BSD-3-Clause
    
    Purpose:
        To import historical prices from HST archives into Python

"""

import os
import struct
import time
import pandas as pd

pd.set_option('display.max_columns', 500)
pd.set_option('display.width', 1000)

class DWX_MT_HISTORY_IO():
    
    def __init__(self):
        
        """
        .hst file format valid as of MT4 574 and later
        Refer to: https://www.mql5.com/en/forum/149178
        
        DATABASE HEADER (148 bytes):
            
        int         version;        // 4 bytes
        string	    copyright[64];	// 64 bytes
        string      symbol[12];     // 12 bytes
        int         period;         // 4 bytes
        int         digits;         // 4 bytes
        datetime	timesign;       // 4 bytes
        datetime	last_sync;      // 4 bytes
        int         unused[13];     // 52 bytes
        
        BAR STRUCTURE (60 bytes):
        
        datetime	ctm;            // 8 bytes
        double	    open;           // 8 bytes
        double      high;           // 8 bytes
        double      low;            // 8 bytes
        double      close;          // 8 bytes
        long        volume;         // 8 bytes
        int         spread;         // 4 bytes
        long        real_volume;	// 8 bytes
        
        Python STRUCT format characters:
        (Ref: https://docs.python.org/3/library/struct.html)
            
        < = (Byte Order: little-endian, Size: standard)
        Q = (C Type: unsigned long long, Python type: integer, Size: 8)
        d = (C Type: double, Python type: float, Size: 8)
        q = (C Type: long long, Python type: integer, Size: 8)
        i = (C Type: int, Python type: integer, Size: 4)    
        """
        
        self._HST_BYTE_FORMAT = '<Qddddqiq'
        self._HEADER_BYTES = 148
        self._BAR_BYTES = 60
    
    ##########################################################################
    
    def _run_(self, _filename = '<ENTER_PATH_TO_HST_FILE_HERE>',
                    _symbol = 'EURUSD',
                    _timeframe = '60',  # Timeframe in minutes, e.g. H1 = 60, M1 = 1, etc
                    _verbose = False):
        
        if _filename == None:
            print('[ERROR] Invalid filename!')
            quit()
            
        _seek = 0
        _open_time = []
        _open_price = []
        _low_price = []
        _high_price = []
        _close_price = []
        _volume = []
        _spread = []
        _real_volume = []
    
        with open(_filename.format(_symbol, _timeframe), 'rb') as f:
            
            _filesize = os.stat(_filename.format(_symbol, _timeframe)).st_size
            _num_bars = int((_filesize - self._HEADER_BYTES) / self._BAR_BYTES)
            _counter = 1
            
            while True:
                
                if _seek >= self._HEADER_BYTES:
                    
                    _buf = f.read(self._BAR_BYTES)
                    _seek += self._BAR_BYTES
                        
                    if not _buf:
                        break
                    
                    if _verbose == True:
                        print('[INFO] Extracting Record {} of {} from {} HST archive'.format(_counter, _num_bars, _symbol))
                    
                    _bar = struct.unpack(self._HST_BYTE_FORMAT, _buf)
                    _open_time.append(time.strftime("%Y-%m-%d %H:%M:%S", time.gmtime(_bar[0])))
                    _open_price.append(_bar[1])
                    _high_price.append(_bar[2])
                    _low_price.append(_bar[3])
                    _close_price.append(_bar[4])
                    _volume.append(_bar[5])  
                    _spread.append(_bar[6])
                    _real_volume.append(_bar[7])
                    
                    _counter += 1
                    
                else:           
                    _buf = f.read(self._HEADER_BYTES)
                    _seek += self._HEADER_BYTES
                
        _df = pd.DataFrame.from_dict(
                {'open_time': _open_time, 
                 'open': _open_price,
                 'high': _high_price,
                 'low': _low_price,
                 'close': _close_price,
                 'volume': _volume,
                 'spread': _spread,
                 'real_volume': _real_volume}
                ).set_index('open_time')
        
        if _verbose is True:
            print(_df)
        
        return _df
    
    ##########################################################################