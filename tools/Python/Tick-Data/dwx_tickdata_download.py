# -*- coding: utf-8 -*-

"""
Created on Mon Oct 29 17:24:20 2018

Script: dwx_tickdata_download.py
--
Downloads tick data from the Darwinex tick data server. This code demonstrates
how to download data for one specific date/hour combination, but can be 
extended easily to downloading entire assets over user-specified start/end 
datetime ranges.

Requirements: Your Darwinex FTP credentials.

Result: Dictionary of pandas DataFrame objects by date/hour.
        (columns: float([ask, size]), index: millisecond timestamp)
        
Example code:

    > td = DWX_Tick_Data(dwx_ftp_user='very_secure_username', 
                         dwx_ftp_pass='extremely_secure_password',
                         dwx_ftp_hostname='mystery_ftp.server.com', 
                         dwx_ftp_port=21)
    
    > td._download_hour_(_asset='EURNOK', _date='2018-10-22', _hour='00')
    
    > td._asset_db['EURNOK-2018-10-22-00']
    
                                           ask       size
     2018-10-22 00:00:07.097000+00:00  9.47202  1000000.0
     2018-10-22 00:00:07.449000+00:00  9.47188   750000.0
     2018-10-22 00:01:08.123000+00:00  9.47201   250000.0
     2018-10-22 00:01:10.576000+00:00  9.47202  1000000.0
                                  ...        ...

@author: Darwinex Labs
@twitter: https://twitter.com/darwinexlabs
@web: http://blog.darwinex.com/category/labs

"""

from ftplib import FTP 
from io import BytesIO
import pandas as pd
import gzip

class DWX_Tick_Data():
    
    def __init__(self, dwx_ftp_user='<insert your Darwinex username>', 
                     dwx_ftp_pass='<insert your Darwinex password>',
                     dwx_ftp_hostname='<insert Darwinex Tick Data FTP host>', 
                     dwx_ftp_port=21):
        
        # Dictionary DB to hold dictionary objects in FX/Hour format
        self._asset_db = {}
        
        self._ftpObj = FTP(dwx_ftp_hostname)                            
        self._ftpObj.login(dwx_ftp_user, dwx_ftp_pass)   

        self._virtual_dl = None
        
    #########################################################################
    # Function: Downloads and stored currency tick data from Darwinex FTP
    #           Server. Object stores data in a dictionary, keys being of the
    #           format: CURRENCYPAIR-YYYY-MM-DD-HH
    #########################################################################
    
    def _download_hour_(self, _asset='EURUSD', _date='2017-10-01', _hour='22',
                   _ftp_loc_format='{}/{}_ASK_{}_{}.log.gz',
                   _verbose=False):
        
        _file = _ftp_loc_format.format(_asset, _asset, _date, _hour)
        _key = '{}-{}-{}'.format(_asset, _date, _hour)
        
        self._virtual_dl = BytesIO()
        
        if _verbose is True:
            print("\n[INFO] Retrieving file \'{}\' from Darwinex Tick Data Server..".format(_file))
        
        try:
            self._ftpObj.retrbinary("RETR {}".format(_file), self._virtual_dl.write)
            
            self._virtual_dl.seek(0)
            _log = gzip.open(self._virtual_dl)
                
            # Get bytes into local DB as list of lists
            self._asset_db[_key] = [line.strip().decode().split(',') for line in _log]
            
            # Construct DataFrame
            _temp = self._asset_db[_key]
            self._asset_db[_key] = pd.DataFrame({'ask': [l[1] for l in _temp],
                                'size': [l[2] for l in _temp]}, 
                                index=[pd.to_datetime(l[0], unit='ms', utc=True) for l in _temp])
            
            # Sanitize types
            self._asset_db[_key] = self._asset_db[_key].astype(float)
            
            if _verbose is True:
                print('\n[SUCCESS] {} tick data for {} (hour {}) stored in self._asset_db dict object.\n'.format(_asset, _date, _hour))
        
        # Case: if file not found
        except Exception as ex:
            _exstr = "Exception Type {0}. Args:\n{1!r}"
            _msg = _exstr.format(type(ex).__name__, ex.args)
            print(_msg)
    
    #########################################################################
