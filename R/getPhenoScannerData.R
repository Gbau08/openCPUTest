###################################################################
## PhenoScanner Query                                            ##
##                                                               ##
## James Staley                                                  ##
## Email: james.staley@ucb.com                                   ##
###################################################################

###################################################################
##### Set-up #####
###################################################################


pathToLoad = "/usr/local/src/app/data/map.Robj"
options(stringsAsFactors=F)

suppressMessages(library(phenoscanner))
suppressMessages(library(ddpcr))
suppressMessages(library(foreach))
suppressMessages(library(doParallel))

phenoscanner_snp <- function(rsid){
  quiet(query_snp <- phenoscanner(snpquery=rsid, catalogue="None")$snps, all=FALSE)
  if(nrow(query_snp)>0){
    query_snp$nearest_gene <- query_snp$hgnc
    query_snp$nearest_gene[query_snp$nearest_gene=="-"] <- query_snp$ensembl[query_snp$nearest_gene=="-"]
    query_snp$nearest_gene[query_snp$nearest_gene=="-"] <- "N/A"
    query_snp <- query_snp[,c("rsid", "hg19_coordinates", "a1", "a2", "eur", "consequence", "nearest_gene")]
    names(query_snp) <- c("snpid", "hg19_coordinates", "effect_allele", "other_allele", "effect_allele_frequency", "variant_function", "nearest_gene")
  }
  cat("  ",rsid,"-- SNP\n")
  return(query_snp)
}

phewas <- function(rsid){
  
  ## PhenoScanner SNP-trait look-up
  phenoscanner_query <- function(rsid, type="GWAS"){
    
    suppressMessages(library(phenoscanner))
    # Sleep
    if(type=="GWAS"){Sys.sleep(0)}; if(type=="pQTL"){Sys.sleep(0.15)}; if(type=="mQTL"){Sys.sleep(0.3)}; if(type=="eQTL"){Sys.sleep(0.45)}
    
    # PhenoScanner look-up
    query_results <- phenoscanner(snpquery=rsid, catalogue=type, pvalue=1)$results
    
    # Process results
    if(nrow(query_results)>0){
      if(type=="GWAS"){
        # library(dplyr)
        load(pathToLoad)
        query_results <- merge(query_results, map, by=c("dataset", "trait"), all.x=T, sort=F)[,union(names(query_results), names(map))]
        # query_results <- left_join(query_results, map, by=c("dataset", "trait"))
        query_results <- query_results[!(!is.na(query_results$keep) & query_results$keep=="N"),]; query_results$keep <- NULL 
        query_results$category[is.na(query_results$category)] <- "Unclassified"
        query_results <- query_results[,c(1:8,23,9:22)]
      }
      if(type=="pQTL"){
        query_results$category <- "Proteins"
        query_results$n_cases <- 0
        query_results$n_controls <- query_results$n
        query_results <- query_results[,c(1:8,21,9:17,22,23,18:20)]
      }
      if(type=="mQTL"){
        query_results$category <- "Metabolites"
        query_results$n_cases <- 0
        query_results$n_controls <- query_results$n
        query_results <- query_results[,c(1:8,21,9:17,22,23,18:20)]
      }
      if(type=="eQTL"){
        query_results$trait <- paste0("mRNA expression of ", query_results$exp_gene)
        query_results$trait[query_results$trait=="mRNA expression of -"] <- paste0("mRNA expression of ", query_results$exp_ensembl[query_results$trait=="mRNA expression of -"])
        query_results$trait[query_results$trait=="mRNA expression of -"] <- paste0("mRNA expression of ", query_results$probe[query_results$trait=="mRNA expression of -"])
        query_results$trait <- paste0(query_results$trait, " in ", tolower(query_results$tissue))
        query_results <- query_results[,!(names(query_results) %in% c("tissue", "exp_gene", "exp_ensembl", "probe"))]
        query_results$category <- "mRNA expression"
        query_results$n_cases <- 0
        query_results$n_controls <- query_results$n
        query_results <- query_results[,c(1:8,21,9:17,22,23,18:20)]
      }
    }
    
    return(query_results)
    
  }
  
  foreach(type=c("GWAS", "pQTL", "mQTL", "eQTL"), 
          .combine = rbind)  %dopar%  
    phenoscanner_query(rsid, type)
  
}


###################################################################
##### PhenoScanner Query #####
###################################################################

##### API Query #####


getPhenoScannerData <- function(rsid){

suppressMessages(library(phenoscanner))
suppressMessages(library(ddpcr))
suppressMessages(library(foreach))
suppressMessages(library(doParallel))

  #rsid = "rs140463209"
  snpinfo <- phenoscanner_snp(rsid)
  
  ### PheWAS
  if(nrow(snpinfo)>0){
    
    ## Parallelize
    cl<-makeCluster(4)
    registerDoParallel(cl)
    results <- phewas(rsid)
    stopCluster(cl)
    
    ## Process results
    if(nrow(results)>0){
      results$priority <- 0
      results$priority[results$category=="Immune system" | results$category=="Neurodegenerative" | results$category=="Neurological"] <- 1
      results <- results[results$dataset!="GRASP",]
      results$direction[results$direction=="-"] <- "minus"
      results[results=="NA"] <- "N/A"; results[results=="-"] <- "N/A"
      results$direction[results$direction=="minus"] <- "-"
      results <- results[results$p!="N/A",]
      results <- results[order(-results$priority, as.numeric(results$p)),]; results$priority <- NULL
      names(results)[names(results)=="snp"] <- "snpid"
      names(results)[names(results)=="a1"] <- "effect_allele"; names(results)[names(results)=="a2"] <- "other_allele"
    }
    
    cat("  ",rsid,"-- PheWAS\n")
    
  }else{
    results <- data.frame()
  }
  
  ##### JSON #####
  combined <- list(snps=snpinfo,results=results)
  return(combined)
}

# getPhenoScannerData("rs140463209")



##### Save #####
#write(combined, file=paste0(rsid,".json"))
#
###### Timing #####
#cat("   Time taken:",as.numeric((proc.time()-ptm)[3]),"secs\n")
#
###### Exit #####
#q("no")