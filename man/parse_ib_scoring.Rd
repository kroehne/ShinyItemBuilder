% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/parse_ib_scoring.R
\name{parse_ib_scoring}
\alias{parse_ib_scoring}
\title{Parse CBA ItemBuilder Scoring JSON}
\usage{
parse_ib_scoring(scoringjson)
}
\arguments{
\item{scoringjson}{Scoring JSON as provided by the CBA ItemBuilder runtime.}
}
\value{
data frame with all hits and result texts
}
\description{
`parse_ib_scoring` converts the JSON to a data.frame
}
\details{
The returned object returns a data.frame containing the scoring provided as JSON.
}
\examples{
\dontrun{
 demo <- parse_ib_scoring(json)
}
}
