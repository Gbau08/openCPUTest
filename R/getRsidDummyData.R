getRsidDummyData <- function(rsid) {
	
	load("/usr/local/src/app/data/dummyData.rda")

    setDT(dummy)
	rsidDummyData = dummy[rsId==rsid]

    return(rsidDummyData)
}