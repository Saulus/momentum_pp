 import $, STD;
 
	file_test := DATASET([{'A','Along',20120102,20131231},
															{'B','Blong',20120101,20191231},
															{'C','Clong',20120101,20121231},
															{'C','Clong',20140101,20191231}],
															{$.mdax_import.layout.shortcut,$.mdax_import.layout.share,unsigned4 startdate,unsigned4 enddate});
																														
	mdax_import_file := DATASET([{'20120102','A','Along'},
															{'20120101','B','Blong'},
															{'20120101','C','Clong'},
															{'20130101','A','Along'},
															{'20130101','B','Blong'},
															{'20140101','B','Blong'},
															{'20140101','C','Clong'}],$.mdax_import.layout);

//***********************************************************************
	//Real data
	 // mdax_import_file := $.mdax_import.file;
	
//Prep: Add dates/shares combinations that are not presenz
	//gather shares only
	mdax_shares_rec := RECORD
		mdax_import_file.shortcut;
		mdax_import_file.share;
	END;
	mdax_shares := dedup(sort(table(mdax_import_file,mdax_shares_rec),shortcut),left.shortcut=right.shortcut);
	
	//gather dates only
	//add fictional future date as last enddate
	mdax_dates_rec := RECORD
		mdax_import_file.date;
	END;
	mdax_dates := dedup(sort(table(mdax_import_file,mdax_dates_rec),date)) + DATASET([{$.p.lastdate}],mdax_dates_rec);
	
	//add fictional future date as last enddate
  
	
	//full join to get all possible dates/shares (even false)
	mdax_allsharedates_rec := RECORD
		$.mdax_import.layout;
		boolean isavailable := false;
	END;
	mdax_allsharedates_rec doJoin1(mdax_dates_rec l, mdax_shares_rec r) := TRANSFORM
	 SELF := l;
	 SELF := r;
	END;
	mdax_falsesharedates := JOIN(mdax_dates, mdax_shares,LEFT.date<>RIGHT.shortcut,
                    doJoin1(LEFT,RIGHT), ALL, NOSORT);
								

	// get all valid (true) and invalid (false) combinations
	//a) create base table with isavaiable=true
	 mdax_truesharedates_rec := RECORD
		mdax_import_file;
		boolean isavailable := true;
	END;
	mdax_truesharedates := table(mdax_import_file,mdax_truesharedates_rec);
	
	//b) join true and false combinations, set true if available
	mdax_allsharedates_rec doJoin2(mdax_allsharedates_rec l, mdax_truesharedates r) := TRANSFORM
	 SELF.isavailable := r.isavailable;
	 SELF := l;
	END;
	mdax_imported_plus_notavail := join(mdax_falsesharedates, mdax_truesharedates,LEFT.shortcut = RIGHT.shortcut and LEFT.date = RIGHT.date,doJoin2(LEFT,RIGHT),LEFT OUTER);
	
//Create result: new layout with gregorian dates, and iteration, plus dedup 
	res_layout := RECORD
		mdax_imported_plus_notavail.shortcut;
		mdax_imported_plus_notavail.share;
		UNSIGNED4 date_greg := STD.Date.FromGregorianDate((Unsigned4) mdax_imported_plus_notavail.date);
		UNSIGNED4 startdate_greg := 0;
		UNSIGNED4 enddate_greg := 0;
		mdax_imported_plus_notavail.isavailable;
	END;	
	mdax_imported_plus_newrec := table(mdax_imported_plus_notavail,res_layout);
	SortedAllMdax := SORT(mdax_imported_plus_newrec,shortcut,date_greg);
	GroupedAllMdax := GROUP(SortedAllMdax,shortcut); 
	output(GroupedAllMdax);
	
	//Transform Function to fill start- and enddate (enddate = false startdate-1)
	res_layout get_mdax_dates(res_layout L, res_layout R) := TRANSFORM
		SELF.startdate_greg := if(L.startdate_greg=0 and R.isavailable, R.date_greg, //first true date
																if(not L.isavailable and R.isavailable,R.date_greg,L.startdate_greg));
												//Startdate darf sich nur ändern, wenn Änderung von False zu True, oder neues Shortcut
		SELF.enddate_greg := if(not L.isavailable and not R.isavailable,L.enddate_greg,R.date_greg-1);
											//behalte nur dann das Enddatum, wenn false auf false folgt
		SELF := R;
	END;
	pre_file:= ITERATE(GroupedAllMdax,get_mdax_dates(LEFT,RIGHT));
	
	output(pre_file);
	
	//dedup and keep only false rows (=latest changes)
	res_File := DEDUP(
									sort(pre_file(isavailable=false),startdate_greg,enddate_greg),
								 LEFT.startdate_greg=RIGHT.startdate_greg and LEFT.enddate_greg = RIGHT.enddate_greg);
	
	layout := record
		res_File.shortcut;
		res_File.share;
		Unsigned4 startdate := STD.Date.ToGregorianDate(res_File.startdate_greg);
		Unsigned4 enddate := STD.Date.ToGregorianDate(res_File.enddate_greg);
	END;	
	
	file := UNGROUP(table(res_File,layout));
	output(file);