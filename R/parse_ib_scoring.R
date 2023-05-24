# parse_ib_scoring.R

shinyassess_internal_parse_ib_scoring <- function(scoringjson){

  scoring <- jsonlite::fromJSON(scoringjson)

  a <- list()
  rt <- list()
  ht <- list()
  for(key in names(scoring)){
    s <- unlist(strsplit(key,"\\."))
    if(length(s)>1 && (s[1] =="hit"||s[1] =="mis")){
      a[s[2]] <- scoring[key]
      ht[s[2]] <- s[1]
    } else  if(length(s)>1 && s[1] =="hitText"){
      rt[s[2]] <- scoring[key]
    }
  }

  #d <- data.frame(cbind(Name=names(a),Active=a,ResultText=rt,Type=ht))

  #d <- data.frame(cbind(Name=unlist(names(a)),
  #                      Active=as.logical(unlist(a)),
  #                      ResultText=unlist(rt),
  #                      Type=unlist(ht)))

  d <- data.frame(Name=unlist(names(a)),
                  Active=as.logical(unlist(a)),
                  ResultText=unlist(rt),
                  Type=unlist(ht))

  rownames(d)<-NULL
  d
}

# shinyassess_internal_parse_ib_scoring('{"hit.task_1a_correct":false,"hitText.task_1a_correct":"","hitWeighted.task_1a_correct":0,"hitClass.task_1a_correct":"task_1a","hit.task_1a_incorrect":true,"hitText.task_1a_incorrect":"","hitWeighted.task_1a_incorrect":1,"hitClass.task_1a_incorrect":"task_1a","hit.task_1a_missing":false,"hitText.task_1a_missing":"","hitWeighted.task_1a_missing":0,"hitClass.task_1a_missing":"task_1a","hit.task_1a_Verh":false,"hitText.task_1a_Verh":"","hitWeighted.task_1a_Verh":0,"hitClass.task_1a_Verh":"task_1a","hit.task_1a_raw1":true,"hitText.task_1a_raw1":"1","hitWeighted.task_1a_raw1":1,"hitClass.task_1a_raw1":"task_1a_raw1","hit.task_1a_raw2":true,"hitText.task_1a_raw2":"2","hitWeighted.task_1a_raw2":1,"hitClass.task_1a_raw2":"task_1a_raw2","hitsAccumulated":3,"hitsCount":3,"missesAccumulated":0,"missesCount":0,"classHitWeighted.task_1a":1,"classHitWeighted.task_1a_raw2":1,"classHitWeighted.task_1a_raw1":1,"classResult.task_1a":false,"classResult.task_1a_raw2":true,"classResult.task_1a_raw1":true,"classMaxWeighted":1,"classMaxName":"task_1a","totalResult":1,"nbUserInteractions":6,"nbUserInteractionsTotal":6,"firstReactionTime":872,"firstReactionTimeTotal":872,"taskExecutionTime":2488,"taskExecutionTimeTotal":0}')

