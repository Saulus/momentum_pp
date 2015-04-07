EXPORT mdax_import := MODULE

	export layout := RECORD
		string8 date;
		string4 shortcut;
		string50 share;
	END;
	
	unknowns_set := DATASET([{'AMB2','GE1'},
											{'ESC3','ESC'},
											{'GEH','CLS1'},
											{'GWI','GWI1'},
											{'IWK','KU2'},
											{'KAR','ARO'},
											{'KRN3','KRN'},
											{'RHK3','RHK'},
											{'RHM3','RHM'},
											{'SOW4','SOW'},
											{'WCA','WCMK'},
											{'n/a','PSM'}],{string4 old,string4 new});
	unknowns  := DICTIONARY(unknowns_set,{old => new});

// EXPORT File := dataset('~momentum::import::index_mdax',Layout,CSV(SEPARATOR(':'),QUOTE('""')));
	pre_File := dataset('~momentum::import::index_mdax',Layout,CSV(SEPARATOR(','),QUOTE('""')));
	
	layout changeUnknowns (layout l) := TRANSFORM
		SELF.shortcut := IF(l.shortcut in set(unknowns_set,old),unknowns[l.shortcut].new,l.shortcut);
		SELF := l;
	END;
	export file := project(pre_File,changeUnknowns(LEFT));
	
END;