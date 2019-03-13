

#' Connect to EXFOR MongoDb
#'
#' @param ... see function \code{mongo} of package \code{mongolite}
#'
#' @return Returns a list with the function described below.
#'
#' @section Methods:
#' \describe{
#'   \item{\code{iterate(query = '{}', fields = '{"_id":0}', sort = '{}', skip = 0, limit = 0)}}{Runs query and returns iterator to read single records one-by-one.}
#'   \item{\code{find(query, expr, no.dollar, ...}}{Runs query and returns a data.table constructed from \code{expr} evaluated within the documents in the collection.}
#' }
#'
#' @export
#'
#' @import mongolite data.table
connectExfor <- function(...) {

  # functions
  exforIterator <- exforIterator
  getExforAsDt <- getExforAsDt

  dbcon <- mongo(...)
  assign("dbcon", dbcon, .pkgglobalenv)

  list(db=get("dbcon",.pkgglobalenv),
       iterate=exforIterator,
       find=getExforAsDt)
}


#' Create EXFOR Iterator
#'
#' @param ... arguments passed to \code{iterate} function of \code{mongolite} package,
#'            see \link[mongolite]{mongo}
#'
#' @return list with functions \code{getCur()} and \code{getNext()}
#' @export
#'
exforIterator <- function(...) {

  cur <- NULL

  getCur <- function() {
    cur
  }

  getNext <- function() {
    cur <<- it$one()
    if (!is.null(cur$COMMON)) {
      cur$COMMON$TABLE <<- as.data.table(lapply(cur$COMMON$TABLE,unlistNA))
    }
    if (!is.null(cur$DATA)) {
      cur$DATA$DESCR <<- unlistNA(cur$DATA$DESCR)
      cur$DATA$TABLE <<- as.data.table(lapply(cur$DATA$TABLE,unlistNA))
    }
    cur
  }

  dbcon <- get("dbcon",.pkgglobalenv)
  it <- dbcon$iterate(...)
  list(getCur=getCur,getNext=getNext)
}



getExforAsDt <- function(query, expr, no.dollar=TRUE, ...) {

  named.list <- function(...) {
    expr <- match.call()[-1]
    l <- lapply(expr,function(x) {
      tryCatch(eval(x,cur,parent.frame()), error = function(e) NA)
    })
    names(l) <- as.character( match.call()[-1] )
    l
  }
  nullToNA <- function(x) {
    if (is.null(x)) NA else x
  }

  expr <- substitute(expr)
  it <- exforIterator(query)
  resList <- list()
  while (!is.null(cur <- it$getNext())) {
    cur$named.list <- named.list
    cur$nullToNA <- nullToNA
    curList <- eval(expr,cur,parent.frame())
    if (is.null(curList)) next # NULL elements are skipped
    curDt <- as.data.table(curList)
    if (isTRUE(no.dollar)) setnames(curDt,gsub("\\$",".",names(curDt)))
    resList <- append(resList, list(curDt))
  }
  rbindlist(resList, use.names=TRUE, fill=TRUE, idcol = NULL)
}
