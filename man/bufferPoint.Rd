% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/util-bufferPoint.R
\name{bufferPoint}
\alias{bufferPoint}
\title{Create linear ring from point}
\usage{
bufferPoint(point)
}
\arguments{
\item{point}{A vector of longitude and latitude values}
}
\value{
A linear ring (with closure) as a numeric vector
}
\description{
Buffer ring creation from point
}
\details{
bufferPoint is a function that takes a longitude and latitude pair and creates
a buffered ring (i.e., a feature with non-zero area) centered.
}
\examples{
linearRing = bufferPoint(c(-111.48, 36.95))
}
\seealso{
\linkS4class{simplegeom}
}
\author{
Jordan S. Read
}
\keyword{internal}
\keyword{methods}
