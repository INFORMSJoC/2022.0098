#' PIE: Partially Interpretable Model
#'
#' Partially Interpretable Estimators (PIE), which jointly train an interpretable model and a black-box model to
#' achieve high predictive performance as well as partial model transparency. PIE is designed to attribute a prediction
#' to contribution from individual features via a linear additive model to achieve interpretability while complementing
#' the prediction by a black-box model to boost the predictive performance. Experimental results show that PIE achieves
#' comparable accuracy to the state-of-the-art black-box models on tabular data. In addition, the understandability of PIE
#' is close to linear models as validated via human evaluations.
#'
#' @param X           A matrix for the dataset features with numerical splines.
#' @param y           A vector for the dataset target label.
#' @param lasso_group A vector that indicates groups
#' @param X_orig  A matrix for the dataset features without numerical splines.
#' @param lambda1   A numeric number for group lasso penalty. The larger the value, the larger the penalty.
#' @param lambda2   A numeric number for black-box model. The larger the value, the larger contribution of XGBoost model.
#' @param iter  A numeric number for iterations.
#' @param eta    A numeric number for learning rate of XGBoost model.
#' @param nrounds     A numeric number for number of rounds of XGBoost model.
#' @param ...     Additional arguments passed to the XGBoost function.
#'
#' @details
#' The PIE_fit function use training dataset to train the PIE model through jointly train an interpretable model and a black-box model to
#' achieve high predictive performance as well as partial model transparency.
#'
#' @return An object of class \code{PIE} containing the following components:
#' \item{Betas}{The coefficient of group lasso model}
#' \item{Trees}{The coefficients of XGBoost trees}
#' \item{rrMSE_fit}{A matrix containing the evaluation between group lasso and y, and evaluation between full model and y for each iteration.}
#' \item{GAM_pred}{A matrix containing the contribution of group lasso in each iteration.}
#' \item{Tree_pred}{A matrix containing the contribution of XGBoost model in each iteration.}
#' \item{best_iter}{The number of the best iteration.}
#' \item{lambda1}{The \code{lambda1} tuning parameter used in PIE.}
#' \item{lambda2}{The \code{lambda2} tuning parameter used in PIE.}
#'
#' @examples
#' # Load the training data
#' data("winequality")
#' 
#' # Which columns are numerical?
#' num_col <- 1:11
#' # Which columns are categorical?
#' cat_col <- 12
#' # Which column is the response?
#' y_col <- ncol(winequality)
#' 
#' # Data Processing
#' dat <- data_process(X = as.matrix(winequality[, -y_col]), 
#'   y = winequality[, y_col], 
#'   num_col = num_col, cat_col = cat_col, y_col = y_col)
#' 
#' # Fit a PIE model
#' fold <- 1
#' fit <- PIE_fit(
#'   X = dat$spl_train_X[[fold]],
#'   y = dat$train_y[[fold]],
#'   lasso_group = dat$lasso_group,
#'   X_orig = dat$orig_train_X[[fold]],
#'   lambda1 = 0.01, lambda2 = 0.01, iter = 5, eta = 0.05, nrounds = 200
#' )
#' 
#' @export
PIE_fit <- function(X, y, lasso_group, X_orig, lambda1, lambda2, iter, eta, nrounds, ...) {
  y_orig <- y
  Betas <- matrix(, nrow = ncol(X) + 1, ncol = iter)
  Trees <- vector("list", iter)
  rrMSE_fit <- matrix(, nrow = 2, ncol = iter)
  GAM_pred <- matrix(0, nrow = length(y), ncol = iter)
  Tree_pred <- matrix(0, nrow = length(y), ncol = iter)

  for (i in 1:iter) {
    data <- data.frame(cbind(X, y))
    model <- gglasso(X, y, lasso_group, loss = "ls", lambda = lambda1)
    Betas[, i] <- coef(model)
    GAM_pred[, i] <- (as.matrix(X) %*% as.vector(Betas[2:(ncol(X) + 1), i])) + Betas[1, i]
    res1 <- y - GAM_pred[, i]
    rrMSE_fit[1, i] <- RPE(rowSums(GAM_pred), y_orig)
    ########################## XGboost
    dtrain <- xgb.DMatrix(data = as.matrix(X_orig), label = res1)
    params <- list(booster = "gbtree", objective = "reg:squarederror", eta = eta, max_depth = 6, ...)
    Trees[[i]] <- xgb.train(params = params, data = dtrain, nrounds = nrounds, eval_metric = "rmse")
    Tree_pred[, i] <- lambda2 * (predict(Trees[[i]], dtrain))
    ############################
    y <- res1 - Tree_pred[, i]
    rrMSE_fit[2, i] <- RPE((rowSums(Tree_pred) + rowSums(GAM_pred)), y_orig)
    if (i > 1) {
      if (rrMSE_fit[2, i] >= rrMSE_fit[2, i - 1]) {
        best_iter <- i - 1
        break
      } else {
        best_iter <- i
      }
    }
  }
  ret <- list(Betas = Betas, Trees = Trees, rrMSE_fit = rrMSE_fit, 
              GAM_pred = GAM_pred, Tree_pred = Tree_pred, best_iter = best_iter,
              lambda1 = lambda1, lambda2 = lambda2)
  class(ret) <- "PIE"
  ret
}
