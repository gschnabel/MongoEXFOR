# MongoEXFOR - R package

This package provides an interface to EXFOR data stored
in a MongoDB database. Search queries are formulated 
using strings that represent JSON objects.

## Requirements

The packages `mongolite` and `data.table` must be installed.
In order to use the functionality of the package,
a running MongoDB server containing a collection
with EXFOR entries must be accessible.

## Basic usage

First, the package must be loaded and a connection to
a MongoDB server has to be set up:

```
library(MongoEXFOR)
db <- connectExfor("entries","exfor","mongodb://localhost")
```

The function `makeQueryStr` facilitates the creation of a 
query by providing the functions `and` and `or` to
connect individual conditions for a match.
The following query targets the first subentry of each 
entry that possesses an AUTHOR and DETECTOR field:

```
queryStr <- makeQueryStr(and(
                           'ID: { $regex: "001$", $options: "" }',
                           'BIB.AUTHOR: { $exists: true }',
                           'BIB.DETECTOR: { $exists: true }'
                         ))
```
For a comprehensive documentation of the query MongoDB
query language, consult the [MongoDB documentation](https://docs.mongodb.com/manual/reference/method/db.collection.find/).

This query string can be used in a search to collect 
relevant information. One possibility is to do a search
that returns a data table:

```
db$find(queryStr, {
    list(
        author = BIB$AUTHOR,
        detector = BIB$DETECTOR
    )
})
```
The second argument to `find` is an expression that should evaluate
to a list with named components.
Within the expression enclosed by the curly brackets, the information
of the current subentry is available as a nested list mirroring 
the structure of an EXFOR subentry. The code snippet above shows
how to retrieve the authors and the detector.
All other fields of the EXFOR subentry are accessible analogously 
(e.g., BIB$HISTORY, BIB$METHOD, DATA$TABLE, etc.).

It is also possible to do more sophisticated preprocessing of 
the information to be returned as a data table.
For instance, the `BIB$DETECTOR` field contains key codes in 
capital letters enclosed by brackets indicating the detector used.
Outside the bracket may be a more human-friendly name of the detector
and/or additional details. The following example shows how 
the free form text can be stripped away:

```
db$find(queryStr, {
    detStrRaw <- BIB$DETECTOR
    stopifnot(length(detStrRaw)==1)
    detStr <- regmatches(detStrRaw, regexpr("\\([A-Z1-9,]+\\)", detStrRaw))
    detStr <- gsub("[()]", "", detStr)
    stopifnot(!is.list(detStr), length(detStr)<=1)
    if (length(detStr)==0) NULL else
    list(
        author = BIB$AUTHOR,
        detector = detStr
    )
})
```
We see that the expression in curly brackets can contain additioanl R code
for preprocessing. The only important requirement is that at the end a named list
or NULL is returned. The return value NULL means that no row in the resulting 
data table will be included for the associated subentry.

Sometimes we may not want a data table summarizing matched subentries but want
to iterate over matched subentries in a loop.
This can be done in the following way:

```
it <- exforIterator(queryStr)
while (!is.null((curSub <- it$getNext()))) {
    # do something with the current subentry
    print(curSub$BIB$AUTHOR)
}
```

