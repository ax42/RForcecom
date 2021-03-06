##################################
# Function to parse response from rforcecom.query
# * Internal Use Only 
##################################

query_parser <- function(root){
  top <- XML::xpathApply(root, "records", xmlToList)
  # if no subelements are lists, then proceed normally and assume not nested
  if (!any(sapply(top, FUN=function(x){any(sapply(x, is.list))}))){
    recs <- lapply(top, FUN=function(z){
      # drop attrs, not needed for one-level result
      return(as.data.frame(t(unlist(z[!(names(z)=='.attrs')]))))
    })
    final_recordset <- do.call('rbind.fill', recs)
  } else {
    all_parent_recs <- lapply(top, FUN=function(x){
      list_col <- which(sapply(x, is.list))
      attr_col <- which(names(x)=='.attrs')
      one_parent <- data.frame(t(unlist(x[setdiff(seq.int(length(x)), c(list_col, attr_col))])))
      if (length(list_col)>0){
        for (l in list_col){
          child <- x[l][[1]]
          if ('records' %in% names(child)){
            all_child_recs <- lapply(child[which(names(child)=='records')], FUN=function(record_list){
              if ('.attrs' %in% names(record_list)){
                record_data <- as.data.frame(t(unlist(record_list[!(names(record_list)=='.attrs')])))
                names(record_data) <- paste0(unname(record_list$.attrs['type']), '.', names(record_data))
                return(record_data)
              } else {
                return(NULL)
              }
              })
            all_child_recs <- do.call('rbind.fill', all_child_recs)
          } else {
            if ('.attrs' %in% names(child)){
              all_child_recs <- as.data.frame(t(unlist(child[!(names(child)=='.attrs')])))
              names(all_child_recs) <- paste0(unname(child$.attrs['type']), '.', names(all_child_recs))
            } else {
              all_child_recs <- NULL
            }
          }
          # fails on instance where all_child_recs=NULL, so use try
          try(one_parent <- cbind(one_parent, all_child_recs), silent = T)
        }
      }
      return(one_parent)
    })
    final_recordset <- do.call('rbind.fill', all_parent_recs)
  }
  return(final_recordset)
}