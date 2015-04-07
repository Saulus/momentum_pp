mdaxkurs := RECORD
  STRING kurs;
	string Date,Open,High,Low,Close,Volume,Adj Close

END;

p := PIPE('wget -q -O "-" http://ichart.finance.yahoo.com/table.csv?s=%5EMDAXI&a=11&b=30&c=2013&d=02&e=4&f=2014&g=d&ignore=.csv', mdaxkurs, CSV(SEPARATOR(''))); 

output(p);