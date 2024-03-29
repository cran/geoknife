% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/00-gconfig.R
\name{gconfig}
\alias{gconfig}
\title{configure geoknife settings}
\usage{
gconfig(..., no.readonly = FALSE)
}
\arguments{
\item{\dots}{values for gconfig}

\item{no.readonly}{currently not implemented for \code{TRUE}}
}
\value{
Borrowed text and functionality from \code{\link[graphics]{par}}. 
When parameters are set, their previous values are returned in an invisible named list. 
Such a list can be passed as an argument to par to restore the parameter values. Use gconfig(no.readonly = TRUE) 
for the full list of parameters that can be restored. When just one parameter is queried, the value of that 
parameter is returned as (atomic) vector. When two or more parameters are queried, their values are returned 
in a list, with the list names giving the parameters. Note the inconsistency: setting one parameter returns a list, 
but querying one parameter returns a vector.
}
\description{
access and set defaults for geoknife configuration
}
\examples{
gconfig # all config
gconfig('wait')
gconfig('sleep.time' = 10)
gconfig('sleep.time' = 8, wait=TRUE)
gconfig('progress' = FALSE)
}
