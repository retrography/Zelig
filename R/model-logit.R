#' Logistic Regression for Dichotomous Dependent Variables
#'@param formula a symbolic representation of the model to be
#'   estimated, in the form \code{y ~ x1 + x2}, where \code{y} is the
#'   dependent variable and \code{x1} and \code{x2} are the explanatory
#'   variables, and \code{y}, \code{x1}, and \code{x2} are contained in the
#'   same dataset. (You may include more than two explanatory variables,
#'   of course.) The \code{+} symbol means ``inclusion'' not
#'   ``addition.'' You may also include interaction terms and main
#'   effects in the form \code{x1*x2} without computing them in prior
#'   steps; \code{I(x1*x2)} to include only the interaction term and
#'   exclude the main effects; and quadratic terms in the form
#'   \code{I(x1^2)}.
#'@param model the name of a statistical model to estimate.
#'   For a list of other supported models and their documentation see:
#'   \url{http://docs.zeligproject.org/articles/}.
#'@param data the name of a data frame containing the variables
#'   referenced in the formula or a list of multiply imputed data frames
#'   each having the same variable names and row numbers (created by
#'   \code{Amelia} or \code{\link{to_zelig_mi}}).
#'@param ... additional arguments passed to \code{zelig},
#'   relevant for the model to be estimated.
#'@param by a factor variable contained in \code{data}. If supplied,
#'   \code{zelig} will subset
#'   the data frame based on the levels in the \code{by} variable, and
#'   estimate a model for each subset. This can save a considerable amount of
#'   effort. You may also use \code{by} to run models using MatchIt
#'   subclasses.
#'@param cite If is set to 'TRUE' (default), the model citation will be printed
#'   to the console.
#'
#' @details
#' Additional parameters avaialable to this model include:
#' \itemize{
#'   \item weights: vector of weight values or a name of a variable in the dataset
#'   by which to weight the model. For more information see:
#'   \url{http://docs.zeligproject.org/articles/weights.html}.
#'   \item bootstrap: logical or numeric. If \code{FALSE} don't use bootstraps to
#'   robustly estimate uncertainty around model parameters due to sampling error.
#'   If an integer is supplied, the number of boostraps to run.
#'   For more information see:
#'   \url{http://docs.zeligproject.org/articles/bootstraps.html}.
#' }
#'
#' @return Depending on the class of model selected, \code{zelig} will return
#'   an object with elements including \code{coefficients}, \code{residuals},
#'   and \code{formula} which may be summarized using
#'   \code{summary(z.out)} or individually extracted using, for example,
#'   \code{coef(z.out)}. See
#'   \url{http://docs.zeligproject.org/articles/getters.html} for a list of
#'   functions to extract model components. You can also extract whole fitted
#'   model objects using \code{\link{from_zelig_model}}.
#'
#'@param below (defaults to 0) The point at which the dependent variable is censored from below. If any values in the dependent variable are observed to be less than the censoring point, it is assumed that that particular observation is censored from below at the observed value. (See for a Bayesian implementation that supports both left and right censoring.)
#'@param robust defaults to FALSE. If TRUE, zelig() computes robust standard errors based on sandwich estimators (see and ) and the options selected in cluster.
#'@param if robust = TRUE, you may select a variable to define groups of correlated observations. Let x3 be a variable that consists of either discrete numeric values, character strings, or factors that define strata. Then
#'z.out <- zelig(y ~ x1 + x2, robust = TRUE, cluster = "x3", model = "tobit", data = mydata)
#'means that the observations can be correlated within the strata defined by the variable x3, and that robust standard errors should be calculated according to those clusters. If robust = TRUE but cluster is not specified, zelig() assumes that each observation falls into its own cluster.
#'
#'@examples
#'library(Zelig)
#'data(turnout)
#'z.out1 <- zelig(vote ~ age + race, model = "logit", data = turnout,
#'cite = FALSE)
#'summary(z.out1)
#'summary(z.out1, odds_ratios = TRUE)
#'x.out1 <- setx(z.out1, age = 36, race = "white")
#'s.out1 <- sim(z.out1, x = x.out1)
#'summary(s.out1)
#'plot(s.out1)
#'
#' @seealso Vignette: \url{http://docs.zeligproject.org/articles/zelig_logit.html}
#' @import methods
#' @export Zelig-logit
#' @exportClass Zelig-logit
#'
#' @include model-zelig.R
#' @include model-gee.R
#' @include model-gamma.R
#' @include model-zelig.R
#' @include model-glm.R
#' @include model-binchoice.R

zlogit <- setRefClass("Zelig-logit",
                      contains = "Zelig-binchoice")

zlogit$methods(initialize = function() {
    callSuper()
    .self$name <- "logit"
    .self$link <- "logit"
    .self$description = "Logistic Regression for Dichotomous Dependent Variables"
    .self$packageauthors <- "R Core Team"
    .self$wrapper <- "logit"
})

zlogit$methods(mcfun = function(x, b0 = 0, b1 = 1, ..., sim = TRUE) {
    mu <- 1/(1 + exp(-b0 - b1 * x))
    if (sim) {
        y <- rbinom(n = length(x), size = 1, prob = mu)
        return(y)
    } else {
        return(mu)
    }
  }
)


zlogit$methods(
    show = function(odds_ratios = FALSE, ...) {
    if (odds_ratios & !.self$mi & !.self$bootstrap) {
        summ <- .self$zelig.out %>%
            do(summ = {cat("Model: \n")
                ## Replace coefficients with odds-ratios
                .z.out.summary = base::summary(.$z.out)
                .z.out.summary$coefficients[, c(1, 2)] <- exp(.z.out.summary$coefficients[, c(1, 2)])
                colnames(.z.out.summary$coefficients)[c(1, 2)] <- paste(colnames(.z.out.summary$coefficients)[c(1, 2)],
                     '(OR)')
                print(.z.out.summary)
            })
    }
    else {
        callSuper(...)
    }
        #print(base::summary(.self$zelig.out))
    }
)
