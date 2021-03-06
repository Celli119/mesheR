% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/colorMesh.r
\name{colorMesh}
\alias{colorMesh}
\title{Assign a color to a mesh globally}
\usage{
colorMesh(mesh, col)
}
\arguments{
\item{mesh}{triangular mesh of class \code{mesh3d}}

\item{col}{color}
}
\value{
mesh with material adequately set.
}
\description{
Assign a color to a mesh globally
}
\examples{
require(Rvcg)
data(humface)
humcol <- colorMesh(humface, "red")
}

