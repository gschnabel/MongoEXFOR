

unlistNA <- function(x,...) {
  x[sapply(x,is.null)] <- NA
  unlist(x,...)
}


charAt <- function(i, x) { substring(x,i,i) }
