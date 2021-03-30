withWarnings <- function(expr) {
    #https://stackoverflow.com/a/4947528/949513
    myWarnings <- NULL
    wHandler <- function(w) {
        myWarnings <<- c(myWarnings, list(w))
        invokeRestart("muffleWarning")
    }
    val <- withCallingHandlers(expr, warning = wHandler)
    list(value = val, warnings = myWarnings)
} 
