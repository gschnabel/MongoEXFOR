#' Make MongoDb Query String
#'
#' @param query the query expression
#' @param auto.quote should field names be automatically quoted (default is TRUE)
#'
#' @return a character string containing the JSON object for the query
#' @export
#'
makeQueryStr <- function(query, auto.quote=TRUE) {

  queryOps <- list(
    # logical
    and = function(...) {
      expr <- unlist(list(...))
      paste0('"$and": [',paste0(paste0("{",expr,"}"),collapse=", "),']')
    },
    or = function(...) {
      expr <- unlist(list(...))
      paste0('"$or": [',paste0(paste0("{",expr,"}"),collapse=", "),']')
    }
  )

  query <- paste0('{',eval(substitute(query),queryOps,parent.frame()),'}')

  if (isTRUE(auto.quote)) {
    pat <- '([,\\{\\[] *)([$0-9a-zA-Z.]+)( *:)'
    query <- gsub(pat,'\\1"\\2"\\3',query)
  }
  query <- gsub("\\\\","\\\\\\\\",query)

  query
}




