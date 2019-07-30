getHighestScore <- function(n) {
	
	load("/usr/local/src/app/data/dummyData.rda")
    
    setDT(dummy)
	highestScore = dummy[order(-association_score)][1:n,]

    return (highestScore)
}
