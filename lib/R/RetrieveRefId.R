### retrieverefid ver 3: changed ensembl ftp filesystem ver 2
### added user selectable ensembl version
vars.tmp <- commandArgs()
split.vars <- unlist(strsplit(vars.tmp[length(vars.tmp)], ","));
ericscriptfolder <- split.vars[1];
dbfolder <-  split.vars[2];
ensversion <- as.integer(split.vars[3]);
flagprint <- split.vars[4];
if(ensversion < 0) ensversion <- 0;

resdn <- file.path(dbfolder,"data","_resources");
rfn <- file.path(resdn,"RefID.RData");
if(!file.exists(resdn)) dir.create(resdn,recursive=T);
ctime <- as.integer(Sys.time());
if(file.exists(rfn)) {
	dtime <- as.integer(file.info(rfn)$mtime);
}
if(!exists("dtime") || is.na(dtime)) dtime <- 0;

# update if necessary
if(dtime > ctime-10000 && ensversion==0) {
	z <- new.env();
	load(rfn,envir=z);
	ensversion		<- z$version;
	ensrefid		<- z$refid;
	ensrefid.path	<- z$refid.path;
	rm(z);
	ensversion0 <- ensversion;
} else {
# get ensembl version and fasta lists
cat(xx0.tmp<-readLines("http://ftp.ensembl.org/pub"),file=paste(resdn,"/.ftplist0h",sep=""));
# get the most recent version
ensversion0 <- ensversion
if (ensversion == 0) {
	i1 <- grep(">release-[0-9]*/</a>",xx0.tmp);
	ensversion <- max(as.integer(sub(".*>release-([0-9]*)/</a>.*","\\1",xx0.tmp[i1])));
}

# get available species
cat(xx1.tmp<-readLines((bfn<-paste("http://ftp.ensembl.org/pub/",ifelse(ensversion>0,paste("release-",ensversion,"/fasta",sep=""),"/current_fasta"),sep=""))),file=paste(resdn,"/.ftplist1h",sep=""),sep="\n");
# collect names of all available species 
i1 <- grep("<a href=\"[a-z]",xx1.tmp); 
xx <- sub(".*<a href[^>]*>([^<]*)/</a>.*","\\1",xx1.tmp[i1]);
	ensrefid <- xx;
	ensrefid.path <- c();
	for(i in 1:length(xx)) tryCatch({
		xx2.tmp <- readLines(paste(bfn,"/",xx[i],"/dna",sep=""));
		a1 <- grep("dna.toplevel",xx2.tmp,value=T);
		if(length(a1)==1) ensrefid.path[i] <- sub(".*<a href=\"([^>]*)\">[^<]*</a>.*","\\1",a1);
	},error=function(e){});
	i1 <- which(!is.na(ensrefid.path) & nchar(ensrefid.path)>10);
	ensrefid <- ensrefid[i1];
	ensrefid.path <- ensrefid.path[i1];

};	# end if dtime & ctime comparison

if(flagprint != 0) {
	cat(ifelse(ensversion0!=0,"Selected","Current"),"Ensembl version:", ensversion, "\n");

	if(file.exists(rfn) & any(file.exists(file.path(dbfolder,"data",ensrefid)))) {
		load(rfn);
		cat("Installed Ensembl version:", version, "\n")
	} else {
		cat("Installed Ensembl version:", "No database installed", "\n")
	}
	cat("Available reference IDs:\n", paste("\t", ensrefid, "\n"));
}
flag.updatedb <- 1;
if(file.exists(rfn)) {
	load(rfn);
	if(ensversion != version) {
		flag.updatedb <- 0;
	}
} 
if(flag.updatedb>0) {
	refid <- ensrefid
	refid.path <- ensrefid.path
	version <- ensversion
}

save(refid, refid.path, version, file = rfn);
cat(version, file = file.path(resdn, "Ensembl.version"));
cat(flag.updatedb, file = file.path(resdn, ".flag.updatedb"));



