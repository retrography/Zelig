#' Survey models in Zelig for weights for complex sampling designs
#'
#' @import methods
#' @export Zelig-survey
#' @exportClass Zelig-survey
#'
#' @include model-zelig.R
zsurvey <- setRefClass("Zelig-survey", contains = "Zelig")

zsurvey$methods(initialize = function() {
    callSuper()
    .self$fn <- quote(survey::svyglm)
    .self$packageauthors <- "Thomas Lumley"
    .self$modelauthors <- "Nicholas Carnes"
    .self$acceptweights <- TRUE
})

zsurvey$methods(zelig = function(formula, data, ids = ~1, probs = NULL,
                                strata = NULL, fpc = NULL, nest = FALSE,
                                check.strata = !nest, repweights = NULL,
                                type = NULL, combined.weights = FALSE,
                                rho = NULL, bootstrap.average = NULL,
                                scale = NULL, rscales = NULL,
                                fpctype = "fraction", ..., weights = NULL,
                                by = NULL, bootstrap = FALSE) {
    .self$zelig.call <- match.call(expand.dots = TRUE)

    warning("Not all features are available in Zelig Survey.\nConsider using surveyglm and setx directly.\nFor details see: <http://docs.zeligproject.org/articles/to_zelig.html>.",
            call. = FALSE)

    recastString2Formula <- function(a) {
        if (is.character(a)) {
            a <- as.Formula(paste("~", a))
        }
        return(a)
    }

    extract_vector <- function(x, df = data) {
        if ("formula" %in% class(x))
            x <- as.character(x)[[2]]
        if (is.character(x))
            if (x %in% names(df))
                x <- df[, x]
        return(x)
    }

    checkLogical <- function(a, name = "") {
        if (!("logical" %in% class(a))) {
            cat(paste("Warning: argument ", name, " is a logical and should be set to TRUE for FALSE.",
                sep = ""))
            return(FALSE)
        } else {
            return(TRUE)
        }

    }


    localWeights <- weights # avoids CRAN warning about deep assignment from treatment existing separately as argument and field

    ## Check arguments:

    ## Zelig generally accepts formula names of variables present in dataset, but survey
    ## package looks for formula expressions or data frames, so make conversion of any
    ## character arguments.
    ids <- recastString2Formula(ids)
    probs <- recastString2Formula(probs)
    # Convert to vector from data frame as formula experssion for weights was
    # not being passed
    localWeights <- extract_vector(localWeights)
    #localWeights <- recastString2Formula(localWeights)
    strata <- recastString2Formula(strata)
    fpc <- recastString2Formula(fpc)
    checkforerror <- checkLogical(nest, "nest")
    checkforerror <- checkLogical(check.strata, "check.strata")
    repweights <- recastString2Formula(repweights)
    # type should be a string
    checkforerror <- checkLogical(combined.weights, "combined.weights")
    # rho is shrinkage factor scale is scaling constant rscales is scaling constant

    if (is.null(repweights)) {
        design <- survey::svydesign(data = data, ids = ids, probs = probs,
                                    strata = strata, fpc = fpc, nest = nest,
                                    check.strata = check.strata,
                                    weights = localWeights)
    } else {
        design <- survey::svrepdesign(data = data, repweights = repweights,
                                        type = type, weights = localWeights,
                                        combined.weights = combined.weights,
                                        rho = rho,
                                        bootstrap.average = bootstrap.average,
            scale = scale, rscales = rscales, fpctype = fpctype, fpc = fpc)
    }

    .self$model.call <- as.call(list(.self$fn,
                                formula = .self$zelig.call$formula,
                                design = design))  # fn will be set again by super, but initialized here for clarity
    .self$model.call$family <- call(.self$family, .self$link)

    callSuper(formula = formula, data = data, weights = localWeights, ...,
              by = by, bootstrap = bootstrap)
})
