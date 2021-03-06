#' Meshing tools
#' 
#' A toolbox for meshing operations: elastic mesh mapping, Iteratively closest point matching, vertex selection, ...,
#' 
#' \tabular{ll}{
#' Package: \tab mesheR\cr
#' Type: \tab Package\cr
#' Version: \tab 0.4.151016\cr
#' Date: \tab 2015-10-16\cr
#' License: \tab GPL\cr
#' LazyLoad: \tab yes\cr }
#' 
#' @name mesheR-package
#' @aliases mesheR-package mesheR
#' @docType package
#' @author Stefan Schlager
#' 
#' Maintainer: Stefan Schlager <zarquon42@@gmail.com>
#' @references To be announced
#' @keywords package
#' @useDynLib mesheR
#' @importFrom Morpho angle.calc closemeshKD invertFaces facenormals file2mesh mcNNindex meshcube meshDist meshres projRead rmUnrefVertex rmVertex rotmesh.onto rotonmat rotonto tangentPlane tps3d unrefVertex vert2points tps3d
#' @importFrom Rvcg vcgBorder vcgClost vcgGetEdge vcgRaySearch vcgNonBorderEdge vcgSmooth vcgClostKD
#' @importFrom parallel detectCores mclapply
#' @importFrom Rcpp evalCpp
#' 

NULL
