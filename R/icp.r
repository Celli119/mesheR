#' Iterative closest point matching between two triangular meshes.
#' 
#' performs rigid body transformations (and scaling if requested) to map a
#' reference mesh onto a target mesh
#' 
#' the registration is done by minimising squared distances between reference
#' vertices and closest points on the target surface (a.k.a. Procrustes
#' registration)
#' 
#' @param mesh1 object of class "mesh3d". 
#' @param mesh2 object of class "mesh3d". 
#' @param iterations integer
#' @param lm1 optional: kx3 matrix containing reference points on mesh1. 
#' @param lm2 optional: kx3 matrix containing reference points on mesh2.
#' @param uprange quantile of distances between vertices of mesh1 and closest
#' points on mesh2. All hit points on mesh2 farther away than the specified
#' quantile are not used for matching.
#' @param maxdist maximum distance for closest points to be included for matching. Overrides uprange, if specified.
#' @param minclost integer: only valid if maxdist is specified. If less than maxdist closest points are found, maxdist is increased by distinc (see below) until the specified number is reached.
#' @param distinc numeric: amount to increment maxdist until minclost points are within this disatnce.
#' @param rhotol maximum allowed angle of which normals are allowed to differ
#' between reference points and hit target points. Hit points above this
#' threshold will be neglected.
#' @param k integer: number of closest triangles on target that will be
#' searched for hits.
#' @param reflection logical: allow reflection.
#' @param pro character: algorithm for closest point search "morpho" calls
#' closemeshKD from the package Morpho, while vcg calls vcgClostKD from Rvcg.
#' If the tow meshes have only little or no overlap, "vcg" can be really slow. Otherwise very fast. "morpho" is the stable but somewhat slower algorithm.
#' @param silent logical: no verbosity
#' @param subsample integer use a subsample (using kmeans clustering) to find closest points for  - subsample specifies the size of this subsample.
#' @param subsampletype select type of subsampling (see \code{vcgSample} for details)
#' @param type set type of affine transformation: options are "affine", "rigid" and "similarity" (rigid + scale)
#' @param getTransform logical: if TRUE, a list containing the transformed mesh and the 4x4 transformation matrix.
#' @param pcAlign if TRUE, surfaces are prealigned by principal axis. Overrides intial landmark based alignment.
#' @param threads integer: threads to use in closest point search.
#' @return if \code{getTransform=FALSE}, the tranformed mesh1 is returned and otherwise a list containing
#'
#' \item{mesh}{tranformed mesh1}
#' \item{transform}{4x4 transformation matrix}
#' @author Stefan Schlager
#' @seealso \code{\link{rotmesh.onto}}, \code{\link{rotonto}}
#' @references Zhang Z. 1994. Iterative point matching for registration of
#' free-form curves and surfaces International Journal of Computer Vision
#' 13:119-152.
#' @keywords ~kwd1 ~kwd2
#' @examples
#' 
#' require(Morpho)
#' data(nose)
#' warpnose.long <- tps3d(shortnose.mesh,shortnose.lm,longnose.lm)
#' rotnose <- icp(warpnose.long,shortnose.mesh,lm1=longnose.lm,lm2=shortnose.lm,rhotol=0.7,uprange=0.9)
#' \dontrun{
#' require(rgl)
#' shade3d(rotnose,col=2,alpha=0.7)
#' shade3d(shortnose.mesh,col=3,alpha=0.7)
#' }
#' @importFrom Morpho fastKmeans
#' @export icp
icp <- function(mesh1, mesh2, iterations=3,lm1=NULL, lm2=NULL, uprange=0.9, maxdist=NULL, minclost=50, distinc=0.5, rhotol=pi, k=50, reflection=FALSE,pro=c("vcg","morpho"), silent=FALSE,subsample=NULL,subsampletype=c("km","pd"),type=c("rigid","similarity","affine"),getTransform=FALSE,pcAlign=FALSE,threads=0) {
      meshorig <- mesh1 <- vcgUpdateNormals(mesh1)
      mesh2 <- vcgUpdateNormals(mesh2)
       if (pcAlign) {
                mesh1 <- pcAlign(mesh1,mesh2,optim=FALSE)
                if (!is.null(lm1))
                    lm1 <- applyTransform(lm1,computeTransform(mesh2,mesh1))
            }
      
      if (!is.null(subsample)) {
          subsampletype <- match.arg(subsampletype[1],c("pd","km"))
          if (subsampletype == "pd")
              mysample <- Rvcg::vcgSample(mesh1,type=subsampletype,SampleNum=subsample,MCsamp = 20)
          else
              mysample <- fastKmeans(mesh1,k=subsample,threads=threads)$centers
          
      }
      
      pro <- substring(pro[1],1L,1L)
      if (pro == "v") {
          project3d <- vcgClostKD
      } else if (pro == "m") {
          project3d <- closemeshKD
      }
      type <- match.arg(type,c("rigid","similarity","affine"))
      if (!is.null(lm1) && !pcAlign){## perform initial rough registration
          trafo <- computeTransform(lm2,lm1,type=type,reflection=reflection)
          mesh1 <- applyTransform(mesh1,trafo)
      }
      
      if (!silent) 
          cat(paste0("\n performing ",type," registration\n\n") )
      count <- 0
      while (count < iterations) {
          if (!silent)
              cat("*")
          copymesh <- mesh1
          if (!is.null(subsample)) {
              mysample <- vcgClostKD(mysample,mesh1,threads=threads)
              minclost <- min(minclost,subsample)
              copymesh <- mysample
          }
          proMesh <- project3d(copymesh,mesh2,sign=F,k=k,threads=threads) ## project mesh1 onto mesh2
          x1 <- vert2points(copymesh)
          x2 <- vert2points(proMesh)
          dists <- abs(proMesh$quality)
         
          ## check if normals angles are below rhotol
          
          normchk <- normcheck(copymesh,proMesh)
          goodnorm <- which(normchk < rhotol)
          x1 <- x1[goodnorm,]
          x2 <- x2[goodnorm,]
          dists <- dists[goodnorm]
          
          ## check distances of remaining points and select points
          if (is.null(maxdist)) {
              qud <- quantile(dists,probs=uprange)
              good <- which(dists <= qud)
          } else { 
              qud <- maxdist
              good <- which(dists <= qud)
              increase <- distinc
              while (length(good) < minclost) {
                  ## distgood <- as.logical(abs(clost$quality) <= (dist+increase))
                  good <- which(dists <= (qud+increase))
                  if (!silent)
                      cat(paste("distance increased to",qud+increase,"\n"))
                  increase <- increase+distinc
              }
          }
          trafo <- computeTransform(x2[good,],x1[good,],type=type)
          mesh1 <- applyTransform(mesh1,trafo)
          if (!is.null(subsample))
              mysample <- applyTransform(mysample,trafo)
          count <- count+1
      }
      if (!silent)
          cat("\n")
      if (getTransform) {
          trafo <- computeTransform(vert2points(mesh1),vert2points(meshorig),type=type)
          if (!is.null(lm1))
              lm1 <- applyTransform(lm1,trafo)
          return(list(mesh=mesh1,transform=trafo,landmarks=lm1))
      } else {
          return(mesh1)
      }
  }
#' compare normal directions between two states of a mesh
#'
#' compare normal directions between two states of a mesh
#' @param mesh1 triangular mesh
#' @param mesh2 triangular mesh
#'
#' @return numeric vector containing angles between corresponding normals
#' @export normcheck

normcheck <- function(mesh1,mesh2)
  {
    x1norm <- mesh1$normals[1:3,]
    x2norm <- mesh2$normals[1:3,]
    normcheck <- .Call("angcheck",x1norm,x2norm)
    return(normcheck)
  }
