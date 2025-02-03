#' PIE: A Partially Interpretable Model with Black-box Refinement
#'
#' The PIE package implements a novel Partially Interpretable Model (PIE) framework
#' introduced by Wang et al. <arxiv:2105.02410>. This framework jointly train an interpretable model
#' and a black-box model to achieve high predictive performance as well as partial model transparency.
#'
#' @section Functions:
#' - \code{predict.PIE()}: Main function for generating predictions with the PIE model on dataset.
#' - \code{PIE()}: Main function for training the PIE model with dataset.
#' - \code{data_process()}: Process data into the format that can be used by PIE model.
#' - \code{sparsity_count()}: Counts the number of features used in group lasso.
#' - \code{RPE()}: Evaluate the RPE of a PIE model.
#' - \code{MAE()}: Evaluate the MAE of a PIE model.
#'
#'
#'
#' For more details, see the documentation for individual functions.
#' @importFrom stats predict coef
#' @importFrom splines ns
#' @import gglasso
#' @import xgboost
#'
#' @name PIE
#' @keywords intrepretable-machine-learning
"_PACKAGE"

#' Wine Quality Data
#'
#' This dataset contains 1000 subsamples from the original data.
#'
#' @name winequality
#' @aliases winequality
#' @title Wine Quality Data
#'
#' @usage
#' data(winequality)
#'
#' @description
#' This dataset contains 1000 subsamples from the original data.
#'
#' @return
#' A matrix with 1000 rows and 13 columns. The first 11 columns are numerical variables, the 12th column contains categorical variable, and the last column is the response.
#' 
#' @source
#' The data were introduced in Alon et al. (1999).
#'
#' @references
#' Alon, U., Barkai, N., Notterman, D.A., Gish, K., Ybarra, S., Mack, D., and Levine, A.J. (1999). 
#' ``Broad patterns of gene expression revealed by clustering analysis of tumor and normal colon tissues probed by oligonucleotide arrays,''
#' \emph{Proceedings of the National Academy of Sciences}, \bold{96}(12), 6745--6750.
#'
#' @examples
#' # Load the dcsvm library
#' library(PIE)
#'
#' # Load the dataset
#' data(winequality)
#'
#' @keywords data set
NULL




