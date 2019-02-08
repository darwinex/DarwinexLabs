# -*- coding: utf-8 -*-
 
"""
Created on Mon Feb 04 12:01:07 2019
@author: Darwinex Labs (www.darwinex.com)

DWX_MT_TO_PYTHON_v2_RC4.py

Purpose:
    
    This script enables traders knowledgable in Python to import 
    their Account History and Strategy Tester reports directly into 
    pandas dataframes.
    
    Leverage the capabilities of Python to conduct more meaninful,
    sophisitcated analyses of your track records and backtests.

Dependencies:

    - Python 3.6+
    - BeautifulSoup 4 (bs4)
    - pandas (Python Data Analysis Library)
    - numpy (Scientific Computing with Python)

Notes:
    
    The script isolates certain structural nuances of MetaTrader's HTML report,
    specified in the __init__() function.
    
    These are at the mercy of MetaTrader, and should these change in future, the
    corresponding variables in the script will require adjustments accordingly.
    
Tested with:
    
    MetaTrader 4 Build 1170 (20 Dec 2018)
    
Usage:
    
    1) Set _type = 'normal' for Account Histories saves as "Normal" Reports
    2) Set _type = 'detailed' for Account Histories saves as "Detailed" Reports
    3) Set _type = 'backtest' for Strategy Tester reports
    
    By default, dataframes generated are stored inside a class variable
    called '_statement_df'. Set _verbose to True to print this upon generation.
    
"""

from bs4 import BeautifulSoup
import pandas as pd
import numpy as np

# Set pandas options
pd.set_option('display.width', 1000)
pd.set_option('display.max_columns', 500)

class DWX_MT_TO_PYTHON():

    def __init__(self, _verbose=False,
                 _type='normal',
                 _filename='C://Users/Satch/Desktop/PLX_ALL_NormalStatement.htm'):
        
        #############################
        # MetaTrader HTML Variables #
        #############################
        
        self.STATEMENT_HEADER = ['ticket','open_time','type','size','item',
                                 'open_price','sl','tp','close_time',
                                 'close_price','commission','taxes',
                                 'swap','profit','magic','comment']
        
        self.BACKTEST_HEADER = ['id','open_time','type','order','size',
                                'open_price','sl','tp','profit','balance']
        
        self.TRADE_FIELDS = [(self.STATEMENT_HEADER[_r],_r) for _r in range(0,14)]
        
        self.BALANCE_FIELDS = [('ticket',0),
                              ('open_time',1),
                              ('type',2),
                              ('item',3),
                              ('profit',4)]
        
        self.COMMENT_FIELDS = [('magic',1),
                               ('comment',2)]
        
        # Variables to sanitize
        self.ST_NUMS_TO_SANITIZE = ['ticket','size','open_price','close_price',
                                 'commission','taxes','swap',
                                 'profit','sl','tp','magic']
        
        self.BT_NUMS_TO_SANITIZE = ['id','order','size','open_price',
                                    'sl','tp','profit','balance']
        
        self.ST_DATES_TO_SANITIZE = ['open_time','close_time']
        
        
        self.BT_DATES_TO_SANITIZE = ['open_time']
        
        # Number of rows to exclude depending on statement type (normal or detailed)
        self.NORMAL_TRUNC = 15
        self.DETAILED_TRUNC = 29
        self.BACKTEST_TRUNC = 0
        
        # Backtest rows differ as follows:
        self.BT_ROW_NO_PROFIT_LEN = 8
        self.BT_ROW_WITH_PROFIT_LEN = 10
        
        #####################################
        # Store DataFrame for other methods #
        #####################################
        self._statement_df = None
        self._backtest_df = None
        self._verbose = _verbose
    
        # Transform input file into pandas dataframe
        print(self._statement_to_dataframe_(_type=_type,
                                      _filename=_filename))
        
        print('\n[INFO] Data stored in self._statement_df.')
        
    ##########################################################################
    
    def _statement_to_dataframe_(self, _type='normal',
                                 _filename='C://Users/Satch/Desktop/PLX_ALL_NormalStatement.htm'):
     
        # Check if input type is correct, else return error
        if _type not in ['backtest','normal','detailed']:
            print('[KERNEL] Invalid input file -> must be one of backtest, normal or detailed.')
            return None
        
        try:
            with open (_filename, "r") as myfile:
                s=myfile.read()
        except FileNotFoundError:
            print('[ERROR] No such file exists!')
            return None
        
        # Invoke HTML Parser
        _soup = BeautifulSoup(s, 'html.parser')
        
        if _type.lower() == 'normal':
            _table = _soup.find_all('table')[0]
            _trunc = self.NORMAL_TRUNC
        elif _type.lower() == 'detailed':
            _table = _soup.find_all('table')[0]
            _trunc = self.DETAILED_TRUNC
        elif _type.lower() == 'backtest':
            _table = _soup.find_all('table')[1]
            _trunc = self.BACKTEST_TRUNC
        else:
            print('[ERROR] Unrecognized statement type.. must be backtest, normal or detailed.')
            return None
        
        # Count number of rows in track record (ignore last 14)
        _x = (len(_table.findAll('tr')) - _trunc)
        
        # Extract rows
        _rows = _table.findAll('tr')
        
        if _type == 'backtest':
            _rows = _rows[1:_x]
            
            # Create dict DB with empty lists (for dataframe later)
            _dict = {_c: [np.nan for _l in range(len(_rows))] for _c in self.BACKTEST_HEADER}
            
        else:
            _rows = _rows[3:_x]
        
            # Create dict DB with empty lists (for dataframe later)
            _dict = {_c: [np.nan for _l in range(len(_rows))] for _c in self.STATEMENT_HEADER}
        
        # Initialize row counter
        _row_counter = 0
        
        for _row in _rows:
            
            # Extract values
            _values = _row.findAll('td') 
            
            if _type != 'backtest':
                
                #######################################
                # Balance record (deposit/withdrawal) #
                #######################################
                if len(_row) == len(self.BALANCE_FIELDS):
                    
                    for _f in self.BALANCE_FIELDS:
                        _dict[_f[0]][_row_counter] = _values[_f[1]].getText()
                
                ################
                # Trade record #
                ################
                elif len(_row) == len(self.TRADE_FIELDS):
                    
                    for _f in self.TRADE_FIELDS:
                        _dict[_f[0]][_row_counter] = _values[_f[1]].getText()
                    
                ###################
                # Comment / Magic #
                ###################
                elif len(_row) == len(self.COMMENT_FIELDS)+1:
                    
                    # Update previous trade's comment/magic fields
                    for _f in self.COMMENT_FIELDS:
                        _dict[_f[0]][_row_counter-1] = _values[_f[1]].getText()
                        
                else:
                    print('[ERROR] Cannot recognize row structure.. please check HTML report to confirm if anything has changed?')
                    return None
                
            else:
                if len(_values) == self.BT_ROW_WITH_PROFIT_LEN:
                    _iter_range = range(self.BT_ROW_WITH_PROFIT_LEN)
                else:
                    _iter_range = range(self.BT_ROW_NO_PROFIT_LEN)
                        
                for _i in _iter_range:
                    _dict[self.BACKTEST_HEADER[_i]][_row_counter] = _values[_i].getText()
            
            # Update for next iteration
            _row_counter += 1
       
        # Create dataframe
        _df = pd.DataFrame(data=_dict).dropna(how='all')
        
        # Sanitize data types
        if _type != 'backtest':
        
            for _n in self.ST_NUMS_TO_SANITIZE:
                _df[_n] = pd.to_numeric(_df[_n].str.replace(' ',''))
                
            for _d in self.ST_DATES_TO_SANITIZE:    
                _df[_d] = pd.to_datetime(_df[_d])
            
            # Save locally for future use
            self._statement_df = _df
        
        else:
            
            for _n in self.BT_NUMS_TO_SANITIZE:
                _df[_n] = pd.to_numeric(_df[_n].str.replace(' ',''))
                
            for _d in self.BT_DATES_TO_SANITIZE:    
                _df[_d] = pd.to_datetime(_df[_d])

            # Save locally for future use
            self._backtest_df = _df
        
        # Return sanitized dataframe
        if self._verbose == True:
            return _df
    
    ##########################################################################